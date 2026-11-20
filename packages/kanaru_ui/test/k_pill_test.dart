import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _pill({
  String label = '23:41',
  VoidCallback? onPressed,
  FocusNode? focusNode,
  bool held = false,
  KPillPlacement placement = KPillPlacement.standard,
  String? widest,
  String? tooltip,
}) => Center(
  child: KPill(
    icon: KIcons.sleepTimerActive,
    label: label,
    onPressed: onPressed,
    focusNode: focusNode,
    held: held,
    placement: placement,
    widestLabel: widest,
    tooltip: tooltip,
    semanticLabel: 'Hẹn giờ ngủ: còn $label',
  ),
);

Color _bg(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(KPill),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (box.decoration! as ShapeDecoration).color!;
}

Color _iconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byType(Icon)).color!;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  testWidgets('info pill is 36 on touch, 32 on desktop, not focusable', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_pill()));
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 36);
    expect(find.byType(FocusableActionDetector), findsNothing);
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_pill()));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 32);
  });

  testWidgets('button pill is 40, player bar placement 36', (tester) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_pill(onPressed: () {})));
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 40);
    await tester.pumpWidget(
      host(_pill(onPressed: () {}, placement: KPillPlacement.playerBar)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 36);
  });

  testWidgets('hover 8 %, pressed 10 %, tap fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_pill(onPressed: () => taps++)));
    final rest = _bg(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(KPill)));
    await tester.pumpAndSettle();
    final hover = _bg(tester);
    expect(hover, isNot(rest));
    await mouse.down(tester.getCenter(find.byType(KPill)));
    await tester.pumpAndSettle();
    expect(_bg(tester), isNot(hover));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('keyboard focus shows the ring, Enter activates', (tester) async {
    var taps = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(_pill(onPressed: () => taps++, focusNode: node)),
    );
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('focus node survives label changes', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(_pill(onPressed: () {}, focusNode: node)));
    node.requestFocus();
    await tester.pumpAndSettle();
    for (final l in ['23:40', '23:39', '3 bài']) {
      await tester.pumpWidget(
        host(_pill(label: l, onPressed: () {}, focusNode: node)),
      );
      expect(node.hasPrimaryFocus, isTrue);
    }
  });

  testWidgets('width stays stable across label values with widestLabel', (
    tester,
  ) async {
    final widths = <double>[];
    for (final l in ['1', '11', '23:41', '2:05:09']) {
      await tester.pumpWidget(
        host(_pill(label: l, onPressed: () {}, widest: '2:05:09')),
      );
      widths.add(tester.getSize(find.byType(KPill)).width);
    }
    expect(widths.toSet(), hasLength(1));
  });

  testWidgets('long label is ellipsised at 56', (tester) async {
    await tester.pumpWidget(
      host(_pill(label: 'Hết album này và hàng đợi dài', onPressed: () {})),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(Text)).width, lessThanOrEqualTo(56));
  });

  testWidgets('held turns the icon to onSurfaceVariant', (tester) async {
    await tester.pumpWidget(host(_pill()));
    final scheme = Theme.of(tester.element(find.byType(KPill))).colorScheme;
    expect(_iconColor(tester), scheme.primary);
    await tester.pumpWidget(host(_pill(held: true)));
    expect(_iconColor(tester), scheme.onSurfaceVariant);
  });

  testWidgets('semantics: info = label, button = button with caller label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_pill(onPressed: () {}, tooltip: 'Hẹn giờ')));
    expect(
      tester.getSemantics(find.byType(KPill)),
      matchesSemantics(
        label: 'Hẹn giờ ngủ: còn 23:41',
        isButton: true,
        hasTapAction: true,
      ),
    );
    await tester.pumpWidget(host(_pill()));
    expect(find.bySemanticsLabel('Hẹn giờ ngủ: còn 23:41'), findsOneWidget);
    handle.dispose();
  });

  for (final v in hostVariants) {
    testWidgets('renders in ${v.$1} without overflow', (tester) async {
      useWindow(tester, const Size(320, 640));
      await tester.pumpWidget(
        host(
          _pill(onPressed: () {}),
          brightness: v.$2,
          textScale: v.$3,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 % text and reduced motion keep working', (tester) async {
    useWindow(tester, const Size(320, 640));
    await tester.pumpWidget(
      host(_pill(onPressed: () {}), textScale: 2.0, reduceMotion: true),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
  });
}
