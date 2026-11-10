import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/track_id.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/now_playing.dart';
import '../domain/playback_commands.dart';
import 'audio_engine_provider.dart';
import 'player_controller.dart';
import 'playback_data_providers.dart';

/// The player. Created by [nowPlayingProvider] and by commands, never while a
/// widget builds. The engine inside is made on the first load.
final playerControllerProvider = Provider<PlayerController>((ref) {
  // `read`, not `watch`: a rebuild of a dependency (the focus bridge arrives
  // later) must not dispose the controller and drop the queue and the engine.
  final controller = PlayerController(
    repo: ref.read(queueRepositoryProvider),
    resolver: ref.read(playableResolverProvider),
    settings: ref.read(settingsStoreProvider),
    engineFactory: ref.read(audioEngineFactoryProvider),
    focus: ref.read(playbackFocusProvider),
    titles: ref.read(trackTitleLookupProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// The player's command surface for the library and screens.
final playbackCommandsProvider = Provider<PlaybackCommands>(
  (ref) => ref.watch(playerControllerProvider),
);

/// What is loaded now. Never watch it whole from a list: use the narrow
/// providers below so a play/pause or track change rebuilds only what changed.
final nowPlayingProvider = StreamProvider<NowPlaying>(
  (ref) => ref.watch(playerControllerProvider).nowPlaying,
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
