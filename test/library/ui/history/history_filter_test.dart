import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/ui/history/history_day_bar.dart';
import 'package:kanaru/src/library/ui/history/history_filter.dart';
import 'package:kanaru/src/library/ui/history/history_row.dart';
import 'package:kanaru/src/library/ui/history/history_sticky_bar.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../../history/state/fake_history_store.dart' show info;
import 'history_page_harness.dart';

ScrollPosition _pos(WidgetTester t) =>
    Scrollable.of(t.element(find.byType(HistoryStickyBar))).position;

Future<void> _openFilter(WidgetTester tester) async {
  await tester.tap(byIconButton(l10nOf(tester).libraryFilter));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// [n] plays of distinct songs titled "Tune k", newest first, on 2026-11-20.
List<HistoryPlay> _many(int n, {String title = 'Tune'}) => [
  for (var i = 0; i < n; i++)
    playAt(
      i + 1,
      DateTime(2026, 11, 20).add(Duration(minutes: n - i)),
      track: info(i + 1, title: '$title ${i + 1}'),
    ),
];

void main() {
  testWidgets('the filter field says what it filters, in the shown year', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
    );
    expect(find.byType(KFilterField), findsNothing);
    await _openFilter(tester);
    expect(find.byType(KFilterField), findsOneWidget);
    expect(find.text('Lọc trong 2026'), findsOneWidget);
  });

  testWidgets('matches show as one flat list without day bars', (tester) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3, 3]),
      },
    );
    final l10n = l10nOf(tester);
    expect(find.byType(HistoryStickyBar), findsOneWidget);
    await _openFilter(tester);
    await _type(tester, 'song 4');
    expect(find.byType(HistoryStickyBar), findsNothing);
    expect(find.byType(HistoryDayBar), findsNothing);
    expect(find.text('Song 4'), findsOneWidget);
    expect(find.text('Song 3'), findsNothing);
    expect(find.text(l10n.historyFilterMatches(1)), findsOneWidget);
    expect(h.playback.calls, isEmpty);
  });

  testWidgets('a filter nothing matches says so', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
    );
    await _openFilter(tester);
    await _type(tester, 'zzz');
    expect(find.text('Không có lượt nghe nào khớp “zzz”.'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNothing);
  });

  testWidgets('shows at most 1000 rows and a line saying it is cut', (
    tester,
  ) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {2026: _many(1200)},
      height: 900,
    );
    await _openFilter(tester);
    await _type(tester, 'tune');
    final l10n = l10nOf(tester);
    final result = h.container
        .read(historyFilterProvider((year: 2026, query: 'tune')))
        .value!;
    expect(result.plays, hasLength(historyFilterCap));
    expect(result.matched, 1200);
    expect(result.capped, isTrue);
    expect(find.text(l10n.historyFilterMatches(1200)), findsOneWidget);
    final capped = find.text(l10n.historyFilterCapped(historyFilterCap));
    await tester.scrollUntilVisible(
      capped,
      4000,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    expect(capped, findsOneWidget);
    // The last listed play is the 1000th, not the 1200th.
    expect(find.text('Tune 1000'), findsOneWidget);
    expect(find.text('Tune 1001'), findsNothing);
  });

  testWidgets('a tap plays the matched songs from the one tapped', (
    tester,
  ) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([6]),
      },
    );
    await _openFilter(tester);
    await _type(tester, 'song');
    await tester.tap(find.text('Song 3'));
    await tester.pump();
    final call = h.playback.calls.single as PlayTracksCall;
    expect([for (final t in call.tracks) t.value], [1, 2, 3, 4, 5, 6]);
    expect(call.startIndex, 2);
    expect(call.context.kind, PlayContextKind.history);
  });

  testWidgets('closing the filter puts the timeline back where it was', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([8, 8, 8, 8]),
      },
    );
    // The hero is half scrolled away when the user types.
    await _openFilter(tester);
    _pos(tester).jumpTo(150);
    await tester.pump();
    final before = _pos(tester).pixels;
    expect(before, 150);
    await _type(tester, 'song 1');
    expect(find.byType(HistoryStickyBar), findsNothing);
    // The reader moves around the results; the timeline does not follow.
    Scrollable.of(tester.element(find.byType(HistoryFilterList))).position
        .jumpTo(0);
    await tester.pump();
    // Esc clears the text and closes the field.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KFilterField), findsNothing);
    expect(find.byType(HistoryStickyBar), findsOneWidget);
    expect(_pos(tester).pixels, closeTo(before, 0.01));
  });

  testWidgets('clearing the text alone also brings the timeline back', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([8, 8, 8, 8]),
      },
    );
    await _openFilter(tester);
    _pos(tester).jumpTo(150);
    await tester.pump();
    await _type(tester, 'song 2');
    await _type(tester, '');
    expect(find.byType(HistoryStickyBar), findsOneWidget);
    expect(find.byType(KFilterField), findsOneWidget);
    expect(_pos(tester).pixels, closeTo(150, 0.01));
  });

  testWidgets('switching year clears the query', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
        2025: [
          playAt(50, DateTime(2025, 6, 1, 12), uid: 'old'),
          playAt(51, DateTime(2025, 6, 1, 11), uid: 'old2'),
        ],
      },
    );
    await _openFilter(tester);
    await _type(tester, 'song 2');
    expect(find.byType(HistoryStickyBar), findsNothing);
    await tester.tap(find.widgetWithText(KChip, '2025'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Lọc trong 2025'), findsOneWidget);
    expect(find.byType(HistoryStickyBar), findsOneWidget);
    expect(find.text('Song 50'), findsOneWidget);
  });

  testWidgets('typing more waits for a pause, entering does not', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([3]),
      },
    );
    await _openFilter(tester);
    await _type(tester, 'song');
    expect(find.text('Song 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'song 1');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Song 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('Song 2'), findsNothing);
    expect(find.text('Song 1'), findsOneWidget);
  });
}
