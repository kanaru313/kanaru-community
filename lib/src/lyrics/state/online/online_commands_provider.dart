import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/online/online_lyrics_commands.dart';
import '../../domain/lyrics_status.dart';
import '../../domain/online/lookup_target.dart';
import '../lyrics_choice_commands.dart';
import '../track_lyrics_providers.dart';
import 'online_lookup_providers.dart';

/// Keep, reject and choose online lyrics. Reads what a track shows at the
/// moment of the call, so the provider of that track must be watched (the
/// modal watches it).
final onlineLyricsCommandsProvider = Provider<OnlineLyricsCommands>(
  (ref) => OnlineLyricsCommands(
    db: ref.watch(appDatabaseProvider),
    pins: ref.watch(pinStoreProvider),
    cache: ref.watch(onlineCacheStoreProvider),
    rejects: ref.watch(rejectStoreProvider),
    now: ref.watch(lyricsClockProvider),
    run: ref.watch(lyricsParseRunnerProvider),
    shownOnline: (track) => switch (ref.read(trackLyricsProvider(track))) {
      LyricsShown(:final lyrics) => lyrics.online,
      LyricsInstrumental(:final ref) => ref,
      _ => null,
    },
    cacheKeyOf: (track) {
      final f = ref.read(lyricsFactsProvider(track)).value;
      return f == null
          ? null
          : LookupTarget(trackId: track, query: f.query).cacheKey;
    },
    onRejected: (key) => ref.read(onlineLookupsProvider).forget(key),
  ),
);
