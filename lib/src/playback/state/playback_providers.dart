import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/track_id.dart';
import '../data/unavailable_playback.dart';
import '../domain/now_playing.dart';
import '../domain/playback_commands.dart';

/// The player's command surface for the library and screens. The real
/// controller replaces the body; the declaration is fixed.
final playbackCommandsProvider = Provider<PlaybackCommands>(
  (ref) => const UnavailablePlaybackCommands(),
);

/// What is loaded now. Never watch it whole from a list: use the narrow
/// providers below so a play/pause or track change rebuilds only what changed.
final nowPlayingProvider = StreamProvider<NowPlaying>(
  (ref) => Stream.value(NowPlaying.none),
);

/// Rebuilds only the tiles whose answer changes. Families never auto-dispose
/// in Riverpod 3 unless asked, so every per-tile family is `isAutoDispose`.
final isCurrentTrackProvider = Provider.family<bool, TrackId>(
  (ref, id) =>
      ref.watch(nowPlayingProvider.select((n) => n.value?.trackId == id)),
  isAutoDispose: true,
);

final hasCurrentTrackProvider = Provider<bool>(
  (ref) =>
      ref.watch(nowPlayingProvider.select((n) => n.value?.hasTrack ?? false)),
);

final isPlayingProvider = Provider<bool>(
  (ref) =>
      ref.watch(nowPlayingProvider.select((n) => n.value?.playing ?? false)),
);
