import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/waveform_loader.dart';

import '../support/fake_waveform_repository.dart';

Ready _ready(int seed) =>
    Ready(Uint8List.fromList([seed, seed + 1, seed + 2]), 3000);

String _path(TrackId id) => '/music/${id.value}.flac';

WaveformWant _want(int current, [int? next]) => WaveformWant(
  currentEntry: current,
  currentTrack: TrackId(current),
  nextEntry: next,
  nextTrack: next == null ? null : TrackId(next),
);

/// Lets the loader's microtasks and the fake repository's futures run.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness({int memory = 8}) {
    loader = WaveformLoader(
      repository: repo,
      pathOf: (id) async => hasFile(id) ? _path(id) : null,
      memoryEntries: memory,
    );
  }

  final repo = FakeWaveformRepository();
  bool Function(TrackId) hasFile = (_) => true;
  late final WaveformLoader loader;
  final wants = StreamController<WaveformWant>();
  final views = <WaveformView>[];
  StreamSubscription<WaveformView>? sub;

  void watch() => sub = loader.watch(wants.stream).listen(views.add);

  Future<void> want(WaveformWant w) async {
    wants.add(w);
    await _settle();
  }

  Future<void> finish(int track, WaveformResult r) async {
    repo.loadOf(_path(TrackId(track))).finish(r);
    await _settle();
  }

  Future<void> close() async {
    await sub?.cancel();
    // Never listened to: closing would wait for a listener.
    unawaited(wants.close());
  }
}

