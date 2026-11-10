import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('rows render without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          SetupSection(
            title: const Text('Appearance'),
            children: [
              SetupValueRow(
                icon: KIcons.theme,
                title: const Text('Theme'),
                value: const Text('Follow system'),
                onTap: () {},
              ),
              SetupAddRow(
                icon: KIcons.folderAdd,
                label: const Text('Add excluded folder'),
                onTap: () {},
              ),
              const SetupNote(
                child: Text('Nothing here yet, and a longer note.'),
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

  testWidgets('a value row shows its value and reports taps', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.language,
          title: const Text('Language'),
          value: const Text('English'),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(KIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('Language'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(SetupValueRow)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('the anchor key gives the row box to a desktop picker', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final key = GlobalKey();
    await tester.pumpWidget(
      host(
        SetupValueRow(
          anchorKey: key,
          icon: KIcons.theme,
          title: const Text('Theme'),
          value: const Text('Dark'),
          onTap: () {},
        ),
      ),
    );
    expect(key.currentContext?.findRenderObject(), isA<RenderBox>());
  });

  testWidgets('the add row is primary coloured and dims without onTap', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SetupAddRow(
          icon: KIcons.add,
          label: Text('Add folder'),
          onTap: null,
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('Add folder')))
        .colorScheme;
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Add folder'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.color, scheme.primary);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1));
  });
}
