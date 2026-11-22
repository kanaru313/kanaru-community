import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../../foundation/result.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/net/net_policy.dart';
import '../../domain/package/icon_check.dart';
import '../net/fetcher.dart';
import '../store/plugin_files.dart';
import 'repo_address_guard.dart';

final _log = Logger('plugin_icons');

/// Most bytes of icons kept in memory; the least recently used go first.
const iconCacheMaxBytes = 8 * 1024 * 1024;

/// Most icon fetches in flight at once; the others wait their turn, so a long
/// catalog does not open one connection per row to the repository host.
const iconMaxConcurrent = 4;

/// How long a failed icon is remembered before the next ask tries again.
const iconRetryAfter = Duration(seconds: 60);

/// Icons of catalog entries and of installed plugins. Catalog icons are
/// fetched on first use under the `icon` policy (64 KiB cap, PNG check) and
/// kept in memory only, at most [iconCacheMaxBytes], least recently used
/// first out. A failure of any kind (network, refused address, not a PNG) is
/// remembered for [iconRetryAfter] so a list does not refetch on every
/// rebuild. At most [iconMaxConcurrent] fetches run at once. Concurrent asks for one icon share one fetch. A catalog icon
/// obeys the address class the [RepoAddressGuard] narrows to, never a looser
/// stored one. Installed icons are read from the package folder.
class PluginIconCache {
  PluginIconCache({
    required this._fetcher,
    required this._guard,
    required this._files,
    this._maxBytes = iconCacheMaxBytes,
    this._retryAfter = iconRetryAfter,
    this._maxConcurrent = iconMaxConcurrent,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HttpFetcher _fetcher;
  final RepoAddressGuard _guard;
  final PluginFiles _files;
  final int _maxBytes;
  final Duration _retryAfter;
  final int _maxConcurrent;
  final DateTime Function() _clock;

  /// Insertion order is use order: a hit moves the entry to the end.
  final _icons = <String, Uint8List>{};
  var _bytes = 0;
  final _loading = <String, Future<Uint8List?>>{};
  final _failedAt = <String, DateTime>{};
  var _running = 0;
  final _queue = Queue<Completer<void>>();

  /// Bytes held now (for tests and diagnostics).
  int get cachedBytes => _bytes;

  /// The icon of [entry] of [repo]'s catalog, or null when it has none or
  /// could not be fetched.
  Future<Uint8List?> catalogIcon(PluginRepoRow repo, CatalogEntry entry) {
    final url = entry.icon;
    if (url == null) return Future.value();
    final key = '${repo.id}\n$url';
    final hit = _icons.remove(key);
    if (hit != null) {
      _icons[key] = hit;
      return Future.value(hit);
    }
    final failed = _failedAt[key];
    if (failed != null) {
      if (_clock().difference(failed) < _retryAfter) return Future.value();
      _failedAt.remove(key);
    }
    return _loading[key] ??= _load(key, repo, url).whenComplete(() {
      _loading.remove(key);
    });
  }

  /// The icon of an installed plugin, from its folder.
  Future<Uint8List?> installedIcon(PluginRow row) async {
    try {
      return await _files.readIcon(row);
    } on Object catch (error) {
      _log.warning('Reading an icon failed: ${error.runtimeType}');
      return null;
    }
  }

  /// Forgets remembered failures, so the next ask tries again.
  void clearFailures() => _failedAt.clear();

  /// Waits for one of the fetch slots; each caller gives it back through
  /// [_release].
  Future<void> _acquire() {
    if (_running < _maxConcurrent) {
      _running++;
      return Future.value();
    }
    final turn = Completer<void>();
    _queue.add(turn);
    return turn.future;
  }

  void _release() {
    // The slot passes straight to the next waiter, so the count stays.
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _running--;
    }
  }

  Future<Uint8List?> _load(String key, PluginRepoRow repo, Uri url) async {
    await _acquire();
    try {
      return await _fetch(key, repo, url);
    } finally {
      _release();
    }
  }

  Future<Uint8List?> _fetch(String key, PluginRepoRow repo, Uri url) async {
    try {
      final catalogKind = switch (await _guard.kindFor(repo)) {
        Ok(:final value) => value,
        Err() => null,
      };
      if (catalogKind == null) return _fail(key);
      final got = await _fetcher.get(
        url,
        NetPolicy.icon,
        catalogKind: catalogKind,
      );
      final bytes = switch (got) {
        Ok(:final value) => value.bytes,
        Err() => null,
      };
      if (bytes == null || iconProblem(bytes) != null) return _fail(key);
      _remember(key, bytes);
      return bytes;
    } on Object catch (error) {
      _log.warning('Fetching an icon failed: ${error.runtimeType}');
      return _fail(key);
    }
  }

  Uint8List? _fail(String key) {
    _failedAt[key] = _clock();
    return null;
  }

  void _remember(String key, Uint8List icon) {
    _icons[key] = icon;
    _bytes += icon.length;
    while (_bytes > _maxBytes && _icons.length > 1) {
      final oldest = _icons.keys.first;
      _bytes -= _icons.remove(oldest)!.length;
    }
  }
}
