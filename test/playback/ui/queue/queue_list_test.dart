import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/ui_host.dart';
import 'queue_test_support.dart';

const _list = QueueList(size: QueueRowSize.mobile);

List<int> _ids(WidgetTester tester) => [
  for (final e in find.byType(QueueRow).evaluate())
    (e.widget as QueueRow).item.entryId,
];

void main() {
  testWidgets('20 000 entries build fewer than 50 rows and load few infos', (
    tester,
  ) async {
    final loader = CountingLoader();
    await pumpFakeQueue(
      tester,
      _list,
      view: fakeView(20000, current: 10000),
      loader: loader,
    );
    expect(find.byType(QueueRow).evaluate().length, lessThan(50));
    expect(loader.loaded.length, lessThanOrEqualTo(200));
    expect(loader.loaded, contains(const TrackId(10000)));
  });

  testWidgets('opens with the current row near the top, one played above', (
    tester,
  ) async {
    await pumpFakeQueue(tester, _list, view: fakeView(100, current: 40));
    final ids = _ids(tester);
    // Entry id = index + 1: the first built row is the played one above.
    expect(ids.first, 40);
    expect(tester.getTopLeft(find.byType(QueueRow).at(1)).dy, rowExtent());
  });

  testWidgets('a short queue starts at the top', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(3, current: 2));
    expect(_ids(tester), [1, 2, 3]);
  });

  testWidgets('rows are keyed by entry id', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(6, current: 0));
    for (var id = 1; id <= 6; id++) {
      expect(find.byKey(ValueKey(id)), findsOneWidget);
    }
  });

  testWidgets('tapping a row plays it; the current row does nothing', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _list);
    final entries = [for (final i in host.h.c.queueState.items) i.entryId];
    await host.tap(tester, find.text('T3'));
    expect(host.h.c.queueState.currentItem!.entryId, entries[3]);
    final before = host.h.engine.loads.length;
    await host.tap(tester, find.text('T3'));
    expect(host.h.c.queueState.currentItem!.entryId, entries[3]);
    expect(host.h.engine.loads.length, before);
  });

  /// Plays a drag through the list's own callbacks, in the real zone (a
  /// pointer drop would run the controller in the test's fake zone).
  Future<void> reorder(
    WidgetTester tester,
    UiHost host,
    int from,
    int to, {
    Future<void> Function()? midDrag,
  }) async {
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderStart!(from);
    await midDrag?.call();
    await host.run(tester, () async => list.onReorderItem!(from, to));
    await host.letStreamsArrive(tester);
  }

  testWidgets('only the handle starts a drag', (tester) async {
    await pumpWithPlayer(tester, _list);
    final titleY = tester.getTopLeft(find.text('T2')).dy;
    // A drag on the title scrolls (or nothing): no row makes room.
    final onTitle = await tester.startGesture(
      tester.getCenter(find.text('T1')),
    );
    await onTitle.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.text('T2')).dy, titleY);
    await onTitle.cancel();
    // A drag on the handle lifts the row: the rows below close the gap.
    final handle = tester.getCenter(
      find.byType(ReorderableDragStartListener).at(0),
    );
    final onHandle = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 5; i++) {
      await onHandle.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.text('T2')).dy, lessThan(titleY));
    await onHandle.cancel();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('dropping a row moves that entry', (tester) async {
    final host = await pumpWithPlayer(tester, _list);
    final ids = [for (final i in host.h.c.queueState.items) i.entryId];
    await reorder(tester, host, 1, 3);
    final after = [for (final i in host.h.c.queueState.items) i.entryId];
    expect(after, [ids[0], ids[2], ids[3], ids[1], ids[4], ids[5]]);
  });

  testWidgets('a played row dropped below the current becomes upcoming', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _list);
    await host.tap(tester, find.text('T3'));
    final first = host.h.c.queueState.items.first.entryId;
    await reorder(tester, host, 0, 4);
    final q = host.h.c.queueState;
    expect(q.indexOfEntry(first), greaterThan(q.current!));
  });

  testWidgets('a drop is resolved by entry id when the queue changed', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _list);
    final items = host.h.c.queueState.items;
    final dragged = items[3].entryId;
    final neighbour = items[4].entryId;
    await reorder(
      tester,
      host,
      3,
      1,
      midDrag: () => host.run(tester, () async {
        // The first entry leaves while the drag is on: every index shifts,
        // and the entry at the dragged index is now another one.
        await host.h.c.remove({items[0].entryId});
      }),
    );
    final after = [for (final i in host.h.c.queueState.items) i.entryId];
    // The entry at the dragged index (the old neighbour) stays where it is.
    expect(after, [
      items[1].entryId,
      dragged,
      items[2].entryId,
      neighbour,
      items[5].entryId,
    ]);
  });
}
