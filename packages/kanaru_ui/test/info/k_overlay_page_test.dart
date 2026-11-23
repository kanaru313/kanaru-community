import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

/// Body that remembers a counter (state to keep across a resize), says what
/// it is drawn as and opens the next layer.
class _Body extends StatefulWidget {
  const _Body(this.depth);

  final int depth;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final kind = KOverlayPageScope.maybeKindOf(context);
    return ListView(
      children: [
        Text('kind ${kind?.name}'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: Text('count $_count'),
        ),
        if (widget.depth < 3)
          TextButton(
            onPressed: () => _open(context, widget.depth + 1),
            child: Text('deeper ${widget.depth}'),
          ),
      ],
    );
  }
}

Future<void> _open(
  BuildContext context,
  int depth, {
  double maxWidth = KLayout.dialogWide,
}) => showKOverlayPage<void>(
  context,
  title: 'Layer $depth',
  builder: (_) => _Body(depth),
  actions: [
    KIconButton(tooltip: 'Eye $depth', icon: KIcons.eye, onPressed: () {}),
  ],
  maxWidth: maxWidth,
  closeTooltip: 'Close',
  backTooltip: 'Back',
);

Widget _opener({double maxWidth = 620}) => Builder(
  builder: (context) => Align(
    alignment: Alignment.topLeft,
    child: TextButton(
      onPressed: () => _open(context, 1, maxWidth: maxWidth),
      child: const Text('open'),
    ),
  ),
);

Future<void> _show(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// True when a node of the live semantics tree has [label].
bool _spoken(WidgetTester tester, String label) =>
    find.semantics.byLabel(label).evaluate().isNotEmpty;

Finder _barrier() => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == const Color(0x73000000),
  description: '45 % barrier',
);

