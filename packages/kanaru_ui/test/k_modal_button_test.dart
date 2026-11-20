import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/fit.dart';
import 'support/host.dart';

Widget _button({
  String label = 'Tạm dừng đếm',
  KModalEmphasis emphasis = KModalEmphasis.secondary,
  bool prominent = false,
  VoidCallback? onPressed,
  FocusNode? focusNode,
  IconData? icon,
}) => Center(
  child: KModalButton(
    label: label,
    emphasis: emphasis,
    prominent: prominent,
    onPressed: onPressed,
    focusNode: focusNode,
    icon: icon,
  ),
);

ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as ShapeDecoration;

TextStyle _text(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  testWidgets('semanticLabel replaces the label for a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: KModalButton(
            label: '+5 phút',
            semanticLabel: 'Thêm 5 phút',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Thêm 5 phút'), findsOneWidget);
    expect(find.bySemanticsLabel('+5 phút'), findsNothing);
    semantics.dispose();
  });

  testWidgets('semantics: focusable while enabled, focused once focused', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(_button(onPressed: () {}, focusNode: node)));
    expect(
      tester.getSemantics(byModalButton('Tạm dừng đếm')),
      isSemantics(isButton: true, isFocusable: true, isFocused: false),
    );
    node.requestFocus();
    await tester.pump();
    expect(
      tester.getSemantics(byModalButton('Tạm dừng đếm')),
      isSemantics(isButton: true, isFocusable: true, isFocused: true),
    );
    await tester.pumpWidget(host(_button()));
    expect(
      tester.getSemantics(byModalButton('Tạm dừng đếm')),
      isSemantics(isButton: true, isFocusable: false),
    );
    semantics.dispose();
  });

  for (final e in KModalEmphasis.values) {
    testWidgets('200 % text at 320: ${e.name} label grows the button, '
        'nothing is cut', (tester) async {
      useWindow(tester, const Size(320, 500));
      await tester.pumpWidget(
        host(
          _button(
            emphasis: e,
            label: 'Tạm dừng đếm',
            prominent: true,
            onPressed: () {},
            icon: KIcons.add,
          ),
          textScale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      expectTextsFit(tester, find.byType(KModalButton));
    });
  }

  for (final (name, brightness, scale) in hostVariants) {
    for (final e in KModalEmphasis.values) {
      testWidgets('${e.name} lays out at 320 ($name)', (tester) async {
        useWindow(tester, const Size(320, 500));
        await tester.pumpWidget(
          host(
            _button(emphasis: e, prominent: true, onPressed: () {}),
            brightness: brightness,
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('semantics: label, button, enabled; tap fires; disabled not', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(_button(onPressed: () => taps++)));
    expect(
      tester.getSemantics(byModalButton('Tạm dừng đếm')),
      isSemantics(
        label: 'Tạm dừng đếm',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(byModalButton('Tạm dừng đếm'));
    expect(taps, 1);
    await tester.pumpWidget(host(_button()));
    expect(
      tester.getSemantics(byModalButton('Tạm dừng đếm')),
      isSemantics(
        label: 'Tạm dừng đếm',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('heights: 56 footer / 64 prominent on touch, 40 on desktop', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_button(onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(byModalButton('Tạm dừng đếm')).height, 56);
    await tester.pumpWidget(host(_button(prominent: true, onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(byModalButton('Tạm dừng đếm')).height, 64);
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_button(prominent: true, onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(byModalButton('Tạm dừng đếm')).height, 40);
  });

  testWidgets('prominent on touch has radius 20', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_button(prominent: true, onPressed: () {})));
    expect(
      (_deco(tester).shape as RoundedRectangleBorder).borderRadius,
      KRadius.lg,
    );
  });

  testWidgets('destructive: error text on an error 40 % outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        _button(
          label: 'Tắt hẹn giờ',
          emphasis: KModalEmphasis.destructive,
          onPressed: () {},
        ),
      ),
    );
    final scheme = Theme.of(tester.element(byModalButton('Tắt hẹn giờ')))
        .colorScheme;
    expect(_text(tester, 'Tắt hẹn giờ').color, scheme.error);
    expect(
      (_deco(tester).shape as RoundedRectangleBorder).side.color,
      scheme.error.withValues(alpha: 0.4),
    );
    expect(
      _deco(tester).color,
      Color.alphaBlend(
        scheme.error.withValues(alpha: 0),
        const Color(0x00000000),
      ),
    );
  });

  testWidgets('primary fills with primary; tonal with secondaryContainer', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(_button(emphasis: KModalEmphasis.primary, onPressed: () {})),
    );
    final scheme = Theme.of(tester.element(byModalButton('Tạm dừng đếm')))
        .colorScheme;
    expect(_deco(tester).color, scheme.primary);
    await tester.pumpWidget(
      host(_button(emphasis: KModalEmphasis.tonal, onPressed: () {})),
    );
    await tester.pumpAndSettle();
    expect(_deco(tester).color, scheme.secondaryContainer);
  });

  testWidgets('emphasis swap keeps the element, the node and the focus', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(
        _button(
          emphasis: KModalEmphasis.secondary,
          onPressed: () {},
          focusNode: node,
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    final before = tester.element(find.byType(KModalButton));
    expect(node.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(
      host(
        _button(
          label: 'Tiếp tục đếm',
          emphasis: KModalEmphasis.primary,
          prominent: true,
          icon: KIcons.play,
          onPressed: () {},
          focusNode: node,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      identical(tester.element(find.byType(KModalButton)), before),
      isTrue,
    );
    expect(node.hasPrimaryFocus, isTrue);
    expect(byModalButton('Tiếp tục đếm'), findsOneWidget);
  });

  testWidgets('keyboard focus draws the ring; Enter and Space fire', (
    tester,
  ) async {
    useKeyboardHighlight();
    var taps = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(_button(onPressed: () => taps++, focusNode: node)),
    );
    node.requestFocus();
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('hover 8 % and press 10 % layers (primary)', (tester) async {
    useKeyboardHighlight();
    await tester.pumpWidget(
      host(_button(emphasis: KModalEmphasis.primary, onPressed: () {})),
    );
    final scheme = Theme.of(tester.element(byModalButton('Tạm dừng đếm')))
        .colorScheme;
    final c = tester.getCenter(byModalButton('Tạm dừng đếm'));
    final g = await tester.startGesture(c);
    await tester.pumpAndSettle();
    expect(
      _deco(tester).color,
      Color.alphaBlend(
        scheme.onPrimary.withValues(alpha: 0.10),
        scheme.primary,
      ),
    );
    await g.up();
  });

  testWidgets('reduced motion: emphasis changes apply at once', (tester) async {
    await tester.pumpWidget(
      host(_button(onPressed: () {}), reduceMotion: true),
    );
    await tester.pumpWidget(
      host(
        _button(emphasis: KModalEmphasis.primary, onPressed: () {}),
        reduceMotion: true,
      ),
    );
    await tester.pump();
    final scheme = Theme.of(tester.element(byModalButton('Tạm dừng đếm')))
        .colorScheme;
    expect(_deco(tester).color, scheme.primary);
  });
}
