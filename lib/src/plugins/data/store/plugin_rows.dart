import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../domain/package/manifest_parser.dart';
import '../../domain/package/package_limits.dart';
import '../../domain/package/plugin_manifest.dart';
import 'plugin_row_types.dart';
import 'plugin_store_rules.dart';

final _log = Logger('plugin_store');

/// Typed reads and writes of the `plugins` table. A plugin is live while
/// `removed_at` is null; removing keeps the row as a tombstone.
///
/// Every write is one transaction and is meant to run on the store's serial
/// write queue; the checks inside make a missed queue lose a write, never
/// corrupt a row. [transaction] lets a caller join several writes (a package
/// switch and the config adaptation) into one.
class PluginRows {
  PluginRows(this._db, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _clock;

  // One parsed manifest per install id, valid for the `updated_at` it was
  // parsed at: every change of `manifest_json` moves `updated_at` up.
  final _manifests = <String, ({int updatedAt, PluginManifest? manifest})>{};

  /// Runs [action] in one database transaction (joins the current one).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  SimpleSelectStatement<$PluginsTable, PluginRow> _liveQuery() =>
      _db.select(_db.plugins)
        ..where((t) => t.removedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.installedAt),
          (t) => OrderingTerm.asc(t.installId),
        ]);

  /// Every live plugin, oldest install first.
  Future<List<PluginRow>> live() => _liveQuery().get();

  Stream<List<PluginRow>> watchLive() => _liveQuery().watch();

  /// The row of [installId], tombstone included.
  Future<PluginRow?> byId(String installId) => (_db.select(
    _db.plugins,
  )..where((t) => t.installId.equals(installId))).getSingleOrNull();

  Future<PluginRow?> liveById(String installId) async {
    final row = await byId(installId);
    return row != null && row.isLive ? row : null;
  }

  /// The row installed from [slug] of the repository [url], tombstone
  /// included; null when none.
  Future<PluginRow?> byRepo(String url, String slug) =>
      (_db.select(_db.plugins)
            ..where((t) => t.repoUrl.equals(url) & t.repoSlug.equals(slug)))
          .getSingleOrNull();

  /// `<install_id>/<package_dir>` of every live row with a package: the
  /// folders a sweep keeps.
  Future<Set<String>> livePackageFolders() async => {
    for (final row in await live())
      if (row.packageDir != null) '${row.installId}/${row.packageDir}',
  };

  /// Adds a plugin, or brings a tombstone back as a fresh install (new
  /// source, new consented hosts, empty config, `installed_at` = now).
  /// A live row is left alone ([PluginInstallWrite.alreadyLive]). Throws
  /// [ArgumentError] for an id, folder, hash or source that has the wrong
  /// shape, or a manifest over its cap; nothing is written then.
  Future<(PluginInstallWrite, PluginRow)> installOrRevive(
    String installId,
    PluginDraft draft,
    PluginSource source,
  ) async {
    _check(installId, draft);
    if (!source.isComplete) {
      throw ArgumentError.value(source.origin.wire, 'source', 'incomplete');
    }
    return _db.transaction(() async {
      final now = _clock();
      final old = await byId(installId);
      if (old != null && old.isLive) {
        return (PluginInstallWrite.alreadyLive, old);
      }
      if (old == null) {
        await _db
            .into(_db.plugins)
            .insert(
              PluginsCompanion.insert(
                installId: installId,
                kind: draft.kind.wire,
                name: draft.name,
                author: Value(draft.author),
                version: draft.version,
                apiVersion: draft.apiVersion,
                manifestJson: draft.manifestJson,
                packageDir: Value(draft.packageDir),
                packageSha256: draft.packageSha256,
                origin: source.origin.wire,
                repoUrl: Value(source.repoUrl),
                repoSlug: Value(source.repoSlug),
                originLabel: Value(source.label),
                consentedHostsJson: jsonEncode(draft.consentedHosts),
                installedAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.plugins,
        )..where((t) => t.installId.equals(installId))).write(
          _packageColumns(draft, _nextUpdatedAt(old, now)).copyWith(
            origin: Value(source.origin.wire),
            repoUrl: Value(source.repoUrl),
            repoSlug: Value(source.repoSlug),
            originLabel: Value(source.label),
            installedAt: Value(now),
            removedAt: const Value(null),
          ),
        );
      }
      // Tombstoning deleted the data row; a fresh install starts empty.
      await _db
          .into(_db.pluginData)
          .insert(
            PluginDataCompanion.insert(installId: installId),
            onConflict: DoUpdate(
              (_) => const PluginDataCompanion(
                configJson: Value('{}'),
                customChoicesJson: Value('{}'),
                // A stray data row must not bring back an earlier storage.
                // Rev 0 is safe: the updated_at guard refuses older runs.
                storageJson: Value(''),
                storageRev: Value(0),
              ),
            ),
          );
      _manifests.remove(installId);
      return (
        old == null ? PluginInstallWrite.inserted : PluginInstallWrite.revived,
        (await byId(installId))!,
      );
    });
  }

  /// Points the live plugin at a new package (an update, or a repair that
  /// writes the same version again). Install source, `installed_at` and
  /// config stay. `updated_at` becomes `MAX(now, updated_at + 1)`, so a guarded
  /// write from before the switch can never match. Returns the row before and
  /// after (read in the same transaction, so the caller can delete the old
  /// folder and run `adaptToForm` on the two manifests), or null (nothing
  /// written) when the plugin is missing or removed.
  Future<({PluginRow old, PluginRow now})?> switchPackage(
    String installId,
    PluginDraft draft,
  ) async {
    _check(installId, draft);
    return _db.transaction(() async {
      final old = await liveById(installId);
      if (old == null) return null;
      await (_db.update(_db.plugins)
            ..where((t) => t.installId.equals(installId)))
          .write(_packageColumns(draft, _nextUpdatedAt(old, _clock())));
      _manifests.remove(installId);
      return (old: old, now: (await byId(installId))!);
    });
  }

  /// Tombstones a live plugin in one transaction: its data row is deleted,
  /// `removed_at` is set and `package_dir` cleared. Returns what happened and
  /// the folder the row pointed at (null unless [PluginRemoval.removed]), for
  /// the caller to delete after the commit.
  Future<(PluginRemoval, String?)> remove(String installId) {
    return _db.transaction(() async {
      final old = await byId(installId);
      if (old == null) return (PluginRemoval.missing, null);
      if (!old.isLive) return (PluginRemoval.alreadyRemoved, null);
      await (_db.delete(
        _db.pluginData,
      )..where((t) => t.installId.equals(installId))).go();
      final now = _clock();
      await (_db.update(
        _db.plugins,
      )..where((t) => t.installId.equals(installId))).write(
        PluginsCompanion(
          removedAt: Value(now),
          packageDir: const Value(null),
          updatedAt: Value(_nextUpdatedAt(old, now)),
        ),
      );
      _manifests.remove(installId);
      return (PluginRemoval.removed, old.packageDir);
    });
  }

  /// The parsed `manifest_json` of [row], parsed once per `(install_id,
  /// updated_at)`. Null when the stored text no longer parses (written by a
  /// newer app, or damaged); the plugin is then shown as broken.
  PluginManifest? manifestOf(PluginRow row) {
    final cached = _manifests[row.installId];
    if (cached != null && cached.updatedAt == row.updatedAt) {
      return cached.manifest;
    }
    final manifest = parseManifest(row.manifestJson)
        .fold<PluginManifest?>((m) => m, (_) => null);
    if (manifest == null) _log.warning('A stored plugin.json does not parse');
    _manifests[row.installId] = (updatedAt: row.updatedAt, manifest: manifest);
    return manifest;
  }

  int _nextUpdatedAt(PluginRow old, int now) =>
      now > old.updatedAt ? now : old.updatedAt + 1;

  PluginsCompanion _packageColumns(PluginDraft draft, int updatedAt) =>
      PluginsCompanion(
        kind: Value(draft.kind.wire),
        name: Value(draft.name),
        author: Value(draft.author),
        version: Value(draft.version),
        apiVersion: Value(draft.apiVersion),
        manifestJson: Value(draft.manifestJson),
        packageDir: Value(draft.packageDir),
        packageSha256: Value(draft.packageSha256),
        consentedHostsJson: Value(jsonEncode(draft.consentedHosts)),
        updatedAt: Value(updatedAt),
      );

  void _check(String installId, PluginDraft draft) {
    if (!isInstallIdShape(installId)) {
      throw ArgumentError.value(installId, 'installId', 'not an install id');
    }
    if (!isPackageDirShape(draft.packageDir)) {
      throw ArgumentError.value(draft.packageDir, 'packageDir', 'bad folder');
    }
    if (!isSha256Shape(draft.packageSha256)) {
      throw ArgumentError.value(draft.packageSha256, 'packageSha256', 'bad');
    }
    if (utf8Length(draft.manifestJson) > maxManifestBytes) {
      throw ArgumentError.value(
        draft.manifestJson.length,
        'manifestJson',
        'over $maxManifestBytes bytes',
      );
    }
  }
}
