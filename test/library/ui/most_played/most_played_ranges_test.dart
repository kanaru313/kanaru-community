import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/history/most_played_selection.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_page.dart';
import 'package:kanaru/src/library/ui/most_played/range_dialog/history_calendar_style.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'most_played_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// The chip labelled [label] is the chosen one.
bool _chosen(WidgetTester tester, String label) =>
    tester.widget<KChip>(find.widgetWithText(KChip, label)).selected;

Finder _day(int month, int day) =>
    find.byKey(historyDayCellKey(DateTime(2026, month, day)));

/// Taps the chip [label], scrolling the chip row to it first.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(KChip, label);
  await tester.ensureVisible(chip);
  await tester.pump();
  await tester.tap(chip);
}

bool _enabled(WidgetTester tester, String tooltip) =>
    tester.widget<KIconButton>(byIconButton(tooltip)).onPressed != null;

({int start, int end}) _window(DateTime first, DateTime lastExclusive) => (
  start: first.millisecondsSinceEpoch,
  end: lastExclusive.millisecondsSinceEpoch,
);

void main() {
  testWidgets('30 ngày is chosen at first; each preset can be chosen', (
    tester,
  ) async {
    final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
    for (final label in [
      'Hôm nay',
      '7 ngày',
      '30 ngày',
      '6 tháng',
      '1 năm',
      'Tất cả',
      'Tuỳ chọn…',
    ]) {
      expect(find.widgetWithText(KChip, label), findsOneWidget, reason: label);
    }
    expect(_chosen(tester, '30 ngày'), isTrue);
    expect(_chosen(tester, '7 ngày'), isFalse);

    await _tapChip(tester, '7 ngày');
    await _settle(tester);
    expect(_chosen(tester, '7 ngày'), isTrue);
    expect(_chosen(tester, '30 ngày'), isFalse);
    expect(
      h.container.read(mostPlayedRangeProvider).preset,
      MostPlayedPreset.days7,
    );
    // The list is read again for the week ending today.
    expect(
      h.store.topCalls.last,
      _window(DateTime(2026, 11, 14), DateTime(2026, 11, 21)),
    );

    await _tapChip(tester, 'Tất cả');
    await _settle(tester);
    expect(h.store.topCalls.last, isNull, reason: 'all time has no window');
    expect(find.text('Tất cả'), findsWidgets);
  });

  testWidgets('the range and the number are kept when the page is left and '
      'opened again', (tester) async {
    final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
    await _tapChip(tester, '6 tháng');
    await _settle(tester);
    h.container.read(mostPlayedLimitProvider.notifier).set(250);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MostPlayedPage()),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_chosen(tester, '6 tháng'), isTrue);
    expect(_chosen(tester, '30 ngày'), isFalse);
    expect(find.text('Top 250'), findsOneWidget);
  });

  group('period row', () {
    testWidgets('Kỳ trước and Kỳ sau step a whole period; Kỳ sau is off at '
        'today', (tester) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      expect(find.text('22/10 – 20/11/2026'), findsOneWidget);
      expect(_enabled(tester, 'Kỳ trước'), isTrue);
      expect(_enabled(tester, 'Kỳ sau'), isFalse);

      await tester.tap(byIconButton('Kỳ trước'));
      await _settle(tester);
      expect(find.text('22/09 – 21/10/2026'), findsOneWidget);
      expect(_enabled(tester, 'Kỳ sau'), isTrue);
      expect(
        h.store.topCalls.last,
        _window(DateTime(2026, 9, 22), DateTime(2026, 10, 22)),
      );

      await tester.tap(byIconButton('Kỳ sau'));
      await _settle(tester);
      expect(find.text('22/10 – 20/11/2026'), findsOneWidget);
      expect(_enabled(tester, 'Kỳ sau'), isFalse);
    });

    testWidgets('Tất cả has no arrows', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await _tapChip(tester, 'Tất cả');
      await _settle(tester);
      expect(byIconButton('Kỳ trước'), findsNothing);
      expect(byIconButton('Kỳ sau'), findsNothing);
    });

    testWidgets('choosing a preset starts at its current period again', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await tester.tap(byIconButton('Kỳ trước'));
      await _settle(tester);
      await _tapChip(tester, '7 ngày');
      await _settle(tester);
      expect(find.text('14/11 – 20/11/2026'), findsOneWidget);
      expect(_enabled(tester, 'Kỳ sau'), isFalse);
    });
  });

  group('Tuỳ chọn…', () {
    Future<void> openDialog(WidgetTester tester) async {
      await _tapChip(tester, 'Tuỳ chọn…');
      await _settle(tester);
    }

    testWidgets('Lưu selects the chip and the hero and the period read the '
        'span; Kỳ trước shifts by its length', (tester) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.tap(_day(11, 3));
      await tester.pump();
      await tester.tap(_day(11, 7));
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await _settle(tester);

      expect(_chosen(tester, 'Tuỳ chọn…'), isTrue);
      expect(_chosen(tester, '30 ngày'), isFalse);
      // The span shows in the period row and as the hero's second line.
      expect(find.text('03/11 – 07/11/2026'), findsNWidgets(2));
      expect(
        h.store.topCalls.last,
        _window(DateTime(2026, 11, 3), DateTime(2026, 11, 8)),
      );

      await tester.tap(byIconButton('Kỳ trước'));
      await _settle(tester);
      expect(find.text('29/10 – 02/11/2026'), findsWidgets);
    });

    testWidgets('Huỷ keeps the chip that was chosen', (tester) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await _tapChip(tester, '7 ngày');
      await _settle(tester);
      await openDialog(tester);
      await tester.tap(_day(11, 3));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          TextButton,
          MaterialLocalizations.of(tester.element(find.byType(MostPlayedPage)))
              .cancelButtonLabel,
        ),
      );
      await _settle(tester);
      expect(_chosen(tester, '7 ngày'), isTrue);
      expect(_chosen(tester, 'Tuỳ chọn…'), isFalse);
      expect(
        h.container.read(mostPlayedRangeProvider).preset,
        MostPlayedPreset.days7,
      );
    });

    testWidgets('reopened, it starts on the range in use', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.tap(_day(11, 3));
      await tester.pump();
      await tester.tap(_day(11, 7));
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await _settle(tester);
      await openDialog(tester);
      expect(find.text('03/11 – 07/11/2026'), findsWidgets);
      expect(find.text('5 ngày'), findsOneWidget);
    });

    testWidgets('no play at all: the chip is dim and does nothing', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList(const []), hasPlays: false);
      await _tapChip(tester, 'Tuỳ chọn…');
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('the chips scroll sideways on a narrow phone at 2.0x', (
    tester,
  ) async {
    await pumpMostPlayed(
      tester,
      width: 320,
      textScale: 2,
      top: topList([topEntry(1)]),
    );
    expect(tester.takeException(), isNull);
    final row = find.byType(SingleChildScrollView).first;
    expect(
      tester.widget<SingleChildScrollView>(row).scrollDirection,
      Axis.horizontal,
    );
    await tester.drag(row, const Offset(-300, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
