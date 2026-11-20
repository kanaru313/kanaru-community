import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/history/history_calendar_dialog.dart';
import 'package:kanaru/src/library/ui/history/history_clear_dialog.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'history_page_harness.dart';

void main() {
  group('recording-off notice', () {
    testWidgets('wide: spans the page above both columns', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
        width: 1280,
        recording: false,
      );
      final notice = tester.getRect(find.byType(KInlineNotice));
      expect(
        notice.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(HistoryHero)).top),
      );
      expect(notice.width, greaterThan(KDetailLayout.columnWidth * 2));
    });

    testWidgets('narrow: sits on top of the hero', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
        recording: false,
      );
      expect(
        tester.getRect(find.byType(KInlineNotice)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(HistoryHero)).top),
      );
    });
  });

  group('dialog widths on desktop', () {
    testWidgets('clear dialog is 440 wide', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
        width: 1280,
      );
      unawaited(
        showHistoryClearDialog(tester.element(find.byType(HistoryPage))),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AlertDialog)).width, 440);
    });

    testWidgets('jump dialog is 360 wide', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
        width: 1280,
      );
      unawaited(
        showHistoryCalendar(
          tester.element(find.byType(HistoryPage)),
          year: 2026,
          plays: {DateTime(2026, 11, 20): 3},
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Dialog)).width, 360);
    });
  });

  group('dialog widths on mobile keep the default dialog insets', () {
    testWidgets('clear dialog', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
      );
      unawaited(
        showHistoryClearDialog(tester.element(find.byType(HistoryPage))),
      );
      await tester.pumpAndSettle();
      // The app's default: the dialog's own size, within the window and
      // never forced to the desktop cap.
      expect(
        tester.getSize(find.byType(AlertDialog)).width,
        inInclusiveRange(280, 400),
      );
    });

    testWidgets('jump dialog', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3]),
        },
      );
      unawaited(
        showHistoryCalendar(
          tester.element(find.byType(HistoryPage)),
          year: 2026,
          plays: {DateTime(2026, 11, 20): 3},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Dialog)).width,
        inInclusiveRange(280, 360),
      );
    });
  });

  testWidgets('filter field keeps the same side margin on both sides', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
    );
    await tester.tap(byIconButton('Lọc'));
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(KFilterField));
    expect(field.left, 400 - field.right);
  });
}
