import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

Widget _button({bool on = false, ValueChanged<bool>? onChanged, int? badge}) =>
    Align(
      alignment: Alignment.topLeft,
      child: KInfoToggleButton(
        on: on,
        onChanged: onChanged,
        icon: KIcons.eye,
        onIcon: KIcons.hideFromLibrary,
        tooltip: 'Show 3',
        onTooltip: 'Hide',
        disabledTooltip: 'None',
        badgeCount: badge,
        badgeLabel: '3 hidden',
      ),
    );

void main() {
  testWidgets('off with a count: pill with the number, tap asks for on', (
    tester,
  ) async {
    final asked = <bool>[];
    await tester.pumpWidget(host(_button(onChanged: asked.add, badge: 3)));
    expect(find.text('3'), findsOneWidget);
    final pill = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .where(
          (d) =>
              d.color ==
              Theme.of(tester.element(find.text('3')))
                  .colorScheme
                  .secondaryContainer,
        );
    expect(pill, isNotEmpty);
    await tester.tap(byIconButton('Show 3'));
    expect(asked, [true]);
  });

  testWidgets('a count above 9 reads 9+', (tester) async {
    await tester.pumpWidget(host(_button(onChanged: (_) {}, badge: 14)));
    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('on: the on tooltip, primary icon, no pill, tap asks for off', (
    tester,
  ) async {
    final asked = <bool>[];
    await tester.pumpWidget(
      host(_button(on: true, onChanged: asked.add, badge: 3)),
    );
    expect(find.text('3'), findsNothing);
    expect(byIconButton('Hide'), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(of: byIconButton('Hide'), matching: find.byType(Icon)),
    );
    expect(icon.icon, KIcons.hideFromLibrary);
    expect(
      icon.color,
      Theme.of(tester.element(find.byType(Icon).first)).colorScheme.primary,
    );
    await tester.tap(byIconButton('Hide'));
    expect(asked, [false]);
  });

  testWidgets('disabled (nothing to reveal): dim, own tooltip, no tap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_button(badge: 0)));
    expect(find.text('0'), findsNothing);
    expect(byIconButton('None'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('None')),
      isSemantics(
        label: 'None',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('semantics: toggled off, then on', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_button(onChanged: (_) {})));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show 3')),
      isSemantics(
        label: 'Show 3',
        isButton: true,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    await tester.pumpWidget(host(_button(on: true, onChanged: (_) {})));
    expect(byToggled('Hide'), findsOneWidget);
    handle.dispose();
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name', (tester) async {
      await tester.pumpWidget(
        host(
          _button(onChanged: (_) {}, badge: 5),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the count is spoken with the label while the pill shows', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_button(onChanged: (_) {}, badge: 3)));
    expect(find.bySemanticsLabel('Show 3, 3 hidden'), findsOneWidget);
    await tester.pumpWidget(
      host(_button(on: true, onChanged: (_) {}, badge: 3)),
    );
    expect(find.bySemanticsLabel('Hide'), findsOneWidget);
    handle.dispose();
  });
}
