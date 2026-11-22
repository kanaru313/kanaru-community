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
import '../domain/lyrics_intro_gap.dart';
import '../domain/lyrics_status.dart';
import 'lyrics_loader_provider.dart';
import 'lyrics_settings.dart';

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
/// then the selection order and the user's choice applied. A change of the
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
  if (facts.value?.off ?? false) return LyricsOff(pick.shown);
  final unavailable = result.unavailable;
  if (unavailable != null) return LyricsUnavailable(unavailable);
  final shown = pick.shown;
  return shown == null ? const LyricsNone() : LyricsShown(withIntroGap(shown));
}, isAutoDispose: true);
