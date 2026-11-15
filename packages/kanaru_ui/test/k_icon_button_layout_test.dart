import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

KIconButton button({
  EdgeInsetsGeometry? padding,
  double size = KIconSize.md,
  VoidCallback? onPressed,
  Widget? child,
  bool? selected,
}) {
  final onTap = onPressed ?? () {};
  final icon = child == null ? Icons.add : null;
  // Without [padding] the widget's own default applies.
  return padding == null
      ? KIconButton(
          icon: icon,
          size: size,
          tooltip: 'Add',
          selected: selected,
          onPressed: onTap,
          child: child,
        )
      : KIconButton(
          icon: icon,
          size: size,
          padding: padding,
          tooltip: 'Add',
          selected: selected,
          onPressed: onTap,
          child: child,
        );
}

void main() {
  group('size', () {
    testWidgets('default is icon + 16 wide, icon tall', (tester) async {
      await tester.pumpWidget(host(Center(child: button())));
      expect(tester.getSize(find.byType(KIconButton)), const Size(40, 24));
    });

    testWidgets('explicit padding and icon size set the box', (tester) async {
      await tester.pumpWidget(
        host(
          Center(
            child: button(
              size: KIconSize.sm,
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x3,
                vertical: KSpace.x2,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(KIconButton)), const Size(44, 36));
    });

    testWidgets('text scale 2.0 does not change the box', (tester) async {
      await tester.pumpWidget(host(Center(child: button()), textScale: 2.0));
      expect(tester.getSize(find.byType(KIconButton)), const Size(40, 24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out under intrinsics and dry layout', (tester) async {
      await tester.pumpWidget(
        host(
          Center(
            child: IntrinsicWidth(
              child: IntrinsicHeight(child: Row(children: [button()])),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(KIconButton)), const Size(40, 24));
      final box = tester.renderObject<RenderBox>(find.byType(KIconButton));
      expect(box.getDryLayout(const BoxConstraints()), const Size(40, 24));
      expect(box.getMinIntrinsicWidth(100), 40);
    });
  });

  group('tap target', () {
    testWidgets('the edge of the box and its padding do not reach the row', (
      tester,
    ) async {
      var pressed = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => rowTaps++,
              child: SizedBox(
                width: 200,
                height: 56,
                child: Align(child: button(onPressed: () => pressed++)),
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(KIconButton));
      for (final p in [
        rect.topLeft + const Offset(1, 1),
        rect.bottomRight - const Offset(1, 1),
        rect.centerLeft + const Offset(2, 0),
      ]) {
        await tester.tapAt(p);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect([pressed, rowTaps], [3, 0]);
      // Outside the box the tap belongs to the row.
      await tester.tapAt(rect.centerLeft - const Offset(4, 0));
      expect([pressed, rowTaps], [3, 1]);
    });
  });

  group('semantics', () {
    testWidgets('one button node with one label, enabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(Center(child: button(child: const Text('7')))),
      );
      final data = tester
          .getSemantics(find.byType(KIconButton))
          .getSemanticsData();
      expect(data.label, 'Add');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled.name, 'isTrue');
      expect(find.bySemanticsLabel('Add'), findsOneWidget);
      expect(find.bySemanticsLabel('7'), findsNothing);
      handle.dispose();
    });

    testWidgets('semanticLabel replaces the tooltip as the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Center(
            child: KIconButton(
              icon: Icons.add,
              tooltip: 'Add',
              semanticLabel: 'Add to queue',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Add to queue'), findsOneWidget);
      expect(find.bySemanticsLabel('Add'), findsNothing);
      handle.dispose();
    });

    testWidgets('toggled state is exposed only for a toggle', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(Center(child: button(selected: true))));
      var flags = tester
          .getSemantics(find.byType(KIconButton))
          .getSemanticsData()
          .flagsCollection;
      expect(flags.isToggled.name, 'isTrue');
      await tester.pumpWidget(host(Center(child: button())));
      flags = tester
          .getSemantics(find.byType(KIconButton))
          .getSemanticsData()
          .flagsCollection;
      expect(flags.isToggled.name, 'none');
      handle.dispose();
    });

    testWidgets('inside an InkWell row the button keeps its own node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Material(
            child: InkWell(
              onTap: () {},
              child: Row(children: [const Text('Row title'), button()]),
            ),
          ),
        ),
      );
      final row = tester
          .getSemantics(find.text('Row title'))
          .getSemanticsData();
      expect(row.label, isNot(contains('Add')));
      expect(
        tester.getSemantics(find.byType(KIconButton)).getSemanticsData().label,
        'Add',
      );
      handle.dispose();
    });

    testWidgets('a disabled button is a disabled button node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Center(
            child: KIconButton(
              icon: Icons.add,
              tooltip: 'Soon',
              onPressed: null,
            ),
          ),
        ),
      );
      final flags = tester
          .getSemantics(find.byType(KIconButton))
          .getSemanticsData()
          .flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled.name, 'isFalse');
      handle.dispose();
    });
  });

  group('tree', () {
    testWidgets('has no Material, ink, theme animation or opacity layers', (
      tester,
    ) async {
      await tester.pumpWidget(host(Center(child: button())));
      for (final type in [
        Material,
        InkResponse,
        InkWell,
        AnimatedTheme,
        Opacity,
        AnimatedOpacity,
        LayoutBuilder,
      ]) {
        expect(
          find.descendant(
            of: find.byType(KIconButton),
            matching: find.byType(type),
          ),
          findsNothing,
          reason: '$type inside KIconButton',
        );
      }
    });

    testWidgets('an idle button has no ticker, also after a theme swap', (
      tester,
    ) async {
      await tester.pumpWidget(host(Center(child: button())));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(
        host(Center(child: button()), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('the tree has the same widgets in every state', (tester) async {
      List<Type> types() => find
          .descendant(
            of: find.byType(KIconButton),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()
          .map((e) => e.widget.runtimeType)
          .toList();
      await tester.pumpWidget(host(Center(child: button(onPressed: null))));
      final disabled = types();
      await tester.pumpWidget(host(Center(child: button(selected: true))));
      expect(types(), disabled);
    });
  });
}
