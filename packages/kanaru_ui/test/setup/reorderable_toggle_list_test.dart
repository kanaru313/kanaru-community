import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

List<ReorderableToggleItem<String>> _items(Set<String> on) => [
  for (final n in ['songs', 'albums', 'artists'])
    ReorderableToggleItem(value: n, title: Text(n), enabled: on.contains(n)),
];

Widget _list(
  Set<String> on, {
  void Function(int, int)? onReorder,
  void Function(String, bool)? onToggle,
}) => SingleChildScrollView(
  child: ReorderableToggleList<String>(
    items: _items(on),
    dragLabel: 'Drag to reorder',
    lockedLabel: 'locked',
    onReorder: onReorder ?? (_, _) {},
    onToggle: onToggle ?? (_, _) {},
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders handles and switches ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          _list({'songs', 'albums'}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(KIcons.dragIndicator), findsNWidgets(3));
      expect(find.byType(Switch), findsNWidgets(3));
    });
  }

  testWidgets('toggling a row reports its value', (tester) async {
    useWindow(tester, const Size(400, 800));
    final toggles = <(String, bool)>[];
    await tester.pumpWidget(
      host(
        _list({'songs', 'albums'}, onToggle: (v, on) => toggles.add((v, on))),
      ),
    );
    await tester.tap(find.byType(Switch).at(2));
    await tester.tap(find.byType(Switch).at(0));
    expect(toggles, [('artists', true), ('songs', false)]);
  });

  testWidgets('the last enabled row is locked', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_list({'albums'})));
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // songs is off and may be turned on; albums is the only one on: locked.
    expect(switches[0].onChanged, isNotNull);
    expect(switches[1].onChanged, isNull);
    expect(switches[1].value, isTrue);
    expect(switches[0].value, isFalse);
  });

  testWidgets('dragging a handle reports from and the index after removal', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final moves = <(int, int)>[];
    await tester.pumpWidget(
      host(
        _list({
          'songs',
          'albums',
          'artists',
        }, onReorder: (f, t) => moves.add((f, t))),
      ),
    );
    final handle = find.byIcon(KIcons.dragIndicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 130));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [(0, 1)]);
  });

  testWidgets('the handle has a tooltip and a spoken label', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_list({'songs'})));
    expect(find.byTooltip('Drag to reorder'), findsNWidgets(3));
  });

  testWidgets('a tap on the handle does not toggle the row', (tester) async {
    useWindow(tester, const Size(400, 800));
    final toggles = <(String, bool)>[];
    await tester.pumpWidget(
      host(
        _list({'songs', 'albums'}, onToggle: (v, on) => toggles.add((v, on))),
      ),
    );
    await tester.tap(find.byIcon(KIcons.dragIndicator).first);
    await tester.pump();
    expect(toggles, isEmpty);
  });
}
