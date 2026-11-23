import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/state/player_ready.dart';
import '../../../plugins/state/plugin_run_provider.dart';
import '../../data/lyrics_parse_jobs.dart';
import '../../data/online/online_backoff.dart';
import '../../data/online/online_cache_store.dart';
import '../../data/online/online_lookups.dart';
import '../../data/online/online_row_mapper.dart' as rows;
import '../../data/online/pin_store.dart';
import '../../data/online/reject_store.dart';
import '../../data/online/lyrics_run_client.dart';
import '../../domain/online/lookup_outcome.dart';
import '../../domain/online/lookup_target.dart';
import '../../domain/online/online_cache_pick.dart';
import '../../domain/online/online_rows.dart';
import '../lyrics_choice_commands.dart';
import '../lyrics_settings.dart';
import 'lyrics_sources_provider.dart';

Duration? _noRetry(int count, Object error) => null;

final onlineCacheStoreProvider = Provider<OnlineCacheStore>(
  (ref) => OnlineCacheStore(ref.watch(appDatabaseProvider)),
);
final pinStoreProvider = Provider<PinStore>(
  (ref) => PinStore(ref.watch(appDatabaseProvider)),
);
final rejectStoreProvider = Provider<RejectStore>(
  (ref) => RejectStore(ref.watch(appDatabaseProvider)),
);

/// Where large lyrics texts are parsed (off the UI isolate); tests run them
/// inline.
final lyricsParseRunnerProvider = Provider<IsolateRunner>(
  (ref) => runInIsolate,
);

/// A value in 0..1 for the backoff jitter; tests replace it.
final onlineRandomProvider = Provider<double Function()>(
  (ref) => Random().nextDouble,
);

/// The wall clock of the online lyrics code (the lyrics clock, as a time).
DateTime Function() _clockOf(Ref ref) {
  final ms = ref.read(lyricsClockProvider);
  return () => DateTime.fromMillisecondsSinceEpoch(ms());
}

/// The in-memory failure backoff of the sources, shared by every lookup.
final onlineBackoffProvider = Provider<OnlineBackoff>(
  (ref) =>
      OnlineBackoff(now: _clockOf(ref), random: ref.read(onlineRandomProvider)),
);

/// Runs the lyrics scripts of the plugins.
final lyricsRunClientProvider = Provider<LyricsRunClient>(
  (ref) => LyricsRunClient(
    ref.watch(pluginRunnerProvider),
    run: ref.watch(lyricsParseRunnerProvider),
  ),
);

/// How long a track stays playing before its automatic lookup starts.
final lookupDebounceProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// The recorded ends of automatic lookups by cache key, for the resolution.
class LookupOutcomes extends Notifier<Map<String, LookupOutcome>> {
  @override
  Map<String, LookupOutcome> build() => const {};

  void publish(Map<String, LookupOutcome> outcomes) => state = outcomes;
}

final lookupOutcomesProvider =
    NotifierProvider<LookupOutcomes, Map<String, LookupOutcome>>(
      LookupOutcomes.new,
    );

/// The automatic lookups of the app. A change of the sources, of the
/// auto-search setting or of a plugin's configuration drops the recorded ends
/// and restarts what is running.
final onlineLookupsProvider = Provider<OnlineLookups>((ref) {
  final lookups = OnlineLookups(
    client: ref.watch(lyricsRunClientProvider),
    cache: ref.watch(onlineCacheStoreProvider),
    rejects: ref.watch(rejectStoreProvider),
    backoff: ref.watch(onlineBackoffProvider),
    now: _clockOf(ref),
    sources: () => ref.read(lyricsSourcesProvider),
    debounce: ref.watch(lookupDebounceProvider),
    onOutcomes: (outcomes) {
      if (ref.mounted) {
        ref.read(lookupOutcomesProvider.notifier).publish(outcomes);
      }
    },
  );
  ref.onDispose(lookups.dispose);
  ref.listen(lyricsSourcesProvider, (_, _) => lookups.reset());
  ref.listen(lyricsAutoSearchProvider, (_, _) => lookups.reset());
  ref.listen(lyricsSourcesLoadedProvider, (_, _) => lookups.reset());
  return lookups;
});

/// Keeps the lookup of [target] alive while something watches it (only the
/// resolution of the playing track does).
final lookupDriverProvider = Provider.autoDispose.family<void, LookupTarget>((
  ref,
  target,
) {
  final watch = ref.watch(onlineLookupsProvider).watch(target);
  ref.onDispose(watch.release);
});

/// The track the player has loaded; null before the player exists.
final playingTrackIdProvider = Provider<TrackId?>((ref) {
  if (!ref.watch(playerCreatedProvider)) return null;
  return ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
});

/// The kept copy of a track.
final lyricsPinProvider = StreamProvider.family<OnlinePick?, TrackId>(
  (ref, id) {
    final run = ref.watch(lyricsParseRunnerProvider);
    return ref
        .watch(pinStoreProvider)
        .watch(id)
        .asyncMap((row) async => row == null ? null : rows.pickOfRow(row, run));
  },
  isAutoDispose: true,
  retry: _noRetry,
);

/// The cached answers of the sources for a cache key.
final onlineCacheEntriesProvider =
    StreamProvider.family<List<OnlineCacheEntry>, String>(
      (ref, key) {
        final run = ref.watch(lyricsParseRunnerProvider);
        return ref
            .watch(onlineCacheStoreProvider)
            .watch(key)
            .asyncMap(
              (list) async => [
                for (final row in list) await rows.entryOfRow(row, run),
              ],
            );
      },
      isAutoDispose: true,
      retry: _noRetry,
    );

/// What the user refused for a track.
final lyricsRejectsProvider = StreamProvider.family<RejectedResults, TrackId>(
  (ref, id) => ref.watch(rejectStoreProvider).watch(id).map((list) {
    final set = RejectedSet.of(list);
    return RejectedResults(refs: set.refs, hashes: set.hashes);
  }),
  isAutoDispose: true,
  retry: _noRetry,
);
