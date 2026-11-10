import 'dart:async';

import '../domain/audio_engine.dart';

/// An [AudioEngine] that makes no sound and loads no native library: it is
/// the default under `flutter test`. It echoes commands as events, reports a
/// synthetic duration and moves the position on a timer only while playing.
class SilentAudioEngine implements AudioEngine {
  SilentAudioEngine({
    Duration Function(EngineMedia media)? durationOf,
    this.tick = const Duration(milliseconds: 250),
  }) : _durationOf = durationOf ?? ((_) => const Duration(seconds: 180));

  final Duration Function(EngineMedia) _durationOf;
  final Duration tick;
  final _events = StreamController<EngineEvent>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  EngineMedia? _current;
  EngineMedia? _next;
  Duration _pos = Duration.zero;
  bool _isPlaying = false;
  bool _disposed = false;
  Timer? _timer;

  void _setPlaying(bool v) {
    _isPlaying = v;
    _timer?.cancel();
    _timer = v ? Timer.periodic(tick, (_) => _advance(tick)) : null;
    if (!_playing.isClosed) _playing.add(v);
  }

  void _advance(Duration by) {
    final cur = _current;
    if (cur == null || _disposed) return;
    _pos += by;
    final total = _durationOf(cur);
    if (_pos < total) {
      _position.add(_pos);
      return;
    }
    final next = _next;
    if (next == null) {
      _pos = total;
      _setPlaying(false);
      _events.add(EngineEnded(cur.token));
      return;
    }
    _current = next;
    _next = null;
    _pos = Duration.zero;
    _events
      ..add(EngineAdvanced(next.token))
      ..add(EngineLoaded(next.token, _durationOf(next)));
  }

  @override
  Future<void> load(
    EngineMedia current, {
    EngineMedia? next,
    required bool play,
    Duration start = Duration.zero,
  }) async {
    if (_disposed) return;
    _current = current;
    _next = next;
    _pos = start;
    _events.add(EngineLoaded(current.token, _durationOf(current)));
    _setPlaying(play);
  }

  @override
  Future<void> setNext(EngineMedia? next) async {
    if (!_disposed) _next = next;
  }

  @override
  Future<void> play() async {
    if (!_disposed && _current != null) _setPlaying(true);
  }

  @override
  Future<void> pause() async {
    if (!_disposed) _setPlaying(false);
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _current = null;
    _next = null;
    _pos = Duration.zero;
    _setPlaying(false);
  }

  @override
  Future<void> seek(Duration position) async {
    if (_disposed || _current == null) return;
    _pos = position;
    _events.add(EngineSeeked(position));
  }

  @override
  Future<void> setVolume(double volume0to100) async {}

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  /// Whether it is playing now (tests).
  bool get isPlaying => _isPlaying;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _isPlaying = false;
    _timer?.cancel();
    await _events.close();
    await _position.close();
    await _playing.close();
  }
}
