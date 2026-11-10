import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _options = [
  SelectionOption<int>(value: 1, title: Text('One')),
  SelectionOption<int>(value: 2, title: Text('Two')),
];

Widget _opener(void Function(Future<int?>) onFuture, {
  Future<bool> Function(int)? confirm,
  Widget? header,
  GlobalKey? anchor,
  Alignment align = Alignment.center,
}) {
  return Align(
    alignment: align,
    child: Builder(
      builder: (context) => TextButton(
        key: anchor,
        onPressed: () => onFuture(showSelectionPicker<int>(
          context,
          options: _options,
          selected: 1,
          title: const Text('Pick'),
          header: header,
          confirm: confirm,
          anchor: anchor,
        )),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('mobile sheet returns the tapped value ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f),
          brightness: brightness, textScale: scale));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Pick'), findsOneWidget);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(await result, 2);
      expect(find.text('Pick'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('confirm false keeps the picker open, true closes it', (tester) async {
    useWindow(tester, const Size(400, 800));
    late Future<int?> result;
    final answers = <int, bool>{2: false};
    await tester.pumpWidget(host(_opener(
      (f) => result = f,
      confirm: (v) async => answers[v] ?? true,
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('Pick'), findsOneWidget, reason: 'cancelled confirm keeps it open');

    answers[2] = true;
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(await result, 2);
    expect(find.text('Pick'), findsNothing);
  });

  testWidgets('second tap while confirm is pending is ignored', (tester) async {
    useWindow(tester, const Size(400, 800));
    final gate = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(host(_opener((_) {}, confirm: (v) {
      calls++;
      return gate.future;
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pump();
    await tester.tap(find.text('One'));
    await tester.pump();
    expect(calls, 1);
    gate.complete(false);
    await tester.pumpAndSettle();
  });

  testWidgets('header stays visible above the options', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {}, header: const Text('ORDER'))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ORDER'), findsOneWidget);
    expect(tester.getTopLeft(find.text('ORDER')).dy,
        lessThan(tester.getTopLeft(find.text('One')).dy));
  });

  testWidgets('desktop with anchor opens a panel under it', (tester) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    late Future<int?> result;
    await tester.pumpWidget(host(_opener((f) => result = f, anchor: anchor)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final anchorBox = tester.getRect(find.byKey(anchor));
    expect(tester.getTopLeft(find.text('Pick')).dy, greaterThan(anchorBox.bottom - 1));
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(await result, 1);
  });

  testWidgets('desktop without anchor opens a dialog; Back dismisses to null', (tester) async {
    useWindow(tester, const Size(1400, 900));
    late Future<int?> result;
    await tester.pumpWidget(host(_opener((f) => result = f)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets('anchored panel flips above an anchor near the bottom', (tester) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    await tester.pumpWidget(host(
      _opener((_) {}, anchor: anchor, align: Alignment.bottomLeft),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    expect(tester.getBottomLeft(find.text('Two')).dy, lessThan(a.top));
  });

  testWidgets('anchored panel ignores safe-area insets', (tester) async {
    useWindow(tester, const Size(1400, 900));
    tester.view.padding = const FakeViewPadding(top: 80);
    tester.view.viewPadding = const FakeViewPadding(top: 80);
    final anchor = GlobalKey();
    await tester.pumpWidget(host(Padding(
      padding: const EdgeInsets.only(top: 100),
      child: _opener((_) {}, anchor: anchor, align: Alignment.topLeft),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    final panel = tester.getRect(find.descendant(of: find.byType(CustomSingleChildLayout), matching: find.byType(Material)).first);
    expect(panel.top, closeTo(a.bottom + 4, 1));
  });

  testWidgets('Escape closes the desktop picker with null', (tester) async {
    useWindow(tester, const Size(1400, 900));
    late Future<int?> result;
    await tester.pumpWidget(host(_opener((f) => result = f)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(find.text('Pick'), findsNothing);
  });

  testWidgets('arrow keys move focus between rows', (tester) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_opener((_) {})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    Element focused() => (FocusManager.instance.primaryFocus!.context!) as Element;
    bool within(String label) => find
        .descendant(of: find.byElementPredicate((e) => e == focused()), matching: find.text(label))
        .evaluate()
        .isNotEmpty;
    expect(within('One'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(within('Two'), isTrue);
  });

  testWidgets('rows are disabled while confirm is pending', (tester) async {
    useWindow(tester, const Size(400, 800));
    final gate = Completer<bool>();
    await tester.pumpWidget(host(_opener((_) {}, confirm: (_) => gate.future)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pump();
    final rows = tester.widgetList<SelectionRow>(find.byType(SelectionRow));
    expect(rows.every((r) => !r.enabled), isTrue);
    gate.complete(false);
    await tester.pumpAndSettle();
    expect(tester.widgetList<SelectionRow>(find.byType(SelectionRow)).every((r) => r.enabled), isTrue);
  });
}
