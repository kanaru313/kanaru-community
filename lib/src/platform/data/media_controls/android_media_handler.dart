import 'package:audio_service/audio_service.dart';

import '../../domain/media_controls.dart';
import 'command_buffer.dart';

/// The `audio_service` handler: turns what the notification, lock screen,
/// headset and Bluetooth buttons ask into [MediaCommand]s. It owns no
/// playback state; the app pushes state in through
/// `AndroidMediaControls.update`.
class AndroidMediaHandler extends BaseAudioHandler {
  AndroidMediaHandler({CommandBuffer? buffer})
    : commandBuffer = buffer ?? CommandBuffer();

  /// Commands for the player. Holds the last one until the player listens.
  final CommandBuffer commandBuffer;

  @override
  Future<void> play() async => commandBuffer.add(const Play());

  @override
  Future<void> pause() async => commandBuffer.add(const Pause());

  @override
  Future<void> stop() async => commandBuffer.add(const Stop());

  @override
  Future<void> skipToNext() async => commandBuffer.add(const Next());

  @override
  Future<void> skipToPrevious() async => commandBuffer.add(const Previous());

  @override
  Future<void> seek(Duration position) async {
    final id = mediaItem.value?.id;
    if (id != null) commandBuffer.add(SetPosition(id, position));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async =>
      commandBuffer.add(SetShuffle(shuffleMode != AudioServiceShuffleMode.none));

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async =>
      commandBuffer.add(
        SetRepeat(switch (repeatMode) {
          AudioServiceRepeatMode.none => MediaRepeat.none,
          AudioServiceRepeatMode.one => MediaRepeat.track,
          AudioServiceRepeatMode.all ||
          AudioServiceRepeatMode.group => MediaRepeat.playlist,
        }),
      );

  /// A headset button: the app decides play or pause from its own state.
  @override
  Future<void> click([MediaButton button = MediaButton.media]) async =>
      commandBuffer.add(switch (button) {
        MediaButton.media => const PlayPause(),
        MediaButton.next => const Next(),
        MediaButton.previous => const Previous(),
      });
}
