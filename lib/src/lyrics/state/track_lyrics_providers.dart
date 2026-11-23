import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../database/state/database_providers.dart';
import '../../media/domain/track_id.dart';
import '../../playback/domain/playable.dart';
import '../../playback/state/playback_data_providers.dart';
import '../data/local_lyrics_read.dart';
import '../data/lyrics_facts_query.dart';
import '../domain/local_lyrics_pick.dart';
import '../domain/lyrics_facts.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_intro_gap.dart';
import '../domain/lyrics_status.dart';
import '../domain/online/lookup_target.dart';
import '../domain/online/online_cache_pick.dart';
import '../domain/online/online_resolution.dart';
import 'lyrics_loader_provider.dart';
import 'lyrics_choice_commands.dart';
import 'lyrics_settings.dart';
import 'online/lyrics_sources_provider.dart';
import 'online/online_lookup_providers.dart';

final _log = Logger('lyrics_state');

/// Riverpod 3 retries failed providers by default; a lyrics read that failed
/// is shown as "no lyrics" and tried again the next time it is watched.
Duration? _noRetry(int count, Object error) => null;

/// The database facts of one track (paths, revisions, the user's choice).
final lyricsFactsProvider = StreamProvider.family<LyricsFacts?, TrackId>(
  (ref, id) => watchLyricsFacts(ref.watch(appDatabaseProvider), id),
  isAutoDispose: true,
  retry: _noRetry,
);

/// What the local sources hold for one track. Re-runs only when the file
/// identity changes (revisions, `.lrc` locator), never on a choice write or a
/// setting flip. Playability comes only from the playback resolver; a track
/// without a local file is answered without any I/O.
final localLyricsReadProvider = FutureProvider.family<LocalLyricsRead, TrackId>(
  (ref, id) async {
    final loader = ref.read(lyricsLoaderProvider);
    // A tag read still waiting when this provider goes away is not wanted.
    final cancel = LoadCancel();
    ref.onDispose(cancel.cancel);
    final resolver = ref.read(playableResolverProvider);
    final key = await ref.watch(
      lyricsFactsProvider(id).selectAsync((f) => f?.readKey),
    );
    final playable = (await resolver.resolve([id]))[id];
    switch (playable) {
      case LocalFile(:final path):
        final locator = key?.$2;
        try {
          return await loader.load(
            LyricsRequest(
              trackId: id,
              audioPath: path,
              trackRevision: key?.$1,
              lrcPath: locator == null ? null : lrcPathBeside(path, locator),
            ),
            cancel: cancel,
          );
        } on LyricsSuperseded {
          // Only our own cancel (the provider is disposed) drops a read;
          // nobody consumes this value, so never complete.
          if (!cancel.isCancelled) rethrow;
          return await Completer<LocalLyricsRead>().future;
        }
      case Unplayable(:final reason):
        return LocalLyricsRead.unavailable(reason);
      case null:
        return const LocalLyricsRead.unavailable(UnplayableReason.unknownTrack);
    }
  },
  isAutoDispose: true,
  retry: _noRetry,
);

