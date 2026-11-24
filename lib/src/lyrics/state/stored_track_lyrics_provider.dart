import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/track_id.dart';
import '../domain/lyrics_status.dart';
import 'track_lyrics_providers.dart';

/// The lyrics a track already has, for screens that must never start work
/// (the song info page): the same selection as `trackLyricsProvider` (the
/// user's choice, a kept online copy, local lyrics, a cached online result),
/// but it never watches the lookup driver, so opening it starts no plugin and
/// no network request, even for the playing track. A track that would need a
/// lookup answers `LyricsNone(reason: notPlaying)`, also while Now Playing's own lookup is
/// still running; its cached result then shows here. Both providers share one file read per
/// track (`localLyricsReadProvider`).
final storedTrackLyricsProvider = Provider.family<TrackLyrics, TrackId>(
  (ref, id) => resolveLyricsState(ref, id, lookup: false),
  isAutoDispose: true,
);
