import 'dart:async';
import 'dart:io';

import 'package:kanaru/src/playback/data/waveform_cache.dart';
import 'package:kanaru/src/playback/data/waveform_repository.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';

/// One load the fake repository started.
class FakeLoad {
  FakeLoad(this.path);

  final String path;
  final Completer<WaveformResult> done = Completer();
  bool cancelled = false;

  void finish(WaveformResult result) => done.complete(result);
}

/// A repository whose loads wait for the test to finish them and whose cache
/// answers come from [cached].
class FakeWaveformRepository extends WaveformRepository {
  FakeWaveformRepository()
    : super(
        cache: WaveformCache(Directory('/nonexistent/kanaru-waveform-test')),
        start: (_) => throw StateError('the fake never decodes'),
      );

  /// What the disk cache holds, by path.
  final cached = <String, WaveformResult>{};

  /// Every load in start order.
  final loads = <FakeLoad>[];

  /// Paths in start order.
  List<String> get started => [for (final l in loads) l.path];

  FakeLoad loadOf(String path) => loads.lastWhere((l) => l.path == path);

  /// Paths whose file "changed": the key gets this suffix.
  final changed = <String>{};

  @override
  Future<String?> cacheKey(String path) async =>
      changed.contains(path) ? '$path#changed' : path;

  @override
  Future<WaveformResult?> peek(String path) async => cached[path];

  @override
  WaveformLoad load(String path) {
    final fake = FakeLoad(path);
    loads.add(fake);
    return WaveformLoad(fake.done.future, () {
      fake.cancelled = true;
      if (!fake.done.isCompleted) fake.finish(const RetryLater());
    });
  }
}
