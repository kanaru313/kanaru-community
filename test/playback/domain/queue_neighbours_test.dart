import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/queue_neighbours.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';

import '../support/controller_harness.dart';
import '../support/queue_fixtures.dart';

/// 'none' | 'unknown' | the entry index of a known neighbour.
Object _show(Neighbour n, List<int> entryIds) => switch (n) {
  NoNeighbour() => 'none',
  UnknownNeighbour() => 'unknown',
  KnownNeighbour(:final item) => entryIds.indexOf(item.entryId),
};

void main() {
  group('table', () {
    // repeat, queue size, current, previous, next
    final cases = <(RepeatMode, int, int, Object, Object)>[
      (RepeatMode.off, 3, 0, 'none', 1),
      (RepeatMode.off, 3, 1, 0, 2),
      (RepeatMode.off, 3, 2, 1, 'none'),
      (RepeatMode.one, 3, 0, 'none', 1),
      (RepeatMode.one, 3, 1, 0, 2),
      (RepeatMode.one, 3, 2, 1, 'none'),
      (RepeatMode.all, 3, 0, 2, 1),
      (RepeatMode.all, 3, 1, 0, 2),
      (RepeatMode.all, 3, 2, 1, 0),
      (RepeatMode.allShuffled, 3, 0, 'none', 1),
      (RepeatMode.allShuffled, 3, 1, 0, 2),
      (RepeatMode.allShuffled, 3, 2, 1, 'unknown'),
      for (final r in RepeatMode.values) (r, 1, 0, 'none', 'none'),
    ];
    for (final (repeat, n, cur, prev, next) in cases) {
      test('$repeat, $n entries, at $cur', () {
        final s = makeQueue(n, current: cur, repeat: repeat);
        final ids = [for (final i in s.items) i.entryId];
        final nb = neighboursOf(s.items, cur, repeat);
        expect(_show(nb.previous, ids), prev, reason: 'previous');
        expect(_show(nb.next, ids), next, reason: 'next');
      });
    }

    test('an empty queue and nothing current have no neighbours', () {
      for (final repeat in RepeatMode.values) {
        final s = makeQueue(3, repeat: repeat);
        for (final nb in [
          neighboursOf(const [], null, repeat),
          neighboursOf(const [], 0, repeat),
          neighboursOf(s.items, null, repeat),
          neighboursOf(s.items, 7, repeat),
        ]) {
          expect(nb.previous, isA<NoNeighbour>());
          expect(nb.next, isA<NoNeighbour>());
        }
      }
    });
  });

  group('agrees with the controller', () {
    for (final repeat in RepeatMode.values) {
      for (final size in [1, 2, 3]) {
        for (var cur = 0; cur < size; cur++) {
          test('$repeat, $size entries, at $cur: Next', () async {
            final h = await Harness.create(tracks: size);
            addTearDown(h.close);
            await h.c.setRepeat(repeat);
            await h.play(start: cur);
            await h.settle();
            final entryIds = [for (final i in h.c.queueState.items) i.entryId];
            final before = h.c.queueState.currentItem!.entryId;
            final nb = neighboursOf(
              h.c.queueState.items,
              h.c.queueState.current,
              repeat,
            );
            await h.c.next();
            await h.settle();
            final after = h.c.queueState.currentItem!.entryId;
            switch (nb.next) {
              case KnownNeighbour(:final item):
                expect(after, item.entryId);
              case NoNeighbour():
                expect(after, before, reason: 'Next stays on the entry');
              case UnknownNeighbour():
                // A new pass: the first entry of a new order.
                expect(h.c.queueState.current, 0);
            }
            expect(entryIds, isNotEmpty);
          });

          test('$repeat, $size entries, at $cur: Previous', () async {
            final h = await Harness.create(tracks: size);
            addTearDown(h.close);
            await h.c.setRepeat(repeat);
            await h.play(start: cur);
            await h.settle();
            final before = h.c.queueState.currentItem!.entryId;
            final nb = neighboursOf(
              h.c.queueState.items,
              h.c.queueState.current,
              repeat,
            );
            await h.c.previous();
            await h.settle();
            final after = h.c.queueState.currentItem!.entryId;
            switch (nb.previous) {
              case KnownNeighbour(:final item):
                expect(after, item.entryId);
              case NoNeighbour():
                expect(after, before, reason: 'Previous restarts the entry');
              case UnknownNeighbour():
                fail('Previous is never unknown');
            }
          });
        }
      }
    }
  });
}
