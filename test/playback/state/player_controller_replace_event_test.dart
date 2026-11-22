import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/domain/replaced_queue.dart';

import '../support/controller_harness.dart';

const _album = PlayContext(PlayContextKind.album, ref: 'k', label: 'Album');

void main() {
  late Harness h;
  late List<ReplacedQueue> events;

  setUp(() async {
    h = await Harness.create();
    events = [];
    h.c.queueReplaced.listen(events.add);
  });
  tearDown(() => h.close());

  test('replacing a queue emits the old one and the new tracks', () async {
    await h.c.playTracks(
      h.tracks,
      startIndex: 2,
      shuffle: true,
      context: _album,
    );
    await h.settle();
    final order = [for (final i in h.c.queueState.items) i.trackId];
    final other = h.tracks.sublist(0, 3);
    await h.c.playTracks(other, context: ctx);
    await h.settle();

    expect(events, hasLength(1));
    final e = events.single;
    expect(e.tracks, order);
    expect(e.userOrder, h.tracks);
    expect(e.context, _album);
    expect(e.next, other);
    expect(e.isClear, isFalse);
  });

  test('the first play, with nothing before it, emits nothing', () async {
    await h.play();
    await h.settle();
    expect(events, isEmpty);
  });

  test('playNext and enqueue on an empty queue emit nothing', () async {
    await h.c.playNext(h.tracks.sublist(0, 2));
    await h.settle();
    await h.c.clearQueue();
    await h.settle();
    events.clear();
    await h.c.enqueue(h.tracks.sublist(0, 2));
    await h.settle();
    expect(events, isEmpty);
  });

  test('playNext and enqueue on a queue with tracks emit nothing', () async {
    await h.play();
    await h.settle();
    await h.c.playNext([h.tracks[3]]);
    await h.c.enqueue([h.tracks[4]]);
    await h.settle();
    expect(events, isEmpty);
  });

  test('clearQueue emits with no next', () async {
    await h.play();
    await h.settle();
    await h.c.clearQueue();
    await h.settle();
    expect(events.single.next, isNull);
    expect(events.single.isClear, isTrue);
  });

  test('a database error while replacing emits nothing', () async {
    await h.play();
    await h.settle();
    await h.db.customStatement(
      'CREATE TRIGGER no_delete BEFORE DELETE ON queue_entries '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    await expectLater(h.play(start: 1), throwsA(anything));
    await h.settle();
    expect(events, isEmpty);
    expect(h.c.queueState.items, hasLength(6));
  });

  test(
    'two replaces in a row emit in order, the second sees the first',
    () async {
      await h.play();
      await h.settle();
      final first = h.tracks.sublist(0, 3);
      final second = h.tracks.sublist(3);
      final a = h.c.playTracks(first, context: ctx);
      final b = h.c.playTracks(second, context: ctx);
      await Future.wait([a, b]);
      await h.settle();
      expect(events, hasLength(2));
      expect(events[0].next, first);
      expect(events[1].tracks, first);
      expect(events[1].next, second);
    },
  );

  test('restoring the saved session emits nothing', () async {
    await h.play(start: 2);
    await h.settle();
    events.clear();
    await h.restart();
    h.c.queueReplaced.listen(events.add);
    await h.settle();
    expect(h.c.queueState.items, hasLength(6));
    expect(events, isEmpty);
  });
}
