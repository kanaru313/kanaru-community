import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kanaru/src/library/state/history/history_removal_holder.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'history_page_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

/// Lets the toast come in, run its 4 s and go out, then lets the commit run.
Future<void> _letToastClose(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await _settle(tester);
}

/// Lets the toast come in (its action takes taps only then).
Future<void> _letToastIn(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

/// Focuses the row of [title] and presses Delete.
Future<void> _remove(WidgetTester tester, String title) async {
  await focusRow(tester, title);
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await _settle(tester);
}

Future<HistoryHarness> _page(WidgetTester tester) => pumpHistoryPage(
  tester,
  byYear: {
    2026: playsOverDays([3]),
  },
  // The Delete key is a desktop input; rows take focus there.
  width: 1400,
);

void main() {
  testWidgets('removing a play shows the toast with Undo', (tester) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 2');
    expect(h.store.removed, [
      ['p2'],
    ]);
    expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsOneWidget);
  });

  testWidgets('removals while the toast is open merge into one count', (
    tester,
  ) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 1');
    await _remove(tester, 'Song 3');
    expect(find.text('Đã xoá 2 lượt nghe'), findsOneWidget);
    expect(find.text('Đã xoá 1 lượt nghe'), findsNothing);
    // The first toast closed because a newer one replaced it: nothing is
    // committed yet.
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.committed, isEmpty);
  });

  testWidgets('one Undo brings every removed play back', (tester) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 1');
    await _remove(tester, 'Song 3');
    await _letToastIn(tester);
    await tester.tap(find.text('Hoàn tác'));
    await _settle(tester);
    expect(h.store.undone, hasLength(1));
    expect(
      h.store.undone.single.expand((b) => b.uids),
      unorderedEquals(['p1', 'p3']),
    );
    // Closing the toast after Undo commits nothing.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await _settle(tester);
    expect(h.store.committed, isEmpty);
  });

  testWidgets('the toast timing out commits the removal', (tester) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 2');
    await _letToastClose(tester);
    expect(h.store.committed, hasLength(1));
    expect(h.store.committed.single.single.uids, ['p2']);
    expect(find.text('Đã xoá 1 lượt nghe'), findsNothing);
  });

  group('failures', () {
    testWidgets('a failed write toasts the error and no "removed"', (
      tester,
    ) async {
      final h = await _page(tester);
      h.store.removeError = StateError('disk');
      await _remove(tester, 'Song 2');
      expect(find.text('Không xoá được lượt nghe'), findsOneWidget);
      expect(find.textContaining('Đã xoá'), findsNothing);
    });

    testWidgets('a failed Undo says it could not', (tester) async {
      final h = await _page(tester);
      await _remove(tester, 'Song 2');
      h.store.undoError = StateError('disk');
      await _letToastIn(tester);
      await tester.tap(find.text('Hoàn tác'));
      await _settle(tester);
      // The toast of the removal leaves first, then the error comes in.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l10nOf(tester).libraryMenuUndoFailed), findsOneWidget);
    });

    testWidgets('a failed commit after the toast closes says so', (
      tester,
    ) async {
      final h = await _page(tester);
      await _remove(tester, 'Song 2');
      h.store.commitError = StateError('disk');
      await _letToastClose(tester);
      expect(find.text('Không lưu được thay đổi'), findsOneWidget);
    });
  });

  testWidgets('the toast outlives the page: popping it leaves the toast, '
      'and the timeout still commits', (tester) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
      width: 1400,
      pushed: true,
    );
    await _remove(tester, 'Song 2');
    Navigator.of(tester.element(find.byType(HistoryPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HistoryPage), findsNothing);
    expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);
    expect(h.store.committed, isEmpty);
    await _letToastClose(tester);
    expect(h.store.committed.single.single.uids, ['p2']);
  });

  testWidgets('tearing the app down commits the pending removal', (
    tester,
  ) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
      width: 1400,
    );
    await _remove(tester, 'Song 2');
    expect(h.store.committed, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    h.container.dispose();
    // Drift closes its query streams on a zero-length timer.
    await tester.pump(const Duration(milliseconds: 10));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(h.store.committed.single.single.uids, ['p2']);
  });

  testWidgets('a removal while the toast is open gives the merged toast a '
      'fresh 4 s', (tester) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 1');
    await tester.pump(const Duration(seconds: 3));
    await _remove(tester, 'Song 3');
    // 3 s after the second removal: the first toast's 4 s are long gone.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester);
    expect(find.text('Đã xoá 2 lượt nghe'), findsOneWidget);
    expect(h.store.committed, isEmpty);
    await _letToastClose(tester);
    expect(h.store.committed, hasLength(1));
    expect(
      h.store.committed.single.expand((b) => b.uids),
      unorderedEquals(['p1', 'p3']),
    );
  });

  testWidgets('a forced commit closes the toast and commits once', (
    tester,
  ) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 1');
    await tester.pump(const Duration(seconds: 1));
    final done = h.container.read(historyRemovalHolderProvider).commit();
    await tester.pump();
    await _settle(tester);
    await done;
    await tester.pumpAndSettle();
    expect(h.store.committed, hasLength(1));
    expect(find.text('Đã xoá 1 lượt nghe'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    expect(h.store.committed, hasLength(1));
  });

  testWidgets('a replaced toast is not hidden again on commit', (tester) async {
    final h = await _page(tester);
    await _remove(tester, 'Song 1');
    // A second toast (the missing-song one) replaces ours.
    final context = tester.element(find.byType(HistoryPage));
    showAppSnackBar(context, 'other toast');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('other toast'), findsOneWidget);
    await h.container.read(historyRemovalHolderProvider).commit();
    await tester.pump();
    expect(find.text('other toast'), findsOneWidget);
  });
}
