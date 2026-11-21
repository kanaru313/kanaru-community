import 'package:flutter_test/flutter_test.dart';
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

/// The picker's row titled [title] is the chosen one.
bool _chosen(WidgetTester tester, String title) => tester
    .widget<SelectionRow>(find.widgetWithText(SelectionRow, title))
    .selected;

void main() {
  for (final shell in [
    ('mobile dropdown', 400.0),
    ('desktop dropdown', 1400.0),
  ]) {
    group(shell.$1, () {
      testWidgets('lists the presets and Tuỳ chọn…, the current one chosen', (
        tester,
      ) async {
        await pumpMostPlayed(
          tester,
          width: shell.$2,
          top: topList([topEntry(1)]),
        );
        await _openPicker(tester, 'Top 100');
        for (final t in ['Top 5', 'Top 10', 'Top 50', 'Top 100']) {
          expect(find.widgetWithText(SelectionRow, t), findsOneWidget);
        }
        // Both shells show the anchored dropdown, never a sheet.
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(CustomSingleChildLayout), findsWidgets);
        expect(_chosen(tester, 'Top 100'), isTrue);
        expect(_chosen(tester, 'Top 5'), isFalse);
        expect(find.widgetWithText(SelectionRow, 'Tuỳ chọn…'), findsOneWidget);
        expect(find.text('Từ 1 đến 1000 bài'), findsOneWidget);
        expect(_chosen(tester, 'Tuỳ chọn…'), isFalse);
      });

      testWidgets('a preset sets the number, reads the list again and shows '
          'in the chip', (tester) async {
        final h = await pumpMostPlayed(
          tester,
          width: shell.$2,
          top: topList([topEntry(1)]),
        );
        await _openPicker(tester, 'Top 100');
        await tester.tap(find.widgetWithText(SelectionRow, 'Top 10'));
        await _settle(tester);
        expect(h.container.read(mostPlayedLimitProvider), 10);
        expect(h.store.topLimits.last, 10);
        expect(find.widgetWithText(KChip, 'Top 10'), findsOneWidget);
        expect(find.byType(SelectionRow), findsNothing);
      });

      testWidgets('a number outside the presets selects Tuỳ chọn… and shows '
          'itself', (tester) async {
        final h = await pumpMostPlayed(
          tester,
          width: shell.$2,
          top: topList([topEntry(1)]),
        );
        h.container.read(mostPlayedLimitProvider.notifier).set(250);
        await _settle(tester);
        await _openPicker(tester, 'Top 250');
        expect(_chosen(tester, 'Tuỳ chọn…'), isTrue);
        expect(find.text('Top 250 · từ 1 đến 1000 bài'), findsOneWidget);
        for (final t in ['Top 5', 'Top 10', 'Top 50', 'Top 100']) {
          expect(_chosen(tester, t), isFalse, reason: t);
        }
      });

      testWidgets('Tuỳ chọn… closes the picker, then the dialog opens '
          'prefilled; Lưu sets the number', (tester) async {
        final h = await pumpMostPlayed(
          tester,
          width: shell.$2,
          top: topList([topEntry(1)]),
        );
        await _openPicker(tester, 'Top 100');
        await tester.tap(find.widgetWithText(SelectionRow, 'Tuỳ chọn…'));
        await tester.pumpAndSettle();
        expect(find.byType(SelectionRow), findsNothing);
        expect(find.text('Số bài xếp hạng'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '100',
        );
        await tester.enterText(find.byType(TextField), '250');
        await tester.pump();
        await tester.tap(find.text('Lưu'));
        await _settle(tester);
        expect(h.container.read(mostPlayedLimitProvider), 250);
        expect(find.widgetWithText(KChip, 'Top 250'), findsOneWidget);
        expect(h.store.topLimits.last, 250);
      });

      testWidgets('Huỷ in the dialog keeps the old number and does not bring '
          'the picker back', (tester) async {
        final h = await pumpMostPlayed(
          tester,
          width: shell.$2,
          top: topList([topEntry(1)]),
        );
        h.container.read(mostPlayedLimitProvider.notifier).set(50);
        await _settle(tester);
        await _openPicker(tester, 'Top 50');
        await tester.tap(find.widgetWithText(SelectionRow, 'Tuỳ chọn…'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '7');
        await tester.tap(
          find.widgetWithText(
            TextButton,
            MaterialLocalizations.of(tester.element(find.byType(AlertDialog)))
                .cancelButtonLabel,
          ),
        );
        await _settle(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(SelectionRow), findsNothing);
        expect(h.container.read(mostPlayedLimitProvider), 50);
        expect(find.widgetWithText(KChip, 'Top 50'), findsOneWidget);
      });
    });
  }
}
