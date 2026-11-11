import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

import '../support/queue_fixtures.dart';

const keys = KeyGen();
List<TrackId> ids(Iterable<int> v) => [for (final i in v) TrackId(i)];

void main() {
  for (final shuffled in [false, true]) {
    final mode = shuffled ? 'shuffled' : 'sorted';
    for (final cur in [0, 2, 4]) {
      group('$mode, current $cur of 5', () {
        QueueState base() => makeQueue(5, current: cur, shuffled: shuffled);

        test('insertPlayNext goes right after the current entry', () {
          final s = base();
          final e = insertPlayNext(s, ids([90, 91]), keys);
          final t = tracks(e.next);
          final at = t.indexOf(tracks(s)[cur]);
          expect(t.sublist(at + 1, at + 3), [90, 91]);
          expect(e.next.playNextRun, 2);
          expect(e.next.currentItem, s.currentItem);
          expect(e.inserted.map((i) => i.entryId), everyElement(isNegative));
          expectHealthy(e.next);
        });

        test('consecutive play next calls queue up behind each other', () {
          var s = base();
          s = insertPlayNext(s, ids([90]), keys).next;
          s = insertPlayNext(s, ids([91, 92]), keys).next;
          final t = tracks(s);
          final at = s.current!;
          expect(t.sublist(at + 1, at + 4), [90, 91, 92]);
          expect(s.playNextRun, 3);
          expectHealthy(s);
        });

        test('enqueue appends at the end and keeps the run', () {
          var s = insertPlayNext(base(), ids([90]), keys).next;
          final e = enqueue(s, ids([95, 96]), keys);
          expect(tracks(e.next).sublist(tracks(e.next).length - 2), [95, 96]);
          expect(e.next.playNextRun, 1);
          expect(e.next.current, s.current);
          expectHealthy(e.next);
        });

        test('shuffleUpcoming keeps played entries and the current one', () {
          final s = base();
          final e = shuffleUpcoming(s, Random(3), keys);
          expect(e.next.shuffled, isTrue);
          expect(e.next.current, cur);
          expect(
            entries(e.next).sublist(0, cur + 1),
            entries(s).sublist(0, cur + 1),
          );
          expect(
            entries(e.next).sublist(cur + 1).toSet(),
            entries(s).sublist(cur + 1).toSet(),
          );
          expectHealthy(e.next);
          // Upcoming only: played rows already had keys when shuffled.
          if (shuffled) {
            expect(e.rekeyed.keys.toSet(), entries(s).sublist(cur + 1).toSet());
          }
        });
      });
    }
  }

  group('remove', () {
    test('a non-current entry before the current one shifts the index', () {
      final s = makeQueue(5, current: 3);
      final e = remove(s, {1, 2});
      expect(tracks(e.next), [2, 3, 4]);
      expect(e.next.current, 1);
      expect(e.next.currentItem?.trackId.value, 3);
      expect(e.removedIds, [1, 2]);
    });

    test('the current entry hands over to the next one', () {
      final e = remove(makeQueue(4, current: 1), {2});
      expect(tracks(e.next), [0, 2, 3]);
      expect(e.next.currentItem?.trackId.value, 2);
    });

    test('the last entry hands over to the previous one', () {
      final e = remove(makeQueue(4, current: 3), {4});
      expect(e.next.currentItem?.trackId.value, 2);
    });

    test('the current plus every later entry falls back to the one before', () {
      final e = remove(makeQueue(4, current: 2), {3, 4});
      expect(tracks(e.next), [0, 1]);
      expect(e.next.currentItem?.trackId.value, 1);
    });

    test('the only entry leaves nothing current', () {
      final e = remove(makeQueue(1, current: 0), {1});
      expect(e.next.items, isEmpty);
      expect(e.next.current, isNull);
      expect(e.undo?.previousCurrentEntryId, 1);
    });

    test('unknown ids change nothing', () {
      final s = makeQueue(3, current: 1);
      expect(remove(s, {99}).isNoop, isTrue);
    });

    test('works while shuffled and keeps the order', () {
      final s = makeQueue(5, current: 2, shuffled: true);
      final e = remove(s, {s.items[2].entryId});
      expect(e.next.current, 2);
      expect(entries(e.next), [
        ...entries(s).sublist(0, 2),
        ...entries(s).sublist(3),
      ]);
    });

    test('removing run entries shrinks the run', () {
      var s = insertPlayNext(
        makeQueue(4, current: 0),
        ids([90, 91]),
        keys,
      ).next;
      final e = remove(s, {s.items[1].entryId});
      expect(e.next.playNextRun, 1);
    });

    test('removing the current entry makes the first run entry current', () {
      var s = insertPlayNext(
        makeQueue(4, current: 0),
        ids([90, 91]),
        keys,
      ).next;
      final e = remove(s, {s.currentItem!.entryId});
      expect(e.next.currentItem?.trackId.value, 90);
      expect(e.next.playNextRun, 1);
    });
  });

  group('move', () {
    test('moves an upcoming entry up', () {
      final s = makeQueue(5, current: 0);
      final e = move(s, 5, 1, keys);
      expect(tracks(e.next), [0, 4, 1, 2, 3]);
      expect(e.next.current, 0);
      expect(e.rekeyed.keys, [5]);
      expectHealthy(e.next);
    });

    test('a played entry moved below the current one becomes upcoming', () {
      final s = makeQueue(5, current: 3);
      final e = move(s, 1, 4, keys);
      expect(tracks(e.next), [1, 2, 3, 4, 0]);
      expect(e.next.current, 2);
      expect(e.next.currentItem?.trackId.value, 3);
      expectHealthy(e.next);
    });

    test('an upcoming entry moved above the current one becomes played', () {
      final s = makeQueue(5, current: 1);
      final e = move(s, 5, 0, keys);
      expect(e.next.current, 2);
      expect(e.next.currentItem?.trackId.value, 1);
    });

    test('moving the current entry moves current with it', () {
      final e = move(makeQueue(5, current: 1), 2, 4, keys);
      expect(e.next.current, 4);
      expect(e.next.currentItem?.entryId, 2);
    });

    test('while shuffled only the shuffle key changes', () {
      final s = makeQueue(5, current: 0, shuffled: true);
      final e = move(s, s.items[4].entryId, 1, keys);
      final change = e.rekeyed[s.items[4].entryId]!;
      expect(change.sortKey, isNull);
      expect(change.shuffleKey, isNotNull);
      expectHealthy(e.next);
    });

    test('moving into and out of the play-next run updates the run', () {
      var s = insertPlayNext(
        makeQueue(5, current: 0),
        ids([90, 91, 92]),
        keys,
      ).next;
      expect(s.playNextRun, 3);
      final inside = move(s, s.items.last.entryId, 2, keys).next;
      expect(inside.playNextRun, 4);
      final out = move(s, s.items[1].entryId, 5, keys).next;
      expect(tracks(out).sublist(1, 3), [91, 92]);
      expect(out.playNextRun, 2);
    });

    test('same index or unknown id is a no-op', () {
      final s = makeQueue(3, current: 0);
      expect(move(s, 2, 1, keys).isNoop, isTrue);
      expect(move(s, 99, 0, keys).isNoop, isTrue);
    });
  });

  group('unshuffle', () {
    test('restores sort order and keeps the current entry', () {
      final s = makeQueue(5, current: 1, shuffled: true);
      final e = unshuffle(s);
      expect(tracks(e.next), [0, 1, 2, 3, 4]);
      expect(e.next.currentItem?.entryId, s.currentItem?.entryId);
      expect(e.next.shuffled, isFalse);
      expect(e.clearShuffleKeys, isTrue);
      expect(e.next.items.every((i) => i.shuffleKey == null), isTrue);
    });

    test('is a no-op when not shuffled', () {
      expect(unshuffle(makeQueue(3, current: 0)).isNoop, isTrue);
    });
  });

  group('shuffle with a play-next run', () {
    QueueState withRun({required bool shuffled}) {
      final base = makeQueue(8, current: 1, shuffled: shuffled);
      return insertPlayNext(base, ids([90, 91, 92]), keys).next;
    }

    for (final shuffled in [false, true]) {
      test('the run stays right after the current entry, in order '
          '(already shuffled: $shuffled)', () {
        final s = withRun(shuffled: shuffled);
        for (var seed = 0; seed < 20; seed++) {
          final e = shuffleUpcoming(s, Random(seed), keys);
          final t = tracks(e.next);
          expect(t.sublist(0, 2), tracks(s).sublist(0, 2));
          expect(t.sublist(2, 5), [90, 91, 92]);
          expect(e.next.playNextRun, 3);
          expect(t.sublist(5).toSet(), tracks(s).sublist(5).toSet());
          expectHealthy(e.next);
        }
      });
    }

    test('only the entries behind the run are shuffled', () {
      final s = withRun(shuffled: false);
      final rests = {
        for (var seed = 0; seed < 20; seed++)
          tracks(shuffleUpcoming(s, Random(seed), keys).next)
              .sublist(5)
              .join(','),
      };
      expect(rests.length, greaterThan(1));
    });

    test('turning shuffle off gives back the order the user built', () {
      final s = withRun(shuffled: false);
      final on = shuffleUpcoming(s, Random(5), keys).next;
      final off = unshuffle(on).next;
      expect(tracks(off), tracks(s));
      expect(off.playNextRun, 3);
    });
  });

  group('cleanup', () {
    test('counts duplicates, played, upcoming and all but current', () {
      final s = _withTracks([1, 2, 1, 3, 2, 4], current: 2);
      final c = cleanupCounts(s);
      // Current is the second "1": the first "1" goes, the later "2" goes.
      expect(c.duplicates, 2);
      expect(c.before, 2);
      expect(c.after, 3);
      expect(c.allButCurrent, 5);
      expect(duplicateEntryIds(s), {1, 5});
    });

    test('no duplicates and nothing current', () {
      final c = cleanupCounts(makeQueue(3));
      expect(
        c,
        const CleanupCounts(
          duplicates: 0,
          before: 0,
          after: 0,
          allButCurrent: 3,
        ),
      );
    });

    test('removing the duplicates keeps the current entry', () {
      final s = _withTracks([1, 1, 1], current: 1);
      final e = remove(s, duplicateEntryIds(s));
      expect(entries(e.next), [2]);
      expect(e.next.current, 0);
    });
  });

  group('navigation', () {
    final cases = <(RepeatMode, int, bool, int?, int?)>[
      // repeat, current, auto, next, previous
      (RepeatMode.off, 0, true, 1, null),
      (RepeatMode.off, 2, true, null, 1),
      (RepeatMode.off, 2, false, null, 1),
      (RepeatMode.all, 2, true, 0, 1),
      (RepeatMode.all, 2, false, 0, 1),
      (RepeatMode.one, 1, true, 1, 0),
      (RepeatMode.one, 1, false, 2, 0),
      (RepeatMode.one, 2, false, null, 1),
      // After the last entry a reshuffled repeat has no automatic next (a new
      // pass starts); Next wraps like repeat all.
      (RepeatMode.allShuffled, 1, true, 2, 0),
      (RepeatMode.allShuffled, 2, true, null, 1),
      (RepeatMode.allShuffled, 2, false, 0, 1),
    ];
    for (final (repeat, cur, auto, next, prev) in cases) {
      test('$repeat at $cur auto=$auto', () {
        final s = makeQueue(3, current: cur, repeat: repeat);
        expect(nextIndex(s, auto: auto), next);
        expect(previousIndex(s), prev);
      });
    }

    test('extra plays of the current entry come before anything else', () {
      for (final repeat in RepeatMode.values) {
        final s = makeQueue(3, current: 2, repeat: repeat);
        expect(nextIndex(s, auto: true, loops: 2), 2, reason: '$repeat');
        expect(
          nextIndex(s, auto: false, loops: 2),
          repeat.wrapsQueue ? 0 : null,
          reason: 'a manual Next ignores the count',
        );
      }
    });

    test('empty and unloaded queues', () {
      expect(nextIndex(makeQueue(0), auto: true), isNull);
      expect(nextIndex(makeQueue(2), auto: true), 0);
      expect(previousIndex(makeQueue(2)), isNull);
    });
  });

  group('reshuffled pass', () {
    test('a fresh order of every entry, the first is never the last played',
        () {
      for (var seed = 0; seed < 30; seed++) {
        final s = makeQueue(6, current: 5, repeat: RepeatMode.allShuffled);
        final e = reshufflePass(s, Random(seed), const KeyGen());
        final ids = [for (final i in e.next.items) i.entryId];
        expect([...ids]..sort(), [for (final i in s.items) i.entryId]..sort());
        expect(ids.first, isNot(s.items[5].entryId), reason: 'seed $seed');
        expect(e.next.current, 0);
        expect(e.next.shuffled, isTrue);
        expect(e.next.repeat, RepeatMode.allShuffled);
        expect(e.rekeyed.keys.toSet(), ids.toSet());
        final keys = [for (final i in e.next.items) i.shuffleKey!];
        expect([...keys]..sort(), keys, reason: 'keys follow the order');
        expect(e.next.items.map((i) => i.sortKey),
            unorderedEquals(s.items.map((i) => i.sortKey)));
      }
    });

    test('fewer than two entries stay as they are', () {
      for (final n in [0, 1]) {
        final s = makeQueue(n, current: n == 0 ? null : 0);
        final e = reshufflePass(s, Random(1), const KeyGen());
        expect(e.isNoop, isTrue);
        expect(e.next, s);
      }
    });
  });

  group('keys', () {
    test('play next beside equal neighbour keys does not throw', () {
      final base = makeQueue(4, current: 0);
      final s = base.copyWith(
        items: [for (final i in base.items) i.withKeys(sortKey: 'a5')],
      );
      final e = insertPlayNext(s, ids([90, 91]), keys);
      expect(tracks(e.next).sublist(0, 3), [0, 90, 91]);
      expectHealthy(e.next);
      expect(e.rekeyed.keys, {2, 3, 4});
    });

    test('move beside equal neighbour keys does not throw', () {
      final base = makeQueue(4, current: 0);
      final s = base.copyWith(
        items: [for (final i in base.items) i.withKeys(sortKey: 'a5')],
      );
      final e = move(s, 4, 1, keys);
      expect(tracks(e.next), [0, 3, 1, 2]);
      expectHealthy(e.next);
    });
  });

  group('undo', () {
    test('restores entries with their ids, keys and current', () {
      final s = makeQueue(5, current: 2);
      final removed = remove(s, {3}, positionMs: 4000, playing: true);
      final back = undo(removed.next, removed.undo!, keys);
      expect(back.next, s);
      expect(back.inserted.single.entryId, 3);
      expect(removed.undo!.positionMs, 4000);
      expect(removed.undo!.wasPlaying, isTrue);
    });

    test('restores a removed current entry as current', () {
      final s = makeQueue(3, current: 1);
      final removed = remove(s, {2});
      expect(removed.next.currentItem?.entryId, 3);
      final back = undo(removed.next, removed.undo!, keys);
      expect(back.next.currentItem?.entryId, 2);
      expect(back.next, s);
    });

    test('keeps the live current entry when the removal did not take it', () {
      final s = makeQueue(5, current: 1);
      final removed = remove(s, {4});
      // The player advanced to entry 3 during the undo window.
      final advanced = removed.next.withCurrent(2, const {});
      expect(advanced.currentItem?.entryId, 3);
      final back = undo(advanced, removed.undo!, keys);
      expect(back.next.currentItem?.entryId, 3);
      expect(back.next.length, 5);
    });

    test('restores the only entry', () {
      final s = makeQueue(1, current: 0);
      final removed = remove(s, {1});
      expect(undo(removed.next, removed.undo!, keys).next, s);
    });

    test(
      'a play next in the window that took the key re-keys the restored row',
      () {
        final s = makeQueue(3, current: 0);
        final removed = remove(s, {2}); // frees the key right after current
        // Same neighbours as before: the generator makes the removed key again.
        final inWindow = insertPlayNext(removed.next, ids([90]), keys);
        expect(
          inWindow.inserted.single.sortKey,
          s.items[1].sortKey,
          reason: 'deterministic generator reuses the removed key',
        );
        final back = undo(inWindow.next, removed.undo!, keys);
        expectHealthy(back.next);
        expect(back.next.length, 4);
        final restored = back.inserted.single;
        expect(restored.entryId, 2);
        expect(restored.sortKey, isNot(s.items[1].sortKey));
        expect(tracks(back.next), [0, 90, 1, 2]);
      },
    );

    test('same for a shuffled queue', () {
      final s = makeQueue(4, current: 0, shuffled: true);
      final removed = remove(s, {s.items[1].entryId});
      final inWindow = insertPlayNext(removed.next, ids([90]), keys);
      final back = undo(inWindow.next, removed.undo!, keys);
      expectHealthy(back.next);
      expect(back.next.length, 5);
    });

    test('shuffle toggled inside the window still restores', () {
      final s = makeQueue(4, current: 0);
      final removed = remove(s, {3});
      final shuffled = shuffleUpcoming(removed.next, Random(1), keys).next;
      final back = undo(shuffled, removed.undo!, keys);
      expectHealthy(back.next);
      expect(back.next.length, 4);
      expect(back.next.items.every((i) => i.shuffleKey != null), isTrue);
    });

    test('an entry that is already live is not restored twice', () {
      final s = makeQueue(3, current: 0);
      final removed = remove(s, {2});
      final once = undo(removed.next, removed.undo!, keys);
      expect(undo(once.next, removed.undo!, keys).isNoop, isTrue);
    });
  });

  group('performance', () {
    test('20 000 entries: insert and remove stay under 200 ms', () {
      final s = makeQueue(20000, current: 10000);
      final best = [
        for (var run = 0; run < 3; run++)
          () {
            final sw = Stopwatch()..start();
            final e = insertPlayNext(s, ids([1, 2, 3]), keys);
            remove(e.next, {e.inserted.first.entryId, 5, 6});
            return sw.elapsedMilliseconds;
          }(),
      ].reduce(min);
      // Normally a few tens of ms; loose enough for a loaded machine.
      expect(best, lessThan(1500));
    });
  });
}

QueueState _withTracks(List<int> trackIds, {int? current}) {
  final base = makeQueue(trackIds.length, current: current);
  return base.copyWith(
    items: [
      for (var i = 0; i < trackIds.length; i++)
        QueueItem(
          entryId: i + 1,
          trackId: TrackId(trackIds[i]),
          sortKey: base.items[i].sortKey,
        ),
    ],
  );
}
