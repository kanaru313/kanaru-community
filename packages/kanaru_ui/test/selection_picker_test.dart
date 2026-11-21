import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _options = [
  SelectionOption<int>(value: 1, title: Text('One')),
  SelectionOption<int>(value: 2, title: Text('Two')),
];

Widget _opener(
  void Function(Future<int?>) onFuture, {
  Future<bool> Function(int)? confirm,
  Widget? header,
  GlobalKey? anchor,
  Alignment align = Alignment.center,
  KAnchorAlign anchorAlign = KAnchorAlign.start,
  SelectionPickerPresentation presentation = SelectionPickerPresentation.auto,
}) {
  return Align(
    alignment: align,
    child: Builder(
      builder: (context) => TextButton(
        key: anchor,
        onPressed: () => onFuture(
          showSelectionPicker<int>(
            context,
            options: _options,
            selected: 1,
            title: const Text('Pick'),
            header: header,
            confirm: confirm,
            anchor: anchor,
            anchorAlign: anchorAlign,
            presentation: presentation,
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('mobile sheet returns the tapped value ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(
        host(
          _opener((f) => result = f),
          brightness: brightness,
          textScale: scale,
        ),
      );
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

  testWidgets('confirm false keeps the picker open, true closes it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    late Future<int?> result;
    final answers = <int, bool>{2: false};
    await tester.pumpWidget(
      host(
        _opener((f) => result = f, confirm: (v) async => answers[v] ?? true),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pick'),
      findsOneWidget,
      reason: 'cancelled confirm keeps it open',
    );

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
    await tester.pumpWidget(
      host(
        _opener(
          (_) {},
          confirm: (v) {
            calls++;
            return gate.future;
          },
        ),
      ),
    );
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
    expect(
      tester.getTopLeft(find.text('ORDER')).dy,
      lessThan(tester.getTopLeft(find.text('One')).dy),
    );
  });

  group('anchored presentation on a phone-width surface', () {
    Future<Future<int?>> open(
      WidgetTester tester,
      GlobalKey anchor, {
      Alignment align = Alignment.center,
    }) async {
      useWindow(tester, const Size(360, 700));
      late Future<int?> result;
      await tester.pumpWidget(
        host(
          _opener(
            (f) => result = f,
            anchor: anchor,
            align: align,
            presentation: SelectionPickerPresentation.anchored,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('opens a panel under the trigger, not a sheet', (tester) async {
      final anchor = GlobalKey();
      final result = await open(tester, anchor);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(CustomSingleChildLayout), findsWidgets);
      final a = tester.getRect(find.byKey(anchor));
      expect(tester.getTopLeft(find.text('Pick')).dy, greaterThan(a.bottom));
      final panel = tester.getRect(
        find
            .descendant(
              of: find.byType(CustomSingleChildLayout),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(360));
      // Dense rows: 40 dp.
      expect(tester.getSize(find.byType(SelectionRow).first).height, 40);
      expect(
        tester.getSemantics(find.text('One')),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(await result, 2);
    });

    testWidgets('flips above a trigger near the bottom', (tester) async {
      final anchor = GlobalKey();
      await open(tester, anchor, align: Alignment.bottomLeft);
      final a = tester.getRect(find.byKey(anchor));
      expect(tester.getBottomLeft(find.text('Two')).dy, lessThan(a.top));
    });

    testWidgets('stays above the bottom inset; last row is hittable', (
      tester,
    ) async {
      useWindow(tester, const Size(360, 700));
      tester.view.padding = const FakeViewPadding(bottom: 120);
      tester.view.viewPadding = const FakeViewPadding(bottom: 120);
      final anchor = GlobalKey();
      late Future<int?> result;
      // The panel would fit below the trigger (ending near 594) but not above
      // the 120 dp inset (limit 564): it must flip up instead.
      await tester.pumpWidget(
        host(
          Padding(
            padding: const EdgeInsets.only(bottom: 260),
            child: _opener(
              (f) => result = f,
              anchor: anchor,
              align: Alignment.bottomLeft,
              presentation: SelectionPickerPresentation.anchored,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('Two')).dy,
        lessThanOrEqualTo(700 - 120),
      );
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(await result, 2);
    });

    testWidgets('Back closes with null', (tester) async {
      final result = await open(tester, GlobalKey());
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(await result, isNull);
    });

    testWidgets('a tap outside closes with null', (tester) async {
      final result = await open(tester, GlobalKey());
      await tester.tapAt(const Offset(2, 690));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(find.text('Pick'), findsNothing);
    });
  });

  testWidgets('default presentation on a phone is still a sheet', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 700));
    final anchor = GlobalKey();
    await tester.pumpWidget(host(_opener((_) {}, anchor: anchor)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('desktop with anchor opens a panel under it', (tester) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    late Future<int?> result;
    await tester.pumpWidget(host(_opener((f) => result = f, anchor: anchor)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final anchorBox = tester.getRect(find.byKey(anchor));
    expect(
      tester.getTopLeft(find.text('Pick')).dy,
      greaterThan(anchorBox.bottom - 1),
    );
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(await result, 1);
  });

  group('anchored desktop panel has the sort dropdown size', () {
    double fontOf(WidgetTester tester, String text) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .fontSize!;

    Future<void> openWith(
      WidgetTester tester,
      List<SelectionOption<int>> options,
      Size window, {
      Widget? header,
      bool footer = false,
    }) async {
      useWindow(tester, window);
      final anchor = GlobalKey();
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: Builder(
              builder: (context) => TextButton(
                key: anchor,
                onPressed: () => showSelectionPicker<int>(
                  context,
                  options: options,
                  selected: 1,
                  title: const Text('Pick'),
                  header: header,
                  confirmLabel: footer ? 'OK' : null,
                  cancelLabel: footer ? 'Cancel' : null,
                  anchor: anchor,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('rows 40 tall, bodyMedium, title titleSmall, no gap', (
      tester,
    ) async {
      await openWith(tester, _options, const Size(1400, 900));
      final text = Theme.of(tester.element(find.text('One'))).textTheme;
      final rows = find.byType(SelectionRow);
      expect(tester.getSize(rows.first).height, KLayout.dropdownRowHeight);
      expect(
        tester.getTopLeft(rows.last).dy - tester.getBottomLeft(rows.first).dy,
        0,
      );
      expect(fontOf(tester, 'Two'), text.bodyMedium!.fontSize);
      expect(fontOf(tester, 'Pick'), text.titleSmall!.fontSize);
    });

    testWidgets('anchored with a footer renders, buttons visible, 200..360', (
      tester,
    ) async {
      await openWith(tester, _options, const Size(1400, 900), footer: true);
      expect(tester.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      final panel = tester.getSize(
        find
            .ancestor(of: find.text('OK'), matching: find.byType(Material))
            .last,
      );
      expect(panel.width, inInclusiveRange(200, 360));
    });

    testWidgets('50 options stay inside the window and scroll', (tester) async {
      const window = Size(1400, 600);
      await openWith(tester, [
        for (var i = 1; i <= 50; i++)
          SelectionOption<int>(value: i, title: Text('Option $i')),
      ], window);
      expect(tester.takeException(), isNull);
      final scroll = find.byType(SingleChildScrollView);
      expect(
        tester.getSize(scroll).height,
        lessThanOrEqualTo(window.height - 2 * KSpace.x4),
      );
      await tester.dragUntilVisible(
        find.text('Option 50'),
        scroll,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Option 50').hitTestable(), findsOneWidget);
    });

    testWidgets('caption is bodySmall', (tester) async {
      await openWith(
        tester,
        _options,
        const Size(1400, 900),
        header: const Text('Caption'),
      );
      final text = Theme.of(tester.element(find.text('One'))).textTheme;
      expect(fontOf(tester, 'Caption'), text.bodySmall!.fontSize);
    });

    testWidgets('width follows content, clamped to 200..360', (tester) async {
      await openWith(tester, _options, const Size(1400, 900));
      final panel = find.ancestor(
        of: find.byType(SelectionRow).first,
        matching: find.byType(Material),
      );
      expect(tester.getSize(panel.first).width, KLayout.anchoredPickerMinWidth);
      await tester.tapAt(const Offset(900, 600));
      await tester.pumpAndSettle();
      await openWith(tester, [
        SelectionOption<int>(value: 1, title: Text('Long ' * 40)),
        const SelectionOption<int>(value: 2, title: Text('Two')),
      ], const Size(1400, 900));
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byType(SelectionRow).first,
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .width,
        KLayout.anchoredPickerMaxWidth,
      );
    });

    testWidgets('mobile sheet keeps 48 dp rows and bodyLarge', (tester) async {
      useWindow(tester, const Size(400, 800));
      late Future<int?> result;
      await tester.pumpWidget(host(_opener((f) => result = f)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final text = Theme.of(tester.element(find.text('One'))).textTheme;
      expect(
        tester.getSize(find.byType(SelectionRow).first).height,
        greaterThanOrEqualTo(48),
      );
      expect(fontOf(tester, 'One'), text.bodyLarge!.fontSize);
      expect(fontOf(tester, 'Pick'), text.titleMedium!.fontSize);
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(await result, 1);
    });
  });

  testWidgets('desktop without anchor opens a dialog; Back dismisses to null', (
    tester,
  ) async {
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

  testWidgets('anchored panel flips above an anchor near the bottom', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    await tester.pumpWidget(
      host(_opener((_) {}, anchor: anchor, align: Alignment.bottomLeft)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    expect(tester.getBottomLeft(find.text('Two')).dy, lessThan(a.top));
  });

  Rect panelRect(WidgetTester tester) => tester.getRect(
    find
        .descendant(
          of: find.byType(CustomSingleChildLayout),
          matching: find.byType(Material),
        )
        .first,
  );

  testWidgets('end alignment lines the panel right edge up with the anchor', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    await tester.pumpWidget(
      host(
        _opener(
          (_) {},
          anchor: anchor,
          align: Alignment.topRight,
          anchorAlign: KAnchorAlign.end,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    final panel = panelRect(tester);
    // The anchor hugs the right window edge: the panel is clamped 16 from it.
    expect(panel.right, closeTo(math.min(a.right, 1400 - 16), 1));
    expect(panel.top, closeTo(a.bottom + 4, 1));
  });

  testWidgets('end alignment right-aligns to an anchor away from the edge', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 600,
            child: _opener(
              (_) {},
              anchor: anchor,
              align: Alignment.topRight,
              anchorAlign: KAnchorAlign.end,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    expect(panelRect(tester).right, closeTo(a.right, 1));
  });

  testWidgets(
    'end alignment flips above near the bottom and stays 16 from the edge',
    (tester) async {
      useWindow(tester, const Size(1400, 900));
      final anchor = GlobalKey();
      await tester.pumpWidget(
        host(
          _opener(
            (_) {},
            anchor: anchor,
            align: Alignment.bottomRight,
            anchorAlign: KAnchorAlign.end,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final a = tester.getRect(find.byKey(anchor));
      final panel = panelRect(tester);
      expect(panel.bottom, lessThanOrEqualTo(a.top));
      expect(panel.right, lessThanOrEqualTo(1400 - 16 + 0.5));
    },
  );

  testWidgets('start alignment keeps left edges aligned', (tester) async {
    useWindow(tester, const Size(1400, 900));
    final anchor = GlobalKey();
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 600, child: _opener((_) {}, anchor: anchor)),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      panelRect(tester).left,
      closeTo(tester.getRect(find.byKey(anchor)).left, 1),
    );
  });

  testWidgets('anchored panel ignores safe-area insets', (tester) async {
    useWindow(tester, const Size(1400, 900));
    tester.view.padding = const FakeViewPadding(top: 80);
    tester.view.viewPadding = const FakeViewPadding(top: 80);
    final anchor = GlobalKey();
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: _opener((_) {}, anchor: anchor, align: Alignment.topLeft),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(anchor));
    final panel = tester.getRect(
      find
          .descendant(
            of: find.byType(CustomSingleChildLayout),
            matching: find.byType(Material),
          )
          .first,
    );
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
    Element focused() =>
        (FocusManager.instance.primaryFocus!.context!) as Element;
    bool within(String label) => find
        .descendant(
          of: find.byElementPredicate((e) => e == focused()),
          matching: find.text(label),
        )
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
    expect(
      tester
          .widgetList<SelectionRow>(find.byType(SelectionRow))
          .every((r) => r.enabled),
      isTrue,
    );
  });
}
