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
    // The glyph takes its colour from the IconTheme the button sets.
    Color? glyph() => IconTheme.of(
      tester.element(
        find.descendant(
          of: find.byType(KToggleIconButton),
          matching: find.byType(Icon),
        ),
      ),
    ).color;
    final scheme = Theme.of(tester.element(find.byType(KIconButton)))
        .colorScheme;
    expect(glyph(), scheme.primary);
    await tester.pumpWidget(build(false));
    expect(glyph(), isNot(scheme.primary));
    await tester.tap(find.byType(KToggleIconButton));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('exposes tooltip label and toggled state to semantics', (
    tester,
  ) async {
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
    final node = tester.getSemantics(find.byType(KToggleIconButton));
    final data = node.getSemanticsData();
    expect(data.label, 'Shuffle');
    expect(data.flagsCollection.isToggled.name, 'isTrue');
    expect(data.flagsCollection.isButton, isTrue);
    expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);
    handle.dispose();
  });

  // The dot hangs 2 dp under the glyph whatever box the button sits in.
  final slots = <String, Widget Function(Widget)>{
    'a bounded 52 dp box': (b) => Center(
      child: SizedBox.square(dimension: 52, child: Center(child: b)),
    ),
    'a bar': (b) => SizedBox(height: 64, child: Row(children: [b])),
    'an unbounded slot': (b) => Align(alignment: Alignment.topLeft, child: b),
  };
  slots.forEach((name, wrap) {
    testWidgets('the dot sits 2 dp under the glyph in $name', (tester) async {
      await tester.pumpWidget(
        host(
          wrap(
            KToggleIconButton(
              icon: Icons.shuffle,
              active: true,
              tooltip: 'Shuffle',
              onPressed: () {},
            ),
          ),
        ),
      );
      final glyph = tester.getRect(
        find.descendant(
          of: find.byType(KToggleIconButton),
          matching: find.byType(Icon),
        ),
      );
      final dot = tester.getRect(find.byKey(KToggleIconButton.dotKey));
      expect(dot.top - glyph.bottom, 2);
      expect(dot.center.dx, closeTo(glyph.center.dx, 0.01));
    });
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

  testWidgets('in a tall tile the dot stays 2 dp under the glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Center(
          child: SizedBox(
            width: 85,
            height: 52,
            child: KToggleIconButton(
              icon: Icons.shuffle,
              active: true,
              tooltip: 'Shuffle',
              padding: const EdgeInsets.all(KSpace.x1),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final tile = tester.getRect(find.byType(KIconButton));
    expect(tile.size, const Size(85, 52));
    final glyph = tester.getRect(find.byIcon(Icons.shuffle));
    final dot = tester.getRect(find.byKey(KToggleIconButton.dotKey));
    expect(dot.top - glyph.bottom, closeTo(2, 0.01));
    expect(dot.center.dx, closeTo(glyph.center.dx, 0.01));
    // The glyph is centred in the tile, not pushed up to make room.
    expect(glyph.center.dx, closeTo(tile.center.dx, 0.5));
    expect(glyph.center.dy, closeTo(tile.center.dy, 0.5));
  });
}
