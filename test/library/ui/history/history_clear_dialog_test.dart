import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_clear_scope.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/history/history_clear_dialog.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../../support/icon_button_finders.dart';
import '../../history/state/fake_history_store.dart';
import '../menus/menu_pump.dart';
import 'fake_clear_recorder.dart';
import 'history_page_harness.dart';

/// Counts the fake store answers per scope: the key of each scope is its
/// `from` bound at the fixed [testToday].
const _counts = {
  ClearScope.hour: 2,
  ClearScope.today: 4,
  ClearScope.week: 9,
  ClearScope.all: 12,
};

class _CountFails extends FakeHistoryStore {
  var failures = 1;

  @override
  Future<int> countPlays(int start, int end) async {
    if (failures > 0) {
      failures--;
      throw StateError('no count');
    }
    return super.countPlays(start, end);
  }
}

Future<FakeClearRecorder> _open(
  WidgetTester tester, {
  FakeHistoryStore? store,
  int? result = 0,
}) async {
  final db = openTestDb();
  addTearDown(db.close);
  final recorder = FakeClearRecorder(db)..result = result;
  final fake = store ?? FakeHistoryStore();
  for (final e in _counts.entries) {
    // The count of "everything" starts at the floor the actions use.
    final from = e.key.bounds(testToday).from ?? -(1 << 52);
    fake.counts[from] = e.value;
  }
  await pumpHistoryPage(
    tester,
    byYear: {
      2026: playsOverDays([6, 6]),
    },
    store: fake,
    recorder: recorder,
    overrides: [historyClockProvider.overrideWithValue(() => testToday)],
  );
  unawaited(showHistoryClearDialog(tester.element(find.byType(HistoryPage))));
  await tester.pumpAndSettle();
  return recorder;
}

/// Text inside the dialog (the page behind has the same words).
Finder _in(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

Finder get _clear => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(FilledButton),
);
Finder get _cancel => find.widgetWithText(TextButton, 'Huỷ');

bool _enabled(WidgetTester tester, Finder f) =>
    isSemantics(isEnabled: true).matches(tester.getSemantics(f), {});

