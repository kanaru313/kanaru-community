import 'dart:async';

import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../domain/catalog/repo_url.dart';
import '../../domain/install/repo_results.dart';
import '../install/write_queue.dart';
import '../net/fetcher.dart';
import '../store/plugin_repo_rows.dart';
import 'catalog_cache.dart';
import 'catalog_fetch.dart';

final _log = Logger('plugin_repos');

/// Adds and removes repositories. The network part of an add runs outside the
/// write queue (it can take 20 seconds); only the database write is a queue
/// job, so config saves and installs are not held up by a slow server.
class PluginRepositories {
  PluginRepositories({
    required this._rows,
    required this._fetcher,
    required this._queue,
    required this._catalogs,
    int Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final PluginRepoRows _rows;
  final HttpFetcher _fetcher;
  final PluginWriteQueue _queue;
  final CatalogCache _catalogs;
  final int Function() _clock;

  final _adding = <String, Future<RepoAddResult>>{};

  /// Adds the repository at [input]: canonical address, duplicate check,
  /// fetch, parse, then one insert of the row with its catalog and address
  /// class. A failure leaves nothing. Two calls for one address share one
  /// run. Never throws.
  Future<RepoAddResult> add(String input) {
    final url = canonicalRepoUrl(input);
    if (url == null) {
      return Future.value(const RepoAddFailed(RepoError.invalidUrl));
    }
    return _adding[url] ??= _add(url).whenComplete(() {
      _adding.remove(url);
    });
  }

  Future<RepoAddResult> _add(String url) async {
    try {
      if (await _rows.byUrl(url) != null) {
        return const RepoAddFailed(RepoError.duplicate);
      }
      final fetched = await fetchCatalog(_fetcher, Uri.parse(url));
      final FetchedCatalog catalog;
      switch (fetched) {
        case Err(:final error):
          return RepoAddFailed(
            error.error,
            reason: error.reason,
            status: error.status,
          );
        case Ok(:final value):
          catalog = value;
      }
      // The write waits for the queue (a sweep or an install may be running).
      return await _queue.run<RepoAddResult>(() async {
        final (write, id) = await _rows.add(
          url: url,
          name: catalog.catalog.name,
          catalogJson: catalog.stored,
          addressKind: catalog.kind,
          now: _clock(),
        );
        return switch (write) {
          RepoWrite.written when id != null => RepoAdded(id),
          RepoWrite.duplicate => const RepoAddFailed(RepoError.duplicate),
          RepoWrite.tooLarge => const RepoAddFailed(RepoError.tooLarge),
          _ => const RepoAddFailed(RepoError.storageFailed),
        };
      });
    } on Object catch (error) {
      _log.warning('Adding a repository failed: ${error.runtimeType}');
      return const RepoAddFailed(RepoError.storageFailed);
    }
  }

  /// Removes the row of repository [id]. Plugins installed from it keep their
  /// `repo_url` and stop getting updates. Never throws.
  Future<RepoRemoveResult> remove(int id) => _queue.run<RepoRemoveResult>(
    () async {
      final removed = await _rows.remove(id);
      _catalogs.forget(id);
      return removed ? RepoRemoveResult.removed : RepoRemoveResult.missing;
    },
    key: 'repo-remove:$id',
    onError: (_, _) => RepoRemoveResult.failed,
  );
}
