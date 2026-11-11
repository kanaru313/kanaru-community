import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/track_id.dart';
import '../../platform/state/device_id_provider.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/now_playing.dart';
import '../domain/playback_commands.dart';
import '../domain/playback_focus.dart';
import 'audio_engine_provider.dart';
import 'listen_recorder.dart';
import 'player_controller.dart';
import 'playback_data_providers.dart';

/// The player. Created by [nowPlayingProvider] and by commands, never while a
/// widget builds. The engine inside is made on the first load.
///
/// Dependencies are read, not watched: a rebuild of one of them (the focus
/// provider, the media bridge) must not dispose the controller and drop the
/// queue and the engine. Focus is asked through a live link to the current
/// provider value, and the media bridge is attached again if it is rebuilt.
final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController(
    repo: ref.read(queueRepositoryProvider),
    resolver: ref.read(playableResolverProvider),
    settings: ref.read(settingsStoreProvider),
    engineFactory: ref.read(audioEngineFactoryProvider),
    focus: _LiveFocus(ref),
    titles: ref.read(trackTitleLookupProvider),
    listens: ListenRecorder(
      writer: ref.read(playLogWriterProvider),
      // Read when a listen is written, so a container without a device id
      // (a bare test) can still build the player.
      deviceId: () => ref.read(deviceIdProvider),
    ),
  );
  ref.onDispose(controller.dispose);
  ref.listen(
    mediaSessionBridgeProvider,
    (_, bridge) => bridge.attach(controller),
    fireImmediately: true,
  );
  return controller;
});

/// Audio focus through whatever [playbackFocusProvider] holds now.
class _LiveFocus implements PlaybackFocus {
  _LiveFocus(this._ref);

  final Ref _ref;

  @override
  Future<bool> activate() => _ref.read(playbackFocusProvider).activate();

  @override
  Future<void> deactivate() => _ref.read(playbackFocusProvider).deactivate();
}

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
