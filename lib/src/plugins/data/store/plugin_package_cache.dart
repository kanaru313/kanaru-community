import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/package/manifest_parser.dart';
import '../../domain/package/package_limits.dart';
import '../../domain/package/plugin_manifest.dart';

/// The `src/` file names a package may hold (same rule as the zip reader).
final scriptFileName = RegExp(r'^[A-Za-z0-9_.-]+\.js$');

/// The package of a plugin could not be read from its folder (missing, a
/// file unreadable or too large, `plugin.json` not valid). [reason] names the
/// problem and holds no path, so it is safe to log and to show.
class PluginPackageUnreadable implements Exception {
  const PluginPackageUnreadable(this.reason);

  final String reason;

  @override
  String toString() => 'PluginPackageUnreadable($reason)';
}

/// The files of one installed package, ready to run.
class StoredPackage {
  const StoredPackage({
    required this.manifest,
    required this.manifestText,
    required this.scripts,
  });

  final PluginManifest manifest;

  /// The `plugin.json` text as stored.
  final String manifestText;

  /// Every file of `src/` by name; a script's `load()` reaches only these.
  final Map<String, String> scripts;
}

/// Reads package folders and keeps what it read, by folder key. A folder is
/// written whole and never changed (an update writes a new one), so a cached
/// entry stays right while its folder exists. Concurrent loads of one folder
/// share one read; a failed read is not cached, so the next call tries again.
class PluginPackageCache {
  PluginPackageCache({this.maxEntries = 16});

  /// Most folders kept; the oldest goes first. Old versions are never asked
  /// for again, so this only bounds memory.
  final int maxEntries;

  final _loads = <String, Future<StoredPackage>>{};

  /// The package in [dir], read once per [key].
  Future<StoredPackage> load(String key, Directory dir) {
    final cached = _loads[key];
    if (cached != null) return cached;
    final load = _read(dir);
    _loads[key] = load;
    while (_loads.length > maxEntries) {
      _loads.remove(_loads.keys.first);
    }
    // A failed read must not stay cached. The handler also marks the error
    // as handled here; the caller still receives it from [load].
    unawaited(
      load.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_loads[key], load)) _loads.remove(key);
        },
      ),
    );
    return load;
  }

  /// Forgets [key] (its folder was deleted).
  void evict(String key) => _loads.remove(key);

  Future<StoredPackage> _read(Directory dir) async {
    try {
      final manifestFile = File('${dir.path}/plugin.json');
      if (!await isPlainFile(manifestFile.path)) {
        throw const PluginPackageUnreadable('plugin.json is missing');
      }
      final text = utf8.decode(await _bytes(manifestFile, maxManifestBytes));
      final manifest = parseManifest(text)
          .fold<PluginManifest?>((m) => m, (_) => null);
      if (manifest == null) {
        throw const PluginPackageUnreadable('plugin.json is not valid');
      }
      final scripts = <String, String>{};
      var total = 0;
      await for (final entity in Directory(
        '${dir.path}/src',
      ).list(followLinks: false)) {
        final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (entity is! File || !scriptFileName.hasMatch(name)) continue;
        final bytes = await _bytes(entity, maxScriptBytes);
        total += bytes.length;
        if (total > maxUnpackedBytes) {
          throw const PluginPackageUnreadable('package too large');
        }
        scripts[name] = utf8.decode(bytes);
      }
      for (final file in manifest.scriptFiles) {
        if (!scripts.containsKey(file)) {
          throw const PluginPackageUnreadable('a script file is missing');
        }
      }
      return StoredPackage(
        manifest: manifest,
        manifestText: text,
        scripts: Map.unmodifiable(scripts),
      );
    } on PluginPackageUnreadable {
      rethrow;
    } on FileSystemException {
      throw const PluginPackageUnreadable('package files cannot be read');
    } on FormatException {
      throw const PluginPackageUnreadable('a file is not valid UTF-8');
    }
  }

  Future<List<int>> _bytes(File file, int limit) async {
    if (await file.length() > limit) {
      throw const PluginPackageUnreadable('a package file is too large');
    }
    return file.readAsBytes();
  }
}

/// Whether [path] is a regular file (a symbolic link does not count).
Future<bool> isPlainFile(String path) async =>
    await FileSystemEntity.type(path, followLinks: false) ==
    FileSystemEntityType.file;
