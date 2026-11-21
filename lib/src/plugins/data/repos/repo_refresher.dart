import 'dart:async';

import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../../foundation/result.dart';
import '../../domain/install/repo_results.dart';
import '../../domain/net/address_rules.dart';
import '../install/write_queue.dart';
import '../net/fetcher.dart';
import '../store/plugin_repo_rows.dart';
import 'catalog_fetch.dart';
import 'repo_address_guard.dart';

final _log = Logger('plugin_repos');

/// At most this many repositories are fetched at once.
const repoRefreshParallelism = 4;

/// A repository fetched longer ago than this is refreshed when the store
/// opens.
const repoRefreshMaxAge = Duration(hours: 6);

/// Whether a repository must be fetched by a stale-only refresh: never
/// fetched, last attempt failed, no catalog, or older than [maxAge]. A time
/// in the future (clock set back) counts as stale.
bool repoNeedsRefresh(PluginRepoRow row, int now, Duration maxAge) {
  final fetchedAt = row.refreshedAt;
  if (fetchedAt == null || row.lastError != null || row.catalogJson == null) {
    return true;
  }
  final age = now - fetchedAt;
  return age < 0 || age >= maxAge.inMilliseconds;
}

/// Refreshes the catalogs of the stored repositories. A fetch runs outside
/// the write queue; storing its result is a queue job. A failed fetch keeps
/// the last good catalog and records only the kind of the error. Fetches of
/// one repository are shared, and `refreshAll` calls share one run.
class RepoRefresher {
  RepoRefresher({
    required this._rows,
    required this._fetcher,
    required this._queue,
    this._guard,
    this._onRefreshedAll,
    int Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final PluginRepoRows _rows;
  final HttpFetcher _fetcher;
  final PluginWriteQueue _queue;

  /// Forgotten after a refresh, so a changed network is looked at again.
  final RepoAddressGuard? _guard;
  final void Function()? _onRefreshedAll;
  final int Function() _clock;

  Future<List<RepoRefreshResult>>? _all;
  final _one = <int, Future<RepoRefreshResult?>>{};

  /// Refreshes repository [id]; null when it is not stored (any more). Shares
  /// the fetch already running for it. Never throws.
  Future<RepoRefreshResult?> refresh(int id) =>
      _one[id] ??= _refreshOne(id).whenComplete(() {
        _one.remove(id);
      });

  /// Refreshes every repository, [repoRefreshParallelism] at once. A call made
  /// while another runs shares it. Never throws.
  Future<List<RepoRefreshResult>> refreshAll() =>
      _all ??= _refreshAll().whenComplete(() {
        _all = null;
      });

  /// Refreshes the repositories [repoNeedsRefresh] flags (the Kho open).
  /// While a [refreshAll] runs it returns that run. The result holds only the
  /// repositories fetched. Never throws.
  Future<List<RepoRefreshResult>> refreshStale({
    Duration maxAge = repoRefreshMaxAge,
  }) async {
    final running = _all;
    if (running != null) return running;
    final now = _clock();
    final List<int> ids;
    try {
      ids = [
        for (final row in await _rows.all())
          if (repoNeedsRefresh(row, now, maxAge)) row.id,
      ];
    } on Object catch (error) {
      _log.warning('Listing repositories failed: ${error.runtimeType}');
      return const [];
    }
    return _refreshIds(ids);
  }

  Future<List<RepoRefreshResult>> _refreshAll() async {
    final List<int> ids;
    try {
      ids = [for (final row in await _rows.all()) row.id];
    } on Object catch (error) {
      _log.warning('Listing repositories failed: ${error.runtimeType}');
      return const [];
    }
    final results = await _refreshIds(ids);
    _guard?.clear();
    _onRefreshedAll?.call();
    return results;
  }

  Future<List<RepoRefreshResult>> _refreshIds(List<int> ids) async {
    final results = List<RepoRefreshResult?>.filled(ids.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < ids.length) {
        final i = next++;
        results[i] = await refresh(ids[i]);
      }
    }

    await Future.wait([
      for (var i = 0; i < repoRefreshParallelism && i < ids.length; i++)
        worker(),
    ]);
    return List.unmodifiable(results.nonNulls);
  }

  Future<RepoRefreshResult?> _refreshOne(int id) async {
    try {
      final row = await _rows.byId(id);
      if (row == null) return null;
      final fetched = await fetchCatalog(_fetcher, Uri.parse(row.url));
      return await _queue.run<RepoRefreshResult?>(() => _store(id, fetched));
    } on Object catch (error) {
      _log.warning('Refreshing a repository failed: ${error.runtimeType}');
      return RepoRefreshResult(id, RepoError.storageFailed);
    }
  }

  /// Writes the outcome of a fetch. The row may be gone by now (removed while
  /// the fetch ran): then nothing is written.
  Future<RepoRefreshResult?> _store(
    int id,
    Result<FetchedCatalog, CatalogFetchError> fetched,
  ) async {
    final now = _clock();
    switch (fetched) {
      case Ok(:final value):
        // A refresh never lowers a stored `public` class to `local`: a name
        // that starts resolving to LAN addresses must not widen what its
        // package and icon references may reach. Only removing and adding
        // the repository again can do that.
        final stored = (await _rows.byId(id))?.addressKind;
        final kind = stored == AddressKind.public
            ? AddressKind.public
            : value.kind;
        final saved = await _rows.saveCatalog(
          id,
          name: value.catalog.name,
          catalogJson: value.stored,
          addressKind: kind,
          now: now,
        );
        switch (saved) {
          case RepoWrite.written:
            return RepoRefreshResult(id);
          case RepoWrite.missing:
            return null;
          default:
            await _rows.saveFailure(
              id,
              errorKind: RepoError.tooLarge.name,
              now: now,
            );
            return RepoRefreshResult(id, RepoError.tooLarge);
        }
      case Err(:final error):
        final saved = await _rows.saveFailure(
          id,
          errorKind: error.error.name,
          now: now,
        );
        return saved == RepoWrite.missing
            ? null
            : RepoRefreshResult(id, error.error);
    }
  }
}
