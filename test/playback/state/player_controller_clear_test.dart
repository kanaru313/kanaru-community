import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/domain/cleared_queue.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/session_restore.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;
  late List<ClearedQueue> cleared;

  setUp(() async {
    h = await Harness.create();
    cleared = [];
    h.c.queueCleared.listen(cleared.add);
  });
  tearDown(() => h.close());

  Future<void> playAndClear({int start = 1}) async {
    await h.play(start: start);
    await h.settle();
    await h.c.clearQueue();
    await h.settle();
  }

  test('clears the queue, stops, keeps shuffle and repeat', () async {
    await h.c.setRepeat(RepeatMode.all);
    await h.play(start: 1, shuffle: true);
    await h.settle();
    await h.c.clearQueue();
    await h.settle();

    expect((await h.c.queueView.first).items, isEmpty);
    expect((await h.c.nowPlaying.first).trackId, isNull);
    expect(h.c.intent, PlayIntent.stopped);
    expect(h.c.context, isNull);
    expect(h.c.queueState.shuffled, isTrue);
    expect(h.c.queueState.repeat, RepeatMode.all);
    expect(h.engine.commands.last, 'stop');
  });

  test('the saved session is emptied', () async {
    await playAndClear();
    expect(h.settings.read('playback.queue.current_entry'), isNull);
    expect(h.settings.read('playback.position_ms'), 0);
    expect(h.settings.read('playback.context'), isNull);
    expect(
      h.settings.read('playback.queue.play_next_run'),
      anyOf(isNull, isEmpty),
    );
  });

  test('a restart finds no session', () async {
    await playAndClear();
    expect(
      await loadSession(repo: QueueRepository(h.db), settings: h.settings),
      isNull,
    );
    await h.restart();
    await h.settle();
    expect(h.c.queueState.items, isEmpty);
    expect(h.c.queueState.current, isNull);
  });

  test('the exit flush does not write the old session back', () async {
    await h.play(start: 2);
    await h.settle();
    h.engine.tickPosition(const Duration(seconds: 7));
    await h.settle();
    await h.c.clearQueue();
    await h.settle();
    await h.c.flushPlayback();
    expect(h.settings.read('playback.queue.current_entry'), isNull);
    expect(h.settings.read('playback.position_ms'), 0);
  });

  test('a position tick after the clear is not saved', () async {
    await h.play();
    await h.settle();
    await h.c.clearQueue();
    await h.settle();
    h.engine.tickPosition(const Duration(seconds: 40));
    await h.settle();
    expect(h.settings.read('playback.position_ms'), 0);
  });

  test('queueCleared fires once with the tracks in play order', () async {
    await h.play(start: 2, shuffle: true);
    await h.settle();
    final order = [for (final i in h.c.queueState.items) i.trackId];
    await h.c.clearQueue();
    await h.settle();
    expect(cleared, hasLength(1));
    expect(cleared.single.tracks, order);
    expect(cleared.single.context, ctx);
  });

  test('an empty queue does nothing and emits nothing', () async {
    await h.c.clearQueue();
    await h.settle();
    expect(cleared, isEmpty);
    expect(h.notices, isEmpty);
  });

  test('a database error keeps the queue and emits nothing', () async {
    await h.play(start: 1);
    await h.settle();
    await h.db.customStatement(
      'CREATE TRIGGER no_delete BEFORE DELETE ON queue_entries '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    await expectLater(h.c.clearQueue(), throwsA(anything));
    await h.settle();
    expect(h.c.queueState.items, hasLength(6));
    expect(h.c.queueState.current, 1);
    expect(h.c.intent, PlayIntent.playing);
    expect(cleared, isEmpty);
  });

  test('playing again after a clear works and is saved', () async {
    await playAndClear();
    await h.play(start: 3);
    await h.settle();
    expect(h.c.queueState.current, 3);
    expect(h.c.intent, PlayIntent.playing);
    expect(
      h.settings.read('playback.queue.current_entry'),
      h.c.queueState.currentItem!.entryId,
    );
  });

  test('a clear queued behind next() runs after it', () async {
    await h.play(start: 1);
    await h.settle();
    final next = h.c.next();
    final clear = h.c.clearQueue();
    await Future.wait([next, clear]);
    await h.settle();
    expect(h.c.queueState.items, isEmpty);
    expect(h.notices.whereType<QueueEnd>(), isEmpty);
    expect(cleared, hasLength(1));
  });
}
