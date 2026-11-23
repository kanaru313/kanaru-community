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

  static bool _isFontFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.ttf') || p.endsWith('.otf') || p.endsWith('.ttc');
  }
}
