import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _button({
  bool selected = false,
  VoidCallback? onPressed,
  IconData? selectedIcon,
}) => Center(
  child: KTonalToggleButton(
    icon: KIcons.filter,
    selectedIcon: selectedIcon,
    tooltip: 'Filter',
    selected: selected,
    onPressed: onPressed,
  ),
);

void main() {
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  testWidgets('off is the light button, on is the tonal disc of the same box', (
    tester,
  ) async {
    await tester.pumpWidget(host(_button(onPressed: () {})));
    final off = tester.getSize(byIconButton('Filter'));
    expect(find.byType(IconButton), findsNothing);
    await tester.pumpWidget(host(_button(selected: true, onPressed: () {})));
    expect(byIconButton('Filter'), findsNothing);
    expect(tester.getSize(find.byType(IconButton)), off);
  });

  testWidgets('on reads as a selected button to a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_button(selected: true, onPressed: () {})));
    final data = tester
        .getSemantics(find.byType(IconButton))
        .getSemanticsData();
    expect(data.flagsCollection.isSelected, isNot(0));
    expect(data.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('selectedIcon replaces the glyph while on', (tester) async {
    await tester.pumpWidget(
      host(
        _button(selected: true, selectedIcon: KIcons.check, onPressed: () {}),
      ),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(IconButton), matching: find.byType(Icon)),
    );
    expect(icon.icon, KIcons.check);
  });

  testWidgets('tapping calls onPressed in both looks', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_button(onPressed: () => taps++)));
    await tester.tap(byIconButton('Filter'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(
      host(_button(selected: true, onPressed: () => taps++)),
    );
    await tester.tap(find.byType(IconButton));
    expect(taps, 2);
  });

  testWidgets('keyboard focus survives the toggle', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    var on = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              _button(selected: on, onPressed: () => setState(() => on = !on)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 400));
    expect(on, isTrue);
    expect(find.byType(IconButton), findsOneWidget);
    // Enter again toggles back: the focus stayed on the button.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 400));
    expect(on, isFalse);
  });

  testWidgets('disabled is not enabled in either look', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_button()));
    expect(
      tester.getSemantics(byIconButton('Filter')),
      isSemantics(isButton: true, isEnabled: false),
    );
    await tester.pumpWidget(host(_button(selected: true)));
    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(isButton: true, isEnabled: false, isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('disc sets the box of both looks', (tester) async {
    Widget sized(bool on) => Center(
      child: KTonalToggleButton(
        icon: KIcons.filter,
        tooltip: 'Filter',
        selected: on,
        disc: 44,
        onPressed: () {},
      ),
    );
    await tester.pumpWidget(host(sized(false)));
    expect(tester.getSize(byIconButton('Filter')), const Size.square(44));
    await tester.pumpWidget(host(sized(true)));
    expect(tester.getSize(find.byType(IconButton)), const Size.square(44));
  });
}
