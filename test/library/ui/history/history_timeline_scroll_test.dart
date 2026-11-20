import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/library/ui/history/history_day_bar.dart';
import 'package:kanaru/src/library/ui/history/history_row.dart';
import 'package:kanaru/src/library/ui/history/history_sticky_bar.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:material_ui/material_ui.dart';

import 'history_page_harness.dart';

ScrollPosition _pos(WidgetTester t) =>
    Scrollable.of(t.element(find.byType(HistoryHero))).position;

double _barBottom(WidgetTester t) =>
    t.getBottomLeft(find.byType(HistoryStickyBar)).dy;

Future<void> _arrive(
  WidgetTester t,
  HistoryHarness h,
  List<dynamic> plays, {
  HistoryChange change = const HistoryChange(inserted: true),
}) async {
  h.store.byYear = {2026: List.of(plays.cast())};
  h.store.playsChanged.add(change);
  await t.runAsync(() => Future<void>.delayed(Duration.zero));
  await t.pump(const Duration(seconds: 1));
  await t.pump();
}

void main() {
  testWidgets('the first play of a new day keeps the content in place', (
    tester,
  ) async {
    final plays = playsOverDays([0, 6, 6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    _pos(tester).jumpTo(_pos(tester).pixels + 900);
    await tester.pump();
    final before = tester.getTopLeft(find.text('Song 10')).dy;
    await _arrive(tester, h, [
      playAt(99, DateTime(2026, 11, 20, 21), uid: 'p99'),
      ...plays,
    ]);
    expect(tester.getTopLeft(find.text('Song 10')).dy, closeTo(before, 0.01));
  });

  testWidgets('several plays in one read keep the content in place', (
    tester,
  ) async {
    final plays = playsOverDays([6, 6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    _pos(tester).jumpTo(_pos(tester).pixels + 900);
    await tester.pump();
    final before = tester.getTopLeft(find.text('Song 12')).dy;
    await _arrive(tester, h, [
      for (var i = 0; i < 3; i++)
        playAt(90 + i, DateTime(2026, 11, 20, 23 - i), uid: 'n$i'),
      ...plays,
    ]);
    expect(tester.getTopLeft(find.text('Song 12')).dy, closeTo(before, 0.01));
  });

  testWidgets('scrolled under the bar by less than its height still holds', (
    tester,
  ) async {
    final plays = playsOverDays([6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    // Bring the page to where the first row is 20 dp under the pinned bar.
    final p = _pos(tester);
    final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    p.jumpTo(
      p.pixels +
          tester.getTopLeft(find.byType(HistoryStickyBar)).dy -
          viewportTop +
          20,
    );
    await tester.pump();
    final before = tester.getTopLeft(find.text('Song 3')).dy;
    await _arrive(tester, h, [
      playAt(99, DateTime(2026, 11, 20, 21), uid: 'p99'),
      ...plays,
    ]);
    expect(tester.getTopLeft(find.text('Song 3')).dy, closeTo(before, 0.01));
  });

  testWidgets('plays removed above the viewport keep the content in place', (
    tester,
  ) async {
    final plays = playsOverDays([6, 6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    _pos(tester).jumpTo(_pos(tester).pixels + 900);
    await tester.pump();
    final before = tester.getTopLeft(find.text('Song 12')).dy;
    await _arrive(
      tester,
      h,
      plays.skip(3).toList(),
      change: const HistoryChange(removed: true),
    );
    expect(tester.getTopLeft(find.text('Song 12')).dy, closeTo(before, 0.01));
  });

  testWidgets('one read that drops the first play and adds new ones holds '
      'the content', (tester) async {
    final plays = playsOverDays([6, 6, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays});
    _pos(tester).jumpTo(_pos(tester).pixels + 900);
    await tester.pump();
    final before = tester.getTopLeft(find.text('Song 12')).dy;
    await _arrive(tester, h, [
      playAt(99, DateTime(2026, 11, 20, 21), uid: 'p99'),
      ...plays.skip(1),
    ], change: const HistoryChange(inserted: true, removed: true));
    expect(tester.getTopLeft(find.text('Song 12')).dy, closeTo(before, 0.01));
  });

  testWidgets('a year opened from the footer lands on its first day bar', (
    tester,
  ) async {
    final y25 = [
      for (var i = 0; i < 40; i++)
        playAt(
          500 + i,
          DateTime(2025, 6, 30 - (i ~/ 5), 20 - (i % 5)),
          uid: 'q$i',
        ),
    ];
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([6, 6, 6]),
        2025: y25,
      },
      height: 700,
    );
    // The older year is already in memory: the switch is immediate.
    final keep = h.container.listen(historyYearProvider(2025), (_, _) {});
    addTearDown(keep.close);
    await tester.runAsync(
      () => h.container.read(historyYearProvider(2025).future),
    );
    final p = _pos(tester);
    p.jumpTo(p.maxScrollExtent);
    await tester.pump();
    await tester.tap(find.text('Xem năm 2025'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HistoryStickyBar),
        matching: find.text('30/06'),
      ),
      findsOneWidget,
    );
    // The first row of the new year sits right under the pinned bar.
    expect(
      tester
          .getTopLeft(
            find.ancestor(
              of: find.text('Song 500'),
              matching: find.byType(HistoryRow),
            ),
          )
          .dy,
      closeTo(_barBottom(tester), 1),
    );
  });

  testWidgets('the bar stays right when the notice above folds away', (
    tester,
  ) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([6, 6, 6]),
      },
      recording: false,
      animations: false,
      height: 500,
    );
    final p = _pos(tester);
    p.jumpTo(p.pixels + 600);
    await tester.pump();
    // Recording comes back on (from Settings, say): the strip above folds.
    await h.container.read(historyEnabledProvider.notifier).set(true);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump();
    // The day on the pinned bar is the day of the first row under it.
    final under = find
        .byType(HistoryRow)
        .evaluate()
        .where(
          (e) =>
              (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy +
                  80 >
              _barBottom(tester) + 1,
        )
        .map((e) => (e.widget as HistoryRow).play.track.id.value)
        .first;
    final day = under <= 6
        ? 'Hôm nay'
        : under <= 12
        ? 'Hôm qua'
        : 'Thứ Tư';
    expect(
      find.descendant(
        of: find.byType(HistoryStickyBar),
        matching: find.text(day),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the bar and a header line are one rendered height, with long '
      'text at 2.0 on a narrow screen', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2, 2]),
      },
      textScale: 2,
      width: 320,
      height: 3000,
    );
    final bars = find.byType(HistoryDayBar);
    expect(bars, findsNWidgets(2));
    expect(tester.getSize(bars.first).height, tester.getSize(bars.last).height);
    for (final bar in bars.evaluate()) {
      final column = find.descendant(
        of: find.byElementPredicate((e) => e == bar),
        matching: find.byType(Column),
      );
      expect(
        tester.getSize(column.first).height,
        lessThanOrEqualTo(tester.getSize(bars.first).height),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a big removal above the reader never scrolls past the top', (
    tester,
  ) async {
    final plays = playsOverDays([14, 6]);
    final h = await pumpHistoryPage(tester, byYear: {2026: plays}, height: 700);
    final p = _pos(tester);
    p.jumpTo(p.pixels + 700);
    await tester.pump();
    await _arrive(
      tester,
      h,
      plays.skip(12).toList(),
      change: const HistoryChange(removed: true),
    );
    expect(p.pixels, greaterThanOrEqualTo(p.minScrollExtent));
  });
}
