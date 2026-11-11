import 'dart:async';

import 'package:kanaru/src/playback/data/load_failure_guard.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';

/// A scripted [AudioEngine]: records every command, and a test pushes events
/// with [emit]. [loadGate] lets a test hold a `load` open.
class FakeAudioEngine implements AudioEngine {
  final List<String> commands = [];
  final List<EngineMedia> loads = [];
  final List<EngineMedia?> nexts = [];
  Duration? lastStart;
  bool lastLoadPlay = false;
  bool disposed = false;
  Future<void>? loadGate;

  /// Holds `seek` open, so a test can emit ticks while a seek is in flight.
  Future<void>? seekGate;

  /// When set, `load` throws it after recording the call, the way an engine
  /// whose open fails does; the failure is reported through the same guard
  /// the real engine uses.
  Object? loadError;
  final _events = StreamController<EngineEvent>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  void emit(EngineEvent e) => _events.add(e);
  void tickPosition(Duration d) => _position.add(d);

  @override
  Future<void> load(
    EngineMedia current, {
    EngineMedia? next,
    required bool play,
    Duration start = Duration.zero,
  }) async {
    commands.add('load');
    loads.add(current);
    nexts.add(next);
    lastStart = start;
    lastLoadPlay = play;
    await guardLoad(
      current: current,
      emit: _events.add,
      onFailed: () {},
      body: () async {
        await loadGate;
        final error = loadError;
        if (error != null) throw error;
      },
    );
  }

  @override
  Future<void> setNext(EngineMedia? next) async {
    commands.add('setNext');
    nexts.add(next);
  }

  @override
  Future<void> play() async => commands.add('play');

  @override
  Future<void> pause() async => commands.add('pause');

  @override
  Future<void> stop() async => commands.add('stop');

  @override
  Future<void> seek(Duration position) async {
    commands.add('seek:${position.inMilliseconds}');
    await seekGate;
  }

  @override
  Future<void> setVolume(double volume0to100) async =>
      commands.add('volume:${volume0to100.round()}');

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
    await _position.close();
    await _playing.close();
  }
}
