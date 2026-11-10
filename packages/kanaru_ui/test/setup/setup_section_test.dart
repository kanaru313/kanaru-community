import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('heading, caption and rows render ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const SetupSection(
            title: Text('Library folders'),
            subtitle: Text('Kanaru scans these folders and everything below.'),
            children: [
              ListTile(title: Text('One')),
              ListTile(title: Text('Two')),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Library folders'), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });
  }

  testWidgets('the heading is a semantics header and the card is tonal', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const SetupSection(title: Text('Look'), children: [Text('row')])),
    );
    expect(
      tester.getSemantics(find.text('Look')),
      matchesSemantics(label: 'Look', isHeader: true),
    );
    final scheme = Theme.of(tester.element(find.text('row'))).colorScheme;
    final card = tester.widget<Material>(
      find
          .ancestor(of: find.text('row'), matching: find.byType(Material))
          .first,
    );
    expect(card.color, scheme.surfaceContainerLow);
    handle.dispose();
  });

  testWidgets('card: false leaves the children without a card', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SetupSection(title: Text('A'), card: true, children: [Text('x')]),
      ),
    );
    final withCard = find
        .ancestor(of: find.text('x'), matching: find.byType(Material))
        .evaluate()
        .length;
    await tester.pumpWidget(
      host(
        const SetupSection(
          title: Text('A'),
          card: false,
          children: [Text('x')],
        ),
      ),
    );
    final bare = find
        .ancestor(of: find.text('x'), matching: find.byType(Material))
        .evaluate()
        .length;
    expect(bare, withCard - 1);
  });
}
