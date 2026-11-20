import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/history/history_calendar_dialog.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';

/// Plays per day from `[year, month, day]` or `[year, month, day, plays]`.
Map<DateTime, int> _days(List<List<int>> days) => {
  for (final d in days) DateTime(d[0], d[1], d[2]): d.length > 3 ? d[3] : 1,
};

Finder _cell(int day) => find.byKey(ValueKey('history-calendar-day-$day'));

bool _enabled(WidgetTester tester, int day) => isSemantics(
  isEnabled: true,
  isButton: true,
).matches(tester.getSemantics(_cell(day)), {});

bool _buttonOn(WidgetTester tester, String tooltip) =>
    isSemantics(isEnabled: true)
        .matches(tester.getSemantics(byIconButton(tooltip)), {});

/// Opens the dialog from a button and collects what it picked.
Future<void> _open(
  WidgetTester tester, {
  required int year,
  required Map<DateTime, int> plays,
  required List<DateTime?> picked,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      locale: locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked.add(
            await showHistoryCalendar(context, year: year, plays: plays),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the month of the latest play, others are off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 10, 23],
        [2026, 10, 10, 3],
        [2026, 8, 1],
      ]),
      picked: [],
    );

    expect(find.text('October 2026'), findsOneWidget);
    expect(_enabled(tester, 23), isTrue);
    expect(_enabled(tester, 10), isTrue);
    expect(_enabled(tester, 11), isFalse);
    expect(_enabled(tester, 1), isFalse);
    // October has 31 days, no more.
    expect(_cell(31), findsOneWidget);
    expect(_cell(32), findsNothing);
    handle.dispose();
  });

  testWidgets('a day is read out with its date and how many plays', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 10, 10, 3],
      ]),
      picked: [],
    );

    expect(
      find.bySemanticsLabel('Saturday, October 10, 2026, 3 plays'),
      findsOneWidget,
    );
    // A day without plays reads only its date.
    expect(find.bySemanticsLabel('Sunday, October 11, 2026'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('days sit under their weekday, the week starting on Sunday', (
    tester,
  ) async {
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 10, 23],
      ]),
      picked: [],
    );

    double dx(int day) => tester.getCenter(_cell(day)).dx;
    double dy(int day) => tester.getCenter(_cell(day)).dy;
    // 2026-10-01 is a Thursday; the 4th, 11th, 18th and 25th are Sundays.
    expect(dx(1), dx(8));
    expect(dx(4), dx(11));
    expect(dx(4), lessThan(dx(1)));
    expect(dy(4), greaterThan(dy(1)));
    expect(dy(1), dy(3));
  });

  testWidgets('February of a leap year has 29 days', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      year: 2024,
      plays: _days([
        [2024, 2, 29],
      ]),
      picked: [],
    );

    expect(find.text('February 2024'), findsOneWidget);
    expect(_enabled(tester, 29), isTrue);
    expect(_cell(30), findsNothing);
    handle.dispose();
  });

  testWidgets('months step within the year only', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 12, 20],
        [2026, 1, 5],
      ]),
      picked: [],
    );

    expect(find.text('December 2026'), findsOneWidget);
    expect(_buttonOn(tester, 'Next month'), isFalse);
    expect(_buttonOn(tester, 'Previous month'), isTrue);
    for (var i = 0; i < 11; i++) {
      await tester.tap(byIconButton('Previous month'));
      await tester.pump();
    }
    expect(find.text('January 2026'), findsOneWidget);
    expect(_buttonOn(tester, 'Previous month'), isFalse);
    expect(_buttonOn(tester, 'Next month'), isTrue);
    expect(_enabled(tester, 5), isTrue);
    handle.dispose();
  });

  testWidgets('picking a day with plays closes the dialog with it', (
    tester,
  ) async {
    final picked = <DateTime?>[];
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 10, 23],
        [2026, 10, 10],
      ]),
      picked: picked,
    );

    await tester.tap(_cell(11), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    expect(find.byType(HistoryCalendar), findsOneWidget);

    await tester.tap(_cell(10));
    await tester.pumpAndSettle();

    expect(picked, [DateTime(2026, 10, 10)]);
    expect(find.byType(HistoryCalendar), findsNothing);
  });

  testWidgets('closing without a pick returns nothing', (tester) async {
    final picked = <DateTime?>[];
    await _open(
      tester,
      year: 2026,
      plays: _days([
        [2026, 10, 23],
      ]),
      picked: picked,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(picked, [null]);
  });

  testWidgets('with no plays it opens on January, every day off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, year: 2026, plays: const {}, picked: []);

    expect(find.text('January 2026'), findsOneWidget);
    expect(_enabled(tester, 1), isFalse);
    expect(_enabled(tester, 31), isFalse);
    handle.dispose();
  });
}
