import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'capped_output.dart';
import 'icon_check.dart';
import 'package_limits.dart';
import 'package_problem.dart';
import 'zip_directory_scan.dart';
import 'zip_entry_names.dart';

// `src/<name>.js`, flat; the whole file name is restricted.
final _scriptPath = RegExp(r'^src/([A-Za-z0-9_.-]+\.js)$');

/// The header of an `assets/<name>` entry. Reading the zip does not inflate
/// it: only [inflate] does, and only a seekbar package asks for that.
class ZipAssetEntry {
  const ZipAssetEntry._(this.path, this._header);

  /// Package path, `assets/<name>`.
  final String path;
  final ZipFileHeader _header;

  /// Size the header declares.
  int get declaredSize => _header.uncompressedSize;

  /// Zip compression method (0 stored, 8 deflate).
  int get method => _header.compressionMethod;

  /// The entry's bytes. A declared size over [cap] is `PackageTooLarge`, data
  /// that does not match the header is `PackageTooLarge` or `NotAZip`; every
  /// problem names [path].
  Uint8List inflate(int cap) {
    if (declaredSize > cap) throw PackageProblemError(PackageTooLarge(path));
    return _inflate(_header, path);
  }
}

/// The whitelisted entries of a plugin zip, still raw bytes.
class ZipContents {
  const ZipContents({
    required this.manifest,
    required this.scripts,
    this.assetHeaders = const {},
    this.icon,
    this.iconProblem,
  });

  /// `plugin.json` bytes.
  final Uint8List manifest;

  /// `src/` files by name (`search.js`), bytes not yet decoded.
  final Map<String, Uint8List> scripts;

  /// `assets/` entries by file name (`t.png`), headers only.
  final Map<String, ZipAssetEntry> assetHeaders;

  /// `icon.png` bytes, null when absent or [iconProblem] says it is bad.
  final Uint8List? icon;

  /// Why the icon was dropped (for logs); null when kept or absent.
  final String? iconProblem;
}

/// Reads [bytes] as a plugin zip entirely in memory. Throws
/// [PackageProblemError] for any rule broken; nothing is partly returned.
///
/// Only `plugin.json`, `icon.png` and `src/<name>.js` are inflated; the
/// `assets/<name>` entries are kept as headers for [ZipAssetEntry.inflate].
/// Other entries are ignored (a nested `plugin.zip` included) but their names, count
/// and declared sizes still count toward the limits. Every inflate is capped
/// at the entry's declared size, which is first checked against the entry's
/// cap, so an entry whose header lies about its size is refused instead of
/// filling memory.
///
/// Synchronous and CPU-bound on up to 5 MiB: callers run it in `Isolate.run`.
ZipContents readZip(Uint8List bytes) {
  if (bytes.length > maxPackageBytes) {
    throw const PackageProblemError(PackageTooLarge());
  }
  final headers = _readHeaders(bytes);
  for (final header in headers) {
    checkEntryName(header.filename);
    checkNotSymlink(header);
  }
  checkNoDuplicateNames(headers.map((h) => h.filename));
  var declaredTotal = 0;
  for (final header in headers) {
    declaredTotal += header.uncompressedSize;
    if (declaredTotal > maxUnpackedBytes) {
      throw PackageProblemError(PackageTooLarge(header.filename));
    }
  }

  final folder = topFolder(headers.map((h) => h.filename).toList());
  final prefix = folder == null ? '' : '$folder/';
  Uint8List? manifest;
  Uint8List? icon;
  String? droppedIcon;
  final scripts = <String, Uint8List>{};
  final assetHeaders = <String, ZipAssetEntry>{};
  var inflatedTotal = 0;
  for (final header in headers) {
    if (isFinderMetadata(header.filename)) continue;
    final name = header.filename.substring(prefix.length);
    final scriptMatch = _scriptPath.firstMatch(name);
    if (name.startsWith('assets/') &&
        assetFileName.hasMatch(name.substring(7))) {
      assetHeaders[name.substring(7)] = ZipAssetEntry._(name, header);
      continue;
    }
    final int cap;
    if (name == 'plugin.json') {
      cap = maxManifestBytes;
    } else if (name == 'icon.png') {
      cap = maxIconBytes;
    } else if (scriptMatch != null) {
      cap = maxScriptBytes;
    } else {
      continue;
    }
    final isIcon = name == 'icon.png';
    final Uint8List data;
    try {
      if (header.uncompressedSize > cap) {
        throw PackageProblemError(PackageTooLarge(header.filename));
      }
      data = _inflate(header);
    } on PackageProblemError catch (e) {
      // A broken icon is dropped like any bad icon; anything else is fatal.
      if (!isIcon) rethrow;
      droppedIcon = e.problem is PackageTooLarge
          ? 'over $cap B'
          : 'cannot be read';
      continue;
    }
    inflatedTotal += data.length;
    if (inflatedTotal > maxUnpackedBytes) {
      throw PackageProblemError(PackageTooLarge(header.filename));
    }
    if (name == 'plugin.json') {
      manifest = data;
    } else if (isIcon) {
      droppedIcon = iconProblem(data);
      icon = droppedIcon == null ? data : null;
    } else {
      scripts[scriptMatch!.group(1)!] = data;
    }
  }
  if (manifest == null) throw const PackageProblemError(MissingManifest());
  return ZipContents(
    manifest: manifest,
    scripts: scripts,
    assetHeaders: Map.unmodifiable(assetHeaders),
    icon: icon,
    iconProblem: droppedIcon,
  );
}

