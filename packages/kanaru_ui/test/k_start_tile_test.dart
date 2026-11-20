import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/fit.dart';
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

  for (final width in [320.0, 1400.0]) {
    testWidgets('200 % text at width $width: every tile shows all its text', (
      tester,
    ) async {
      useWindow(tester, Size(width, 900));
      await tester.pumpWidget(
        host(
          Padding(
            padding: const EdgeInsets.all(16),
            child: KStartTileGrid(
              children: [
                for (final t in ['15 phút', '30 phút', '45 phút', '1 giờ 30'])
                  KStartTile(
                    title: t,
                    detail: 'đến 23:40',
                    semanticLabel: t,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
          textScale: 2.0,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final tile in find.byType(KStartTile).evaluate()) {
        expectTextsFit(tester, find.byElementPredicate((e) => e == tile));
      }
    });
  }

  testWidgets('semantics: focusable while enabled, focused once focused', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_tile(onPressed: () {})));
    expect(
      tester.getSemantics(byStartTile('Bắt đầu 15 phút')),
      isSemantics(isButton: true, isFocusable: true, isFocused: false),
    );
    await tester.pumpWidget(
      host(
        KeyedSubtree(
          key: UniqueKey(),
          child: _tile(onPressed: () {}, autofocus: true),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSemantics(byStartTile('Bắt đầu 15 phút')),
      isSemantics(isButton: true, isFocusable: true, isFocused: true),
    );
    await tester.pumpWidget(host(_tile()));
    expect(
      tester.getSemantics(byStartTile('Bắt đầu 15 phút')),
      isSemantics(isButton: true, isFocusable: false),
    );
    semantics.dispose();
  });

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

  testWidgets('touch tile: 56 tall, radius 12', (tester) async {
    useWindow(tester, _touch);
    await tester.pumpWidget(host(_tile(onPressed: () {})));
    expect(tester.getSize(byStartTile('Bắt đầu 15 phút')).height, 56);
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(KFocusRing),
        matching: find.byType(Container),
      ),
    );
    final shape = (box.decoration! as ShapeDecoration).shape;
    expect((shape as RoundedRectangleBorder).borderRadius, KRadius.sm);
  });

  testWidgets('opensMore: outlined, no icon on either shell', (tester) async {
    useWindow(tester, _touch);
    await tester.pumpWidget(
      host(_tile(title: 'Tuỳ chỉnh…', onPressed: () {}, opensMore: true)),
    );
    expect(find.byType(Icon), findsNothing);
    expect(_fill(tester), isNull);
    useWindow(tester, _desk);
    await tester.pumpWidget(
      host(_tile(title: 'Tuỳ chỉnh…', onPressed: () {}, opensMore: true)),
    );
    expect(find.byType(Icon), findsNothing);
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

    testWidgets('3 columns on touch, 1 at 200 % text', (tester) async {
      useWindow(tester, _touch);
      await tester.pumpWidget(host(grid(6)));
      expect(columns(tester, 6), 3);
      await tester.pumpWidget(host(grid(6), textScale: 2));
      expect(columns(tester, 6), 1);
    });

    testWidgets('touch: 2 columns when the grid is narrower than 360', (
      tester,
    ) async {
      for (final (width, want) in [(359.0, 2), (360.0, 3), (320.0, 2)]) {
        useWindow(tester, Size(width, 800));
        await tester.pumpWidget(
          host(
            Center(
              child: SizedBox(width: width, child: grid(6)),
            ),
          ),
        );
        expect(columns(tester, 6), want, reason: 'width $width');
      }
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
                SelectionRow.action(title: const Text('r1'), onTap: () {}),
                const SelectionRow.action(
                  title: Text('r2'),
                  disabledReason: 'Không có album',
                ),
                SelectionRow.action(title: const Text('r3'), onTap: () {}),
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
      await go(tester, 'a', LogicalKeyboardKey.arrowDown, 'd');
      await go(tester, 'd', LogicalKeyboardKey.arrowUp, 'a');
      await go(tester, 'c', LogicalKeyboardKey.arrowDown, 'e');
      await go(tester, 'e', LogicalKeyboardKey.arrowRight, 'e');
      await go(tester, 'e', LogicalKeyboardKey.arrowDown, 'r1');
      await go(tester, 'e', LogicalKeyboardKey.arrowUp, 'b');
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

  group('arrow navigation boundaries', () {
    testWidgets('a focused non-start control keeps its arrow keys', (
      tester,
    ) async {
      useWindow(tester, _touch);
      var outer = 0;
      final tile = FocusNode();
      final other = FocusNode();
      addTearDown(tile.dispose);
      addTearDown(other.dispose);
      await tester.pumpWidget(
        host(
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  outer++,
            },
            child: KStartArea(
              child: Column(
                children: [
                  KStartTile(
                    title: 'a',
                    semanticLabel: 'a',
                    focusNode: tile,
                    onPressed: () {},
                  ),
                  Focus(
                    focusNode: other,
                    child: const SizedBox(width: 100, height: 40),
                  ),
                  KStartTile(title: 'b', semanticLabel: 'b', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      other.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(outer, 1, reason: 'the area lets the key through');
      expect(other.hasPrimaryFocus, isTrue);
      tile.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(outer, 1, reason: 'from a start button the area consumes it');
      expect(other.hasPrimaryFocus, isFalse, reason: 'not a start button');
      expect(tile.hasPrimaryFocus, isFalse);
    });

    testWidgets('arrow focus scrolls the target into view', (tester) async {
      useWindow(tester, const Size(400, 500));
      final top = FocusNode();
      addTearDown(top.dispose);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 300,
              child: SingleChildScrollView(
                controller: controller,
                child: KStartArea(
                  child: Column(
                    children: [
                      KStartTile(
                        title: 'a',
                        semanticLabel: 'a',
                        focusNode: top,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 1000),
                      SelectionRow.action(
                        title: const Text('far'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      top.requestFocus();
      await tester.pump();
      expect(controller.offset, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      final row = tester.getRect(find.text('far'));
      expect(row.bottom, lessThanOrEqualTo(300));
      expect(row.top, greaterThanOrEqualTo(0));
    });
  });
}
