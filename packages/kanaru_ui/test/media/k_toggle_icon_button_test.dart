import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('dot shows only when active ($name)', (tester) async {
      Widget build(bool active) => host(
        KToggleIconButton(
          icon: Icons.shuffle,
          active: active,
          tooltip: 'Shuffle',
          onPressed: () {},
        ),
        brightness: brightness,
        textScale: scale,
      );
      await tester.pumpWidget(build(false));
      expect(find.byKey(KToggleIconButton.dotKey), findsNothing);
      await tester.pumpWidget(build(true));
      expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
    });
  }

  testWidgets('active icon is primary, inactive is not; tap fires', (
    tester,
  ) async {
    var taps = 0;
    Widget build(bool active) => host(
      KToggleIconButton(
        icon: Icons.shuffle,
        active: active,
        tooltip: 'Shuffle',
        onPressed: () => taps++,
      ),
    );
    await tester.pumpWidget(build(true));
    final scheme = Theme.of(tester.element(find.byType(IconButton)))
        .colorScheme;
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).color,
      scheme.primary,
    );
    await tester.pumpWidget(build(false));
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).color,
      isNot(scheme.primary),
    );
    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
  });

  testWidgets('exposes tooltip and toggled state to semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        KToggleIconButton(
          icon: Icons.shuffle,
          active: true,
          tooltip: 'Shuffle',
          onPressed: () {},
        ),
      ),
    );
    final node = tester.getSemantics(find.byTooltip('Shuffle'));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isSelected.name == 'isTrue', isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('an icon widget replaces the icon and keeps the dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KToggleIconButton(
          iconWidget: const Text('7'),
          active: true,
          tooltip: 'Repeat',
          onPressed: () {},
        ),
      ),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
  });
}
