import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/history/history_store.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/most_played/range_dialog/history_calendar_style.dart';
import 'package:kanaru/src/library/ui/most_played/range_dialog/history_range_dialog.dart';
import 'package:kanaru/src/library/ui/most_played/range_dialog/history_range_dialog_header.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/icon_button_finders.dart';
import '../../../history/state/fake_history_store.dart';

/// A store whose days with plays are [days], answered for the asked window.
class _DaysStore extends FakeHistoryStore {
  _DaysStore(this.days);

  final List<DateTime> days;
  Object? error;

  @override
  Future<Set<DateTime>> playDays(int start, int end) async {
    final failure = error;
    if (failure != null) throw failure;
    return {
      for (final d in days)
        if (d.millisecondsSinceEpoch >= start && d.millisecondsSinceEpoch < end)
          DateTime(d.year, d.month, d.day),
    };
  }
}

/// A store whose first and last play cannot be read ([fail]) or do not exist.
class _BoundsStore extends _DaysStore {
  _BoundsStore({required this.fail}) : super(const []);

  final bool fail;

  @override
  Future<({int first, int last})?> playedRange() async {
    if (fail) throw StateError('db');
    return null;
  }
}

Finder _day(int month, int day, {int year = 2026}) =>
    find.byKey(historyDayCellKey(DateTime(year, month, day)));

HistoryDayCell _cell(WidgetTester tester, int month, int day) =>
    tester.widget<HistoryDayCell>(
      find.ancestor(
        of: _day(month, day),
        matching: find.byType(HistoryDayCell),
      ),
    );

class _Opened {
  /// What the dialog returned; one entry per time it closed.
  final results = <HistoryDayRange?>[];
}

