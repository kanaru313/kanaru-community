import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/domain/sleep_stop_policy.dart';

import '../support/controller_harness.dart';

/// A policy with a settable answer and a count of natural ends.
class _Policy implements SleepStopPolicy {
  _Policy({this.stop = true});
  bool stop;
  int ended = 0;
  Object? error;

  /// When set, answers from the count of ends instead of [stop].
  int? stopWhenEndedIs;

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) {
    if (error != null) throw error!;
    return stopWhenEndedIs != null ? ended == stopWhenEndedIs : stop;
  }

  @override
  void trackEnded() => ended++;
}

void main() {
  late Harness h;
  late List<TrackEnd> ends;
  setUp(() async {
    h = await Harness.create();
    ends = [];
    h.c.trackEnds.listen(ends.add);
  });
  tearDown(() => h.close());

  EngineToken handed() => h.engine.nexts.last!.token;
  int entryAt(int i) => h.c.queueState.items[i].entryId;
  Future<int> times() async => (await h.c.queueView.first).repeatTimes;

  Future<void> loaded() async {
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 10)));
    await h.settle();
  }

  Future<void> ended() async {
    await loaded();
    h.engine.emit(EngineEnded(h.loadedToken));
    await h.settle();
  }

  Future<void> advance() async {
    final t = handed();
    h.engine.emit(EngineAdvanced(t));
    h.engine.emit(EngineLoaded(t, const Duration(seconds: 10)));
    await h.settle();
  }

  /// The engine moved on to an entry that is not the handed one.
  Future<void> advanceToOther(int index) async {
    h.engine.emit(
      EngineAdvanced(
        EngineToken(
          entryId: entryAt(index),
          generation: h.loadedToken.generation,
          handoff: 999,
        ),
      ),
    );
    await h.settle();
  }

  group('withholding the next', () {
    test('installed: no next is handed; removed: it is', () async {
      await h.play();
      await h.settle();
      expect(h.engine.nexts.last, isNotNull);
      final policy = _Policy();
      await h.c.setSleepStopPolicy(policy);
      await h.settle();
      expect(h.engine.nexts.last, isNull);
      await h.c.setSleepStopPolicy(null);
      await h.settle();
      expect(h.engine.nexts.last?.token.entryId, entryAt(1));
    });

    test('load of a new current carries no next while installed', () async {
      await h.c.setSleepStopPolicy(_Policy());
      await h.play();
      await h.settle();
      expect(h.engine.loads, hasLength(1));
      expect(h.engine.nexts.single, isNull);
    });

    test(
      'a queue edit or repeat change in one burst never hands one',
      () async {
        await h.play();
        await h.settle();
        final policy = _Policy();
        final before = h.engine.nexts.length;
        final tail = h.c.queueState.items.last.entryId;
        await Future.wait([
          h.c.setSleepStopPolicy(policy),
          h.c.remove({entryAt(1)}),
          h.c.move(tail, 1),
          h.c.playNext([h.tracks[5]]),
          h.c.enqueue([h.tracks[0]]),
          h.c.setRepeat(RepeatMode.all),
        ]);
        await h.settle();
        expect(
          h.engine.nexts.skip(before).where((n) => n != null),
          isEmpty,
          reason: 'the policy is asked with the queue as it is',
        );
      },
    );

    test('a throwing policy counts as stop', () async {
      await h.play();
      await h.settle();
      await h.c.setSleepStopPolicy(_Policy()..error = StateError('x'));
      await h.settle();
      expect(h.engine.nexts.last, isNull);
    });
  });

  group('stop at a natural end', () {
    test('loads the next paused at 0, one event, policy gone', () async {
      final policy = _Policy();
      await h.c.setSleepStopPolicy(policy);
      await h.play();
      await h.settle();
      final first = entryAt(0);
      await ended();
      expect(h.c.queueState.current, 1);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.engine.loads, hasLength(2));
      expect(h.engine.lastLoadPlay, isFalse);
      expect(h.engine.lastStart, Duration.zero);
      expect(ends, [
        TrackEnd(entryId: first, sleepStop: true, queueEnded: false),
      ]);
      expect(policy.ended, 0);
      // The policy is gone: the next natural end hands over again.
      await h.c.play();
      await h.settle();
      expect(h.engine.nexts.last?.token.entryId, entryAt(2));
    });

    test('repeat one rests at 0 of the same entry, no loop', () async {
      await h.c.setRepeat(RepeatMode.one);
      await h.c.setSleepStopPolicy(_Policy());
      await h.play();
      await h.settle();
      await ended();
      expect(h.c.queueState.current, 0);
      expect(h.engine.loads, hasLength(2));
      expect(h.engine.lastLoadPlay, isFalse);
      expect(h.engine.lastStart, Duration.zero);
      expect(h.c.intent, PlayIntent.paused);
      expect(ends.single.sleepStop, isTrue);
    });

    test('counted repeat ends with count 0 and setting 0', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(3);
      await h.c.setSleepStopPolicy(_Policy());
      await h.settle();
      await ended();
      expect(await times(), 0);
      expect(h.settings.read('playback.repeat_count'), 0);
      expect(h.c.intent, PlayIntent.paused);
    });

    test('last entry, repeat off: queue ends, paused, queueEnded', () async {
      await h.c.setSleepStopPolicy(_Policy());
      await h.play(start: 5);
      await h.settle();
      await ended();
      expect(h.notices.whereType<QueueEnd>(), hasLength(1));
      expect(h.c.intent, PlayIntent.paused);
      expect(ends.single.sleepStop, isTrue);
      expect(ends.single.queueEnded, isTrue);
    });

    test('last entry, repeat all: first entry, paused', () async {
      await h.c.setRepeat(RepeatMode.all);
      await h.c.setSleepStopPolicy(_Policy());
      await h.play(start: 5);
      await h.settle();
      await ended();
      expect(h.c.queueState.current, 0);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.engine.lastLoadPlay, isFalse);
      expect(ends.single.sleepStop, isTrue);
    });

    test(
      'last entry, reshuffled: new shuffled pass, paused at its first',
      () async {
        await h.c.setRepeat(RepeatMode.allShuffled);
        await h.c.setSleepStopPolicy(_Policy());
        await h.play(start: 5);
        await h.settle();
        await ended();
        expect(h.c.queueState.current, 0);
        expect(h.c.queueState.shuffled, isTrue);
        expect(h.settings.read('playback.shuffle'), isTrue);
        expect(h.c.intent, PlayIntent.paused);
        expect(h.engine.lastLoadPlay, isFalse);
        expect(ends.single.sleepStop, isTrue);
      },
    );
  });

  group('stop in the advance race', () {
    test('the handed next became current: pause and seek to 0', () async {
      await h.play();
      await h.settle();
      final next = handed();
      final first = entryAt(0);
      await h.c.setSleepStopPolicy(_Policy());
      // The engine moved on before the reconcile withheld the next.
      h.engine.emit(EngineAdvanced(next));
      await h.settle();
      expect(h.c.queueState.currentItem!.entryId, next.entryId);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.engine.commands, containsAllInOrder(['pause', 'seek:0']));
      expect(ends, [
        TrackEnd(entryId: first, sleepStop: true, queueEnded: false),
      ]);
    });

    test('the same entry looping: count 0, not 2, pause and seek 0', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(3);
      await h.settle();
      final loop = handed();
      expect(loop.entryId, entryAt(0));
      // Installed in the same burst the engine's advance already sits in.
      final policy = h.c.setSleepStopPolicy(_Policy());
      h.engine.emit(EngineAdvanced(loop));
      await policy;
      await h.settle();
      expect(await times(), 0);
      expect(h.settings.read('playback.repeat_count'), 0);
      expect(h.engine.commands, containsAllInOrder(['pause', 'seek:0']));
      expect(h.c.intent, PlayIntent.paused);
    });

    test(
      'a replaced next: the entry after the ended one loads paused',
      () async {
        await h.play();
        await h.settle();
        await h.c.setSleepStopPolicy(_Policy());
        await h.settle();
        final first = entryAt(0);
        await advanceToOther(3);
        expect(h.c.queueState.current, 1);
        expect(h.c.intent, PlayIntent.paused);
        expect(h.engine.lastLoadPlay, isFalse);
        expect(ends.single.entryId, first);
        expect(ends.single.sleepStop, isTrue);
      },
    );
  });

  group('track-end events without a stop', () {
    test('last entry, repeat off, no stop', () async {
      await h.play(start: 5);
      await h.settle();
      final last = entryAt(5);
      await ended();
      expect(ends, [
        TrackEnd(entryId: last, sleepStop: false, queueEnded: true),
      ]);
    });

    test('an advance with nothing after the ended entry', () async {
      await h.c.setRepeat(RepeatMode.off);
      await h.play(start: 5);
      await h.settle();
      final last = entryAt(5);
      // Engine reports an entry that cannot follow the last one.
      h.engine.emit(
        EngineAdvanced(
          EngineToken(
            entryId: entryAt(2),
            generation: h.loadedToken.generation,
            handoff: 999,
          ),
        ),
      );
      await h.settle();
      expect(ends.single.entryId, last);
      expect(ends.single.queueEnded, isTrue);
      expect(ends.single.sleepStop, isFalse);
    });

    test('accepted advance: one event, no stop', () async {
      await h.play();
      await h.settle();
      final first = entryAt(0);
      await advance();
      expect(ends, [
        TrackEnd(entryId: first, sleepStop: false, queueEnded: false),
      ]);
    });

    test('a counted loop is a natural end too', () async {
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(1);
      await h.settle();
      await advance();
      expect(ends.single.entryId, entryAt(0));
      expect(ends.single.sleepStop, isFalse);
    });

    test('trackEnded runs once per end, before the next is decided', () async {
      final policy = _Policy()..stopWhenEndedIs = 1;
      await h.c.setSleepStopPolicy(policy);
      await h.play();
      await h.settle();
      expect(
        h.engine.nexts.last,
        isNotNull,
        reason: 'two to go: next is handed',
      );
      final before = h.engine.nexts.length;
      await advance();
      expect(policy.ended, 1);
      expect(
        h.engine.nexts.skip(before).where((n) => n != null),
        isEmpty,
        reason: 'one left: withheld at once',
      );
      expect(ends.single.sleepStop, isFalse);
    });
  });

  group('no event', () {
    test('failures, next, previous, jump, seek', () async {
      final policy = _Policy(stop: false);
      await h.c.setSleepStopPolicy(policy);
      await h.play();
      await h.settle();
      await loaded();
      h.engine.emit(EngineFailed(h.loadedToken, 'boom'));
      await h.settle();
      await h.c.next();
      await h.settle();
      await h.c.previous();
      await h.settle();
      await h.c.playEntry(entryAt(3));
      await h.settle();
      await h.c.seek(const Duration(seconds: 2));
      await h.settle();
      expect(ends, isEmpty);
      expect(policy.ended, 0);
    });
  });

  group('policy lifetime', () {
    test('clearQueue removes the policy', () async {
      final policy = _Policy();
      await h.c.setSleepStopPolicy(policy);
      await h.play();
      await h.settle();
      await h.c.clearQueue();
      await h.play();
      await h.settle();
      expect(h.engine.nexts.last, isNotNull);
    });

    test('playTracks and stop keep it', () async {
      await h.c.setSleepStopPolicy(_Policy());
      await h.play();
      await h.settle();
      await h.c.stop();
      await h.play();
      await h.settle();
      expect(h.engine.nexts.last, isNull);
    });
  });

  group('dispose', () {
    test('closes the stream; later calls do nothing', () async {
      final done = Completer<void>();
      h.c.trackEnds.listen((_) {}, onDone: done.complete);
      await h.play();
      await h.settle();
      await h.c.dispose();
      await done.future.timeout(const Duration(seconds: 2));
      await h.c.setSleepStopPolicy(_Policy());
      await h.c.sleepPolicyChanged();
      expect(ends, isEmpty);
    });
  });
}
