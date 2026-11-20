import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/ui/history/history_day_bar.dart';
import 'package:kanaru/src/library/ui/history/history_line_metrics.dart';
import 'package:kanaru/src/library/ui/history/history_row.dart';
import 'package:kanaru/src/library/ui/history/history_sticky_bar.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'history_page_harness.dart';

Finder get _pinned => find.byType(HistoryStickyBar);

Finder get _pinnedBars =>
    find.descendant(of: _pinned, matching: find.byType(HistoryDayBar));

ScrollPosition _position(WidgetTester tester) =>
    Scrollable.of(tester.element(find.byType(SongTile).first)).position;

/// Scrolls the page by [dy] pixels (positive = further down).
Future<void> _scroll(WidgetTester tester, double dy) async {
  final position = _position(tester);
  position.jumpTo(position.pixels + dy);
  await tester.pump();
}

/// Top of the pinned bar on screen.
double _barTop(WidgetTester tester) => tester.getTopLeft(_pinned).dy;

/// Texts of the day labels in the pinned bar (the current day first).
List<String> _pinnedLabels(WidgetTester tester) => [
  for (final bar in tester.widgetList<HistoryDayBar>(_pinnedBars))
    tester
        .widgetList<Text>(
          find.descendant(of: find.byWidget(bar), matching: find.byType(Text)),
        )
        .first
        .data!,
];

void main() {
  testWidgets('the pinned bar and every header line are one height, at 1.0 and '
      '2.0 text scale', (tester) async {
    for (final scale in [1.0, 2.0]) {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 2, 2]),
        },
        height: 4000,
        textScale: scale,
      );
      final theme = Theme.of(tester.element(find.byType(HistoryStickyBar)));
      final metrics = HistoryLineMetrics.of(
        theme.textTheme,
        TextScaler.linear(scale),
      );
      final bars = tester.widgetList<HistoryDayBar>(find.byType(HistoryDayBar));
      // The pinned bar (first day) and one header line per later day.
      expect(bars, hasLength(3), reason: 'scale $scale');
      for (final bar in find.byType(HistoryDayBar).evaluate()) {
        expect(
          tester.getSize(find.byElementPredicate((e) => e == bar)).height,
          closeTo(metrics.dayBar, 0.001),
          reason: 'scale $scale',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('a day\'s header line starts where the previous day\'s last '
      'row slot ends', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2, 2]),
      },
      height: 4000,
    );
    final row = find.ancestor(
      of: find.text('Song 2'),
      matching: find.byType(HistoryRow),
    );
    final slot = KMediaCard.extentOf(
      MediaQuery.textScalerOf(tester.element(row)),
    );
    expect(
      tester.getTopLeft(find.byType(HistoryDayBar).last).dy,
      closeTo(tester.getTopLeft(row).dy + slot, 0.01),
    );
  });

  testWidgets('the pinned bar shows the day at the top as the list scrolls', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([6, 6, 6]),
      },
      height: 500,
    );
    expect(_pinnedLabels(tester), ['Hôm nay']);
    // Scroll to the very end: the last day (two days back) is at the top.
    final position = _position(tester);
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(_pinnedLabels(tester), ['Thứ Tư']);
    position.jumpTo(0);
    await tester.pump();
    expect(_pinnedLabels(tester), ['Hôm nay']);
  });

  testWidgets('the next day pushes the pinned bar up as its header arrives', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([6, 6, 6]),
      },
    );
    final theme = Theme.of(tester.element(find.byType(HistoryStickyBar)));
    final height = HistoryLineMetrics.of(
      theme.textTheme,
      MediaQuery.textScalerOf(tester.element(find.byType(HistoryStickyBar))),
    ).dayBar;
    // Bring the page to the point where the bar is pinned under the header.
    await _scroll(tester, 700);
    final barTop = _barTop(tester);
    // The header line of day 1 is a HistoryDayBar outside the pinned bar.
    final header = find
        .byType(HistoryDayBar)
        .evaluate()
        .map((e) => e.widget as HistoryDayBar)
        .where((b) => !_pinnedBars.evaluate().any((p) => p.widget == b))
        .toList();
    expect(header, isNotEmpty);
    // Move so the next header's top is 20 dp under the bar's top.
    final nextTop = tester.getTopLeft(find.byWidget(header.first)).dy;
    await _scroll(tester, nextTop - (barTop + 20));
    expect(_pinnedBars, findsNWidgets(2));
    expect(
      tester.getTopLeft(_pinnedBars.first).dy,
      closeTo(barTop + 20 - height, 0.01),
    );
    expect(tester.getTopLeft(_pinnedBars.last).dy, closeTo(barTop + 20, 0.01));
    expect(_pinnedLabels(tester), ['Hôm nay', 'Hôm qua']);
    // The header has covered the bar: the bar is that day, nothing pushed.
    await _scroll(tester, 20);
    expect(_pinnedBars, findsOneWidget);
    expect(_pinnedLabels(tester), ['Hôm qua']);
  });

  testWidgets('a play added on top while scrolled leaves the content where it '
      'was', (tester) async {
    final plays = playsOverDays([6, 6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    await _scroll(tester, 900);
    await tester.pump();
    final probe = find.text('Song 12');
    expect(probe, findsOneWidget);
    final before = tester.getTopLeft(probe).dy;
    final offsetBefore = _position(tester).pixels;

    // A new play (a new song) arrives and the year is read again.
    final fresh = playAt(99, DateTime(2026, 11, 20, 21), uid: 'p99');
    h.store.byYear = {
      2026: [fresh, ...plays],
    };
    h.store.playsChanged.add(const HistoryChange(inserted: true));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Song 12'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Song 12')).dy, closeTo(before, 0.01));
    // The offset moved by the height the new row brought.
    final row = KMediaCard.extentOf(
      MediaQuery.textScalerOf(tester.element(find.byType(SongTile).first)),
    );
    expect(_position(tester).pixels - offsetBefore, closeTo(row, 0.01));
  });

  testWidgets('at the top a new play simply appears first', (tester) async {
    final plays = playsOverDays([3, 3]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    final before = tester.getTopLeft(find.text('Song 1')).dy;
    final fresh = playAt(99, DateTime(2026, 11, 20, 21), uid: 'p99');
    h.store.byYear = {
      2026: [fresh, ...plays],
    };
    h.store.playsChanged.add(const HistoryChange(inserted: true));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Song 99'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Song 1')).dy, greaterThan(before));
  });
}
