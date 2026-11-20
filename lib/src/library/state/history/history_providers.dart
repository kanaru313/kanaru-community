import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../database/state/database_providers.dart';
import '../../../foundation/text/text_fold.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/state/listen_recorder_provider.dart';
import '../../../playback/state/playback_settings_providers.dart';
import '../../data/history/history_repository.dart';
import '../../domain/history/history_change.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_store.dart';
import 'local_day_provider.dart';

final _log = Logger('library.history');

/// Most plays the filtered list shows.
const historyFilterCap = 1000;

final historyStoreProvider = Provider<HistoryStore>(
  (ref) => HistoryRepository(ref.watch(appDatabaseProvider)),
);

/// Calls [onChange] for every debounced change of the plays until [ref] is
/// disposed (or rebuilt). Checkpoints of a listen in progress never arrive.
void watchPlayChanges(
  Ref ref,
  HistoryStore store,
  void Function(HistoryChange change) onChange,
) {
  final sub = store.watchPlays().listen(
    onChange,
    onError: (Object e) =>
        _log.warning('Watching plays failed: ${e.runtimeType}'),
  );
  ref.onDispose(() => unawaited(sub.cancel()));
}

/// Calls [onChange] when track metadata changes, until [ref] is disposed.
void watchTrackChanges(Ref ref, HistoryStore store, VoidCallback onChange) {
  final sub = store.watchTracks().listen(
    (_) => onChange(),
    onError: (Object e) =>
        _log.warning('Watching tracks failed: ${e.runtimeType}'),
  );
  ref.onDispose(() => unawaited(sub.cancel()));
}

/// Years with plays, newest first.
final historyYearsProvider = FutureProvider.autoDispose<List<int>>((ref) {
  final store = ref.read(historyStoreProvider);
  watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
  return store.years();
});

/// Every play of one year. Reads again on an insert or delete when it is the
/// current year, on a delete (or undo) only for an older one: a new play
/// never changes the numbers of a past year. A change of track metadata
/// reloads only the song infos of the plays already read.
final historyYearProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryYearNotifier, List<HistoryPlay>, int>(
      HistoryYearNotifier.new,
    );

class HistoryYearNotifier extends AsyncNotifier<List<HistoryPlay>> {
  HistoryYearNotifier(this.year);

  final int year;
  int _generation = 0;

  @override
  Future<List<HistoryPlay>> build() async {
    final generation = ++_generation;
    final store = ref.read(historyStoreProvider);
    final current = year == ref.watch(localDayProvider.select((d) => d.year));
    watchPlayChanges(ref, store, (change) {
      if (current || change.removed) ref.invalidateSelf();
    });
    watchTrackChanges(
      ref,
      store,
      () => unawaited(_reloadInfos(store, generation)),
    );
    final watch = Stopwatch()..start();
    final plays = await store.yearPlays(year);
    _log.fine(
      'Read a year: ${plays.length} plays in ${watch.elapsedMilliseconds} ms',
    );
    return plays;
  }

  Future<void> _reloadInfos(HistoryStore store, int generation) async {
    // A read in flight will bring fresh infos itself, and `state.value` is
    // then the previous read's list.
    if (state.isLoading) return;
    final plays = state.value;
    if (plays == null) return;
    try {
      final fresh = await store.refreshTracks(plays);
      // Replace only the list that was refreshed: a newer read may have
      // landed meanwhile and its answer already has fresh infos.
      if (ref.mounted &&
          generation == _generation &&
          identical(state.value, plays)) {
        state = AsyncData(fresh);
      }
    } on Object catch (e) {
      _log.warning('Reloading song infos failed: ${e.runtimeType}');
    }
  }
}

/// Plays of the history year whose song matches the text, newest first.
typedef HistoryFilterKey = ({int year, String query});

class HistoryFilterResult {
  const HistoryFilterResult({required this.plays, required this.matched});

  /// At most [historyFilterCap] plays.
  final List<HistoryPlay> plays;

  /// How many plays matched in all.
  final int matched;

  bool get capped => matched > plays.length;
}

final historyFilterProvider = Provider.autoDispose
    .family<AsyncValue<HistoryFilterResult>, HistoryFilterKey>((ref, key) {
      final match = foldedMatcher(key.query);
      return ref.watch(historyYearProvider(key.year)).whenData((all) {
        final hits = <HistoryPlay>[];
        var matched = 0;
        for (final p in all) {
          final t = p.track;
          if (!match('${t.title} ${t.artist ?? ''} ${t.album ?? ''}')) continue;
          matched++;
          if (hits.length < historyFilterCap) hits.add(p);
        }
        return HistoryFilterResult(plays: hits, matched: matched);
      });
    });

final historyOverviewProvider = FutureProvider.autoDispose<HistoryOverview>((
  ref,
) {
  final store = ref.read(historyStoreProvider);
  watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
  return store.overview();
});

/// All plays of one song; null when the song does not exist.
final trackHistoryProvider = FutureProvider.autoDispose
    .family<TrackHistory?, TrackId>((ref, id) {
      final store = ref.read(historyStoreProvider);
      watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
      watchTrackChanges(ref, store, ref.invalidateSelf);
      return store.trackHistory(id);
    });

/// Local days of the epoch-ms window that have a play (the calendar marks).
final playDaysProvider = FutureProvider.autoDispose
    .family<Set<DateTime>, ({int start, int end})>((ref, w) {
      final store = ref.read(historyStoreProvider);
      watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
      return store.playDays(w.start, w.end);
    });

/// First and last counted play (bounds of the date pickers); null when none.
final historyBoundsProvider =
    FutureProvider.autoDispose<({int first, int last})?>((ref) {
      final store = ref.read(historyStoreProvider);
      watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
      return store.playedRange();
    });

/// Whether new listens are recorded (the Settings switch).
final historyRecordingProvider = Provider<bool>(
  (ref) => ref.watch(historyEnabledProvider),
);

/// Whether a clear is queued or running in the recorder; screens disable
/// clearing and deleting a day meanwhile.
final historyClearingProvider = NotifierProvider.autoDispose<_Clearing, bool>(
  _Clearing.new,
);

class _Clearing extends Notifier<bool> {
  @override
  bool build() {
    final clearing = ref.watch(listenRecorderProvider).clearing;
    void sync() {
      if (ref.mounted) state = clearing.value;
    }

    clearing.addListener(sync);
    ref.onDispose(() => clearing.removeListener(sync));
    return clearing.value;
  }
}
