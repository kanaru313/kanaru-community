import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_limit_picker.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/history/most_played_selection.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'most_played_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _openPicker(WidgetTester tester, String chip) async {
  await tester.tap(find.widgetWithText(KChip, chip));
  await tester.pumpAndSettle();
}

void main() {
  group('the number dialog', () {
    Future<void> openDialog(WidgetTester tester) async {
      await _openPicker(tester, 'Top 100');
      await tester.tap(find.widgetWithText(SelectionRow, 'Tuỳ chọn…'));
      await tester.pumpAndSettle();
    }

    FilledButton save(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Lưu'));

    testWidgets('a valid number: the helper stays, Lưu is on', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      expect(find.text('Từ 1 đến 1000 bài'), findsOneWidget);
      expect(find.text('Chỉ nhận số từ 1 đến 1000'), findsNothing);
      expect(save(tester).onPressed, isNotNull);
      expect(find.text('Số bài'), findsOneWidget);
    });

    for (final bad in ['0', '000', '1001', '9999']) {
      testWidgets('"$bad" shows the error in place of the helper and turns '
          'Lưu off', (tester) async {
        await pumpMostPlayed(tester, top: topList([topEntry(1)]));
        await openDialog(tester);
        await tester.enterText(find.byType(TextField), bad);
        await tester.pumpAndSettle();
        expect(find.text('Chỉ nhận số từ 1 đến 1000'), findsOneWidget);
        expect(find.text('Từ 1 đến 1000 bài'), findsNothing);
        expect(save(tester).onPressed, isNull);
      });
    }

    testWidgets('empty: the helper stays, no error, Lưu is off', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Từ 1 đến 1000 bài'), findsOneWidget);
      expect(find.text('Chỉ nhận số từ 1 đến 1000'), findsNothing);
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('digits only, at most four', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '1a2-3.4567');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1234',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('1 and 1000 are valid; Enter saves a valid number', (
      tester,
    ) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '1000');
      await tester.pump();
      expect(save(tester).onPressed, isNotNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(h.container.read(mostPlayedLimitProvider), 1000);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a repeated Enter saves once and keeps the page', (
      tester,
    ) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '42');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(h.container.read(mostPlayedLimitProvider), 42);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.widgetWithText(KChip, 'Top 42'), findsOneWidget);
    });

    testWidgets(
      'closing the page while the dialog is open ignores the result',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final show = ValueNotifier(true);
        addTearDown(show.dispose);
        final anchor = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildKanaruTheme(brightness: Brightness.light),
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: ValueListenableBuilder<bool>(
                valueListenable: show,
                builder: (_, visible, _) => visible
                    ? Consumer(
                        builder: (context, ref, _) => TextButton(
                          key: anchor,
                          onPressed: () => chooseMostPlayedLimit(
                            context,
                            ref,
                            anchor: anchor,
                          ),
                          child: const Text('open'),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(SelectionRow, 'Tuỳ chọn…'));
        await tester.pumpAndSettle();
        show.value = false;
        await tester.pump();
        await tester.enterText(find.byType(TextField), '7');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(container.read(mostPlayedLimitProvider), isNot(7));
      },
    );

    testWidgets('Enter on an invalid number does nothing', (tester) async {
      final h = await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '2000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(h.container.read(mostPlayedLimitProvider), 100);
    });

    testWidgets('Esc keeps the old number and the picker stays closed', (
      tester,
    ) async {
      final h = await pumpMostPlayed(
        tester,
        width: 1400,
        top: topList([topEntry(1)]),
      );
      await openDialog(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SelectionRow), findsNothing);
      expect(h.container.read(mostPlayedLimitProvider), 100);
    });
  });

  group('checkMostPlayedLimitText', () {
    test('empty, valid and out of range', () {
      expect(checkMostPlayedLimitText(''), MostPlayedLimitInput.empty);
      expect(checkMostPlayedLimitText('  '), MostPlayedLimitInput.empty);
      expect(checkMostPlayedLimitText('0'), MostPlayedLimitInput.outOfRange);
      expect(checkMostPlayedLimitText('1'), MostPlayedLimitInput.valid);
      expect(checkMostPlayedLimitText('0012'), MostPlayedLimitInput.valid);
      expect(checkMostPlayedLimitText('1000'), MostPlayedLimitInput.valid);
      expect(checkMostPlayedLimitText('1001'), MostPlayedLimitInput.outOfRange);
    });
  });
}