List<ZipFileHeader> _readHeaders(Uint8List bytes) {
  // Cheap walk first: the parser below allocates per central record.
  final expected = scanZipDirectory(bytes);
  final directory = ZipDirectory();
  try {
    directory.read(InputMemoryStream(bytes));
  } on Object {
    // The zip parser throws several types on hostile input; all mean the
    // same here.
    throw const PackageProblemError(NotAZip('central directory'));
  }
  if (directory.fileHeaders.length != expected) {
    throw const PackageProblemError(NotAZip('entry count'));
  }
  return directory.fileHeaders;
}

/// Inflates one entry: stored or deflate, not encrypted. The output is
/// capped at the declared size by a stream of our own, so data longer than
/// declared is `PackageTooLarge` whatever the zip package does; any other
/// failure is `NotAZip`. The size and CRC32 must match the header.
Uint8List _inflate(ZipFileHeader header, [String? label]) {
  final name = label ?? header.filename;
  final method = header.compressionMethod;
  if (header.generalPurposeBitFlag & 1 != 0) {
    throw PackageProblemError(NotAZip('encrypted: $name'));
  }
  if (method != 0 && method != 8) {
    throw PackageProblemError(NotAZip('compression $method: $name'));
  }
  final declared = header.uncompressedSize;
  final Uint8List raw;
  try {
    // The zip parser reads the local header lazily and may throw any type
    // on hostile input.
    final file = header.file;
    if (file == null) throw PackageProblemError(NotAZip('no data: $name'));
    raw = file.getRawContent();
  } on PackageProblemError {
    rethrow;
  } on Object {
    throw PackageProblemError(NotAZip('local header: $name'));
  }
  final Uint8List data;
  if (method == 0) {
    if (raw.length > declared) throw PackageProblemError(PackageTooLarge(name));
    data = raw;
  } else {
    final out = CappedOutput(declared);
    try {
      data = inflateRawCapped(raw, out);
    } on OutputOverrun {
      throw PackageProblemError(PackageTooLarge(name));
    } on FormatException {
      throw PackageProblemError(NotAZip('cannot inflate: $name'));
    }
  }
  if (data.length != declared || getCrc32(data) != header.crc32) {
    throw PackageProblemError(NotAZip('size or checksum: $name'));
  }
  return data;
}