/// The lyrics state of one track: loading until facts and files are read,
/// then the selection order applied (`resolveTrackLyrics`: the user's choice,
/// a kept online copy, the local lyrics, a cached online result, the lookup
/// state). Reading is local and free for every track; only the playing track
/// whose resolution needs a lookup starts one. A change of the
/// `lyrics.local_first` setting or of the choice recomputes this without any
/// read.
final trackLyricsProvider = Provider.family<TrackLyrics, TrackId>((ref, id) {
  final facts = ref.watch(lyricsFactsProvider(id));
  final read = ref.watch(localLyricsReadProvider(id));
  final first = ref.watch(lyricsLocalFirstProvider);
  if (facts.isLoading && !facts.hasValue) return const LyricsLoading();
  // A refresh of the same track keeps what it shows (the family is per id).
  if (read.isLoading && !read.hasValue) return const LyricsLoading();
  final result = read.value;
  if (result == null) {
    _log.warning('track ${id.value}: lyrics read failed');
    return const LyricsNone();
  }
  final pick = pickLocalLyrics(tag: result.tag, lrc: result.lrc, first: first);
  final f = facts.value;
  final target = f == null
      ? null
      : LookupTarget(trackId: id, query: f.query, artists: f.artists);
  final key = target?.cacheKey ?? '';
  final pin = ref.watch(lyricsPinProvider(id));
  final cache = ref.watch(onlineCacheEntriesProvider(key));
  final rejects = ref.watch(lyricsRejectsProvider(id));
  for (final online in [pin, cache, rejects]) {
    if (online.isLoading && !online.hasValue) return const LyricsLoading();
  }
  final sourcesLoaded = ref.watch(lyricsSourcesLoadedProvider);
  final outcome = ref.watch(lookupOutcomesProvider.select((m) => m[key]));
  final playing = ref.watch(playingTrackIdProvider.select((p) => p == id));
  final now = DateTime.fromMillisecondsSinceEpoch(
    ref.read(lyricsClockProvider)(),
  );
  final resolution = resolveTrackLyrics(
    choice: f == null
        ? null
        : f.off
        ? LyricsChoice.off
        : f.file
        ? LyricsChoice.file
        : null,
    pin: pin.value,
    local: pick.shown,
    cache: cache.value ?? const [],
    sources: sourcesLoaded ? ref.watch(lyricsSourcesProvider) : const [],
    autoOn: ref.watch(lyricsAutoSearchProvider),
    autoSearchable: target?.searchable ?? false,
    now: now,
    trackDuration: f?.duration,
    backoff: ref.read(onlineBackoffProvider).snapshot(),
    lookup: outcome,
    rejected: rejects.value ?? const RejectedResults(),
    sourcesLoaded: sourcesLoaded,
  );
  final state = resolution.state;
  final unavailable = result.unavailable;
  if (unavailable != null &&
      state is! LyricsShown &&
      state is! LyricsInstrumental &&
      state is! LyricsOff) {
    return LyricsUnavailable(unavailable);
  }
  if (resolution.needsLookup && target != null) {
    if (!playing) {
      // Only the playing track is looked up; the others show what is stored.
      return const LyricsNone(reason: LyricsNoneReason.notPlaying);
    }
    ref.watch(lookupDriverProvider(target));
  }
  if (playing) _armWake(ref, state, now);
  return switch (state) {
    LyricsShown(:final lyrics) => LyricsShown(_withGap(lyrics)),
    _ => state,
  };
}, isAutoDispose: true);

/// [lyrics] with the intro gap of `withIntroGap`, keeping the online source.
Lyrics _withGap(Lyrics lyrics) {
  final gapped = withIntroGap(lyrics);
  if (identical(gapped, lyrics)) return lyrics;
  return Lyrics(
    lines: gapped.lines,
    synced: gapped.synced,
    origin: lyrics.origin,
    online: lyrics.online,
  );
}

/// A failed or paused lookup of the playing track is tried again when its
/// retry time comes, though nothing else changes by then: one timer
/// recomputes the state, which by then no longer holds the old end, so the
/// lookup starts again. Cancelled when the state is recomputed or disposed.
void _armWake(Ref ref, TrackLyrics state, DateTime now) {
  final at = switch (state) {
    LyricsLookupFailed(:final retryAt) => retryAt,
    LyricsLookupPaused(:final until) => until,
    _ => null,
  };
  if (at == null) return;
  // A time already past (a pause that has not notified yet) is not waited on
  // at zero: that could spin.
  final wait = at.isAfter(now)
      ? at.difference(now) + const Duration(milliseconds: 1)
      : const Duration(seconds: 1);
  final timer = ref.read(lyricsWakeTimerProvider)(wait, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}