void main() {
  test('nothing is decoded until somebody watches', () async {
    final h = _Harness();
    h.wants.add(_want(1, 2));
    await _settle();
    expect(h.repo.loads, isEmpty);
    await h.close();
  });

  test('current first, then next, one job at a time', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    expect(h.repo.started, [_path(const TrackId(1))]);
    await h.finish(1, _ready(1));
    expect(h.repo.started, [_path(const TrackId(1)), _path(const TrackId(2))]);
    await h.finish(2, _ready(2));
    expect(h.repo.loads.length, 2);
    await h.close();
  });

  test('the bar is flat first, then fades in with the levels', () async {
    final h = _Harness()..watch();
    await h.want(_want(1));
    expect(h.views.last.entryId, 1);
    expect(h.views.last.levels, isNull);
    await h.finish(1, _ready(5));
    final view = h.views.last;
    expect(view.entryId, 1);
    expect(view.levels, [5, 6, 7]);
    expect(view.durationMs, 3000);
    expect(view.instant, isFalse);
    await h.close();
  });

  test('levels already on disk show at once, without a job', () async {
    final h = _Harness();
    h.repo.cached[_path(const TrackId(1))] = _ready(9);
    h.watch();
    await h.want(_want(1));
    expect(h.views.last.levels, [9, 10, 11]);
    expect(h.views.last.instant, isTrue);
    expect(h.repo.loads, isEmpty);
    await h.close();
  });

  test('a prefetched next entry is instant when it becomes current', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    await h.finish(1, _ready(1));
    await h.finish(2, _ready(2));
    await h.want(_want(2, 3));
    expect(h.views.last.entryId, 2);
    expect(h.views.last.instant, isTrue);
    expect(h.views.last.levels, [2, 3, 4]);
    await h.close();
  });

  test('a job for an entry that is no longer wanted is cancelled', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    final first = h.repo.loadOf(_path(const TrackId(1)));
    await h.want(_want(3, 4));
    expect(first.cancelled, isTrue);
    expect(h.repo.started.last, _path(const TrackId(3)));
    await h.close();
  });

  test('a job that is still wanted keeps running', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    final first = h.repo.loadOf(_path(const TrackId(1)));
    // Skip to the next: entry 2 is current, 1 is gone; but 2 was only next.
    await h.want(_want(1, 5));
    expect(first.cancelled, isFalse);
    await h.close();
  });

  test('the last watcher going away cancels the running job', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    final job = h.repo.loadOf(_path(const TrackId(1)));
    await h.sub!.cancel();
    await _settle();
    expect(job.cancelled, isTrue);
    expect(h.repo.loads.length, 1);
    await h.wants.close();
  });

  test('a retry waits for a new entry or a new view', () async {
    final h = _Harness()..watch();
    await h.want(_want(1));
    await h.finish(1, const RetryLater());
    // The queue changed around the entry; the same entry is not retried.
    await h.want(_want(1, 2));
    await h.finish(2, _ready(2));
    expect(h.repo.started.where((p) => p.endsWith('/1.flac')).length, 1);
    await h.close();

    // A new view (the seek bar mounted again) tries again.
    h.repo.loads.clear();
    final again = WaveformLoader(
      repository: h.repo,
      pathOf: (id) async => _path(id),
    );
    final wants = StreamController<WaveformWant>();
    final sub = again.watch(wants.stream).listen((_) {});
    wants.add(_want(1));
    await _settle();
    expect(h.repo.started, [_path(const TrackId(1))]);
    await sub.cancel();
    await wants.close();
  });

  test(
    'an entry cancelled for moving on is tried again when it returns',
    () async {
      final h = _Harness()..watch();
      await h.want(_want(1));
      await h.want(_want(2));
      expect(h.repo.loadOf(_path(const TrackId(1))).cancelled, isTrue);
      await h.finish(2, _ready(2));
      await h.want(_want(1));
      expect(h.repo.started.where((p) => p.endsWith('/1.flac')).length, 2);
      await h.close();
    },
  );

  test('a file with no waveform stays flat and is not decoded again', () async {
    final h = _Harness()..watch();
    await h.want(_want(1, 2));
    await h.finish(1, const NoWaveform());
    expect(h.views.last.levels, isNull);
    await h.finish(2, _ready(2));
    await h.want(_want(2, 1));
    expect(h.repo.started.where((p) => p.endsWith('/1.flac')).length, 1);
    await h.close();
  });

  test('a track without a local file is flat and skipped', () async {
    final h = _Harness()..hasFile = (id) => id.value != 1;
    h.watch();
    await h.want(_want(1, 2));
    expect(h.views.last.entryId, 1);
    expect(h.views.last.levels, isNull);
    expect(h.repo.started, [_path(const TrackId(2))]);
    await h.close();
  });

  test('the memory keeps the latest few results only', () async {
    final h = _Harness(memory: 2)..watch();
    await h.want(_want(1));
    await h.finish(1, _ready(1));
    await h.want(_want(2));
    await h.finish(2, _ready(2));
    await h.want(_want(3));
    await h.finish(3, _ready(3));
    // 1 was evicted: back to it, a load starts again (the disk is empty).
    await h.want(_want(1));
    expect(h.repo.started.where((p) => p.endsWith('/1.flac')).length, 2);
    // 3 is still in memory.
    await h.want(_want(3));
    expect(h.repo.started.where((p) => p.endsWith('/3.flac')).length, 1);
    expect(h.views.last.instant, isTrue);
    await h.close();
  });

  test('a failing path lookup means no local file', () async {
    final h = _Harness();
    final loader = WaveformLoader(
      repository: h.repo,
      pathOf: (id) async =>
          id.value == 1 ? throw StateError('db gone') : _path(id),
    );
    final views = <WaveformView>[];
    final sub = loader.watch(h.wants.stream).listen(views.add);
    h.wants.add(_want(1, 2));
    await _settle();
    expect(views.last.entryId, 1);
    expect(views.last.levels, isNull);
    expect(h.repo.started, [_path(const TrackId(2))]);
    await sub.cancel();
  });

  test('the memory is keyed by file version, not by path', () async {
    final h = _Harness()..watch();
    await h.want(_want(1));
    await h.finish(1, _ready(1));
    // The file changed on disk: the old result must not answer for it.
    h.repo.changed.add(_path(const TrackId(1)));
    await h.want(_want(2));
    await h.finish(2, _ready(2));
    await h.want(_want(1));
    expect(h.repo.started.where((p) => p.endsWith('/1.flac')).length, 2);
    await h.close();
  });

  test('nothing playing is a view without an entry', () async {
    final h = _Harness()..watch();
    await h.want(_want(1));
    await h.want(WaveformWant.none);
    expect(h.views.last.entryId, isNull);
    await h.close();
  });
}
