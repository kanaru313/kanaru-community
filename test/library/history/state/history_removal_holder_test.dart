import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/history/history_removal_holder.dart';

import 'fake_history_store.dart';

HistoryBatch batch(List<String> uids, [int stamp = 1]) =>
    HistoryBatch(uids: uids, stamp: stamp);

void main() {
  late FakeHistoryStore store;
  late StreamController<void> cleared;
  late HistoryRemovalHolder holder;

  setUp(() {
    store = FakeHistoryStore();
    cleared = StreamController<void>.broadcast();
    holder = HistoryRemovalHolder(store, cleared: cleared.stream);
  });
  tearDown(() async {
    await holder.dispose();
    await cleared.close();
  });

  test('batches merge: counts add up, undo brings all back', () async {
    holder.add(batch(['a'], 1));
    holder.add(batch(['b', 'c'], 2));
    expect(holder.pendingCount, 3);
    expect(await holder.undo(), 3);
    expect(store.undone.single.map((b) => b.stamp), [1, 2]);
    expect(holder.hasPending, isFalse);
    expect(await holder.undo(), 0, reason: 'idempotent');
    await holder.commit();
    expect(
      store.committed,
      isEmpty,
      reason: 'undone batches are not committed',
    );
  });

  test('commit deletes every batch once and hides its toast', () async {
    var hidden = 0;
    holder.add(batch(['a'], 1));
    holder.add(batch(['b'], 2));
    holder.attachToast(() => hidden++);
    await Future.wait([holder.commit(), holder.commit()]);
    expect(store.committed.length, 1);
    expect(store.committed.single.length, 2);
    expect(hidden, 1);
  });

  test('toast closing commits; a replaced toast closing does not', () async {
    void first() {}
    void second() {}
    holder.add(batch(['a']));
    holder.attachToast(first);
    holder.attachToast(second);
    await holder.toastClosed(first);
    expect(store.committed, isEmpty);
    await holder.toastClosed(second);
    expect(store.committed.length, 1);
  });

  test('the recorder reporting a clear commits', () async {
    holder.add(batch(['a']));
    cleared.add(null);
    await pumpEventQueue();
    expect(store.committed.length, 1);
  });

  test('dispose commits what is pending', () async {
    holder.add(batch(['a']));
    await holder.dispose();
    expect(store.committed.length, 1);
    cleared.add(null);
    await pumpEventQueue();
    expect(store.committed.length, 1, reason: 'listener removed');
  });

  test('a failed undo throws and commits the batches right away', () async {
    holder.add(batch(['a']));
    store.undoError = StateError('x');
    await expectLater(holder.undo(), throwsStateError);
    expect(holder.hasPending, isFalse);
    expect(store.committed.single.single.uids, ['a']);
    holder.add(batch(['b'], 2));
    expect(holder.pendingCount, 1, reason: 'the next toast counts its own');
  });

  test('a failed undo followed by a failed commit still throws the undo '
      'error', () async {
    holder.add(batch(['a']));
    store.undoError = StateError('x');
    store.commitError = StateError('y');
    await expectLater(holder.undo(), throwsStateError);
    expect(holder.hasPending, isFalse);
  });

  test(
    'commit reports true, a failed one false and drops the batches',
    () async {
      expect(await holder.commit(), isTrue, reason: 'nothing pending');
      holder.add(batch(['a']));
      store.commitError = StateError('x');
      expect(await holder.commit(), isFalse);
      expect(holder.hasPending, isFalse);
    },
  );

  test('a toast closing reports a failed commit', () async {
    void hide() {}
    holder.add(batch(['a']));
    holder.attachToast(hide);
    store.commitError = StateError('x');
    expect(await holder.toastClosed(hide), isFalse);
    expect(await holder.toastClosed(() {}), isTrue, reason: 'not the toast');
  });
}
