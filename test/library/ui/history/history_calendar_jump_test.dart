import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/ui/history/history_calendar_dialog.dart';
import 'package:kanaru/src/library/ui/history/history_day_bar.dart';
import 'package:kanaru/src/library/ui/history/history_sticky_bar.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/kanaru_ui.dart' show KChip;

import '../../../support/icon_button_finders.dart';
import 'history_page_harness.dart';

/// 20 days of 6 plays: 2026-11-20 back to 2026-11-01. The play ids of day n
/// (0 = the 20th) are 6n+1 .. 6n+6, newest first.
List<HistoryPlay> _month() => playsOverDays(List.filled(20, 6));

ScrollPosition _pos(WidgetTester t) =>
    Scrollable.of(t.element(find.byType(HistoryStickyBar))).position;

/// Page y of the top of the scroll view the timeline is in.
double _viewportTop(WidgetTester t) =>
    (Scrollable.of(t.element(find.byType(HistoryStickyBar))).context
                .findRenderObject()!
            as RenderBox)
        .localToGlobal(Offset.zero)
        .dy;

DateTime _pinnedDay(WidgetTester t) => t
    .widget<HistoryDayBar>(
      find
          .descendant(
            of: find.byType(HistoryStickyBar),
            matching: find.byType(HistoryDayBar),
          )
          .first,
    )
    .day
    .start;

/// Opens the jump dialog from the bar's button, moves the page to
/// [pageOffset] under it, and taps the day of November [day].
Future<void> _jumpTo(
  WidgetTester tester, {
  required int day,
  required double pageOffset,
}) async {
  await tester.tap(byIconButton(l10nOf(tester).historyJumpToDay));
  await tester.pumpAndSettle();
  expect(find.byType(HistoryCalendar), findsOneWidget);
  _pos(tester).jumpTo(pageOffset);
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('history-calendar-day-$day')));
  await tester.pumpAndSettle();
  expect(find.byType(HistoryCalendar), findsNothing);
}

void main() {
  for (final width in [320.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final offset in [0.0, 700.0]) {
        // 0: the page is at its top (the hero is in view on a narrow page);
        // 700: scrolled past the hero.
        for (final day in [20, 17, 9]) {
          testWidgets(
            'lands the bar of Nov $day at the top, ${width.toInt()} dp, '
            'text $scale, page at ${offset.toInt()}',
            (tester) async {
              await pumpHistoryPage(
                tester,
                byYear: {2026: _month()},
                width: width,
                height: 900,
                textScale: scale,
              );
              await _jumpTo(tester, day: day, pageOffset: offset);

              final n = 20 - day;
              // The pinned bar is the picked day's.
              expect(_pinnedDay(tester), DateTime(2026, 11, day));
              final bar = find.byType(HistoryStickyBar);
              final barBox = tester.getRect(bar);
              expect(barBox.top, closeTo(_viewportTop(tester), 0.01));
              // Its first play sits right under the bar, no gap, no overlap.
              final first = find.byKey(ValueKey('p${6 * n + 1}'));
              expect(first, findsOneWidget);
              expect(tester.getTopLeft(first).dy, closeTo(barBox.bottom, 0.01));
            },
          );
        }
      }
    }
  }

  testWidgets('a day with no list room below clamps at the end of the page', (
    tester,
  ) async {
    await pumpHistoryPage(tester, byYear: {2026: _month()}, height: 900);
    await _jumpTo(tester, day: 1, pageOffset: 0);
    final p = _pos(tester);
    expect(p.pixels, p.maxScrollExtent);
    // The page cannot go further: the last play is on screen, and the bar
    // that is not the picked day's yet is the day before it.
    expect(find.byKey(const ValueKey('p120')), findsOneWidget);
    expect(_pinnedDay(tester), DateTime(2026, 11, 2));
  });

  testWidgets('still lands after switching to another year and back', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: _month(),
        2025: [playAt(500, DateTime(2025, 6, 1, 12), uid: 'old')],
      },
      height: 900,
    );
    for (final year in ['2025', '2026']) {
      await tester.tap(find.widgetWithText(KChip, year));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }
    await _jumpTo(tester, day: 17, pageOffset: 0);
    expect(_pinnedDay(tester), DateTime(2026, 11, 17));
    final bar = tester.getRect(find.byType(HistoryStickyBar));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('p19'))).dy,
      closeTo(bar.bottom, 0.01),
    );
  });
}
