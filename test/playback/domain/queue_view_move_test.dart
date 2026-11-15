import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/domain/queue_view_move.dart';

import '../support/queue_fixtures.dart';

QueueView viewOf(QueueState s) =>
    QueueView(items: s.items, current: s.current, shuffled: s.shuffled);

const keys = KeyGen();

List<int> order(QueueView v) => [for (final i in v.items) i.entryId];

void main() {
  final v = viewOf(makeQueue(5, current: 2));

  test('moves an entry down', () {
    final r = moveInView(v, 1, 3);
    expect(order(r), [2, 3, 4, 1, 5]);
    expect(r.current, 1); // entry 3 shifted up
  });

  test('moves an entry up across the current one', () {
    final r = moveInView(v, 5, 0);
    expect(order(r), [5, 1, 2, 3, 4]);
    expect(r.current, 3);
  });

  test('the current entry is followed', () {
    final r = moveInView(v, 3, 4);
    expect(order(r), [1, 2, 4, 5, 3]);
    expect(r.current, 4);
    expect(r.items[r.current!].entryId, 3);
  });

  test('an entry moved within the played part keeps current', () {
    final r = moveInView(v, 1, 1);
    expect(order(r), [2, 1, 3, 4, 5]);
    expect(r.current, 2);
  });

  test('unknown id, same place and short lists return the same view', () {
    expect(identical(moveInView(v, 99, 1), v), isTrue);
    expect(identical(moveInView(v, 2, 1), v), isTrue);
    final one = viewOf(makeQueue(1, current: 0));
    expect(identical(moveInView(one, 1, 0), one), isTrue);
  });

  test('the index is clamped', () {
    expect(order(moveInView(v, 1, 99)), [2, 3, 4, 5, 1]);
    expect(order(moveInView(v, 5, -4)), [5, 1, 2, 3, 4]);
  });

  test('a null current stays null and other fields are copied', () {
    final s = QueueView(
      items: v.items,
      shuffled: true,
      repeat: RepeatMode.all,
      repeatTimes: 2,
      stopped: true,
    );
    final r = moveInView(s, 1, 2);
    expect(r.current, isNull);
    expect(r.shuffled, isTrue);
    expect(r.repeat, RepeatMode.all);
    expect(r.repeatTimes, 2);
    expect(r.stopped, isTrue);
  });

  test('matches the entry order and current of queue_logic move', () {
    final rnd = Random(7);
    for (var n = 0; n < 200; n++) {
      final len = 1 + rnd.nextInt(8);
      final cur = rnd.nextBool() ? rnd.nextInt(len) : null;
      final state = makeQueue(len, current: cur, shuffled: rnd.nextBool());
      final id = 1 + rnd.nextInt(len + 1); // sometimes unknown
      final to = rnd.nextInt(len + 4) - 2; // sometimes out of range
      final expected = move(state, id, to, keys).next;
      final actual = moveInView(viewOf(state), id, to);
      expect(order(actual), entries(expected), reason: '$len $cur $id $to');
      expect(actual.current, expected.current, reason: '$len $cur $id $to');
    }
  });
}
