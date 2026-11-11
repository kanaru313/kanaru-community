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

  EngineToken handed() => h.engine.nexts.last!.token;
  int entryAt(int i) => h.c.queueState.items[i].entryId;
  Future<int> times() async => (await h.c.queueView.first).repeatTimes;
  Object? saved(String key) => h.settings.read(key);

  /// The engine starts the handed-over entry and reports it loaded.
  Future<void> advance() async {
    final t = handed();
    h.engine.emit(EngineAdvanced(t));
    h.engine.emit(EngineLoaded(t, const Duration(seconds: 10)));
    await h.settle();
  }

  /// The last entry of the pass ends with nothing handed over.
  Future<void> endLast() async {
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 10)));
    h.engine.emit(EngineEnded(h.loadedToken));
    await h.settle();
  }

  group('counted repeat', () {
    test('plays the entry N more times, then goes on', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(2);
      await h.settle();
      expect(await times(), 2);
      expect(saved('playback.repeat_count'), 2);
      expect(handed().entryId, entryAt(0), reason: 'the entry loops first');

      var last = handed();
      await advance();
      expect(await times(), 1);
      expect(h.c.queueState.current, 0);
      expect(handed().entryId, entryAt(0));
      expect(handed().handoff, greaterThan(last.handoff));

      last = handed();
      await advance();
      expect(await times(), 0);
      expect(saved('playback.repeat_count'), 0);
      expect(h.c.queueState.current, 0);
      expect(handed().entryId, entryAt(1), reason: 'the count is used up');
      expect(handed().handoff, greaterThan(last.handoff));

      await advance();
      expect(h.c.queueState.current, 1);
      expect(h.engine.loads, hasLength(1), reason: 'loops never reload');
    });

    test('keeps the repeat mode behind it: all wraps afterwards', () async {
      await h.c.setRepeat(RepeatMode.all);
      await h.play(start: 5);
      await h.settle();
      await h.c.setRepeatTimes(1);
      await h.settle();
      expect(h.c.queueState.repeat, RepeatMode.all);
      await advance();
      expect(await times(), 0);
      expect(handed().entryId, entryAt(0), reason: 'wraps to the first');
      await advance();
      expect(h.c.queueState.current, 0);
    });

    test('over repeat one, the base becomes off', () async {
      await h.c.setRepeat(RepeatMode.one);
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(1);
      await h.settle();
      expect(h.c.queueState.repeat, RepeatMode.off);
      expect(saved('playback.repeat'), 'off');
      await advance();
      expect(handed().entryId, entryAt(1), reason: 'one more play, then next');
    });

    test('stepping, the bounds and 0', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(5);
      expect(await times(), 5);
      await h.c.setRepeatTimes(6);
      expect(await times(), 6);
      await h.c.setRepeatTimes(500);
      expect(await times(), maxRepeatTimes);
      await h.c.setRepeatTimes(-3);
      expect(await times(), 0);
      expect(saved('playback.repeat_count'), 0);
      await h.settle();
      expect(handed().entryId, entryAt(1), reason: 'back to the next entry');
    });

    test('arming it hands the entry again in place of the next', () async {
      await h.play();
      await h.settle();
      expect(handed().entryId, entryAt(1));
      await h.c.setRepeatTimes(3);
      await h.settle();
      expect(handed().entryId, entryAt(0));
    });

    test('any change of the current entry ends it', () async {
      Future<void> arm({int start = 2}) async {
        await h.play(start: start);
        await h.settle();
        await h.c.setRepeatTimes(4);
        expect(await times(), 4);
      }

      await arm();
      await h.c.next();
      expect(await times(), 0, reason: 'next');

      await arm();
      await h.c.previous();
      expect(await times(), 0, reason: 'previous');

      await arm();
      await h.c.playEntry(entryAt(4));
      expect(await times(), 0, reason: 'a picked entry');

      await arm();
      await h.c.remove({entryAt(2)});
      expect(await times(), 0, reason: 'the entry was removed');

      await arm();
      await h.play(start: 1);
      expect(await times(), 0, reason: 'a new queue');

      await arm();
      await h.c.stop();
      expect(await times(), 0, reason: 'stop');
      expect(saved('playback.repeat_count'), 0);
    });

    test('pause, seek, shuffle and queue edits keep it', () async {
      await h.play(start: 1);
      await h.settle();
      await h.c.setRepeatTimes(3);
      await h.c.pause();
      await h.c.seek(const Duration(seconds: 5));
      await h.c.setShuffle(true);
      await h.c.enqueue([h.tracks[0]]);
      await h.c.move(entryAt(4), 3);
      expect(await times(), 3);
    });

    test('setting a repeat mode ends it, even the mode already set', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(3);
      await h.c.setRepeat(RepeatMode.off);
      expect(await times(), 0);
      await h.c.setRepeatTimes(3);
      await h.c.setRepeat(RepeatMode.all);
      expect(await times(), 0);
      expect(h.c.queueState.repeat, RepeatMode.all);
    });

    test('cannot be armed while stopped or after the queue ended', () async {
      await h.c.setRepeatTimes(2);
      expect(await times(), 0, reason: 'empty queue');

      await h.play(start: 5);
      await h.settle();
      await endLast();
      expect((await h.c.queueView.first).stopped, isTrue);
      await h.c.setRepeatTimes(2);
      expect(await times(), 0, reason: 'the queue ran out');

      await h.c.stop();
      await h.c.setRepeatTimes(2);
      expect(await times(), 0, reason: 'stopped');
      expect((await h.c.queueView.first).stopped, isTrue);

      await h.c.play();
      await h.settle();
      expect((await h.c.queueView.first).stopped, isFalse);
      await h.c.setRepeatTimes(2);
      expect(await times(), 2);
    });

    test('the end of the queue ends it', () async {
      await h.play(start: 5);
      await h.settle();
      await h.c.setRepeatTimes(1);
      await h.settle();
      final loop = handed();
      await advance();
      expect(await times(), 0);
      h.engine.emit(EngineEnded(loop));
      await h.settle();
      expect(h.c.intent, PlayIntent.paused);
      expect(h.notices.whereType<QueueEnd>(), hasLength(1));
    });

    test('a count and the mode survive a restart', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 2);
      await h.settle();
      await h.c.setRepeatTimes(7);
      await h.restart();
      await h.settle();
      final v = await h.c.queueView.first;
      expect(v.repeat, RepeatMode.allShuffled);
      expect(v.repeatTimes, 7);
      expect(handed().entryId, entryAt(h.c.queueState.current!));
      await advance();
      expect(await times(), 6);
    });

    test('a bad or endless-one stored count is ignored', () async {
      await h.play();
      await h.settle();
      await h.settings.write('playback.repeat_count', 'many');
      await h.restart();
      await h.settle();
      expect(await times(), 0);

      await h.settings.write('playback.repeat_count', 12);
      await h.settings.write('playback.repeat', 'one');
      await h.restart();
      await h.settle();
      expect(await times(), 0, reason: 'a count never rides on endless one');

      await h.settings.write('playback.repeat', 'off');
      await h.settings.write('playback.repeat_count', 400);
      await h.restart();
      await h.settle();
      expect(await times(), maxRepeatTimes);
    });
  });

  group('repeat all, reshuffled every pass', () {
    test('the mode is saved with its own name', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeat(RepeatMode.allShuffled);
      expect(saved('playback.repeat'), 'allShuffled');
      await h.restart();
      await h.settle();
      expect(h.c.queueState.repeat, RepeatMode.allShuffled);
    });

    test('no next is handed on the last entry of a pass', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      expect(h.engine.nexts.last, isNull);
      await h.c.playEntry(entryAt(0));
      await h.settle();
      expect(handed().entryId, entryAt(1), reason: 'inside a pass it follows');
    });

    test('each pass is a new order of the whole queue, never starting with '
        'the entry that just played', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      final everyOrder = <String>{};
      for (var pass = 0; pass < 8; pass++) {
        final lastId = h.c.queueState.items.last.entryId;
        final loads = h.engine.loads.length;
        await endLast();
        final q = h.c.queueState;
        expect(q.shuffled, isTrue);
        expect(q.current, 0);
        expect([...h.order()]..sort(), [0, 1, 2, 3, 4, 5], reason: 'no loss');
        expect(q.items.first.entryId, isNot(lastId), reason: 'pass $pass');
        expect(h.engine.loads, hasLength(loads + 1));
        expect(h.engine.loads.last.token.entryId, q.items.first.entryId);
        expect(h.engine.lastLoadPlay, isTrue);
        everyOrder.add(h.order().join());
        // On to the last entry of the new pass.
        await h.c.playEntry(q.items.last.entryId);
        await h.settle();
      }
      expect(everyOrder.length, greaterThan(1));
      expect(saved('playback.shuffle'), true);
    });

    test('the new order is stored: a restart keeps it', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      await endLast();
      final order = h.order();
      await h.restart();
      await h.settle();
      expect(h.order(), order);
      expect(h.c.queueState.shuffled, isTrue);
    });

    test('shuffle off still gives the order the user built', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      await endLast();
      await h.c.setShuffle(false);
      expect(h.order(), [0, 1, 2, 3, 4, 5]);
      expect(h.c.queueState.repeat, RepeatMode.allShuffled);
    });

    test('Next on the last entry starts a new pass', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      final lastId = entryAt(5);
      await h.c.next();
      await h.settle();
      expect(h.c.queueState.current, 0);
      expect(h.c.queueState.shuffled, isTrue);
      expect(h.c.queueState.items.first.entryId, isNot(lastId));
      expect(
        h.engine.loads.last.token.entryId,
        h.c.queueState.items.first.entryId,
      );
    });

    test('Next inside a pass does not reshuffle', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play();
      await h.settle();
      await h.c.next();
      expect(h.order(), [0, 1, 2, 3, 4, 5]);
      expect(h.c.queueState.shuffled, isFalse);
    });

    test('an advance to a replaced next at the end of a pass starts the next '
        'pass', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 4);
      await h.settle();
      final stale = handed();
      await h.c.playEntry(entryAt(5));
      await h.settle();
      h.engine.emit(EngineAdvanced(stale));
      await h.settle();
      expect(h.c.queueState.shuffled, isFalse, reason: 'stale: no change');
    });

    test('a one-entry queue plays the entry again', () async {
      final one = await Harness.create(tracks: 1);
      addTearDown(one.close);
      await one.c.setRepeat(RepeatMode.allShuffled);
      await one.play();
      await one.settle();
      one.engine.emit(
        EngineLoaded(one.loadedToken, const Duration(seconds: 9)),
      );
      one.engine.emit(EngineEnded(one.loadedToken));
      await one.settle();
      expect(one.engine.loads, hasLength(2));
      expect(one.engine.lastLoadPlay, isTrue);
      expect(one.c.intent, PlayIntent.playing);
    });

    test('with a count, the last entry loops before the new pass', () async {
      await h.c.setRepeat(RepeatMode.allShuffled);
      await h.play(start: 5);
      await h.settle();
      await h.c.setRepeatTimes(1);
      await h.settle();
      final loop = handed();
      expect(loop.entryId, entryAt(5), reason: 'loops, no new pass yet');
      final handOvers = h.engine.nexts.length;
      await advance();
      expect(h.c.queueState.current, 5);
      expect(h.engine.nexts, hasLength(handOvers), reason: 'count used up');
      h.engine.emit(EngineEnded(loop));
      await h.settle();
      expect(h.c.queueState.current, 0);
      expect(h.c.queueState.shuffled, isTrue, reason: 'the pass ended');
    });
  });

  group('manual Next and Previous keep the base mode', () {
    for (final (mode, nextAtLast) in [
      (RepeatMode.off, false),
      (RepeatMode.one, false),
      (RepeatMode.all, true),
    ]) {
      test(
        '$mode: Next on the last entry ${nextAtLast ? 'wraps' : 'stops'}',
        () async {
          await h.c.setRepeat(mode);
          await h.play(start: 5);
          await h.settle();
          await h.c.next();
          await h.settle();
          expect(h.c.queueState.current, nextAtLast ? 0 : 5);
          expect(h.c.queueState.repeat, mode);
        },
      );
    }

    test('repeat one: Next goes to the next entry', () async {
      await h.c.setRepeat(RepeatMode.one);
      await h.play(start: 1);
      await h.settle();
      await h.c.next();
      expect(h.c.queueState.current, 2);
      await h.c.previous();
      expect(h.c.queueState.current, 1);
    });
  });

  group('repeat with an empty queue', () {
    test(
      'setting a repeat mode on an empty queue saves it without touching the '
      'engine and applies to the next queue opened',
      () async {
        await h.settle();
        expect(h.c.queueState.items, isEmpty);
        expect((await h.c.queueView.first).stopped, isTrue);

        for (final mode in [
          RepeatMode.one,
          RepeatMode.all,
          RepeatMode.allShuffled,
          RepeatMode.off,
          RepeatMode.one,
        ]) {
          await h.c.setRepeat(mode);
          await h.settle();
          final view = await h.c.queueView.first;
          expect(view.repeat, mode);
          expect(view.repeatTimes, 0);
          expect(view.stopped, isTrue);
        }
        expect(saved('playback.repeat'), 'one');
        expect(h.engineCreations, 0);

        await h.play();
        await h.settle();
        expect(h.c.queueState.repeat, RepeatMode.one);
        expect(handed().entryId, entryAt(0), reason: 'repeat one is active');
      },
    );

    test(
      'setRepeatTimes on an empty queue is a no-op and keeps repeat one',
      () async {
        await h.settle();
        await h.c.setRepeat(RepeatMode.one);
        await h.c.setRepeatTimes(4);
        await h.settle();
        expect(await times(), 0);
        expect(h.c.queueState.repeat, RepeatMode.one);
        expect(saved('playback.repeat'), 'one');
        expect(h.engineCreations, 0);
      },
    );

    test(
      'next and previous on an empty queue are safe in every repeat mode',
      () async {
        await h.settle();
        for (final mode in RepeatMode.values) {
          await h.c.setRepeat(mode);
          await h.c.next();
          await h.c.previous();
          await h.settle();
          expect(h.c.queueState.items, isEmpty);
          expect(h.notices, isEmpty);
          expect(h.engineCreations, 0);
        }
      },
    );

    test(
      'removing the only entry drops a counted repeat, keeps the base mode '
      'and marks the view stopped',
      () async {
        final one = await Harness.create(tracks: 1);
        addTearDown(one.close);
        await one.c.setRepeat(RepeatMode.all);
        await one.play();
        await one.settle();
        await one.c.setRepeatTimes(3);
        await one.settle();
        expect((await one.c.queueView.first).repeatTimes, 3);

        final token = await one.c.remove({
          one.c.queueState.items.single.entryId,
        });
        await one.settle();
        final emptied = await one.c.queueView.first;
        expect(emptied.length, 0);
        expect(emptied.repeat, RepeatMode.all);
        expect(emptied.repeatTimes, 0);
        expect(emptied.stopped, isTrue);
        expect(one.settings.read('playback.repeat_count'), 0);

        await one.c.undo(token!);
        await one.settle();
        final restored = await one.c.queueView.first;
        expect(restored.length, 1);
        expect(restored.repeat, RepeatMode.all);
        expect(restored.repeatTimes, 0);
      },
    );

    test(
      'restoring an empty queue clears a leftover repeat count in settings',
      () async {
        final empty = await Harness.create(
          prepare: (h) async {
            await h.settings.write('playback.repeat', 'allShuffled');
            await h.settings.write('playback.repeat_count', 5);
          },
        );
        addTearDown(empty.close);
        await empty.settle();
        final view = await empty.c.queueView.first;
        expect(view.repeat, RepeatMode.allShuffled);
        expect(view.repeatTimes, 0);
        expect(view.stopped, isTrue);
        expect(empty.settings.read('playback.repeat_count'), 0);
      },
    );
  });
}
