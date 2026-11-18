import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

const _options = [
  SelectionOption<int>(value: 1, title: Text('One')),
  SelectionOption<int>(value: 2, title: Text('Two')),
  SelectionOption<int>(value: 3, title: Text('Three')),
];

Widget _opener(
  void Function(Future<int?>) onFuture, {
  int? selected = 1,
  Future<bool> Function(int)? confirm,
  SelectionPickerPresentation presentation = SelectionPickerPresentation.auto,
  bool footer = true,
}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => onFuture(
      showSelectionPicker<int>(
        context,
        options: _options,
        selected: selected,
        title: const Text('Pick'),
        confirm: confirm,
        confirmLabel: footer ? 'Confirm' : null,
        cancelLabel: footer ? 'Cancel' : null,
        presentation: presentation,
      ),
    ),
    child: const Text('open'),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The dialog's own surface (the Dialog widget itself fills the route).
final _surface = find
    .descendant(of: find.byType(Dialog), matching: find.byType(Material))
    .first;

void main() {
  group('footer mode', () {
    testWidgets('a tap only selects; confirm resolves the selection', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f)));
      await _open(tester);
      expect(byCheckState(KCheckState.on), findsOneWidget);

      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();
      expect(find.text('Pick'), findsOneWidget, reason: 'still open');
      expect(
        find.descendant(
          of: find.widgetWithText(SelectionRow, 'Three'),
          matching: byCheckState(KCheckState.on),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(SelectionRow, 'One'),
          matching: byCheckState(KCheckState.off),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await result, 3);
    });

    testWidgets('the preselected row confirms as it is', (tester) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f)));
      await _open(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await result, 1);
    });

    testWidgets('cancel resolves to null', (tester) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f)));
      await _open(tester);
      await tester.tap(find.text('Two'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isNull);
    });

    testWidgets('confirm is off while nothing is selected', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_opener((_) {}, selected: null)));
      await _open(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('confirm: false keeps it open with the same selection', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      final asked = <int>[];
      await tester.pumpWidget(
        host(
          _opener(
            (f) => result = f,
            confirm: (v) async {
              asked.add(v);
              return asked.length > 1;
            },
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Two'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(asked, [2]);
      expect(find.text('Pick'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(SelectionRow, 'Two'),
          matching: byCheckState(KCheckState.on),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await result, 2);
    });

    testWidgets('without labels a tap still chooses and closes', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f, footer: false)));
      await _open(tester);
      expect(find.text('Confirm'), findsNothing);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(await result, 2);
    });
  });

  group('presentation', () {
    testWidgets('auto on mobile is a sheet', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(host(_opener((_) {})));
      await _open(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('dialog on mobile is a centred dialog at most 440 wide', (
      tester,
    ) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(_opener((_) {}, presentation: SelectionPickerPresentation.dialog)),
      );
      await _open(tester);
      expect(find.byType(BottomSheet), findsNothing);
      final rect = tester.getRect(_surface);
      expect(rect.width, lessThanOrEqualTo(KLayout.dialog));
      expect(rect.center.dx, closeTo(180, 0.5));
      expect(rect.center.dy, closeTo(400, 40));
    });

    testWidgets('dialog on desktop is the same dialog', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(
        host(_opener((_) {}, presentation: SelectionPickerPresentation.dialog)),
      );
      await _open(tester);
      expect(tester.getSize(_surface).width, KLayout.dialog);
    });
  });
}
