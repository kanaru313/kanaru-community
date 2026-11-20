import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

const _touch = Size(400, 900);
const _desk = Size(1300, 900);

Widget _tile({
  String title = '15 phút',
  String label = 'Bắt đầu 15 phút',
  VoidCallback? onPressed,
  bool opensMore = false,
  bool autofocus = false,
}) => Center(
  child: SizedBox(
    width: 180,
    child: KStartTile(
      title: title,
      detail: 'đến 23:40',
      semanticLabel: label,
      onPressed: onPressed,
      opensMore: opensMore,
      autofocus: autofocus,
      icon: const Icon(KIcons.add),
    ),
  ),
);

Color? _fill(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.descendant(
      of: find.byType(KFocusRing),
      matching: find.byType(Container),
    ),
  );
  return (box.decoration! as ShapeDecoration).color;
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('lays out without overflow ($name)', (tester) async {
      useWindow(tester, const Size(320, 700));
      await tester.pumpWidget(
        host(
          KStartTileGrid(
            children: [
              for (final t in ['15 phút', '30 phút', '45 phút', '1 giờ'])
                KStartTile(
                  title: t,
                  detail: 'đến 23:40',
                  semanticLabel: t,
                  onPressed: () {},
                ),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports a button with its spoken label; tap starts it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(_tile(onPressed: () => taps++)));
    expect(
      tester.getSemantics(byStartTile('Bắt đầu 15 phút')),
      isSemantics(
        label: 'Bắt đầu 15 phút',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(byStartTile('Bắt đầu 15 phút'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('disabled: reports disabled, ignores taps and Enter', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_tile(autofocus: true)));
    await tester.pump();
    expect(
      tester.getSemantics(byStartTile('Bắt đầu 15 phút')),
      isSemantics(
        label: 'Bắt đầu 15 phút',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    await tester.tap(byStartTile('Bắt đầu 15 phút'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    semantics.dispose();
  });

  testWidgets('Enter and Space activate the focused tile', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(_tile(onPressed: () => taps++, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('hover 8 % and press 10 % layers over the fill', (tester) async {
    useWindow(tester, _desk);
    useKeyboardHighlight();
    await tester.pumpWidget(host(_tile(onPressed: () {})));
    final scheme = Theme.of(tester.element(byStartTile('Bắt đầu 15 phút')))
        .colorScheme;
    final base = scheme.surfaceContainerHighest;
    expect(_fill(tester), base);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(byStartTile('Bắt đầu 15 phút')));
    await tester.pump();
    expect(
      _fill(tester),
      Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.08), base),
    );
    await mouse.down(tester.getCenter(byStartTile('Bắt đầu 15 phút')));
    await tester.pump();
    expect(
      _fill(tester),
      Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.10), base),
    );
    await mouse.up();
  });

  testWidgets('keyboard focus draws the ring', (tester) async {
    useKeyboardHighlight();
    await tester.pumpWidget(host(_tile(onPressed: () {}, autofocus: true)));
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
  });

  testWidgets('touch press scales to 97 %, reduced motion does not', (
    tester,
  ) async {
    useWindow(tester, _touch);
    await tester.pumpWidget(host(_tile(onPressed: () {})));
    final g = await tester.startGesture(
      tester.getCenter(byStartTile('Bắt đầu 15 phút')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.97,
    );
    await g.up();
    await tester.pumpWidget(host(_tile(onPressed: () {}), reduceMotion: true));
    final g2 = await tester.startGesture(
      tester.getCenter(byStartTile('Bắt đầu 15 phút')),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await g2.up();
  });

  testWidgets('opensMore: outlined, icon on touch only', (tester) async {
    useWindow(tester, _touch);
    await tester.pumpWidget(
      host(_tile(title: 'Tuỳ chỉnh…', onPressed: () {}, opensMore: true)),
    );
    expect(find.byIcon(KIcons.add), findsOneWidget);
    expect(_fill(tester), isNull);
    useWindow(tester, _desk);
    await tester.pumpWidget(
      host(_tile(title: 'Tuỳ chỉnh…', onPressed: () {}, opensMore: true)),
    );
    expect(find.byIcon(KIcons.add), findsNothing);
  });

  group('grid', () {
    Widget grid(int n) => KStartTileGrid(
      children: [
        for (var i = 0; i < n; i++)
          KStartTile(title: 't$i', semanticLabel: 't$i', onPressed: () {}),
      ],
    );

    int columns(WidgetTester tester, int n) {
      final top = tester.getTopLeft(byStartTile('t0')).dy;
      return [
        for (var i = 0; i < n; i++)
          if (tester.getTopLeft(byStartTile('t$i')).dy == top) i,
      ].length;
    }

    testWidgets('2 columns on touch, 1 at 200 % text', (tester) async {
      useWindow(tester, _touch);
      await tester.pumpWidget(host(grid(5)));
      expect(columns(tester, 5), 2);
      await tester.pumpWidget(host(grid(5), textScale: 2));
      expect(columns(tester, 5), 1);
    });

    testWidgets('3 columns on desktop, 2 at 200 % text', (tester) async {
      useWindow(tester, _desk);
      await tester.pumpWidget(host(grid(5)));
      expect(columns(tester, 5), 3);
      await tester.pumpWidget(host(grid(5), textScale: 2));
      expect(columns(tester, 5), 2);
    });
  });

  group('arrow navigation', () {
    late Map<String, FocusNode> nodes;

    Widget area() {
      nodes = {
        for (final k in ['a', 'b', 'c', 'd', 'e']) k: FocusNode(),
      };
      addTearDown(() {
        for (final n in nodes.values) {
          n.dispose();
        }
      });
      return Column(
        children: [
          KStartArea(
            child: Column(
              children: [
                KStartTileGrid(
                  children: [
                    for (final k in ['a', 'b', 'c', 'd', 'e'])
                      KStartTile(
                        title: k,
                        semanticLabel: k,
                        focusNode: nodes[k],
                        onPressed: () {},
                      ),
                  ],
                ),
                SelectionRow(
                  action: true,
                  selected: false,
                  title: const Text('r1'),
                  onTap: () {},
                ),
                const SelectionRow(
                  action: true,
                  selected: false,
                  title: Text('r2'),
                  disabledReason: 'Không có album',
                ),
                SelectionRow(
                  action: true,
                  selected: false,
                  title: const Text('r3'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('footer')),
        ],
      );
    }

    String focused() {
      final f = FocusManager.instance.primaryFocus;
      for (final e in nodes.entries) {
        if (e.value == f) return e.key;
      }
      final ctx = f?.context;
      if (ctx == null) return 'none';
      for (final t in ['r1', 'r2', 'r3', 'footer']) {
        if (find
            .descendant(of: find.byWidget(ctx.widget), matching: find.text(t))
            .evaluate()
            .isNotEmpty) {
          return t;
        }
      }
      return 'other';
    }

    Future<void> go(
      WidgetTester tester,
      String from,
      LogicalKeyboardKey key,
      String to,
    ) async {
      nodes[from]!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(focused(), to, reason: '$from + ${key.keyLabel}');
    }

    testWidgets('touch: each direction picks the nearest, skips disabled', (
      tester,
    ) async {
      useWindow(tester, _touch);
      await tester.pumpWidget(host(area()));
      await go(tester, 'a', LogicalKeyboardKey.arrowRight, 'b');
      await go(tester, 'b', LogicalKeyboardKey.arrowLeft, 'a');
      await go(tester, 'a', LogicalKeyboardKey.arrowDown, 'c');
      await go(tester, 'd', LogicalKeyboardKey.arrowUp, 'b');
      await go(tester, 'e', LogicalKeyboardKey.arrowRight, 'e');
      await go(tester, 'e', LogicalKeyboardKey.arrowDown, 'r1');
      await go(tester, 'e', LogicalKeyboardKey.arrowUp, 'c');
    });

    testWidgets('rows: down skips the disabled row, up returns; no exit', (
      tester,
    ) async {
      useWindow(tester, _touch);
      await tester.pumpWidget(host(area()));
      nodes['e']!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(), 'r1');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(), 'r3');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(), 'r3', reason: 'footer is reached with Tab only');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(), 'r1');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(), 'e');
    });

    testWidgets('desktop: three columns, left / right / up / down', (
      tester,
    ) async {
      useWindow(tester, _desk);
      await tester.pumpWidget(host(area()));
      await go(tester, 'a', LogicalKeyboardKey.arrowRight, 'b');
      await go(tester, 'b', LogicalKeyboardKey.arrowRight, 'c');
      await go(tester, 'c', LogicalKeyboardKey.arrowRight, 'c');
      await go(tester, 'b', LogicalKeyboardKey.arrowDown, 'e');
      await go(tester, 'e', LogicalKeyboardKey.arrowUp, 'b');
      await go(tester, 'd', LogicalKeyboardKey.arrowRight, 'e');
      await go(tester, 'c', LogicalKeyboardKey.arrowDown, 'e');
      await go(tester, 'e', LogicalKeyboardKey.arrowDown, 'r1');
    });

    testWidgets('Enter on the focused tile starts it', (tester) async {
      useWindow(tester, _touch);
      await tester.pumpWidget(host(area()));
      nodes['a']!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(tester.takeException(), isNull);
    });
  });
}
