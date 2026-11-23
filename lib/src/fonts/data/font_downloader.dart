import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import '../../plugins/data/net/fetcher.dart';
import '../../plugins/domain/net/address_rules.dart';
import '../../plugins/domain/net/net_policy.dart';
import '../domain/font_catalog.dart';
import 'font_registrar.dart';
import 'font_storage.dart';
import 'zip_font_extractor.dart';

final _log = Logger('font_downloader');

/// A catalog font could not be installed. Nothing of it is left on disk.
class FontDownloadException implements Exception {
  const FontDownloadException(this.message);
  final String message;

  @override
  String toString() => 'FontDownloadException: $message';
}

typedef ZipExtractor = Future<Map<String, Uint8List>> Function(Uint8List zip);

/// Moves the finished staging folder to its final place.
typedef DirectoryMover = void Function(Directory from, String to);

void _renameDir(Directory from, String to) => from.renameSync(to);

/// Downloads a catalog font and installs it: fetch (public addresses only,
/// body capped at twice the declared size), SHA-256 check before anything is
/// written, unzip, write to `<id>.tmp`, rename to `<id>`, load into the
/// engine, register the licence. Any failure removes what was written.
class FontDownloader {
  FontDownloader({
    required this._fetcher,
    required this._storage,
    required this._registrar,
    this._extractor = extractFontZipInIsolate,
    this._mover = _renameDir,
  });

  final HttpFetcher _fetcher;
  final FontStorage _storage;
  final FontRegistrar _registrar;
  final ZipExtractor _extractor;
  final DirectoryMover _mover;

  /// Installs [font]. Throws [FontDownloadException] on any failure.
  Future<void> download(CatalogFont font) async {
    final staging = _storage.stagingDir(font.id);
    final target = _storage.fontDir(font.asAppFont.kind, font.id);
    var moved = false;
    try {
      final zip = await _fetch(font);
      final files = await _extractor(zip);
      _stage(staging, files);
      _install(font, staging, target);
      moved = true;
      await _registrar.ensureLoaded(font.asAppFont, _storage);
    } on FontDownloadException {
      _cleanup(staging, moved ? target : null);
      rethrow;
    } on Object catch (e, st) {
      _log.warning('Install of "${font.id}" failed', e, st);
      _cleanup(staging, moved ? target : null);
      throw FontDownloadException('${e.runtimeType}');
    }
    registerCatalogLicense(font, _storage, _registrar);
  }

  Future<Uint8List> _fetch(CatalogFont font) async {
    final result = await _fetcher.get(
      font.downloadUri,
      NetPolicy.package,
      catalogKind: AddressKind.public,
      maxBytes: font.sizeBytes * 2,
      expectedSize: font.sizeBytes,
    );
    final bytes = result.fold(
      (ok) => ok.bytes,
      (failure) =>
          throw FontDownloadException('fetch failed: ${failure.kind.name}'),
    );
    if (sha256.convert(bytes).toString() != font.sha256) {
      throw const FontDownloadException('checksum mismatch');
    }
    return bytes;
  }

  void _stage(Directory staging, Map<String, Uint8List> files) {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);
    for (final e in files.entries) {
      File('${staging.path}/${e.key}').writeAsBytesSync(e.value, flush: true);
    }
  }

  void _install(CatalogFont font, Directory staging, Directory target) {
    if (_storage.fontFiles(font.asAppFont).isNotEmpty) {
      throw const FontDownloadException('already installed');
    }
    // A folder without fonts is a leftover, never an install.
    if (target.existsSync()) target.deleteSync(recursive: true);
    _mover(staging, target.path);
  }

  void _cleanup(Directory staging, Directory? target) {
    for (final dir in [staging, ?target]) {
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException catch (e) {
        _log.warning('Cannot clean ${dir.path}', e);
      }
    }
  }
}

/// Adds the licence text kept with [font] to the licences page. Never throws.
void registerCatalogLicense(
  CatalogFont font,
  FontStorage storage,
  FontRegistrar registrar,
) {
  try {
    for (final file in storage.licenseFiles(font.asAppFont)) {
      registrar.registerLicense(font.label, file.readAsStringSync());
      return;
    }
  } on Object catch (e) {
    _log.warning('Cannot register the licence of "${font.id}"', e);
  }
}

/// Adds the licences of every catalog font on disk to the licences page.
/// Meant for startup, after the first frame. Never throws.
void registerInstalledCatalogLicenses(
  FontStorage storage,
  FontRegistrar registrar,
) {
  for (final id in storage.installedCatalogIds()) {
    final font = catalogFontById(id);
    if (font != null) registerCatalogLicense(font, storage, registrar);
  }
}
