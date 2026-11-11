import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';

import '../../domain/media_controls.dart';
import 'android_audio_session_port.dart';
import 'android_media_handler.dart';

final _log = Logger('android.media_controls');

/// [MediaControls] on Android: a media notification and lock screen through
/// `audio_service`, and audio focus through `audio_session`.
///
/// The handler exists from launch (the session must be initialised once per
/// process); until the player has played, [update] keeps the session idle so
/// there is no notification.
///
/// Audio focus: [activate] runs before every transition to playing. A focus
/// loss that asks for a pause pauses the player and remembers it, so a call
/// that ends hands the music back; a pause the user made before or during the
/// interruption is never undone. Unplugging headphones pauses.
class AndroidMediaControls implements MediaControls {
  AndroidMediaControls(this._handler, this._session) {
    _subs.add(_session.interruptions.listen(_onInterruption));
    _subs.add(_session.becomingNoisy.listen((_) => _post(const Pause())));
  }

  final AndroidMediaHandler _handler;
  final AudioSessionPort _session;
  final _subs = <StreamSubscription<Object?>>[];

  MediaControlsItem? _item;
  MediaControlsState? _state;
  Duration _position = Duration.zero;
  bool _wasPlaying = false;

  /// An interruption paused playback that was running.
  bool _resumeAfterInterruption = false;

  @override
  Stream<MediaCommand> get commands => _handler.commandBuffer.stream;

  @override
  Future<void> start() async {}

  void _post(MediaCommand command) => _handler.commandBuffer.add(command);

  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      // A duck lowers the volume for a moment; the system does it for us.
      if (event.type == AudioInterruptionType.duck) return;
      if (_wasPlaying) {
        _resumeAfterInterruption = true;
        _post(const Pause());
      }
    } else {
      final resume =
          _resumeAfterInterruption && event.type == AudioInterruptionType.pause;
      _resumeAfterInterruption = false;
      if (resume) _post(const Play());
    }
  }

  @override
  Future<void> update(MediaControlsItem? item, MediaControlsState state) async {
    // The user playing again by hand ends the wait for the interruption.
    if (state.playing && !_wasPlaying) _resumeAfterInterruption = false;
    _wasPlaying = state.playing;
    final itemChanged = item != _item;
    final stateChanged = state != _state;
    _item = item;
    _state = state;
    _position = state.position;
    if (itemChanged && item != null) _handler.mediaItem.add(_mediaItem(item));
    if (itemChanged || stateChanged) _publish(state);
  }

  MediaItem _mediaItem(MediaControlsItem item) => MediaItem(
    id: item.id,
    title: item.title,
    artist: item.artists.isEmpty ? null : item.artists.join(', '),
    album: item.album,
    duration: item.duration,
    artUri: item.artUri,
  );

  void _publish(MediaControlsState state, {Duration? position}) {
    final at = position ?? _position;
    _handler.playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state.started && _item != null
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        playing: state.playing,
        updatePosition: at,
        bufferedPosition: at,
        speed: state.speed,
        shuffleMode: state.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: switch (state.repeat) {
          MediaRepeat.none => AudioServiceRepeatMode.none,
          MediaRepeat.track => AudioServiceRepeatMode.one,
          MediaRepeat.playlist => AudioServiceRepeatMode.all,
        },
      ),
    );
  }

  @override
  void updatePosition(Duration position) => _position = position;

  @override
  void seeked(Duration position) {
    _position = position;
    final state = _state;
    if (state != null) _publish(state, position: position);
  }

  @override
  Future<bool> activate() async {
    try {
      return await _session.setActive(true);
    } on Object catch (e) {
      _log.warning('audio focus request failed: $e');
      return false;
    }
  }

  @override
  Future<void> deactivate() async {
    _resumeAfterInterruption = false;
    try {
      await _session.setActive(false);
    } on Object catch (e) {
      _log.fine('audio focus release failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
