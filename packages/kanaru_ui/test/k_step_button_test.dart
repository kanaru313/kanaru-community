import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _step({VoidCallback? onPressed, bool autofocus = false}) => Center(
  child: KStepButton(
    icon: KIcons.add,
    semanticLabel: 'Thêm 5 phút',
    onPressed: onPressed,
    autofocus: autofocus,
  ),
);

Color? _fill(WidgetTester tester) =>
    (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                .decoration!
            as ShapeDecoration)
        .color;

void main() {
  testWidgets('semantics: focusable while enabled, focused once focused', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_step(onPressed: () {})));
    expect(
      tester.getSemantics(byStepButton('Thêm 5 phút')),
      isSemantics(isButton: true, isFocusable: true, isFocused: false),
    );
    await tester.pumpWidget(
      host(
        KeyedSubtree(
          key: UniqueKey(),
          child: _step(onPressed: () {}, autofocus: true),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSemantics(byStepButton('Thêm 5 phút')),
      isSemantics(isButton: true, isFocusable: true, isFocused: true),
    );
    await tester.pumpWidget(host(_step()));
    expect(
      tester.getSemantics(byStepButton('Thêm 5 phút')),
      isSemantics(isButton: true, isFocusable: false),
    );
    semantics.dispose();
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('builds enabled and disabled ($name)', (tester) async {
      useWindow(tester, const Size(320, 400));
      await tester.pumpWidget(
        host(
          Row(
            children: [
              _step(onPressed: () {}),
              _step(),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('semantics: label, button, enabled; tap fires', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(_step(onPressed: () => taps++)));
    expect(
      tester.getSemantics(byStepButton('Thêm 5 phút')),
      isSemantics(
        label: 'Thêm 5 phút',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(byStepButton('Thêm 5 phút'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('at its bound: disabled, dimmed, ignores taps', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_step()));
    expect(
      tester.getSemantics(byStepButton('Thêm 5 phút')),
      isSemantics(
        label: 'Thêm 5 phút',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    final scheme = Theme.of(tester.element(byStepButton('Thêm 5 phút')))
        .colorScheme;
    expect(_fill(tester), scheme.onSurface.withValues(alpha: 0.10));
    semantics.dispose();
  });

  testWidgets('48 on touch shells, 40 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_step(onPressed: () {})));
    expect(tester.getSize(byStepButton('Thêm 5 phút')), const Size(48, 48));
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_step(onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(byStepButton('Thêm 5 phút')), const Size(40, 40));
  });

  testWidgets('hover 8 % and press 10 % of onSecondaryContainer', (
    tester,
  ) async {
    useKeyboardHighlight();
    await tester.pumpWidget(host(_step(onPressed: () {})));
    final scheme = Theme.of(tester.element(byStepButton('Thêm 5 phút')))
        .colorScheme;
    final base = scheme.secondaryContainer;
    expect(_fill(tester), base);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final c = tester.getCenter(byStepButton('Thêm 5 phút'));
    await mouse.moveTo(c);
    await tester.pumpAndSettle();
    expect(
      _fill(tester),
      Color.alphaBlend(
        scheme.onSecondaryContainer.withValues(alpha: 0.08),
        base,
      ),
    );
    await mouse.down(c);
    await tester.pumpAndSettle();
    expect(
      _fill(tester),
      Color.alphaBlend(
        scheme.onSecondaryContainer.withValues(alpha: 0.10),
        base,
      ),
    );
    await mouse.up();
  });

  testWidgets('keyboard focus draws the ring; Enter fires', (tester) async {
    useKeyboardHighlight();
    var taps = 0;
    await tester.pumpWidget(
      host(_step(onPressed: () => taps++, autofocus: true)),
    );
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('reduced motion: layers apply at once', (tester) async {
    useKeyboardHighlight();
    await tester.pumpWidget(host(_step(onPressed: () {}), reduceMotion: true));
    final scheme = Theme.of(tester.element(byStepButton('Thêm 5 phút')))
        .colorScheme;
    final g = await tester.startGesture(
      tester.getCenter(byStepButton('Thêm 5 phút')),
    );
    await tester.pump();
    expect(
      _fill(tester),
      Color.alphaBlend(
        scheme.onSecondaryContainer.withValues(alpha: 0.10),
        scheme.secondaryContainer,
      ),
    );
    await g.up();
  });
}
