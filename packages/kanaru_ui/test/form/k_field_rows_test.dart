import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

void main() {
  Widget list({
    List<String> values = const ['a', 'b'],
    ValueChanged<List<String>>? onCommit,
    int maxRows = 50,
    bool enabled = true,
    String? error,
    Set<int> invalid = const {},
  }) => host(
    SingleChildScrollView(
      child: KFieldRows.list(
        values: values,
        onCommit: onCommit ?? (_) {},
        hint: 'https://…',
        addLabel: 'Thêm',
        removeTooltip: 'Xoá',
        maxRows: maxRows,
        enabled: enabled,
        error: error,
        invalidRows: invalid,
      ),
    ),
  );

  Widget table({
    List<(String, String)> values = const [('a', '1'), ('b', '2')],
    ValueChanged<List<(String, String)>>? onCommit,
    Map<int, String> errors = const {},
    String? error,
    double textScale = 1,
  }) => host(
    SingleChildScrollView(
      child: KFieldRows.map(
        values: values,
        onCommit: onCommit ?? (_) {},
        nameLabel: 'Tên',
        valueLabel: 'Giá trị',
        addLabel: 'Thêm',
        removeTooltip: 'Xoá',
        rowErrors: errors,
        error: error,
      ),
    ),
    textScale: textScale,
  );

  Finder field(int i) => find.byType(TextField).at(i);
  Future<void> leave(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  bool addEnabled(WidgetTester tester) =>
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Thêm'))
          .onPressed !=
      null;

  OutlineInputBorder outline(WidgetTester tester, int i) =>
      tester.widget<TextField>(field(i)).decoration!.enabledBorder!
          as OutlineInputBorder;

  group('list', () {
    testWidgets('one 48 dp field per value, hint as placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.getSize(field(0)).height, 48);
      expect(
        tester.widget<TextField>(field(0)).decoration!.hintText,
        'https://…',
      );
      expect(byIconButton('Xoá'), findsNWidgets(2));
    });

    testWidgets('add appends a focused blank row; disabled at max', (
      tester,
    ) async {
      await tester.pumpWidget(list(maxRows: 3));
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(2))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(addEnabled(tester), isFalse);
    });

    testWidgets('commits non-blank rows when the row loses focus', (
      tester,
    ) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.enterText(field(2), 'c');
      expect(sent, isEmpty);
      await leave(tester);
      expect(sent, [
        ['a', 'b', 'c'],
      ]);
      // Same content again: nothing more is sent.
      await tester.tap(field(0));
      await leave(tester);
      expect(sent, hasLength(1));
    });

    testWidgets('a blank row never counts', (tester) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.enterText(field(2), '   ');
      await leave(tester);
      expect(sent, isEmpty);
    });

    testWidgets('Enter commits at once', (tester) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.enterText(field(0), 'z');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(sent, [
        ['z', 'b'],
      ]);
    });

    testWidgets('remove commits immediately', (tester) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.tap(byIconButton('Xoá').first);
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(sent, [
        ['b'],
      ]);
    });

    testWidgets('an outside change shows unless a field is focused', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      await tester.pumpWidget(list(values: const ['x']));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('x'), findsOneWidget);
      await tester.tap(field(0));
      await tester.enterText(field(0), 'typing');
      await tester.pumpWidget(list(values: const ['y', 'z']));
      expect(find.text('typing'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('an outside change during focus applies on blur', (
      tester,
    ) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.tap(field(0));
      await tester.pump();
      await tester.pumpWidget(
        list(values: const ['y', 'z'], onCommit: sent.add),
      );
      expect(find.text('y'), findsNothing);
      await leave(tester);
      await tester.pump();
      expect(find.text('y'), findsOneWidget);
      expect(find.text('z'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('a user commit discards the pending outside change', (
      tester,
    ) async {
      final sent = <List<String>>[];
      await tester.pumpWidget(list(onCommit: sent.add));
      await tester.tap(field(0));
      await tester.enterText(field(0), 'mine');
      await tester.pumpWidget(list(values: const ['y'], onCommit: sent.add));
      await leave(tester);
      await tester.pump();
      expect(sent, [
        ['mine', 'b'],
      ]);
      expect(find.text('mine'), findsOneWidget);
      expect(find.text('y'), findsNothing);
    });

    testWidgets('removing, reloading and disposing rows throws nothing', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      await tester.tap(field(1));
      await tester.pump();
      // Remove the focused row.
      await tester.tap(byIconButton('Xoá').last);
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      // Outside reload with no focus.
      await leave(tester);
      await tester.pumpWidget(list(values: const ['p', 'q', 'r']));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(3));
      // Add focuses the new row, then dispose the whole widget.
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'one error line under the block; invalid item has a red outline',
      (tester) async {
        await tester.pumpWidget(
          list(error: 'Một mục không hợp lệ', invalid: const {1}),
        );
        final scheme = Theme.of(tester.element(field(0))).colorScheme;
        expect(find.text('Một mục không hợp lệ'), findsOneWidget);
        expect(outline(tester, 1).borderSide.color, scheme.error);
        expect(outline(tester, 0).borderSide.color, scheme.outline);
      },
    );

    testWidgets('locked: fields, remove and add are off', (tester) async {
      await tester.pumpWidget(list(enabled: false));
      expect(tester.widget<TextField>(field(0)).enabled, isFalse);
      expect(
        tester.widget<KIconButton>(byIconButton('Xoá').first).onPressed,
        isNull,
      );
      expect(addEnabled(tester), isFalse);
    });
  });

  group('map', () {
    testWidgets('name and value fields with floating labels', (tester) async {
      await tester.pumpWidget(table());
      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('Tên'), findsNWidgets(2));
      expect(find.text('Giá trị'), findsNWidgets(2));
    });

    testWidgets('name : value is 1 : 1 on a phone', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(table());
      final name = tester.getSize(field(0)).width;
      expect(tester.getSize(field(1)).width, closeTo(name, 0.01));
    });

    testWidgets('name : value is 1 : 1.4 on desktop', (tester) async {
      useWindow(tester, const Size(1400, 900));
      await tester.pumpWidget(table());
      final name = tester.getSize(field(0)).width;
      expect(tester.getSize(field(1)).width / name, closeTo(1.4, 0.001));
    });

    testWidgets('at 200 % text a row stacks, remove stays by the name', (
      tester,
    ) async {
      useWindow(tester, const Size(412, 900));
      await tester.pumpWidget(table(textScale: 2));
      expect(tester.takeException(), isNull);
      final name = tester.getRect(field(0));
      final value = tester.getRect(field(1));
      expect(value.top, greaterThanOrEqualTo(name.bottom));
      expect(value.left, name.left);
      final remove = tester.getRect(byIconButton('Xoá').first);
      expect(remove.left, greaterThanOrEqualTo(name.right));
      expect(remove.center.dy, lessThan(value.top));
    });

    testWidgets('a half-filled row commits only after leaving the row', (
      tester,
    ) async {
      final sent = <List<(String, String)>>[];
      await tester.pumpWidget(table(values: const [], onCommit: sent.add));
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.enterText(field(0), 'k');
      await tester.tap(field(1));
      await tester.pump();
      expect(sent, isEmpty);
      await tester.enterText(field(1), 'v');
      await leave(tester);
      expect(sent, [
        [('k', 'v')],
      ]);
    });

    testWidgets('a row error replaces nothing: it shows under the name', (
      tester,
    ) async {
      await tester.pumpWidget(table(errors: const {1: 'Tên đã dùng'}));
      await tester.pump(const Duration(seconds: 1));
      final scheme = Theme.of(tester.element(field(0))).colorScheme;
      final message = tester.getRect(find.text('Tên đã dùng'));
      expect(message.top, greaterThan(tester.getRect(field(2)).center.dy));
      expect(message.left, greaterThanOrEqualTo(tester.getRect(field(2)).left));
      expect(
        tester.widget<TextField>(field(2)).decoration!.errorText,
        'Tên đã dùng',
      );
      expect(outline(tester, 0).borderSide.color, scheme.outline);
    });

    testWidgets('error indexes skip blank rows', (tester) async {
      await tester.pumpWidget(table(values: const [('a', '1')]));
      await tester.tap(find.text('Thêm'));
      await tester.pump();
      await tester.pumpWidget(
        table(values: const [('a', '1')], errors: const {0: 'Lỗi'}),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<TextField>(field(0)).decoration!.errorText, 'Lỗi');
      expect(tester.widget<TextField>(field(2)).decoration!.errorText, isNull);
    });
  });
}