void main() {
  testWidgets('360 wide: a full-screen page with a back arrow, no barrier', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(host(_opener()));
    await _show(tester);
    expect(find.text('kind page'), findsOneWidget);
    expect(byIconButton('Back'), findsOneWidget);
    expect(byIconButton('Close'), findsNothing);
    expect(_barrier(), findsNothing);
    expect(byIconButton('Eye 1'), findsOneWidget);
    expect(tester.getSize(find.text('Layer 1')).height, lessThan(56));
  });

  for (final (size, expectedHeight) in [
    (const Size(800, 1280), 1280 * 0.85),
    (const Size(1440, 900), 900 * 0.85),
    (const Size(1280, 700), 700.0 - 48),
  ]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: a 620 box of '
        '$expectedHeight at most, with barrier, close and actions', (
      tester,
    ) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(_opener()));
      await _show(tester);
      expect(find.text('kind box'), findsOneWidget);
      expect(_barrier(), findsOneWidget);
      expect(byIconButton('Close'), findsOneWidget);
      expect(byIconButton('Back'), findsNothing);
      expect(byIconButton('Eye 1'), findsOneWidget);
      final surface = tester.getRect(
        find
            .ancestor(
              of: find.text('kind box'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.width, 620);
      expect(surface.height, closeTo(expectedHeight, 0.5));
      expect(surface.center.dx, closeTo(size.width / 2, 0.5));
    });
  }

  testWidgets('maxWidth narrows the box (lyrics modal 560)', (tester) async {
    useWindow(tester, const Size(1440, 900));
    await tester.pumpWidget(host(_opener(maxWidth: 560)));
    await _show(tester);
    final surface = tester.getRect(
      find
          .ancestor(of: find.text('kind box'), matching: find.byType(Material))
          .first,
    );
    expect(surface.width, 560);
  });

  testWidgets('crossing 600 while open switches page <-> box and keeps the '
      'body state; Back still closes one layer', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await _show(tester);
    await tester.tap(find.text('count 0'));
    await tester.pump();
    await tester.tap(find.text('count 1'));
    await tester.pump();
    expect(find.text('kind page'), findsOneWidget);

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(find.text('kind box'), findsOneWidget);
    expect(find.text('count 2'), findsOneWidget);
    expect(_barrier(), findsOneWidget);

    tester.view.physicalSize = const Size(500, 800);
    await tester.pumpAndSettle();
    expect(find.text('kind page'), findsOneWidget);
    expect(find.text('count 2'), findsOneWidget);
    expect(_barrier(), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Layer 1'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  group('three stacked layers', () {
    Future<void> openAll(WidgetTester tester) async {
      await tester.pumpWidget(host(_opener()));
      await _show(tester);
      await tester.tap(find.text('deeper 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('deeper 2'));
      await tester.pumpAndSettle();
      expect(find.text('Layer 3'), findsWidgets);
    }

    for (final (name, close) in <(String, Future<void> Function(WidgetTester))>[
      (
        'Esc',
        (t) async {
          await t.sendKeyEvent(LogicalKeyboardKey.escape);
        },
      ),
      (
        'system Back',
        (t) async {
          await t.binding.handlePopRoute();
        },
      ),
    ]) {
      testWidgets('$name closes one layer at a time (box)', (tester) async {
        useWindow(tester, const Size(1440, 900));
        await openAll(tester);
        expect(_barrier(), findsNWidgets(3));
        await close(tester);
        await tester.pumpAndSettle();
        expect(find.text('Layer 3'), findsNothing);
        expect(find.text('Layer 2'), findsWidgets);
        expect(_barrier(), findsNWidgets(2));
        await close(tester);
        await tester.pumpAndSettle();
        expect(find.text('Layer 2'), findsNothing);
        expect(find.text('Layer 1'), findsWidgets);
        await close(tester);
        await tester.pumpAndSettle();
        expect(find.text('Layer 1'), findsNothing);
      });
    }

    testWidgets('the close button and the barrier close the top layer only', (
      tester,
    ) async {
      useWindow(tester, const Size(1440, 900));
      await openAll(tester);
      await tester.tap(byIconButton('Close').last);
      await tester.pumpAndSettle();
      expect(find.text('Layer 3'), findsNothing);
      expect(find.text('Layer 2'), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Layer 2'), findsNothing);
      expect(find.text('Layer 1'), findsWidgets);
    });

    testWidgets('the back arrow closes the top page only', (tester) async {
      useWindow(tester, const Size(400, 800));
      await openAll(tester);
      await tester.tap(byIconButton('Back').last);
      await tester.pumpAndSettle();
      expect(find.text('Layer 3'), findsNothing);
      expect(find.text('Layer 2'), findsWidgets);
    });
  });

  testWidgets('a tap inside the box does not close it', (tester) async {
    useWindow(tester, const Size(1440, 900));
    await tester.pumpWidget(host(_opener()));
    await _show(tester);
    await tester.tap(find.text('kind box'));
    await tester.pumpAndSettle();
    expect(find.text('Layer 1'), findsWidgets);
  });

  testWidgets('viaKeyboard focuses the first header button (page)', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var back = 0;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKOverlayPage<void>(
              context,
              title: 'T',
              builder: (_) => const SizedBox(),
              viaKeyboard: true,
              backTooltip: 'Back',
            ).then((_) => back++),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(back, 1, reason: 'Enter pressed the focused back button');
  });

  testWidgets('viaKeyboard focuses the first action in a box', (tester) async {
    useWindow(tester, const Size(1440, 900));
    var eye = 0;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKOverlayPage<void>(
              context,
              title: 'T',
              builder: (_) => const SizedBox(),
              actions: [
                KIconButton(
                  tooltip: 'Eye',
                  icon: KIcons.eye,
                  onPressed: () => eye++,
                ),
              ],
              viaKeyboard: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(eye, 1);
  });

  testWidgets('screen readers do not see the layer below', (tester) async {
    final handle = tester.ensureSemantics();
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    expect(_spoken(tester, 'open'), isTrue);
    await _show(tester);
    expect(_spoken(tester, 'open'), isFalse);
    expect(_spoken(tester, 'Layer 1'), isTrue);
    handle.dispose();
  });

  testWidgets('animations off: opens and closes with no transition', (
    tester,
  ) async {
    useWindow(tester, const Size(1440, 900));
    await tester.pumpWidget(host(_opener(), reduceMotion: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('kind box'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(find.text('Layer 1'), findsNothing);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name with a long title, no overflow', (
      tester,
    ) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showKOverlayPage<void>(
                context,
                title: 'A very long title ' * 8,
                builder: (_) => const Text('body'),
                actions: [
                  KIconButton(
                    tooltip: 'Eye',
                    icon: KIcons.eye,
                    onPressed: () {},
                  ),
                ],
              ),
              child: const Text('open'),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('body'), findsOneWidget);
    });
  }

  for (final (name, size) in [
    ('page', const Size(360, 800)),
    ('box', const Size(1440, 900)),
  ]) {
    testWidgets('the route paints no barrier of its own ($name)', (
      tester,
    ) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(_opener()));
      await _show(tester);
      final colours = [
        for (final b in tester.widgetList<ModalBarrier>(
          find.byType(ModalBarrier),
        ))
          b.color,
      ];
      expect(
        colours.where((c) => c != null && c.a > 0),
        isEmpty,
        reason: 'the box draws the one 45 % barrier itself',
      );
      expect(_barrier(), name == 'box' ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('Esc still closes the layer after the focused child is removed', (
    tester,
  ) async {
    useWindow(tester, const Size(1440, 900));
    final show = ValueNotifier(true);
    addTearDown(show.dispose);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKOverlayPage<void>(
              context,
              title: 'T',
              builder: (_) => ValueListenableBuilder<bool>(
                valueListenable: show,
                builder: (_, on, _) => on
                    ? TextButton(
                        autofocus: true,
                        onPressed: () => show.value = false,
                        child: const Text('field'),
                      )
                    : const Text('gone'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // removes the child
    await tester.pumpAndSettle();
    expect(find.text('gone'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('gone'), findsNothing);
  });
}
