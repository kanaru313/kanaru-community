import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../domain/package/package_limits.dart';
import '../../domain/package/plugin_package.dart';
import 'plugin_package_cache.dart';
import 'plugin_store_rules.dart';

export 'plugin_package_cache.dart'
    show PluginPackageUnreadable, StoredPackage, scriptFileName;

final _log = Logger('plugin_store');

/// Writes one file and flushes it to disk. Replaced in tests to make a write
/// fail half way.
typedef WriteFileBytes = Future<void> Function(File file, List<int> bytes);

Future<void> _writeFlushed(File file, List<int> bytes) async {
  final handle = await file.open(mode: FileMode.write);
  try {
    await handle.writeFrom(bytes);
    await handle.flush();
  } finally {
    await handle.close();
  }
}

/// A package folder found on disk.
class PluginFolder {
  const PluginFolder(this.installId, this.packageDir);

  final String installId;
  final String packageDir;

  /// `<install_id>/<package_dir>`, the form of `livePackageFolders`.
  String get key => '$installId/$packageDir';
}

/// The package folders, `<data>/plugins/<install_id>/v<version>-<epochMs>/`.
/// A folder is written whole before the database points at it and removed
/// after the database stopped pointing at it, so the database never names a
/// half-written package. Names that come from outside (an id, a folder name,
/// a script name) are shape-checked before any file system call, so nothing
/// can leave the root.
class PluginFiles {
  PluginFiles(
    Directory dataDir, {
    int Function()? clock,
    WriteFileBytes? writeFile,
    int cacheEntries = 16,
  }) : root = Directory('${dataDir.path}/plugins'),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _write = writeFile ?? _writeFlushed,
       _cache = PluginPackageCache(maxEntries: cacheEntries);

  final Directory root;
  final int Function() _clock;
  final WriteFileBytes _write;
  final PluginPackageCache _cache;

  Directory _dir(String installId, String packageDir) =>
      Directory('${root.path}/$installId/$packageDir');

  /// Writes [package] into a new folder of [installId] and returns its name
  /// (the `package_dir` value): the original `plugin.json` bytes, `icon.png`
  /// when kept, and every `src/*.js`, each file flushed. A failure deletes
  /// what was written and rethrows. Throws [ArgumentError] before touching the
  /// disk for an id or script name with the wrong shape.
  Future<String> write(String installId, PluginPackage package) async {
    if (!isInstallIdShape(installId)) {
      throw ArgumentError.value(installId, 'installId', 'not an install id');
    }
    for (final name in package.scripts.keys) {
      if (!scriptFileName.hasMatch(name)) {
        throw ArgumentError.value(name, 'scripts', 'not a script file name');
      }
    }
    final version = package.manifest.version;
    var stamp = _clock();
    var name = 'v$version-$stamp';
    if (!isPackageDirShape(name)) {
      throw ArgumentError.value(name, 'packageDir', 'bad folder name');
    }
    while (await _dir(installId, name).exists()) {
      name = 'v$version-${++stamp}';
    }
    final dir = _dir(installId, name);
    try {
      await dir.create(recursive: true);
      await _write(File('${dir.path}/plugin.json'), package.manifestBytes);
      final icon = package.icon;
      if (icon != null) await _write(File('${dir.path}/icon.png'), icon);
      await Directory('${dir.path}/src').create();
      for (final entry in package.scripts.entries) {
        await _write(
          File('${dir.path}/src/${entry.key}'),
          utf8.encode(entry.value),
        );
      }
    } on Object {
      await _delete(dir);
      await _pruneParent(dir);
      rethrow;
    }
    return name;
  }

