import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import '../../platform/data/atomic_file.dart';
import '../domain/app_font.dart';
import '../domain/custom_font.dart';
import '../domain/font_header_parser.dart';
import '../domain/font_label.dart';
import 'font_storage.dart';

final _log = Logger('custom_font_store');

/// Imported fonts on disk: one folder per font under `fonts/custom/` plus a
/// manifest `custom_fonts.json` (id -> label). The folders are the truth; the
/// manifest only holds the names.
class CustomFontStore {
  CustomFontStore(this._storage);

  final FontStorage _storage;
  Future<void> _tail = Future.value();

  File get _manifestFile =>
      File('${_storage.customDir.path}/custom_fonts.json');

  /// Imported fonts, sorted by name (case-insensitive). Never throws.
  List<CustomFont> list() {
    final manifest = _readManifest();
    final fonts = <CustomFont>[];
    try {
      if (_storage.customDir.existsSync()) {
        for (final e in _storage.customDir.listSync(followLinks: false)) {
          if (e is! Directory) continue;
          final id = e.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
          if (!isCustomFontId(id) || _filesOf(id).isEmpty) continue;
          fonts.add(
            CustomFont(
              id: id,
              label: manifest[id] ?? customFontFallbackLabel(id),
            ),
          );
        }
      }
    } on FileSystemException catch (e) {
      _log.warning('Cannot scan ${_storage.customDir.path}', e);
    }
    fonts.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return fonts;
  }

  /// Validates and stores [bytes]; the same bytes again give the existing
  /// font. Throws [CustomFontException]; a failed import leaves no folder and
  /// no manifest entry.
  Future<CustomFont> importBytes(String fileName, Uint8List bytes) =>
      _serial(() => _import(fileName, bytes));

  /// Deletes the folder of [id] and its manifest entry. Missing is fine.
  Future<void> delete(String id) => _serial(() async {
    final dir = _storage.fontDir(AppFontKind.custom, id);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final manifest = _readManifest()..remove(id);
    try {
      await _writeManifest(manifest);
    } on Object catch (e, st) {
      // The folder is gone, so the font is gone; a stale name is harmless.
      _log.warning('Cannot update the font manifest', e, st);
    }
  });

  Future<T> _serial<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  List<File> _filesOf(String id) => _storage.fontFiles(
    AppFont(id: id, label: id, family: id, kind: AppFontKind.custom),
  );

  Future<CustomFont> _import(String fileName, Uint8List bytes) async {
    if (bytes.length > maxCustomFontBytes) {
      throw const CustomFontException(CustomFontError.tooLarge);
    }
    final header = parseFontHeader(bytes);
    if (header == null) {
      throw const CustomFontException(CustomFontError.invalid);
    }
    final id = _idFor(
      header.family ?? sanitizeFontLabel(fontFileStem(fileName)),
      bytes,
    );
    final label = header.family ?? _fileLabel(fileName, id);
    final manifest = _readManifest();
    if (_filesOf(id).isNotEmpty) {
      return CustomFont(id: id, label: manifest[id] ?? label);
    }
    final dir = _storage.fontDir(AppFontKind.custom, id);
    final staging = Directory('${dir.path}.tmp');
    try {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
      if (dir.existsSync()) dir.deleteSync(recursive: true); // no font inside
      staging.createSync(recursive: true);
      final ext = header.isCff ? 'otf' : 'ttf';
      await File('${staging.path}/$id.$ext').writeAsBytes(bytes, flush: true);
      staging.renameSync(dir.path);
      manifest[id] = label;
      await _writeManifest(manifest);
    } on Object catch (e, st) {
      _log.warning('Import of "$fileName" failed', e, st);
      for (final d in [staging, dir]) {
        try {
          if (d.existsSync()) d.deleteSync(recursive: true);
        } on FileSystemException catch (_) {
          // Nothing more to do; startup removes `.tmp` leftovers.
        }
      }
      throw CustomFontException(CustomFontError.unwritable, '$e');
    }
    _log.info('Imported "$label" as "$id"');
    return CustomFont(id: id, label: label);
  }

  String _fileLabel(String fileName, String id) {
    final stem = sanitizeFontLabel(fontFileStem(fileName));
    return stem.isEmpty ? customFontFallbackLabel(id) : stem;
  }

  /// id -> label. A missing manifest gives an empty map; an unreadable one is
  /// moved aside (`.corrupt.<ms>`) and the labels fall back to the folders.
  Map<String, String> _readManifest() {
    final file = _manifestFile;
    try {
      if (!file.existsSync()) return {};
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map) throw const FormatException('not an object');
      return {
        for (final e in json.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      };
    } on Object catch (e, st) {
      _log.severe('Font manifest ${file.path} is unreadable', e, st);
      try {
        file.renameSync(
          '${file.path}.corrupt.${DateTime.now().millisecondsSinceEpoch}',
        );
      } on Object catch (err) {
        _log.warning('Cannot move the corrupt manifest aside', err);
      }
      return {};
    }
  }

  Future<void> _writeManifest(Map<String, String> manifest) async {
    _storage.customDir.createSync(recursive: true);
    try {
      await writeFileAtomic(_manifestFile, jsonEncode(manifest));
    } on Object {
      try {
        File('${_manifestFile.path}.tmp').deleteSync();
      } on FileSystemException catch (_) {
        // Never written, or already gone.
      }
      rethrow;
    }
  }

  static String _idFor(String label, Uint8List bytes) {
    final slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final cut = slug.length > 24
        ? slug.substring(0, 24).replaceAll(RegExp(r'_+$'), '')
        : slug;
    final base = cut.isEmpty ? 'font' : cut;
    final hash = sha256.convert(bytes).toString().substring(0, 8);
    return '$customFontIdPrefix${base}_$hash';
  }
}
