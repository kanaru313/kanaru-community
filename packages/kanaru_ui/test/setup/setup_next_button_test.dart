import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _button({
  required bool visible,
  VoidCallback? onPressed,
  String? tooltip,
}) => Center(
  child: SetupNextButton(
    visible: visible,
    onPressed: onPressed,
    semanticLabel: 'Continue',
    disabledTooltip: tooltip,
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('is 64 x 64 and primary ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          _button(visible: true, onPressed: () {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SetupNextButton)), const Size(64, 64));
      final scheme = Theme.of(tester.element(find.byIcon(KIcons.arrowForward)))
          .colorScheme;
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SetupNextButton),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, scheme.primary);
    });
  }

  testWidgets('taps call back when enabled', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(_button(visible: true, onPressed: () => taps++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SetupNextButton));
    expect(taps, 1);
  });

  testWidgets('hidden: not tappable and not in the semantics tree', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(_button(visible: false, onPressed: () => taps++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SetupNextButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.bySemanticsLabel('Continue'), findsNothing);
    handle.dispose();
  });

  testWidgets('scales in when it appears', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_button(visible: false, onPressed: () {})));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(_button(visible: true, onPressed: () {})));
    await tester.pump(const Duration(milliseconds: 60));
    final transition = tester.widget<ScaleTransition>(
      find.descendant(
        of: find.byType(SetupNextButton),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(transition.scale.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(transition.scale.value, 1);
    expect(tester.getSize(find.byType(SetupNextButton)), const Size(64, 64));
  });

  testWidgets('reduced motion: no scale animation', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_button(visible: false, onPressed: () {}), reduceMotion: true),
    );
    await tester.pumpWidget(
      host(_button(visible: true, onPressed: () {}), reduceMotion: true),
    );
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.duration, Duration.zero);
  });

  testWidgets('disabled: dimmed, inert, tooltip on long press', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_button(visible: true, tooltip: 'Add at least one folder')),
    );
    await tester.pumpAndSettle();
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(SetupNextButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, lessThan(0.5));
    await tester.longPress(find.byType(SetupNextButton));
    await tester.pumpAndSettle();
    expect(find.text('Add at least one folder'), findsOneWidget);
  });

  testWidgets('enabled button has no tooltip', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_button(visible: true, onPressed: () {}, tooltip: 'unused')),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(SetupNextButton));
    await tester.pumpAndSettle();
    expect(find.text('unused'), findsNothing);
  });
}
