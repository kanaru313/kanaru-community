import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/queue_state.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/queue_view_provider.dart';
import 'package:kanaru/src/playback/state/waveform_loader.dart';
import 'package:kanaru/src/playback/state/waveform_providers.dart';

import '../support/fake_waveform_repository.dart';

QueueItem _item(int n) =>
    QueueItem(entryId: n, trackId: TrackId(n * 10), sortKey: 'k$n');

QueueView _view(
  int count,
  int? current, {
  RepeatMode repeat = RepeatMode.off,
}) => QueueView(
  items: [for (var i = 1; i <= count; i++) _item(i)],
  current: current,
  repeat: repeat,
);

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('waveformWantOf', () {
    test('the current entry and the next in play order', () {
      final want = waveformWantOf(_view(3, 0));
      expect(want.currentEntry, 1);
      expect(want.currentTrack, const TrackId(10));
      expect(want.nextEntry, 2);
      expect(want.nextTrack, const TrackId(20));
    });

    test('the last entry has no next, unless the queue repeats', () {
      expect(waveformWantOf(_view(3, 2)).nextEntry, isNull);
      expect(waveformWantOf(_view(3, 2, repeat: RepeatMode.all)).nextEntry, 1);
    });

    test('repeating one entry has no other next', () {
      expect(
        waveformWantOf(_view(3, 0, repeat: RepeatMode.one)).nextEntry,
        isNull,
      );
    });

    test('a one-entry queue that repeats all has no next', () {
      expect(
        waveformWantOf(_view(1, 0, repeat: RepeatMode.all)).nextEntry,
        isNull,
      );
    });

    test('nothing current wants nothing', () {
      expect(waveformWantOf(_view(3, null)), WaveformWant.none);
      expect(waveformWantOf(const QueueView()), WaveformWant.none);
    });
  });

  group('waveformProvider', () {
    late FakeWaveformRepository repo;
    late StreamController<QueueView> queue;
    late ProviderContainer container;

    setUp(() {
      repo = FakeWaveformRepository();
      queue = StreamController<QueueView>.broadcast();
      container = ProviderContainer(
        overrides: [
          queueViewProvider.overrideWith((ref) async* {
            yield _view(3, 0);
            yield* queue.stream;
          }),
          waveformLoaderProvider.overrideWithValue(
            WaveformLoader(
              repository: repo,
              pathOf: (id) async => '/music/${id.value}.flac',
            ),
          ),
        ],
      );
      // Closed without waiting: a paused listener would hold the future.
      addTearDown(() => unawaited(queue.close()));
      addTearDown(container.dispose);
    });

    test('no job runs while no seek bar is mounted', () async {
      await _settle();
      expect(repo.loads, isEmpty);
    });

    test('mounting starts the current entry, then the next', () async {
      final sub = container.listen(waveformProvider, (_, _) {});
      await _settle();
      expect(repo.started, ['/music/10.flac']);
      repo
          .loadOf('/music/10.flac')
          .finish(Ready(Uint8List.fromList([1, 2, 3]), 1000));
      await _settle();
      expect(repo.started, ['/music/10.flac', '/music/20.flac']);
      final view = container.read(waveformProvider).value!;
      expect(view.entryId, 1);
      expect(view.levels, [1, 2, 3]);
      sub.close();
    });

    test('the last seek bar going away cancels the job', () async {
      final sub = container.listen(waveformProvider, (_, _) {});
      await _settle();
      final job = repo.loadOf('/music/10.flac');
      sub.close();
      await _settle();
      expect(job.cancelled, isTrue);
    });

    test('a same-frame remount keeps the job', () async {
      final first = container.listen(waveformProvider, (_, _) {});
      await _settle();
      final job = repo.loadOf('/music/10.flac');
      first.close();
      final second = container.listen(waveformProvider, (_, _) {});
      await _settle();
      expect(job.cancelled, isFalse);
      expect(repo.loads.length, 1);
      second.close();
    });

    test('a track change cancels the old job and starts the new one', () async {
      final sub = container.listen(waveformProvider, (_, _) {});
      await _settle();
      final job = repo.loadOf('/music/10.flac');
      queue.add(_view(6, 4));
      await _settle();
      expect(job.cancelled, isTrue);
      expect(repo.started.last, '/music/50.flac');
      sub.close();
    });
  });
}
