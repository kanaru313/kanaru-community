import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget button({
  VoidCallback? onPressed,
  VoidCallback? onLongPress,
  bool autofocus = false,
  bool? selected,
  Color? color,
}) => Center(
  child: KIconButton(
    icon: Icons.add,
    tooltip: 'Add',
    onPressed: onPressed,
    onLongPress: onLongPress,
    autofocus: autofocus,
    selected: selected,
    color: color,
  ),
);

Finder get glyph =>
    find.descendant(of: find.byType(KIconButton), matching: find.byType(Icon));

Color glyphColor(WidgetTester tester) => tester.widget<Icon>(glyph).color!;

ColorScheme scheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(KIconButton))).colorScheme;

/// Lets the press hold and fade finish so no timer outlives the test.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(KMotion.press);
}

void main() {
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  group('tap and press', () {
    testWidgets('tap fires onPressed once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(button(onPressed: () => taps++)));
      await tester.tap(find.byType(KIconButton));
      await settle(tester);
      expect(taps, 1);
    });

    testWidgets('a quick tap in a list row still shows a dimmed frame', (
      tester,
    ) async {
      var pressed = 0, rowTaps = 0, rowLongs = 0;
      await tester.pumpWidget(
        host(
          ListView(
            children: [
              GestureDetector(
                onTap: () => rowTaps++,
                onLongPress: () => rowLongs++,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const Spacer(),
                      KIconButton(
                        icon: Icons.add,
                        tooltip: 'Add',
                        onPressed: () => pressed++,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final rest = glyphColor(tester);
      expect(rest.a, 1);
      await tester.tap(find.byType(KIconButton));
      await tester.pump();
      // Held fully dimmed, not already fading, for the whole minimum hold.
      expect(glyphColor(tester).a, closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 90));
      expect(glyphColor(tester).a, closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(KMotion.press);
      expect(glyphColor(tester), rest);
      expect([pressed, rowTaps, rowLongs], [1, 0, 0]);
    });

    testWidgets('reduced motion holds the pulse then ends it without a fade', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(button(onPressed: () {}), reduceMotion: true),
      );
      await tester.tap(find.byType(KIconButton));
      await tester.pump();
      expect(glyphColor(tester).a, lessThan(1));
      await tester.pump(const Duration(milliseconds: 50));
      expect(glyphColor(tester).a, lessThan(1));
      await tester.pump(const Duration(milliseconds: 60));
      expect(glyphColor(tester).a, 1);
    });

    testWidgets('a cancelled press restores the colour and does not fire', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(host(button(onPressed: () => taps++)));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(KIconButton)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(glyphColor(tester).a, closeTo(0.5, 0.01));
      await gesture.moveBy(const Offset(0, 120));
      await gesture.up();
      await settle(tester);
      expect(glyphColor(tester).a, 1);
      expect(taps, 0);
    });

    testWidgets('a press that outlasts the hold fades back after release', (
      tester,
    ) async {
      await tester.pumpWidget(host(button(onPressed: () {})));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(KIconButton)),
      );
      // The press registers after 100 ms and is held 100 ms more.
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.up();
      await tester.pump();
      expect(glyphColor(tester).a, closeTo(0.5, 0.01));
      await tester.pump(KMotion.press);
      expect(glyphColor(tester).a, 1);
    });

    testWidgets('keyboard activation does not dim the icon', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(button(onPressed: () => taps++, autofocus: true)),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      expect(glyphColor(tester).a, 1);
    });
  });

  group('long press', () {
    testWidgets('gives long press feedback', (tester) async {
      var haptics = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        host(button(onPressed: () {}, onLongPress: () {})),
      );
      await tester.longPress(find.byType(KIconButton));
      await settle(tester);
      expect(haptics, 1);
    });

    testWidgets('fires onLongPress and not onPressed', (tester) async {
      var longs = 0, taps = 0;
      await tester.pumpWidget(
        host(button(onPressed: () => taps++, onLongPress: () => longs++)),
      );
      await tester.longPress(find.byType(KIconButton));
      await settle(tester);
      expect([longs, taps], [1, 0]);
    });

    testWidgets(
      'without a callback shows the tooltip, not the row long press',
      (tester) async {
        var rowLongs = 0;
        await tester.pumpWidget(
          host(
            GestureDetector(
              onLongPress: () => rowLongs++,
              child: button(onPressed: () {}),
            ),
          ),
        );
        expect(find.text('Add'), findsNothing);
        await tester.longPress(find.byType(KIconButton));
        await tester.pump();
        expect(find.text('Add'), findsOneWidget);
        expect(rowLongs, 0);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      },
    );
  });

  group('keyboard', () {
    for (final (name, key) in [
      ('Enter', LogicalKeyboardKey.enter),
      ('NumpadEnter', LogicalKeyboardKey.numpadEnter),
      ('Space', LogicalKeyboardKey.space),
      ('Select', LogicalKeyboardKey.select),
    ]) {
      testWidgets('$name activates the focused button', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          host(button(onPressed: () => taps++, autofocus: true)),
        );
        await tester.pump();
        await tester.sendKeyEvent(key);
        expect(taps, 1);
      });
    }

    testWidgets('the ring shows for keyboard focus only', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await tester.pumpWidget(host(button(onPressed: () {}, autofocus: true)));
      await tester.pump();
      Color ring() =>
          ((tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(KIconButton.ringKey),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration)
                  as BoxDecoration)
              .border!
              .top
              .color;
      expect(ring().a, 0);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(ring(), scheme(tester).primary);
    });

    testWidgets('ownsPrimaryFocus is true only while the button has focus', (
      tester,
    ) async {
      final other = FocusNode();
      addTearDown(other.dispose);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              button(onPressed: () {}, autofocus: true),
              Focus(focusNode: other, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(KIconButton.ownsPrimaryFocus(), isTrue);
      other.requestFocus();
      await tester.pump();
      expect(KIconButton.ownsPrimaryFocus(), isFalse);
    });
  });

  group('disabled', () {
    testWidgets('no callbacks, 38 % colour, tooltip kept, not focusable', (
      tester,
    ) async {
      await tester.pumpWidget(host(button(autofocus: true)));
      await tester.pump();
      await tester.tap(find.byType(KIconButton));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(
        glyphColor(tester),
        scheme(tester).onSurface.withValues(alpha: 0.38),
      );
      // Tooltip is kept (the "coming soon" buttons rely on it) but excluded
      // from semantics, so `find.byTooltip` does not see it: read the widget.
      final tip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(KIconButton),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tip.message, 'Add');
      expect(
        tester
            .widget<FocusableActionDetector>(
              find.byType(FocusableActionDetector),
            )
            .enabled,
        isFalse,
      );
      expect(KIconButton.ownsPrimaryFocus(), isFalse);
    });

    testWidgets('hover does not change a disabled button', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pumpWidget(host(button()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(KIconButton)));
      await tester.pump();
      expect(
        glyphColor(tester),
        scheme(tester).onSurface.withValues(alpha: 0.38),
      );
    });
  });

  testWidgets('a disabled button in a row lets the row take the tap', (
    tester,
  ) async {
    var rowTaps = 0;
    await tester.pumpWidget(
      host(
        GestureDetector(
          onTap: () => rowTaps++,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const Spacer(),
                const KIconButton(
                  icon: Icons.add,
                  tooltip: 'Add',
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(KIconButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(rowTaps, 1);
  });

  group('colour and cursor', () {
    Future<void> hover(WidgetTester tester) async {
      // Hover and focus highlights only show in traditional (mouse and
      // keyboard) highlight mode, which is what a desktop shell runs in.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(KIconButton)));
      await tester.pump();
    }

    testWidgets('rest onSurfaceVariant, hover onSurface', (tester) async {
      await tester.pumpWidget(host(button(onPressed: () {})));
      expect(glyphColor(tester), scheme(tester).onSurfaceVariant);
      await hover(tester);
      expect(glyphColor(tester), scheme(tester).onSurface);
    });

    testWidgets('KIconButtonColors sets rest and hover', (tester) async {
      const rest = Color(0xFFAA0000), over = Color(0xFF0000AA);
      await tester.pumpWidget(
        host(
          KIconButtonColors(
            rest: rest,
            hover: over,
            child: button(onPressed: () {}),
          ),
        ),
      );
      expect(glyphColor(tester), rest);
      await hover(tester);
      expect(glyphColor(tester), over);
    });

    testWidgets('an own colour beats the inherited rest colour', (
      tester,
    ) async {
      const rest = Color(0xFFAA0000), own = Color(0xFF00AA00);
      await tester.pumpWidget(
        host(
          KIconButtonColors(
            rest: rest,
            child: button(onPressed: () {}, color: own),
          ),
        ),
      );
      expect(glyphColor(tester), own);
      await hover(tester);
      expect(glyphColor(tester), scheme(tester).onSurface);
    });

    testWidgets('selected is primary and a selectedIcon replaces the glyph', (
      tester,
    ) async {
      Widget build(bool on) => host(
        Center(
          child: KIconButton(
            icon: Icons.add,
            selectedIcon: Icons.remove,
            selected: on,
            tooltip: 'Add',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpWidget(build(false));
      expect(tester.widget<Icon>(glyph).icon, Icons.add);
      await tester.pumpWidget(build(true));
      expect(tester.widget<Icon>(glyph).icon, Icons.remove);
      expect(glyphColor(tester), scheme(tester).primary);
    });

    testWidgets('hand cursor when enabled, basic when disabled', (
      tester,
    ) async {
      MouseCursor cursor() => tester
          .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
          .mouseCursor;
      await tester.pumpWidget(host(button(onPressed: () {})));
      expect(cursor(), SystemMouseCursors.click);
      await tester.pumpWidget(host(button()));
      expect(cursor(), SystemMouseCursors.basic);
    });
  });

  testWidgets('disabling mid-press drops the press look without an error', (
    tester,
  ) async {
    await tester.pumpWidget(host(button(onPressed: () {})));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(KIconButton)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(glyphColor(tester).a, lessThan(1));
    await tester.pumpWidget(host(button()));
    expect(
      glyphColor(tester),
      scheme(tester).onSurface.withValues(alpha: 0.38),
    );
    await gesture.up();
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing mid-pulse leaves no timer or ticker', (tester) async {
    await tester.pumpWidget(host(button(onPressed: () {})));
    await tester.tap(find.byType(KIconButton));
    await tester.pump();
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
