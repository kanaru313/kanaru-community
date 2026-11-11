import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

import '../support/queue_fixtures.dart';

/// Random operations, undo included, on the pure model: the queue stays a
/// valid ordered list with unique keys after every step.
void main() {
  for (final seed in [1, 2, 3]) {
    test(
      '500 random operations keep the keys ordered and unique (seed $seed)',
      () {
        final r = Random(seed);
        const keys = KeyGen();
        var nextId = 1000;
        var s = makeQueue(8, current: 3);
        UndoToken? token;
        var trackSeq = 100;
        List<TrackId> fresh(int n) => [
          for (var i = 0; i < n; i++) TrackId(trackSeq++),
        ];
        QueueState run(QueueEdit e) => assignIds(e, () => nextId++).next;

        for (var step = 0; step < 500; step++) {
          final op = r.nextInt(10);
          final hadToken = token != null;
          switch (op) {
            case 0:
            case 1:
              s = run(insertPlayNext(s, fresh(1 + r.nextInt(3)), keys));
            case 2:
              s = run(enqueue(s, fresh(1 + r.nextInt(3)), keys));
            case 3:
              if (s.length > 1 && r.nextBool()) {
                final e = remove(s, {s.items[r.nextInt(s.length)].entryId});
                token = e.undo;
                s = e.next;
              } else if (s.length > 3) {
                final ids = {
                  for (var i = 0; i < 2; i++)
                    s.items[r.nextInt(s.length)].entryId,
                };
                final e = remove(s, ids);
                token = e.undo;
                s = e.next;
              }
            case 4:
            case 5:
              if (s.length > 1) {
                final e = move(
                  s,
                  s.items[r.nextInt(s.length)].entryId,
                  r.nextInt(s.length),
                  keys,
                );
                s = e.next;
              }
            case 6:
              s = run(shuffleUpcoming(s, r, keys));
            case 7:
              s = unshuffle(s).next;
            case 8:
              if (token != null) {
                s = run(undo(s, token, keys));
                token = null;
              }
            default:
              if (s.length > 1) {
                s = s.withCurrent(r.nextInt(s.length), s.playNextRunIds);
              }
          }
          // The undo window is short: a token survives only a few steps.
          if (hadToken && r.nextInt(3) == 0) token = null;
          if (s.length > 40) {
            s = remove(s, {
              for (var i = 0; i < 20; i++) s.items[i].entryId,
            }).next;
          }
          expectHealthy(s);
          if (s.items.isEmpty) s = makeQueue(3, current: 0);
        }
      },
    );
  }
}