  /// The package of [row], read from its folder (cached per folder). Throws
  /// [PluginPackageUnreadable] when the row has no package, its folder name
  /// has the wrong shape, the files cannot be read, or the folder's
  /// `plugin.json` differs from the row's `manifest_json`.
  Future<StoredPackage> readPackage(PluginRow row) async {
    final dir = _folderOf(row);
    if (dir == null) {
      throw const PluginPackageUnreadable('the plugin has no package folder');
    }
    final key = '${row.installId}/${row.packageDir}';
    final stored = await _cache.load(key, dir);
    // The folder is write-once, so a different `plugin.json` means it was
    // changed from outside (a restore, a manual copy): not what was reviewed.
    final onDisk = stored.manifestText.startsWith('\uFEFF')
        ? stored.manifestText.substring(1)
        : stored.manifestText;
    if (onDisk != row.manifestJson) {
      _cache.evict(key);
      throw const PluginPackageUnreadable('plugin.json changed');
    }
    return stored;
  }

  /// The `icon.png` of [row]'s package, or null when it has none or it is
  /// unreadable or over its cap.
  Future<Uint8List?> readIcon(PluginRow row) async {
    final dir = _folderOf(row);
    if (dir == null) return null;
    final file = File('${dir.path}/icon.png');
    try {
      if (!await isPlainFile(file.path) || await file.length() > maxIconBytes) {
        return null;
      }
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Whether the folder [row] points at is on disk with its `plugin.json`
  /// (false for a row without a package).
  Future<bool> exists(PluginRow row) async {
    final dir = _folderOf(row);
    return dir != null &&
        await dir.exists() &&
        await isPlainFile('${dir.path}/plugin.json');
  }

  Directory? _folderOf(PluginRow row) {
    final packageDir = row.packageDir;
    if (packageDir == null ||
        !isInstallIdShape(row.installId) ||
        !isPackageDirShape(packageDir)) {
      return null;
    }
    return _dir(row.installId, packageDir);
  }

  /// Every well-named package folder under the root, for the sweep. Entries
  /// with other names, files and symbolic links are never listed (and so
  /// never followed). An unreadable entry is logged and skipped.
  Future<List<PluginFolder>> listFolders() async {
    final found = <PluginFolder>[];
    if (!await root.exists()) return found;
    try {
      await for (final plugin in root.list(followLinks: false)) {
        final id = _nameOf(plugin);
        if (plugin is! Directory || !isInstallIdShape(id)) continue;
        try {
          await for (final version in plugin.list(followLinks: false)) {
            final name = _nameOf(version);
            if (version is Directory && isPackageDirShape(name)) {
              found.add(PluginFolder(id, name));
            }
          }
        } on FileSystemException catch (error) {
          _log.warning('Skipped a plugin folder: ${error.runtimeType}');
        }
      }
    } on FileSystemException catch (error) {
      _log.warning('Plugin folder listing stopped: ${error.runtimeType}');
    }
    return found;
  }

  /// Deletes one package folder (and the plugin's folder when that is left
  /// empty). Returns whether a folder was deleted; a bad name is refused and
  /// a failure is logged, never thrown (the sweep retries).
  Future<bool> deleteFolder(String installId, String packageDir) async {
    if (!isInstallIdShape(installId) || !isPackageDirShape(packageDir)) {
      _log.warning('Refused to delete a folder with an unexpected name');
      return false;
    }
    _cache.evict('$installId/$packageDir');
    final dir = _dir(installId, packageDir);
    final deleted = await _delete(dir);
    await _pruneParent(dir);
    return deleted;
  }

  Future<bool> _delete(Directory dir) async {
    try {
      await dir.delete(recursive: true);
      return true;
    } on PathNotFoundException {
      return false;
    } on FileSystemException catch (error) {
      _log.warning('Could not delete a plugin folder: ${error.runtimeType}');
      return false;
    }
  }

  Future<void> _pruneParent(Directory dir) async {
    final parent = dir.parent;
    try {
      if (parent.path != root.path &&
          await parent.exists() &&
          await parent.list(followLinks: false).isEmpty) {
        await parent.delete();
      }
    } on FileSystemException {
      // An empty folder left behind is harmless; the next delete retries.
    }
  }

  String _nameOf(FileSystemEntity entity) =>
      entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
}
