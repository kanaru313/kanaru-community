import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/browse/library_view_toggle.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';

Widget _toggle(Size size, bool grid, ValueChanged<bool> onChanged) =>
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Center(
          child: LibraryViewToggle<bool>(
            value: grid,
            options: const [
              ViewOption(true, KIcons.grid, 'Grid view'),
              ViewOption(false, KIcons.list, 'List view'),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1300, 800)),
  ]) {
    testWidgets('$name: one small icon button showing the layout it switches '
        'to', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(_toggle(size, true, seen.add));
      // In the grid, the button offers the list; there is no segmented pill.
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      expect(find.byType(KIconButton), findsOneWidget);
      expect(find.byIcon(KIcons.list), findsOneWidget);
      expect(find.byIcon(KIcons.grid), findsNothing);
      expect(byIconButton('List view'), findsOneWidget);
      expect(tester.getSize(find.byType(KIconButton)), const Size.square(36));
      await tester.tap(find.byType(KIconButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(seen, [false]);

      await tester.pumpWidget(_toggle(size, false, seen.add));
      expect(find.byIcon(KIcons.grid), findsOneWidget);
      expect(byIconButton('Grid view'), findsOneWidget);
    });
  }
}
