import 'package:audio_session/audio_session.dart';

/// The few `audio_session` calls the Android controls need, so tests can fake
/// them.
abstract interface class AudioSessionPort {
  /// Takes (true) or gives back (false) audio focus. False = the system
  /// refused.
  Future<bool> setActive(bool active);

  Stream<AudioInterruptionEvent> get interruptions;

  /// Headphones unplugged or similar: audio should stop.
  Stream<void> get becomingNoisy;
}

/// Over the real [AudioSession].
class PluginAudioSessionPort implements AudioSessionPort {
  PluginAudioSessionPort(this._session);

  final AudioSession _session;

  @override
  Future<bool> setActive(bool active) => _session.setActive(active);

  @override
  Stream<AudioInterruptionEvent> get interruptions =>
      _session.interruptionEventStream;

  @override
  Stream<void> get becomingNoisy => _session.becomingNoisyEventStream;
}