Future<void> _settleClear(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the four options with the count of each', (tester) async {
    await _open(tester);
    expect(find.text('Xoá lịch sử?'), findsOneWidget);
    for (final row in [
      ('Giờ qua', '2 lượt nghe'),
      ('Hôm nay', '4 lượt nghe'),
      ('7 ngày qua', '9 lượt nghe'),
      ('Toàn bộ', '12 lượt nghe'),
    ]) {
      expect(_in(row.$1), findsOneWidget, reason: row.$1);
      expect(_in(row.$2), findsOneWidget, reason: row.$2);
    }
  });

  testWidgets('opens from the page menu\'s red row', (tester) async {
    final db = openTestDb();
    addTearDown(db.close);
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2]),
      },
      recorder: FakeClearRecorder(db),
      overrides: [historyClockProvider.overrideWithValue(() => testToday)],
    );
    final l10n = l10nOf(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(HistoryHero),
        matching: byIconButton(l10n.libraryMenuMore),
      ),
    );
    await pumpMenu(tester);
    await tester.tap(find.text(l10n.historyMenuClear));
    await pumpMenu(tester);
    expect(find.text(l10n.historyClearTitle), findsOneWidget);
  });

  testWidgets('Clear waits for a choice and for a count above zero', (
    tester,
  ) async {
    final recorder = await _open(tester);
    expect(_enabled(tester, _clear), isFalse);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    expect(_enabled(tester, _clear), isTrue);
    await tester.tap(find.text('Giờ qua'));
    await tester.pump();
    expect(_enabled(tester, _clear), isTrue);
    expect(recorder.calls, isEmpty);
  });

  testWidgets('a scope with no plays cannot be cleared', (tester) async {
    final store = FakeHistoryStore();
    final recorder = await _open(tester, store: store);
    // The hour's count is gone: reopen the dialog, it reads zero.
    await tester.tap(_cancel);
    await tester.pumpAndSettle();
    store.counts.remove(ClearScope.hour.bounds(testToday).from);
    unawaited(showHistoryClearDialog(tester.element(find.byType(HistoryPage))));
    await tester.pumpAndSettle();
    expect(_in('0 lượt nghe'), findsOneWidget);
    await tester.tap(find.text('Giờ qua'));
    await tester.pump();
    expect(_enabled(tester, _clear), isFalse);
    expect(recorder.calls, isEmpty);
  });

  testWidgets('clearing everything calls the recorder and says how many', (
    tester,
  ) async {
    final recorder = await _open(tester, result: 12);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    await tester.tap(_clear);
    await _settleClear(tester);
    expect(recorder.calls, [
      (from: null, to: ClearScope.all.bounds(testToday).to),
    ]);
    expect(find.text('Xoá lịch sử?'), findsNothing);
    expect(find.text('Đã xoá 12 lượt nghe'), findsOneWidget);
  });

  testWidgets('a range scope uses the bounds of the moment it opened', (
    tester,
  ) async {
    final recorder = await _open(tester, result: 4);
    await tester.tap(find.text('7 ngày qua'));
    await tester.pump();
    await tester.tap(_clear);
    await _settleClear(tester);
    final b = ClearScope.week.bounds(testToday);
    expect(recorder.calls, [(from: b.from, to: b.to)]);
  });

  testWidgets('while the clear runs the dialog stays and shows progress', (
    tester,
  ) async {
    final recorder = await _open(tester, result: 12);
    recorder.gate = Completer<void>();
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    await tester.tap(_clear);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_enabled(tester, _clear), isFalse);
    expect(_enabled(tester, _cancel), isFalse);
    // Esc and Back do not close it.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Xoá lịch sử?'), findsOneWidget);
    recorder.gate!.complete();
    await _settleClear(tester);
    expect(find.text('Xoá lịch sử?'), findsNothing);
    expect(find.text('Đã xoá 12 lượt nghe'), findsOneWidget);
  });

  testWidgets('the toast shows even when the dialog was removed meanwhile', (
    tester,
  ) async {
    final recorder = await _open(tester, result: 7);
    recorder.gate = Completer<void>();
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    await tester.tap(_clear);
    await tester.pump();
    final dialog = tester.element(find.byType(AlertDialog));
    Navigator.of(
      dialog,
      rootNavigator: true,
    ).removeRoute(ModalRoute.of(dialog)!);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Xoá lịch sử?'), findsNothing);
    recorder.gate!.complete();
    await _settleClear(tester);
    expect(find.text('Đã xoá 7 lượt nghe'), findsOneWidget);
  });

  testWidgets('a failed clear shows the error toast, never "Removed"', (
    tester,
  ) async {
    final recorder = await _open(tester, result: null);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    await tester.tap(_clear);
    await _settleClear(tester);
    expect(recorder.calls, hasLength(1));
    expect(find.text('Không xoá được lịch sử'), findsOneWidget);
    expect(find.textContaining('Đã xoá'), findsNothing);
  });

  testWidgets('Clear is off while another clear runs', (tester) async {
    final recorder = await _open(tester);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    expect(_enabled(tester, _clear), isTrue);
    recorder.externalClear = true;
    await tester.pump();
    expect(_enabled(tester, _clear), isFalse);
    recorder.externalClear = false;
    await tester.pump();
    expect(_enabled(tester, _clear), isTrue);
  });

  testWidgets('Cancel closes without clearing', (tester) async {
    final recorder = await _open(tester);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    await tester.tap(_cancel);
    await tester.pumpAndSettle();
    expect(find.text('Xoá lịch sử?'), findsNothing);
    expect(recorder.calls, isEmpty);
  });

  testWidgets('a count that fails shows Try again, which reads it again', (
    tester,
  ) async {
    final store = _CountFails();
    final recorder = await _open(tester, store: store);
    expect(find.text('Không đếm được số lượt nghe'), findsOneWidget);
    await tester.tap(find.text('Toàn bộ'));
    await tester.pump();
    expect(_enabled(tester, _clear), isFalse);
    await tester.tap(find.text('Thử lại'));
    await _settleClear(tester);
    expect(find.text('Không đếm được số lượt nghe'), findsNothing);
    expect(_in('12 lượt nghe'), findsOneWidget);
    expect(_enabled(tester, _clear), isTrue);
    expect(recorder.calls, isEmpty);
  });
}
