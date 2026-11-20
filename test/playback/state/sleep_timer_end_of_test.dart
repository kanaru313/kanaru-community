import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/state/queue_row_infos.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:logging/logging.dart';

import '../support/sleep_timer_harness.dart';

void main() {
  late SleepHarness s;
  setUp(() async {
    s = await SleepHarness.create();
  });
  tearDown(() => s.close());

  /// Tracks 0-2 are album A, 3-4 album B, 5 has no album.
  void twoAlbums() {
    for (var i = 0; i < 3; i++) {
      s.albumOf(i, 'A');
    }
    s.albumOf(3, 'B');
    s.albumOf(4, 'B');
    s.albumOf(5, null);
  }

  /// A next entry was handed to the engine after [before] calls.
  bool handedSince(int before) =>
      s.h.engine.nexts.length > before && s.h.engine.nexts.last != null;

  group('end of track', () {
    test('stops after the current entry, then turns off', () async {
      await s.play();
      s.timer.startEndOfTrack();
      await s.h.settle();
      expect(s.state.mode, SleepTimerMode.endOfTrack);
      expect(s.h.engine.nexts.last, isNull);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.h.c.queueState.current, 1);
      expect(s.controls.cancelledResumes, 1);
    });

    test('the stop is consumed: the next entry plays on', () async {
      await s.play();
      s.timer.startEndOfTrack();
      await s.end();
      await s.userPlay();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
    });
  });

  group('end of queue', () {
    test('only the last entry stops, whatever repeat says', () async {
      await s.h.c.setRepeat(RepeatMode.all);
      await s.play(start: 4);
      s.timer.startEndOfQueue();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
      await s.advance();
      expect(s.state.mode, SleepTimerMode.endOfQueue);
      expect(s.h.c.queueState.current, 5);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.controls.cancelledResumes, 1);
    });

    test('with repeat off the queue end turns it off too', () async {
      await s.play(start: 5);
      s.timer.startEndOfQueue();
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.controls.cancelledResumes, 1);
    });
  });

  group('end of album', () {
    test('two albums stop between them', () async {
      twoAlbums();
      await s.play();
      s.timer.startEndOfAlbum();
      await s.h.settle();
      // The keys came, so the next of the same album is handed over.
      expect(s.h.engine.nexts.last, isNotNull);
      await s.advance();
      await s.h.settle();
      await s.advance();
      await s.h.settle();
      expect(s.h.c.queueState.current, 2);
      expect(s.state.mode, SleepTimerMode.endOfAlbum);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.queueState.current, 3);
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.controls.cancelledResumes, 1);
    });

    test('a track without an album stops after itself', () async {
      twoAlbums();
      await s.play(start: 4);
      s.timer.startEndOfAlbum();
      await s.h.settle();
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.queueState.current, 5);
    });

    test(
      'keys that arrive late: the stop first, the answer re-opens',
      () async {
        twoAlbums();
        s.loadGate = Completer<void>();
        await s.play();
        s.timer.startEndOfAlbum();
        await s.h.settle();
        // Unknown keys: the player was told to stop, nothing is handed over.
        expect(s.h.engine.nexts.last, isNull);
        expect(s.loads, hasLength(1));
        expect(s.loads.single.map((t) => t.value - s.h.tracks.first.value), [
          0,
          1,
          2,
        ]);
        final before = s.h.engine.nexts.length;
        s.loadGate!.complete();
        await s.h.settle();
        expect(handedSince(before), isTrue);
        expect(s.state.mode, SleepTimerMode.endOfAlbum);
      },
    );

    test('an entry ending before the keys came stops', () async {
      twoAlbums();
      s.loadGate = Completer<void>();
      await s.play();
      s.timer.startEndOfAlbum();
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      s.loadGate!.complete();
      await s.h.settle();
      expect(s.state, const SleepTimerState.off());
    });

    test('the same ids are not asked for again and again', () async {
      twoAlbums();
      s.loadGate = Completer<void>();
      await s.play();
      s.timer.startEndOfAlbum();
      await s.h.settle();
      await s.h.c.setRepeat(RepeatMode.all);
      await s.h.c.setRepeat(RepeatMode.off);
      await s.h.settle();
      expect(s.loads, hasLength(1));
      s.loadGate!.complete();
      await s.h.settle();
    });

    test('rows the queue list already loaded are used first', () async {
      twoAlbums();
      final ids = s.h.tracks;
      s.container.read(queueRowInfosProvider.notifier).ensure(ids);
      await s.h.settle();
      expect(s.loads, hasLength(1));
      await s.play();
      s.timer.startEndOfAlbum();
      await s.h.settle();
      expect(s.loads, hasLength(1));
      expect(s.h.engine.nexts.last, isNotNull);
    });

    test(
      'a failing load leaves the keys unknown: stops, logs, no error',
      () async {
        twoAlbums();
        s.loadError = StateError('db closed');
        final records = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(records.add);
        addTearDown(sub.cancel);
        final errors = <Object>[];
        await runZonedGuarded(() async {
          await s.play();
          s.timer.startEndOfAlbum();
          await s.h.settle();
          expect(s.h.engine.nexts.last, isNull);
          await s.end();
        }, (e, _) => errors.add(e));
        expect(errors, isEmpty);
        expect(
          records.where((r) => r.message.contains('album keys not loaded')),
          hasLength(1),
        );
        expect(s.state, const SleepTimerState.off());
      },
    );

    test('a change of the tracks table loads the keys again', () async {
      for (var i = 0; i < 6; i++) {
        s.albumOf(i, 'A');
      }
      await s.play();
      s.timer.startEndOfAlbum();
      await s.h.settle();
      expect(s.loads, hasLength(1));
      expect(s.h.engine.nexts.last, isNotNull);
      // A tag edit moves track 1 to another album.
      s.albumOf(1, 'B');
      s.tracksChanged.add(null);
      await s.h.settle();
      expect(s.loads, hasLength(2));
      expect(s.h.engine.nexts.last, isNull);
      // A second edit moves it back: the change must reach the timer again.
      s.albumOf(1, 'A');
      s.tracksChanged.add(null);
      await s.h.settle();
      expect(s.loads, hasLength(3));
      expect(s.h.engine.nexts.last, isNotNull);
    });

    test('shuffled, the boundary is read in play order', () async {
      twoAlbums();
      await s.play();
      await s.h.c.setShuffle(true);
      await s.h.settle();
      s.timer.startEndOfAlbum();
      await s.h.settle();
      String? albumAt(int i) {
        final key = s.albums[s.h.c.queueState.items[i].trackId];
        return key?.titleKey;
      }

      final q = s.h.c.queueState;
      final cur = q.current!;
      var stopAt = cur;
      while (stopAt < q.items.length - 1 &&
          albumAt(stopAt) != null &&
          albumAt(stopAt) == albumAt(stopAt + 1)) {
        stopAt++;
      }
      for (var i = cur; i < stopAt; i++) {
        await s.advance();
        await s.h.settle();
      }
      expect(s.state.mode, SleepTimerMode.endOfAlbum);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
    });

    test('the container going away drops the listeners and requests', () async {
      twoAlbums();
      s.loadGate = Completer<void>();
      final errors = <Object>[];
      await runZonedGuarded(() async {
        await s.play();
        s.timer.startEndOfAlbum();
        await s.h.settle();
        expect(s.h.engine.nexts.last, isNull);
        final before = s.h.engine.nexts.length;
        s.disposeContainer();
        s.loadGate!.complete();
        await s.h.settle();
        // The timer removed its stop on the way out: the next is handed.
        expect(handedSince(before), isTrue);
        s.tracksChanged.add(null);
        await s.h.settle();
        await s.end();
      }, (e, _) => errors.add(e));
      expect(errors, isEmpty);
      expect(s.tracksChanged.hasListener, isFalse);
    });
  });

  group('stale and cleared', () {
    test('a late stop of a replaced policy does not end the new one', () async {
      await s.play();
      final handed = s.h.engine.nexts.last!.token;
      final gate = Completer<void>();
      s.h.engine.pauseGate = gate.future;
      // The engine moves on just after the first install: the stop rests the
      // new entry, which waits on the engine's pause.
      s.timer.startEndOfTrack();
      s.h.engine.emit(EngineAdvanced(handed));
      await pumpEventQueue();
      s.timer.startEndOfTrack();
      gate.complete();
      s.h.engine.pauseGate = null;
      await s.h.settle();
      expect(s.state.mode, SleepTimerMode.endOfTrack);
      // The new policy is really installed, and cancel really removes it.
      final before = s.h.engine.nexts.length;
      await s.h.c.sleepPolicyChanged();
      await s.h.settle();
      expect(handedSince(before), isFalse);
      s.timer.cancel();
      await s.h.settle();
      expect(s.state, const SleepTimerState.off());
      expect(handedSince(before), isTrue);
    });

    test('clearQueue turns an end-of mode off', () async {
      await s.play();
      s.timer.startEndOfTrack();
      await s.h.settle();
      await s.h.c.clearQueue();
      await s.h.settle();
      expect(s.state, const SleepTimerState.off());
      await s.h.play();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
      expect(s.state, const SleepTimerState.off());
    });
  });
}
