import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _mobile = Size(400, 800);
const _desktop = Size(1300, 800);

/// The colour an icon is painted with: its own, else the inherited one.
Color? _painted(WidgetTester tester, IconData icon) {
  final finder = find.byIcon(icon);
  return tester.widget<Icon>(finder).color ??
      IconTheme.of(tester.element(finder)).color;
}

KRowIconAction _action({
  IconData icon = Icons.looks_one,
  IconData? selectedIcon,
  bool? selected,
  VoidCallback? onPressed,
  double iconSize = 20,
  Color? color,
  Color? selectedColor,
  String tooltip = 'Do it',
  String? semanticLabel,
}) => KRowIconAction(
  icon: icon,
  selectedIcon: selectedIcon,
  selected: selected,
  tooltip: tooltip,
  semanticLabel: semanticLabel,
  iconSize: iconSize,
  color: color,
  selectedColor: selectedColor,
  onPressed: onPressed,
);

void main() {
  late ColorScheme scheme;
  setUp(
    () => scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme,
  );

  group('geometry against a real IconButton', () {
    testWidgets('mobile target is 48 and the state circle 40', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _action(onPressed: () {}),
              IconButton(
                onPressed: () {},
                iconSize: 20,
                icon: const Icon(Icons.looks_two),
              ),
            ],
          ),
        ),
      );
      final ours = tester.getSize(find.byType(KRowIconAction));
      expect(ours, const Size(48, 48));
      expect(ours, tester.getSize(find.byType(IconButton)));
      expect(
        tester.widget<InkResponse>(find.byType(InkResponse)).radius,
        KRowIconAction.circle / 2,
      );
      // The real button's visible shape is the same 40 dp circle.
      final material = find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Material),
      );
      expect(tester.getSize(material.first), const Size(40, 40));
    });

    testWidgets('desktop target is 40, like an IconButton there', (
      tester,
    ) async {
      useWindow(tester, _desktop);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Theme(
              data: Theme.of(context).copyWith(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Column(
                children: [
                  _action(onPressed: () {}),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.looks_two),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final ours = tester.getSize(find.byType(KRowIconAction));
      expect(ours, const Size(40, 40));
      expect(ours, tester.getSize(find.byType(IconButton)));
    });

    testWidgets('icon sizes 20 and 24 match IconButton', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _action(icon: Icons.looks_one, onPressed: () {}),
              _action(icon: Icons.looks_3, iconSize: 24, onPressed: () {}),
              IconButton(
                onPressed: () {},
                iconSize: 20,
                icon: const Icon(Icons.looks_two),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.looks_4)),
            ],
          ),
        ),
      );
      Size size(IconData i) => tester.getSize(find.byIcon(i));
      expect(size(Icons.looks_one), size(Icons.looks_two));
      expect(size(Icons.looks_3), size(Icons.looks_4));
      expect(size(Icons.looks_one), const Size(20, 20));
      expect(size(Icons.looks_3), const Size(24, 24));
    });
  });

  group('colours', () {
    testWidgets('rest, selected and disabled match IconButton', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _action(icon: Icons.looks_one, onPressed: () {}),
              _action(icon: Icons.looks_3, selected: true, onPressed: () {}),
              _action(icon: Icons.looks_5, onPressed: null),
              IconButton(onPressed: () {}, icon: const Icon(Icons.looks_two)),
              IconButton(
                onPressed: () {},
                isSelected: true,
                icon: const Icon(Icons.looks_4),
              ),
              const IconButton(onPressed: null, icon: Icon(Icons.looks_6)),
            ],
          ),
        ),
      );
      expect(
        _painted(tester, Icons.looks_one),
        _painted(tester, Icons.looks_two),
      );
      expect(_painted(tester, Icons.looks_3), _painted(tester, Icons.looks_4));
      expect(_painted(tester, Icons.looks_5), _painted(tester, Icons.looks_6));
      expect(_painted(tester, Icons.looks_one), scheme.onSurfaceVariant);
      expect(_painted(tester, Icons.looks_3), scheme.primary);
      expect(_painted(tester, Icons.looks_5), scheme.onSurface.withAlpha(97));
    });

    testWidgets('an explicit colour beats the row colour, which beats the '
        'default', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              KRowIconColor(
                color: Colors.green,
                child: Column(
                  children: [
                    _action(icon: Icons.looks_one, onPressed: () {}),
                    _action(
                      icon: Icons.looks_3,
                      color: Colors.red,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              _action(icon: Icons.looks_5, onPressed: () {}),
            ],
          ),
        ),
      );
      expect(_painted(tester, Icons.looks_one), Colors.green);
      expect(_painted(tester, Icons.looks_3), Colors.red);
      expect(_painted(tester, Icons.looks_5), scheme.onSurfaceVariant);
    });

    testWidgets('a toggle swaps the icon and takes selectedColor', (
      tester,
    ) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(
        host(
          _action(
            icon: Icons.looks_one,
            selectedIcon: Icons.looks_two,
            selected: true,
            selectedColor: Colors.purple,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.looks_one), findsNothing);
      expect(_painted(tester, Icons.looks_two), Colors.purple);
    });

    testWidgets('hover paints an 8 % circle of the icon colour', (
      tester,
    ) async {
      useWindow(tester, _desktop);
      await tester.pumpWidget(host(_action(onPressed: () {})));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(KRowIconAction)));
      await tester.pumpAndSettle();
      final material = find
          .ancestor(
            of: find.byType(KRowIconAction),
            matching: find.byType(Material),
          )
          .first;
      expect(
        tester.renderObject(material),
        paints..circle(
          radius: KRowIconAction.circle / 2,
          color: scheme.onSurfaceVariant.withAlpha(20),
        ),
      );
    });
  });

  group('tooltip and semantics', () {
    testWidgets('long press shows the tooltip on mobile', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(host(_action(onPressed: () {})));
      await tester.longPress(find.byType(KRowIconAction));
      await tester.pumpAndSettle();
      expect(find.text('Do it'), findsOneWidget);
    });

    testWidgets('hover shows the tooltip on desktop', (tester) async {
      useWindow(tester, _desktop);
      await tester.pumpWidget(host(_action(onPressed: () {})));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(KRowIconAction)));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Do it'), findsOneWidget);
    });

    testWidgets('a disabled action has no tooltip and takes no focus', (
      tester,
    ) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(host(_action(onPressed: null)));
      expect(find.byType(Tooltip), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
    });

    testWidgets('own semantics node: button, enabled, label, one tap action, '
        'apart from the row', (tester) async {
      useWindow(tester, _mobile);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          InkWell(
            onTap: () {},
            child: Row(
              children: [
                const Text('Row'),
                _action(onPressed: () {}, tooltip: 'More'),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Real',
                  icon: const Icon(Icons.looks_two),
                ),
              ],
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(KRowIconAction));
      expect(
        node,
        matchesSemantics(
          tooltip: 'More',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // Same node shape as the real button.
      final real = tester.getSemantics(find.byType(IconButton));
      expect(
        real.getSemanticsData().flagsCollection,
        node.getSemanticsData().flagsCollection,
      );
      expect(real.getSemanticsData().actions, node.getSemanticsData().actions);
      expect(node.id, isNot(tester.getSemantics(find.text('Row')).id));
      handle.dispose();
    });

    testWidgets('a toggle exposes selected and toggled, label wins over '
        'tooltip', (tester) async {
      useWindow(tester, _mobile);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _action(
            selected: true,
            tooltip: 'Remove',
            semanticLabel: 'Favorite',
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(KRowIconAction)),
        matchesSemantics(
          label: 'Favorite',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a disabled action reads as a disabled button', (tester) async {
      useWindow(tester, _mobile);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_action(onPressed: null)));
      expect(
        tester.getSemantics(find.byType(KRowIconAction)),
        matchesSemantics(
          label: 'Do it',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('interaction', () {
    testWidgets('a press does not activate the row', (tester) async {
      useWindow(tester, _mobile);
      var row = 0;
      var action = 0;
      await tester.pumpWidget(
        host(
          InkWell(
            onTap: () => row++,
            child: _action(onPressed: () => action++),
          ),
        ),
      );
      await tester.tap(find.byType(KRowIconAction));
      expect([row, action], [0, 1]);
    });

    for (final (name, key) in [
      ('Enter', LogicalKeyboardKey.enter),
      ('numpad Enter', LogicalKeyboardKey.numpadEnter),
      ('Space', LogicalKeyboardKey.space),
    ]) {
      testWidgets('Tab focuses it and $name activates', (tester) async {
        useWindow(tester, _mobile);
        var pressed = 0;
        await tester.pumpWidget(host(_action(onPressed: () => pressed++)));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(pressed, 1);
      });
    }

    testWidgets('the focus ring shows in keyboard mode only and follows '
        'mode changes', (tester) async {
      useWindow(tester, _mobile);
      await tester.pumpWidget(host(_action(onPressed: () {})));
      Color ring() {
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(KRowIconAction),
            matching: find.byType(DecoratedBox),
          ),
        );
        return ((box.decoration as BoxDecoration).border! as Border).top.color;
      }

      expect(ring().a, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      expect(ring(), scheme.primary);
      // A touch anywhere switches to touch mode: ring hides, focus stays.
      await tester.tapAt(const Offset(300, 700));
      await tester.pump();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(ring().a, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(ring(), scheme.primary);
    });

    testWidgets('needs a Material ancestor', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: _mobile),
            child: _action(onPressed: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });
}
