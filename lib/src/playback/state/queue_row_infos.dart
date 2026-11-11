import 'dart:async';
import 'dart:collection';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../data/track_info_rows.dart';

/// Loads infos for some tracks; one query per chunk. Replaceable in tests.
typedef TrackInfoLoader = Future<List<TrackInfo>> Function(List<TrackId> ids);

final queueRowInfoLoaderProvider = Provider<TrackInfoLoader>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (ids) => loadTrackInfos(db, ids);
});

/// Fires when the `tracks` table changes (a scan, a tag edit).
final queueTracksChangedProvider = StreamProvider<void>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .tableUpdates(TableUpdateQuery.onTableName('tracks'))
      .map((_) {}),
);

/// Most infos kept at once; the oldest touched are dropped first.
const int queueRowInfoCapacity = 1000;

/// A `tracks` change reloads the window this long after the last change.
const Duration queueRowInfoReloadDelay = Duration(seconds: 1);

/// Infos of the queue rows near the viewport. A 20 000-entry queue never
/// loads 20 000 infos: the list asks for the visible window plus a margin
/// ([ensure]) and rows read their own entry with a `select`.
class QueueRowInfos extends Notifier<Map<TrackId, TrackInfo>> {
  /// Insertion order = touch order (oldest first).
  final LinkedHashMap<TrackId, TrackInfo> _cache = LinkedHashMap();
  final Set<TrackId> _loading = {};
  List<TrackId> _window = const [];
  Timer? _debounce;
  int _epoch = 0;

  @override
  Map<TrackId, TrackInfo> build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _epoch++;
    });
    ref.listen(queueTracksChangedProvider, (_, next) {
      if (next is AsyncData) _scheduleReload();
    });
    return const {};
  }

  /// Makes sure the infos of [window] are loaded or loading.
  void ensure(List<TrackId> window) {
    _window = window;
    var touched = false;
    for (final id in window) {
      final info = _cache.remove(id);
      if (info != null) {
        _cache[id] = info;
        touched = true;
      }
    }
    final missing = [
      for (final id in {...window})
        if (!_cache.containsKey(id) && !_loading.contains(id)) id,
    ];
    if (missing.isNotEmpty) unawaited(_load(missing));
    if (touched) _evict();
  }

  Future<void> _load(List<TrackId> ids) async {
    final epoch = _epoch;
    _loading.addAll(ids);
    try {
      final infos = await ref.read(queueRowInfoLoaderProvider)(ids);
      if (epoch != _epoch) return;
      _merge(infos);
    } on Object {
      // Rows keep their placeholder; the next scroll or change retries.
    } finally {
      _loading.removeAll(ids);
    }
  }

  void _merge(List<TrackInfo> infos) {
    for (final info in infos) {
      _cache.remove(info.id);
      _cache[info.id] = info;
    }
    _evict();
    state = Map.unmodifiable(_cache);
  }

  void _evict() {
    while (_cache.length > queueRowInfoCapacity) {
      _cache.remove(_cache.keys.first);
    }
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(queueRowInfoReloadDelay, _reload);
  }

  /// Reloads only the window the list last asked for; the rest of the cache
  /// is dropped and comes back on demand.
  Future<void> _reload() async {
    final window = _window;
    if (window.isEmpty) return;
    final epoch = _epoch;
    try {
      final infos = await ref.read(queueRowInfoLoaderProvider)(window);
      if (epoch != _epoch) return;
      _cache.clear();
      _merge(infos);
    } on Object {
      // Keep what is shown.
    }
  }
}

final queueRowInfosProvider =
    NotifierProvider<QueueRowInfos, Map<TrackId, TrackInfo>>(QueueRowInfos.new);
