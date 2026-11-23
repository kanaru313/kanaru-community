import 'dart:io';

import 'package:logging/logging.dart';

import '../../platform/domain/app_paths.dart';
import '../domain/app_font.dart';

final _log = Logger('font_storage');

/// Font files on disk: `<dataDir>/fonts/{catalog,custom}/<id>/`. Every path
/// builder rejects ids that are not valid font ids.
class FontStorage {
  FontStorage(this._paths);

  final AppPaths _paths;

  Directory get _root => Directory('${_paths.dataDir.path}/fonts');

  Directory get catalogDir => Directory('${_root.path}/catalog');
  Directory get customDir => Directory('${_root.path}/custom');

  /// Folder of font [id] of [kind] (catalog or custom). Throws
  /// [ArgumentError] for an invalid id or a built-in kind.
  Directory fontDir(AppFontKind kind, String id) {
    if (!isValidFontId(id)) {
      throw ArgumentError.value(id, 'id', 'invalid font id');
    }
    switch (kind) {
      case AppFontKind.catalog:
        return Directory('${catalogDir.path}/$id');
      case AppFontKind.custom:
        return Directory('${customDir.path}/$id');
      case AppFontKind.builtIn:
        throw ArgumentError.value(
          kind,
          'kind',
          'built-in fonts have no folder',
        );
    }
  }

  /// Font files of [font], sorted by name; empty when it is not installed.
  List<File> fontFiles(AppFont font) {
    final dir = fontDir(font.kind, font.id);
    if (!dir.existsSync()) return const [];
    final files = <File>[
      for (final e in dir.listSync(followLinks: false))
        if (e is File && _isFontFile(e.path)) e,
    ];
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Staging folder `<id>.tmp` of a catalog install; renamed to the font
  /// folder once complete. Throws [ArgumentError] for an invalid id.
  Directory stagingDir(String id) {
    final dir = fontDir(AppFontKind.catalog, id);
    return Directory('${dir.path}.tmp');
  }

  /// Ids of the catalog fonts on disk (a folder with at least one font file).
  Set<String> installedCatalogIds() {
    final ids = <String>{};
    try {
      if (!catalogDir.existsSync()) return ids;
      for (final e in catalogDir.listSync(followLinks: false)) {
        if (e is! Directory) continue;
        final id = e.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (!isValidFontId(id)) continue;
        if (fontFiles(
          AppFont(id: id, label: id, family: id, kind: AppFontKind.catalog),
        ).isNotEmpty) {
          ids.add(id);
        }
      }
    } on FileSystemException catch (err) {
      _log.warning('Cannot scan ${catalogDir.path}', err);
    }
    return ids;
  }

  /// Licence files (`OFL.txt`, `LICENSE*`) kept next to the fonts of [font].
  List<File> licenseFiles(AppFont font) {
    final dir = fontDir(font.kind, font.id);
    if (!dir.existsSync()) return const [];
    return [
      for (final e in dir.listSync(followLinks: false))
        if (e is File && _isLicenseFile(e.path)) e,
    ]..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Deletes the folder of [font] and everything in it. Missing is fine.
  void deleteFont(AppFont font) {
    final dir = fontDir(font.kind, font.id);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  /// Deletes half-written leftovers (`*.tmp` files and folders) of an
  /// interrupted install under the catalog and custom folders. Never throws.
  void repairTmpLeftovers() {
    for (final dir in [catalogDir, customDir]) {
      try {
        if (!dir.existsSync()) continue;
        for (final e in dir.listSync(followLinks: false)) {
          if (!e.path.endsWith('.tmp')) continue;
          try {
            e.deleteSync(recursive: true);
          } on FileSystemException catch (err) {
            _log.warning('Cannot delete leftover ${e.path}', err);
          }
        }
      } on FileSystemException catch (err) {
        _log.warning('Cannot scan ${dir.path}', err);
      }
    }
  }

  static bool _isLicenseFile(String path) {
    final name = path.split('/').last;
    return name == 'OFL.txt' || name.toUpperCase().startsWith('LICENSE');
  }

  static bool _isFontFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.ttf') || p.endsWith('.otf');
  }
}
