import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;
  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  EngineToken nextToken() => h.engine.nexts.where((n) => n != null).last!.token;
  int entryAt(int i) => h.c.queueState.items[i].entryId;

  test(
    'advancing makes the handed-over entry current and hands a new next',
    () async {
      await h.play();
      await h.settle();
      h.engine.emit(EngineAdvanced(nextToken()));
      await h.settle();
      expect(h.c.queueState.current, 1);
      expect(h.engine.loads, hasLength(1));
      expect(h.engine.nexts.last?.path, '/music/t2.mp3');
      expect(h.settings.read('playback.queue.current_entry'), entryAt(1));
    },
  );

  test('an advance to a removed next loads the entry after the finished one, never the finished one', () async {
    await h.play();
    await h.settle();
    final removed = h.engine.loads.length;
    final removal = h.c.remove({entryAt(1)});
    h.engine.emit(EngineAdvanced(nextToken()));
    await removal;
    await h.settle();
    expect(h.engine.loads, hasLength(removed + 1));
    expect(h.engine.loads.last.path, '/music/t2.mp3');
    expect(h.engine.lastStart, Duration.zero);
    expect(h.c.queueState.currentItem?.trackId, h.tracks[2]);
  });

  test(
    'the old advance arrives after the next was handed again (real ordering)',
    () async {
      await h.play();
      await h.settle();
      final old = nextToken();
      // Another entry now follows the current one, so a different next is
      // handed over before the old advance arrives.
      await h.c.move(entryAt(4), 1);
      await h.settle();
      expect(nextToken().entryId, isNot(old.entryId));
      h.engine.emit(EngineAdvanced(old));
      await h.settle();
      expect(
        h.engine.loads.where((l) => l.path == '/music/t0.mp3'),
        hasLength(1),
        reason: 'the finished entry is not loaded again',
      );
      expect(h.c.queueState.currentItem?.trackId, h.tracks[4]);
      expect(h.engine.loads.last.path, '/music/t4.mp3');
      expect(h.engine.lastStart, Duration.zero);
    },
  );

  test('shuffle toggled while an advance is in flight: current is the engine entry, then a new next', () async {
    await h.play();
    await h.settle();
    final handed = nextToken();
    final toggle = h.c.setShuffle(true);
    h.engine.emit(EngineAdvanced(handed));
    await toggle;
    await h.settle();
    expect(h.c.queueState.currentItem?.entryId, handed.entryId);
    expect(h.engine.loads, hasLength(1), reason: 'no reload');
    // The entry handed to the engine is the one after the current in the new order.
    final q = h.c.queueState;
    final following = q.current! + 1 < q.length
        ? q.items[q.current! + 1].entryId
        : null;
    if (following != null) {
      expect(h.engine.nexts.last?.token.entryId, following);
    } else {
      expect(h.engine.nexts, hasLength(1), reason: 'nothing left to hand over');
    }
  });

  test('repeat changed while an advance is in flight', () async {
    await h.play();
    await h.settle();
    final handed = nextToken();
    final change = h.c.setRepeat(RepeatMode.one);
    h.engine.emit(EngineAdvanced(handed));
    await change;
    await h.settle();
    expect(h.c.queueState.currentItem?.entryId, handed.entryId);
    expect(
      nextToken().entryId,
      handed.entryId,
      reason: 'repeat one hands the entry again',
    );
    expect(nextToken().handoff, greaterThan(handed.handoff));
  });

  test('repeat one over 3 loops gives 3 distinct tokens', () async {
    await h.c.setRepeat(RepeatMode.one);
    await h.play();
    await h.settle();
    final tokens = <EngineToken>{h.loadedToken};
    for (var i = 0; i < 3; i++) {
      final handed = nextToken();
      expect(handed.entryId, h.c.queueState.currentItem!.entryId);
      h.engine.emit(EngineAdvanced(handed));
      await h.settle();
      tokens.add(handed);
    }
    expect(tokens, hasLength(4));
    expect(h.c.queueState.current, 0);
    expect(h.engine.loads, hasLength(1));
  });

  test('repeat all wraps to the first entry', () async {
    await h.c.setRepeat(RepeatMode.all);
    await h.play(start: 5);
    await h.settle();
    expect(nextToken().entryId, entryAt(0));
    h.engine.emit(EngineAdvanced(nextToken()));
    await h.settle();
    expect(h.c.queueState.current, 0);
  });

  test('a stale generation is ignored', () async {
    await h.play();
    await h.settle();
    final stale = EngineToken(entryId: entryAt(1), generation: 99, handoff: 99);
    h.engine.emit(EngineAdvanced(stale));
    h.engine.emit(EngineFailed(stale, 'old'));
    await h.settle();
    expect(h.c.queueState.current, 0);
    expect(h.notices, isEmpty);
    expect(h.engine.loads, hasLength(1));
  });

  test('loaded reports the duration on the position stream', () async {
    await h.play();
    await h.settle();
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
    await h.settle();
    final p = await h.c.position.first;
    expect(p.duration, const Duration(seconds: 200));
    expect(p.entryId, entryAt(0));
  });

  test(
    'end of the last entry with repeat off pauses and keeps the entry',
    () async {
      await h.play(start: 5);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 10)));
      h.engine.emit(EngineEnded(h.loadedToken));
      await h.settle();
      expect(h.c.intent, PlayIntent.paused);
      expect(h.c.queueState.current, 5);
      final now = await h.c.nowPlaying.first;
      expect(now.hasTrack, isTrue);
      expect(now.playing, isFalse);
      expect(h.notices.whereType<QueueEnd>(), hasLength(1));
      await h.c.play();
      await h.settle();
      expect(
        h.engine.loads,
        hasLength(2),
        reason: 'play after the end starts over',
      );
      expect(h.engine.lastStart, Duration.zero);
    },
  );

  test('a missing entry is skipped with one notice for the run', () async {
    await h.markMissing(h.tracks[0]);
    await h.markMissing(h.tracks[1]);
    await h.play();
    await h.settle();
    expect(h.c.queueState.current, 2);
    final skipped = h.notices.whereType<TrackSkipped>().single;
    expect(skipped.count, 2);
    expect(h.engine.loads.single.path, '/music/t2.mp3');
  });

  test('a failed entry posts a notice and the queue moves on', () async {
    await h.play();
    await h.settle();
    h.engine.emit(EngineFailed(h.loadedToken, 'bad file'));
    await h.settle();
    expect(h.notices.whereType<TrackFailed>().single.title, 'T0');
    expect(h.c.queueState.current, 1);
    expect(h.engine.loads, hasLength(2));
  });

  test(
    'a position tick of the old file does not become the next start',
    () async {
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 95));
      await h.settle();
      final jump = h.c.next();
      h.engine.tickPosition(const Duration(seconds: 96)); // before the reload
      await jump;
      h.engine.tickPosition(const Duration(seconds: 97)); // during the reload
      await h.settle();
      expect(h.engine.loads.last.path, '/music/t1.mp3');
      expect(h.engine.lastStart, Duration.zero);
      // Ticks of the new file count once it reported that it opened.
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 100)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 2));
      await pumpEventQueue();
      expect((await h.c.position.first).position, const Duration(seconds: 2));
    },
  );

  test('all files failing stops after one failure per entry', () async {
    final small = await Harness.create(tracks: 3);
    addTearDown(small.close);
    await small.play();
    await small.settle();
    for (var i = 0; i < 3; i++) {
      small.engine.emit(EngineFailed(small.loadedToken, 'bad'));
      await small.settle();
    }
    expect(small.c.intent, PlayIntent.stopped);
    expect(small.notices.whereType<TrackFailed>(), hasLength(3));
    final loads = small.engine.loads.length;
    await small.settle();
    expect(small.engine.loads, hasLength(loads), reason: 'no endless loop');
    // A user action resets the counter.
    await small.c.play();
    await small.settle();
    expect(small.c.intent, PlayIntent.playing);
  });

  test('a failed next continues with the next playable entry', () async {
    await h.play();
    await h.settle();
    final failed = nextToken();
    h.engine.emit(EngineFailed(failed, 'bad'));
    await h.settle();
    expect(h.notices.whereType<TrackFailed>(), hasLength(1));
    expect(h.c.queueState.currentItem?.trackId, h.tracks[2]);
    expect(h.engine.loads, hasLength(2));
    expect(h.engine.loads.last.path, '/music/t2.mp3');
    expect(h.engine.lastLoadPlay, isTrue);
    expect(h.c.intent, PlayIntent.playing);
  });

  test(
    'a next that cannot play is passed over; the skip is announced on arrival',
    () async {
      await h.markMissing(h.tracks[1]);
      await h.play();
      await h.settle();
      expect(h.engine.nexts.single?.path, '/music/t2.mp3');
      expect(h.notices.whereType<TrackSkipped>(), isEmpty, reason: 'not yet');
      h.engine.emit(EngineAdvanced(nextToken()));
      await h.settle();
      expect(h.c.queueState.current, 2);
      final skipped = h.notices.whereType<TrackSkipped>().single;
      expect(skipped.title, 'T1');
      expect(skipped.count, 1);
    },
  );

  test('after the end, a song added later waits paused and the finished one is not replayed', () async {
    final small = await Harness.create(tracks: 3);
    addTearDown(small.close);
    await small.play(start: 2);
    await small.settle();
    small.engine.emit(
      EngineLoaded(small.loadedToken, const Duration(seconds: 10)),
    );
    small.engine.emit(EngineEnded(small.loadedToken));
    await small.settle();
    expect(small.engine.commands.last, 'pause');
    final loadsBefore = small.engine.loads.length;
    await small.c.enqueue([small.tracks[0]]);
    await small.settle();
    expect(small.engine.loads, hasLength(loadsBefore));
    expect(small.engine.commands.last, 'setNext');
    expect(small.c.intent, PlayIntent.paused);
    small.engine.emit(EngineAdvanced(small.engine.nexts.last!.token));
    await small.settle();
    expect(small.c.queueState.current, 3);
    expect(small.engine.commands.last, isNot('play'));
    // Ticks flow again after the advance.
    small.engine.emit(
      EngineLoaded(small.engine.nexts.last!.token, const Duration(seconds: 5)),
    );
    await small.settle();
    // The position follows ticks while playing, not while paused.
    small.engine.tickPosition(const Duration(seconds: 3));
    await pumpEventQueue();
    expect((await small.c.position.first).position, Duration.zero);
    await small.c.play();
    await small.settle();
    small.engine.tickPosition(const Duration(seconds: 1));
    await pumpEventQueue();
    expect((await small.c.position.first).position, const Duration(seconds: 1));
  });

  test(
    'skipping many missing entries costs a few lookups, not one per entry',
    () async {
      late CountingResolver counter;
      final big = await Harness.create(
        tracks: 40,
        wrapResolver: (r) => counter = CountingResolver(r),
      );
      addTearDown(big.close);
      for (var i = 0; i < 35; i++) {
        await big.markMissing(big.tracks[i]);
      }
      await big.play();
      await big.settle();
      expect(big.c.queueState.current, 35);
      expect(counter.calls, lessThanOrEqualTo(4));
      expect(big.notices.whereType<TrackSkipped>().single.count, 35);
    },
  );

  test('an unexpected advance when the last entry plays ends the queue paused at its end', () async {
    await h.play(start: 5);
    await h.settle();
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 10)));
    await h.settle();
    final stray = EngineToken(
      entryId: entryAt(0),
      generation: h.loadedToken.generation,
      handoff: 99,
    );
    h.engine.emit(EngineAdvanced(stray));
    await h.settle();
    expect(h.c.intent, PlayIntent.paused);
    expect(h.engine.lastLoadPlay, isFalse);
    expect(h.engine.commands, isNot(contains('play')));
    expect(h.engine.lastStart, const Duration(seconds: 10));
    expect(h.c.queueState.current, 5);
    expect(h.notices.whereType<QueueEnd>(), hasLength(1));
  });

  test(
    'more than 50 unplayable entries after the current one do not stall',
    () async {
      final big = await Harness.create(tracks: 60);
      addTearDown(big.close);
      for (var i = 1; i <= 55; i++) {
        await big.markMissing(big.tracks[i]);
      }
      await big.play();
      await big.settle();
      expect(
        big.engine.nexts.single,
        isNull,
        reason: 'out of reach of the look-ahead',
      );
      big.engine.emit(EngineEnded(big.loadedToken));
      await big.settle();
      expect(big.c.queueState.current, 56);
      expect(big.engine.loads.last.path, '/music/t56.mp3');
      expect(big.c.intent, PlayIntent.playing);
    },
  );
}