/// Opens the dialog from a button over a store with plays on [plays], the
/// first of them on [firstPlay].
Future<_Opened> _open(
  WidgetTester tester, {
  List<DateTime> plays = const [],
  DateTime? firstPlay,
  HistoryDayRange? initial,
  Locale locale = const Locale('en'),
  double textScale = 1,
  FakeHistoryStore? store,
}) async {
  final fake = store ?? _DaysStore(plays);
  fake.played = (
    first: (firstPlay ?? DateTime(2026, 9, 10, 8)).millisecondsSinceEpoch,
    last: DateTime(2026, 10, 1).millisecondsSinceEpoch,
  );
  final opened = _Opened();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        historyStoreProvider.overrideWithValue(fake as HistoryStore),
        historyClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 23, 12),
        ),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => opened.results.add(
                await showHistoryRangeDialog(context, initial: initial),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _tapDay(WidgetTester tester, int month, int day) async {
  await tester.tap(_day(month, day));
  await tester.pumpAndSettle();
}

Future<void> _page(WidgetTester tester, String tooltip) async {
  await tester.tap(byIconButton(tooltip));
  await tester.pumpAndSettle();
}

/// Moves focus to the button around [inside], as a Tab would.
Future<void> _focusButton(WidgetTester tester, Finder inside) async {
  Focus.of(tester.element(inside)).requestFocus();
  await tester.pump();
}

void main() {
  testWidgets('opens on today\'s month with one dialog, six rows', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Pick the start date'), findsOneWidget);
    expect(find.text('Start date – End date'), findsOneWidget);
    // Six weeks: Sep 27 to Nov 7 are all in the grid.
    expect(_day(9, 27), findsOneWidget);
    expect(_day(11, 7), findsOneWidget);
    expect(_day(11, 8), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('days after today and before the first play are off', (
    tester,
  ) async {
    await _open(tester);

    expect(_cell(tester, 10, 24).isDisabled, isTrue);
    expect(_cell(tester, 10, 23).isDisabled, isFalse);
    expect(_cell(tester, 9, 27).isDisabled, isFalse);
    await _tapDay(tester, 10, 24);
    expect(find.text('Pick the start date'), findsOneWidget);
    await _tapDay(tester, 10, 23);
    expect(find.text('Pick the end date'), findsOneWidget);

    await _page(tester, 'Previous month');
    expect(_cell(tester, 9, 9).isDisabled, isTrue);
    expect(_cell(tester, 9, 10).isDisabled, isFalse);
    await _tapDay(tester, 9, 9);
    // The tap on the disabled day changed nothing.
    expect(find.text('23/10/2026 – End date'), findsOneWidget);
    expect(find.text('Pick the end date'), findsOneWidget);
  });

  testWidgets('dots are on days with plays, by local day', (tester) async {
    await _open(
      tester,
      plays: [
        DateTime(2026, 10, 5, 14),
        DateTime(2026, 10, 5, 2),
        // Edges of a local day: the last minute of Sep 30 and the first of Oct 1.
        DateTime(2026, 9, 30, 23, 59),
        DateTime(2026, 10, 1),
      ],
    );

    final dotted = [
      for (var d = 1; d <= 23; d++)
        if (_cell(tester, 10, d).hasPlays) d,
    ];
    expect(dotted, [1, 5]);
    // Sep 30 shows in the October grid as a faded day, with its own dot.
    expect(_cell(tester, 9, 30).hasPlays, isTrue);
    expect(_cell(tester, 9, 29).hasPlays, isFalse);
  });

  testWidgets('dots follow the month in view', (tester) async {
    await _open(tester, plays: [DateTime(2026, 9, 15, 9)]);

    expect(_cell(tester, 10, 5).hasPlays, isFalse);
    await _page(tester, 'Previous month');
    expect(find.text('September 2026'), findsOneWidget);
    expect(_cell(tester, 9, 15).hasPlays, isTrue);
    expect(_cell(tester, 9, 14).hasPlays, isFalse);
  });

  testWidgets('a failed read of the days leaves the dialog usable', (
    tester,
  ) async {
    final store = _DaysStore([DateTime(2026, 10, 5, 9)])
      ..error = StateError('disk');
    await _open(tester, store: store);

    expect(_cell(tester, 10, 5).hasPlays, isFalse);
    await _tapDay(tester, 10, 10);
    await _tapDay(tester, 10, 12);
    expect(find.text('10/10 – 12/10/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('start, end, an earlier day restarts, a later one ends', (
    tester,
  ) async {
    await _open(tester);

    await _tapDay(tester, 10, 10);
    expect(find.text('10/10/2026 – End date'), findsOneWidget);
    await _tapDay(tester, 10, 14);
    expect(find.text('10/10 – 14/10/2026'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    expect(_cell(tester, 10, 10).isEdge, isTrue);
    expect(_cell(tester, 10, 14).isEdge, isTrue);
    expect(_cell(tester, 10, 12).isEdge, isFalse);

    // A third tap starts over.
    await _tapDay(tester, 10, 6);
    expect(find.text('06/10/2026 – End date'), findsOneWidget);
    // Before the start: the start moves and there is still no end.
    await _tapDay(tester, 10, 3);
    expect(find.text('03/10/2026 – End date'), findsOneWidget);
    await _tapDay(tester, 10, 3);
    expect(find.text('03/10/2026'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
  });

  testWidgets('Save is off until both days are picked', (tester) async {
    final opened = await _open(tester);

    TextButton save() =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(save().onPressed, isNull);
    await _tapDay(tester, 10, 10);
    expect(save().onPressed, isNull);
    await _tapDay(tester, 10, 12);
    expect(save().onPressed, isNotNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(opened.results, [
      (start: DateTime(2026, 10, 10), end: DateTime(2026, 10, 12)),
    ]);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the selection survives paging to another month', (tester) async {
    final opened = await _open(tester);

    // Sep 28 shows faded in the October grid; tapping it selects it and pages.
    await _tapDay(tester, 9, 28);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('28/09/2026 – End date'), findsOneWidget);
    await _page(tester, 'Next month');
    expect(find.text('October 2026'), findsOneWidget);
    expect(_cell(tester, 9, 28).isEdge, isTrue);
    await _tapDay(tester, 10, 3);
    expect(find.text('28/09 – 03/10/2026'), findsOneWidget);
    expect(find.text('6 days'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.results, [
      (start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 3)),
    ]);
  });

  testWidgets('the arrows stop at the first play and at today', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    bool on(String tooltip) =>
        isSemantics(isEnabled: true)
            .matches(tester.getSemantics(byIconButton(tooltip)), {});
    expect(on('Next month'), isFalse);
    expect(on('Previous month'), isTrue);
    await _page(tester, 'Previous month');
    expect(on('Previous month'), isFalse);
    expect(on('Next month'), isTrue);
    handle.dispose();
  });

  testWidgets('Cancel and Esc keep nothing', (tester) async {
    final opened = await _open(tester);

    await _tapDay(tester, 10, 10);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(opened.results, [null]);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(opened.results, [null, null]);
  });

  testWidgets('Enter on Cancel cancels, on an arrow pages', (tester) async {
    final opened = await _open(tester);
    await _tapDay(tester, 10, 10);
    await _tapDay(tester, 10, 12);

    await _focusButton(tester, find.byIcon(KIcons.chevronLeft));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(opened.results, isEmpty);

    await _focusButton(tester, find.text('Cancel'));
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    await tester.pumpAndSettle();
    expect(opened.results, [null]);
  });

  testWidgets('numpad Enter saves when no button has the focus', (
    tester,
  ) async {
    final opened = await _open(tester);
    await _tapDay(tester, 10, 10);
    await _tapDay(tester, 10, 12);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    await tester.pumpAndSettle();
    expect(opened.results, [
      (start: DateTime(2026, 10, 10), end: DateTime(2026, 10, 12)),
    ]);
  });

  testWidgets('rapid paging does not throw and keeps the dots right', (
    tester,
  ) async {
    await _open(
      tester,
      plays: [DateTime(2026, 9, 15, 9), DateTime(2026, 10, 5, 9)],
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(byIconButton('Previous month'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(byIconButton('Next month'));
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.tap(byIconButton('Previous month'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('September 2026'), findsOneWidget);
    expect(_cell(tester, 9, 15).hasPlays, isTrue);
    expect(_cell(tester, 9, 14).hasPlays, isFalse);
    // Oct 5 is in the September grid's last row as a faded day.
    expect(_cell(tester, 10, 5).hasPlays, isTrue);
  });

  testWidgets('a day reads as a button with state and a listens cue', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, plays: [DateTime(2026, 10, 5, 9)]);
    await _tapDay(tester, 10, 10);

    SemanticsData of(int month, int day) =>
        tester.getSemantics(_day(month, day)).getSemanticsData();

    final played = of(10, 5);
    expect(played.label, contains('Monday, October 5, 2026'));
    expect(played.label, contains('Has listens'));
    expect(played.flagsCollection.isButton, isTrue);
    expect(played.flagsCollection.isEnabled, Tristate.isTrue);
    expect(played.flagsCollection.isSelected, Tristate.isFalse);

    final plain = of(10, 6);
    expect(plain.label, isNot(contains('Has listens')));

    final picked = of(10, 10);
    expect(picked.flagsCollection.isSelected, Tristate.isTrue);

    final off = of(10, 24);
    expect(off.flagsCollection.isButton, isTrue);
    expect(off.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('opens with the initial range on its end month', (tester) async {
    await _open(
      tester,
      initial: (start: DateTime(2026, 9, 12), end: DateTime(2026, 9, 20)),
    );

    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('12/09 – 20/09/2026'), findsOneWidget);
    expect(find.text('9 days'), findsOneWidget);
  });

  testWidgets('a failed read of the bounds shows a toast and returns null', (
    tester,
  ) async {
    final opened = await _open(tester, store: _BoundsStore(fail: true));

    expect(opened.results, [null]);
    expect(find.text('Could not load the list'), findsOneWidget);
    expect(find.byType(HistoryRangePicker), findsNothing);
  });

  testWidgets('no plays at all returns null without a toast', (tester) async {
    final opened = await _open(tester, store: _BoundsStore(fail: false));

    expect(opened.results, [null]);
    expect(find.text('Could not load the list'), findsNothing);
    expect(find.byType(HistoryRangePicker), findsNothing);
  });

  testWidgets('an initial range outside the bounds is cut to them', (
    tester,
  ) async {
    await _open(
      tester,
      initial: (start: DateTime(2026, 8, 1), end: DateTime(2026, 12, 31)),
    );

    // First play 10 Sep; the last day is today (23 Oct).
    expect(find.text('10/09 – 23/10/2026'), findsOneWidget);
  });

  testWidgets('English weeks start on Sunday', (tester) async {
    await _open(tester);

    // October 2026 starts on a Thursday; the grid begins on Sep 27.
    expect(_day(9, 27), findsOneWidget);
    expect(
      tester.getTopLeft(_day(9, 27)).dx,
      tester.getTopLeft(_day(10, 4)).dx,
    );
  });

  testWidgets('Vietnamese weeks start on Monday, with its texts', (
    tester,
  ) async {
    await _open(tester, locale: const Locale('vi'));

    expect(_day(9, 27), findsNothing);
    expect(
      tester.getTopLeft(_day(9, 28)).dx,
      tester.getTopLeft(_day(10, 5)).dx,
    );
    expect(find.text('Khoảng tuỳ chọn'), findsOneWidget);
    expect(find.text('Chọn ngày bắt đầu'), findsOneWidget);
    expect(find.text('Ngày bắt đầu – Ngày kết thúc'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
  });

  group('header block', () {
    testWidgets('each state shows its placeholders, hint and day count', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Custom range'), findsOneWidget);
      expect(find.text('Start date – End date'), findsOneWidget);
      expect(find.text('Pick the start date'), findsOneWidget);

      await _tapDay(tester, 10, 10);
      expect(find.text('10/10/2026 – End date'), findsOneWidget);
      expect(find.text('Pick the end date'), findsOneWidget);

      await _tapDay(tester, 10, 14);
      expect(find.text('10/10 – 14/10/2026'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('Pick the end date'), findsNothing);

      await _tapDay(tester, 10, 14);
      await _tapDay(tester, 10, 14);
      expect(find.text('14/10/2026'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('a range across two years writes both years', (tester) async {
      await _open(
        tester,
        firstPlay: DateTime(2025, 12, 1),
        initial: (start: DateTime(2025, 12, 28), end: DateTime(2026, 1, 3)),
      );

      expect(find.text('28/12/2025 – 03/01/2026'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('stays on one line and keeps the height at 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(
        tester,
        textScale: 2,
        firstPlay: DateTime(2025, 12, 1),
        initial: (start: DateTime(2025, 12, 28), end: DateTime(2026, 1, 3)),
      );

      Size dialog() => tester.getSize(find.byType(HistoryRangePicker));
      Size header() => tester.getSize(find.byType(HistoryRangeDialogHeader));
      expect(dialog().width, 332);
      final full = (dialog(), header());

      await _tapDay(tester, 1, 3);
      expect(find.text('03/01/2026 – End date'), findsOneWidget);
      expect((dialog(), header()), full);

      await _tapDay(tester, 1, 3);
      await _tapDay(tester, 1, 3);
      expect((dialog(), header()), full);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is one polite live region with the whole sentence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester);

      final empty = tester.getSemantics(
        find.bySemanticsLabel('Start date – End date, Pick the start date'),
      );
      expect(empty.getSemanticsData().flagsCollection.isLiveRegion, isTrue);

      await _tapDay(tester, 10, 10);
      await _tapDay(tester, 10, 14);
      final full = tester.getSemantics(
        find.bySemanticsLabel('10/10 – 14/10/2026, 5 days'),
      );
      expect(full.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });
}
