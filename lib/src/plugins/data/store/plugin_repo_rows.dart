import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../domain/net/address_rules.dart';
import 'plugin_store_rules.dart';

/// How a write of a repository row ended.
enum RepoWrite {
  written,

  /// A repository with this address exists already.
  duplicate,

  /// The catalog text is over [maxCatalogJsonBytes]; nothing was written.
  tooLarge,

  /// No such repository.
  missing,
}

/// Typed reads and writes of `plugin_repos`. A removed repository only loses
/// its row: its plugins keep their own `repo_url` and `repo_slug`.
class PluginRepoRows {
  PluginRepoRows(this._db);

  final AppDatabase _db;

  /// Every repository, oldest added first.
  Future<List<PluginRepoRow>> all() => _ordered().get();

  Stream<List<PluginRepoRow>> watchAll() => _ordered().watch();

  SimpleSelectStatement<$PluginReposTable, PluginRepoRow> _ordered() =>
      _db.select(_db.pluginRepos)..orderBy([
        (t) => OrderingTerm.asc(t.addedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);

  Future<PluginRepoRow?> byId(int id) => (_db.select(
    _db.pluginRepos,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<PluginRepoRow?> byUrl(String url) => (_db.select(
    _db.pluginRepos,
  )..where((t) => t.url.equals(url))).getSingleOrNull();

  /// Adds a repository with its first good catalog. The row and the catalog
  /// are one insert, so a failure leaves nothing. [url] is the canonical
  /// address. Returns the outcome and the new id (null unless written).
  Future<(RepoWrite, int?)> add({
    required String url,
    required String name,
    required String catalogJson,
    required AddressKind addressKind,
    required int now,
  }) {
    if (utf8Length(catalogJson) > maxCatalogJsonBytes) {
      return Future.value((RepoWrite.tooLarge, null));
    }
    return _db.transaction(() async {
      if (await byUrl(url) != null) return (RepoWrite.duplicate, null);
      final id = await _db
          .into(_db.pluginRepos)
          .insert(
            PluginReposCompanion.insert(
              url: url,
              name: name,
              catalogJson: Value(catalogJson),
              refreshedAt: Value(now),
              lastAttemptAt: Value(now),
              addedAt: now,
              addressClass: _classOf(addressKind),
            ),
          );
      return (RepoWrite.written, id);
    });
  }

  /// Stores a freshly fetched catalog (and the repository's [name]) with the
  /// [addressKind] the fetcher reported, and clears the last error.
  Future<RepoWrite> saveCatalog(
    int id, {
    required String name,
    required String catalogJson,
    required AddressKind addressKind,
    required int now,
  }) async {
    if (utf8Length(catalogJson) > maxCatalogJsonBytes) {
      return RepoWrite.tooLarge;
    }
    return _update(
      id,
      PluginReposCompanion(
        name: Value(name),
        catalogJson: Value(catalogJson),
        refreshedAt: Value(now),
        lastAttemptAt: Value(now),
        lastError: const Value(null),
        addressClass: Value(_classOf(addressKind)),
      ),
    );
  }

  /// Records a failed refresh by its [errorKind]; the last good catalog is
  /// kept.
  Future<RepoWrite> saveFailure(
    int id, {
    required String errorKind,
    required int now,
  }) => _update(
    id,
    PluginReposCompanion(
      lastAttemptAt: Value(now),
      lastError: Value(errorKind),
    ),
  );

  /// Deletes the repository row; installed plugins are not touched.
  Future<bool> remove(int id) async =>
      await (_db.delete(_db.pluginRepos)..where((t) => t.id.equals(id))).go() >
      0;

  Future<RepoWrite> _update(int id, PluginReposCompanion values) async {
    final changed = await (_db.update(
      _db.pluginRepos,
    )..where((t) => t.id.equals(id))).write(values);
    return changed == 0 ? RepoWrite.missing : RepoWrite.written;
  }
}

String _classOf(AddressKind kind) => switch (kind) {
  AddressKind.public => PluginAddressClassValues.public,
  AddressKind.local => PluginAddressClassValues.local,
};

/// The address class a repository row stored. Only an exact `local` reads as
/// local; anything else (a damaged or future value) reads as public, the
/// strict class (public references only, `https` only).
extension PluginRepoRowView on PluginRepoRow {
  AddressKind get addressKind => addressClass == PluginAddressClassValues.local
      ? AddressKind.local
      : AddressKind.public;
}
