import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _row({
  bool selected = false,
  bool enabled = true,
  bool expanded = true,
}) => host(
  Center(
    child: SizedBox(
      width: expanded ? 216 : 48,
      child: KNavRow(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Trang chủ',
        selected: selected,
        expanded: expanded,
        onTap: enabled ? () {} : null,
      ),
    ),
  ),
);

Color? _tint(WidgetTester t) =>
    (t.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
            as BoxDecoration)
        .color;

void main() {
  testWidgets('selected: 48 dp row, 3 dp primary bar, tint 14 %', (t) async {
    await t.pumpWidget(_row(selected: true));
    final scheme = Theme.of(t.element(find.byType(KNavRow))).colorScheme;
    expect(t.getSize(find.byType(KNavRow)).height, 48);
    final bar = find.byKey(const ValueKey('nav-row-bar'));
    expect(t.getSize(bar), const Size(3, 48));
    expect(t.widget<ColoredBox>(bar).color, scheme.primary);
    final tint = _tint(t);
    expect(tint, scheme.primary.withValues(alpha: 0.14));
    expect(t.widget<Icon>(find.byType(Icon)).icon, Icons.home);
    expect(t.widget<Icon>(find.byType(Icon)).color, scheme.primary);
  });

  testWidgets('hover on selected raises tint to 20 %', (t) async {
    await t.pumpWidget(_row(selected: true));
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: t.getCenter(find.byType(KNavRow)));
    await t.pumpAndSettle();
    final scheme = Theme.of(t.element(find.byType(KNavRow))).colorScheme;
    expect(_tint(t), scheme.primary.withValues(alpha: 0.20));
  });

  testWidgets('unselected: no bar, outlined icon; rail hides label', (t) async {
    await t.pumpWidget(_row(expanded: false));
    expect(find.byKey(const ValueKey('nav-row-bar')), findsNothing);
    expect(find.text('Trang chủ'), findsNothing);
    expect(t.widget<Icon>(find.byType(Icon)).icon, Icons.home_outlined);
  });

  testWidgets('disabled never shows the selected style', (t) async {
    await t.pumpWidget(_row(selected: true, enabled: false));
    expect(find.byKey(const ValueKey('nav-row-bar')), findsNothing);
  });

  testWidgets('exposes button semantics: tap action, selected, enabled', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_row(selected: true));
    final node = t.getSemantics(find.bySemanticsLabel('Trang chủ'));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    await t.pumpWidget(_row(enabled: false));
    final off = t.getSemantics(find.bySemanticsLabel('Trang chủ'));
    expect(off.getSemanticsData().flagsCollection.isEnabled, Tristate.isFalse);
    expect(off.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('no hover overlay is stacked on the tint', (t) async {
    await t.pumpWidget(_row(selected: true));
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: t.getCenter(find.byType(KNavRow)));
    await t.pumpAndSettle();
    final ink = t.widget<InkWell>(find.byType(InkWell));
    expect(
      ink.overlayColor!.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      ink.overlayColor!.resolve({WidgetState.focused}),
      Colors.transparent,
    );
    expect(ink.overlayColor!.resolve({WidgetState.pressed}), isNull);
  });

  for (final selected in [false, true]) {
    testWidgets('icon and label are vertically centred (selected: $selected)', (
      t,
    ) async {
      await t.pumpWidget(_row(selected: selected));
      final row = t.getCenter(find.byType(KNavRow)).dy;
      expect(t.getCenter(find.byType(Icon)).dy, moreOrLessEquals(row));
      expect(
        t.getCenter(find.text('Trang chủ')).dy,
        moreOrLessEquals(row, epsilon: 1),
      );
    });
  }
}
