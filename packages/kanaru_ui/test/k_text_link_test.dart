import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_link_underline.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _column({
  VoidCallback? onTap,
  String text = 'Artist',
  KTextLinkOverflow overflow = KTextLinkOverflow.ellipsis,
  double width = 300,
}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Above'),
        KTextLink(
          text: text,
          semanticLabel: 'Go to $text',
          onTap: onTap ?? () {},
          overflow: overflow,
        ),
        const IgnorePointer(child: Text('Below')),
      ],
    ),
  ),
);

TextStyle _style(WidgetTester tester) =>
    tester.widget<Text>(find.text('Artist')).style!;

KLinkUnderline _line(WidgetTester tester) =>
    tester.widget<KLinkUnderline>(find.byType(KLinkUnderline));

RenderLinkUnderline _render(WidgetTester tester) =>
    tester.renderObject<RenderLinkUnderline>(find.byType(KLinkUnderline));

Future<TestGesture> _mouse(WidgetTester tester, Offset at) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  await g.moveTo(at);
  await tester.pump();
  return g;
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('normal look in $name: onSurface, 1 px underline at 60 %', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_column(), brightness: brightness, textScale: scale),
      );
      final scheme = Theme.of(tester.element(find.text('Artist'))).colorScheme;
      final s = _style(tester);
      expect(s.color, scheme.onSurface);
      expect(
        s.decoration,
        isNot(TextDecoration.underline),
        reason: 'the underline is painted apart',
      );
      expect(_line(tester).thickness, 1);
      expect(_line(tester).color, scheme.onSurface.withValues(alpha: 0.6));
      expect(_line(tester).gap, 3 + (scale == 1.5 ? 1 : 0));
      expect(s.fontWeight, FontWeight.w500);
    });
  }

  testWidgets('a tap calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    await tester.tap(find.text('Artist'));
    expect(taps, 1);
  });

  testWidgets('hover: 2 px underline at 100 %, back to normal on exit', (
    tester,
  ) async {
    // Hover shows in traditional highlight mode, which desktops run in.
    useKeyboardHighlight();
    await tester.pumpWidget(host(_column()));
    final g = await _mouse(tester, tester.getCenter(find.text('Artist')));
    expect(_line(tester).thickness, 2);
    expect(_line(tester).color.a, 1);
    await g.moveTo(const Offset(700, 500));
    await tester.pump();
    expect(_line(tester).thickness, 1);
  });

  testWidgets('pressed: text fades to 50 % and comes back on release', (
    tester,
  ) async {
    await tester.pumpWidget(host(_column()));
    double opacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('Artist'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    final g = await tester.startGesture(tester.getCenter(find.text('Artist')));
    await tester.pump();
    expect(opacity(), 0.5);
    await g.up();
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('animations off: the press shows at once', (tester) async {
    await tester.pumpWidget(host(_column(), reduceMotion: true));
    final g = await tester.startGesture(tester.getCenter(find.text('Artist')));
    await tester.pump();
    final fade = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Artist'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(fade.opacity, 0.5);
    expect(fade.duration, Duration.zero);
    await g.up();
  });

  testWidgets('keyboard focus draws a 2 px primary ring, a tap does not', (
    tester,
  ) async {
    Finder ring() => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius ==
              KTextLink.ringRadius &&
          (w.decoration as BoxDecoration).border != null,
      description: 'focus ring',
    );
    await tester.pumpWidget(host(_column()));
    await tester.tap(find.text('Artist'));
    await tester.pump();
    expect(ring(), findsNothing);
    useKeyboardHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ring(), findsOneWidget);
    final box = tester.widget<DecoratedBox>(ring()).decoration as BoxDecoration;
    expect((box.border as Border).top.width, 2);
    expect(box.borderRadius, const BorderRadius.all(Radius.circular(4)));
  });

  testWidgets('Tab reaches it and Enter opens it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('semantics: a focusable link with the spoken label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_column()));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Go to Artist')),
      isSemantics(
        label: 'Go to Artist',
        isLink: true,
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('touch area: 48 dp on mobile without growing the line', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    final r = tester.getRect(find.text('Artist'));
    final extra = (48 - r.height) / 2;
    await tester.tapAt(Offset(r.left + 4, r.top - extra + 1));
    await tester.tapAt(Offset(r.left + 4, r.bottom + extra - 1));
    expect(taps, 2);
    await tester.tapAt(Offset(r.left + 4, r.top - extra - 3));
    expect(taps, 2);
    expect(tester.getSize(find.byType(KTextLink)).height, r.height);
  });

  testWidgets('touch area: 40 dp on the desktop shell', (tester) async {
    useWindow(tester, const Size(1400, 900));
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    final r = tester.getRect(find.text('Artist'));
    final extra = (40 - r.height) / 2;
    await tester.tapAt(Offset(r.left + 4, r.top - extra + 1));
    expect(taps, 1);
    await tester.tapAt(Offset(r.left + 4, r.top - extra - 3));
    expect(taps, 1);
  });

  testWidgets('ellipsis keeps one line, wrap uses as many as needed', (
    tester,
  ) async {
    const long = 'A very long artist name that cannot fit in a narrow column';
    await tester.pumpWidget(host(_column(text: long, width: 150)));
    final one = tester.getSize(find.byType(KTextLink)).height;
    await tester.pumpWidget(
      host(_column(text: long, width: 150, overflow: KTextLinkOverflow.wrap)),
    );
    expect(tester.getSize(find.byType(KTextLink)).height, greaterThan(one * 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('200 % text still fits and keeps the underline', (tester) async {
    await tester.pumpWidget(
      host(_column(overflow: KTextLinkOverflow.wrap), textScale: 2),
    );
    expect(tester.takeException(), isNull);
    expect(_line(tester).gap, 5, reason: '5 dp under the baseline at 200 %');
  });

  testWidgets('the underline is 3 dp under the baseline of each line', (
    tester,
  ) async {
    const long = 'A very long artist name that cannot fit in a narrow column';
    await tester.pumpWidget(host(_column()));
    final one = tester.getSize(find.byType(KLinkUnderline)).height;
    await tester.pumpWidget(
      host(_column(text: long, width: 150, overflow: KTextLinkOverflow.wrap)),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(KLinkUnderline),
        matching: find.byType(RichText),
      ),
    );
    final height = tester.getSize(find.byType(KLinkUnderline)).height;
    final lines = _render(tester).segments;
    expect(lines.length, (height / one).round());
    expect(lines.length, greaterThan(1), reason: 'wrapped: one per line');
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: 150);
    addTearDown(painter.dispose);
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    for (var i = 0; i < lines.length; i++) {
      expect(lines[i].top, closeTo(baseline + i * one + 3, 0.6));
      expect(lines[i].height, 1);
      expect(lines[i].width, lessThanOrEqualTo(150));
    }
    await tester.pumpWidget(host(_column()));
    expect(_render(tester).segments, hasLength(1));
  });

  testWidgets('the underline is painted, one stroke per line', (tester) async {
    await tester.pumpWidget(host(_column(text: 'Artist')));
    expect(_render(tester), paints..rect());
  });

  testWidgets('pressed: the underline fades with the text', (tester) async {
    await tester.pumpWidget(host(_column()));
    final fade = find.ancestor(
      of: find.byType(KLinkUnderline),
      matching: find.byType(AnimatedOpacity),
    );
    final g = await tester.startGesture(tester.getCenter(find.text('Artist')));
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(fade).opacity, 0.5);
    await g.up();
  });

  testWidgets('a tap 3 dp left or right of a short link still hits it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: Row(
              children: [
                const SizedBox(width: 40),
                KTextLink(text: 'U2', onTap: () => taps++),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
    final r = tester.getRect(find.text('U2'));
    await tester.tapAt(Offset(r.left - 3, r.center.dy));
    await tester.tapAt(Offset(r.right + 3, r.center.dy));
    expect(taps, 2);
    await tester.tapAt(Offset(r.left - 6, r.center.dy));
    expect(taps, 2);
  });
}
