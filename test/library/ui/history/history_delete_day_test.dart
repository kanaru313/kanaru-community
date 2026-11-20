import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import 'fake_clear_recorder.dart';
import 'history_page_harness.dart';

/// Pumps a page with plays today (2) and yesterday (3), a scripted recorder.
Future<(HistoryHarness, FakeClearRecorder)> _page(
  WidgetTester tester, {
  int? result = 3,
}) async {
  final db = openTestDb();
  addTearDown(db.close);
  final recorder = FakeClearRecorder(db)..result = result;
  final h = await pumpHistoryPage(
    tester,
    byYear: {
      2026: playsOverDays([2, 3]),
    },
    recorder: recorder,
  );
  return (h, recorder);
}

Future<void> _openConfirm(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  await openDayMenu(tester, l10n.historyDayYesterday);
  await tester.tap(find.text(l10n.historyMenuDeleteDay));
  await tester.pumpAndSettle();
}

Finder get _confirm =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text('Xoá'));

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks first, with the number of plays and the date', (
    tester,
  ) async {
    final (_, recorder) = await _page(tester);
    await _openConfirm(tester);
    expect(find.text('Xoá ngày này khỏi lịch sử?'), findsOneWidget);
    expect(
      find.text(
        '3 lượt nghe của ngày 19/11/2026 sẽ bị xoá. Không thể hoàn tác.',
      ),
      findsOneWidget,
    );
    expect(recorder.calls, isEmpty);
  });

  testWidgets('confirming clears exactly that local day and says how many', (
    tester,
  ) async {
    final (_, recorder) = await _page(tester);
    await _openConfirm(tester);
    await tester.tap(_confirm);
    await _settle(tester);
    final start = DateTime(2026, 11, 19);
    expect(recorder.calls, [
      (
        from: start.millisecondsSinceEpoch,
        to: DateTime(2026, 11, 20).millisecondsSinceEpoch,
      ),
    ]);
    expect(find.text('Đã xoá 3 lượt nghe'), findsOneWidget);
    // No Undo: a removed day cannot come back.
    expect(find.text('Hoàn tác'), findsNothing);
  });

  testWidgets('Cancel clears nothing', (tester) async {
    final (_, recorder) = await _page(tester);
    await _openConfirm(tester);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(recorder.calls, isEmpty);
    expect(find.textContaining('Đã xoá'), findsNothing);
  });

  testWidgets('a failed delete shows the error toast, never "Removed"', (
    tester,
  ) async {
    final (_, recorder) = await _page(tester, result: null);
    await _openConfirm(tester);
    await tester.tap(_confirm);
    await _settle(tester);
    expect(recorder.calls, hasLength(1));
    expect(find.text('Không xoá được lịch sử'), findsOneWidget);
    expect(find.textContaining('Đã xoá'), findsNothing);
  });

  testWidgets('the menu row waits while another clear runs', (tester) async {
    final (_, recorder) = await _page(tester);
    recorder.externalClear = true;
    final l10n = l10nOf(tester);
    await openDayMenu(tester, l10n.historyDayYesterday);
    await tester.tap(find.text(l10n.historyMenuDeleteDay));
    await tester.pumpAndSettle();
    // The row is off: no confirm dialog came up.
    expect(find.byType(AlertDialog), findsNothing);
    expect(recorder.calls, isEmpty);
  });
}
