import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/store/store_filter_body.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show TextButton;

import '../../../support/icon_button_finders.dart';
import '../support/plugin_fixtures.dart';

StoreFixture _fixture() => StoreFixture(
  items: [
    itemOf('l', StoreItemState.notInstalled, name: 'Lyr', author: 'ann'),
    itemOf(
      't',
      StoreItemState.notInstalled,
      name: 'Trans',
      kind: PluginKind.translate,
      author: 'bob',
      languages: ['vie'],
    ),
    itemOf('h', StoreItemState.installed, name: 'Have', author: 'ann'),
  ],
  live: [liveRow('id-h', name: 'Have', author: 'ann')],
  repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 3)],
);

/// A chip of the Lọc body (the rows underneath carry tags of the same text).
Finder _chip(String label) => find.descendant(
  of: find.byType(StoreFilterBody),
  matching: find.widgetWithText(KChip, label),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(byIconButton('Filter'));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [
    ('sheet on mobile', const Size(400, 900)),
    ('panel on desktop', const Size(1400, 900)),
  ]) {
    group(name, () {
      testWidgets('groups, live filtering, footer count, clear all', (
        tester,
      ) async {
        final h = await pumpPlugins(tester, _fixture(), size: size);
        await _open(tester);
        expect(find.text('Plugin type'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Author'), findsOneWidget);
        expect(find.text('Repository'), findsOneWidget);
        expect(find.text('Showing 3 plugins'), findsOneWidget);
        // Clear all is disabled while nothing is chosen.
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Clear all'))
              .onPressed,
          isNull,
        );

        await tester.tap(_chip('Translation'));
        await tester.pump();
        expect(
          tester.getSemantics(_chip('Translation')),
          isSemantics(isSelected: true),
        );
        expect(find.text('Showing 1 plugin'), findsOneWidget);
        expect(h.container.read(storeFilterProvider).kinds, {
          PluginKind.translate,
          PluginKind.aiTranslate,
        });
        await tester.tap(_chip('ann'));
        await tester.pump();
        expect(h.container.read(storeFilterProvider).authors, {'ann'});

        await tester.tap(find.text('Clear all'));
        await tester.pump();
        expect(h.container.read(storeFilterProvider).isEmpty, isTrue);
        expect(find.text('Showing 3 plugins'), findsOneWidget);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.text('Plugin type'), findsNothing);
      });
    });
  }

  testWidgets('Clear all keeps the search text', (tester) async {
    final h = await pumpPlugins(tester, _fixture());
    await tester.enterText(find.byType(KFilterField), 'tra');
    await _open(tester);
    await tester.tap(_chip('Translation'));
    await tester.pump();
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    final filter = h.container.read(storeFilterProvider);
    expect(filter.query, 'tra');
    expect(filter.kinds, isEmpty);
  });

  testWidgets('the badge counts every chosen value', (tester) async {
    await pumpPlugins(tester, _fixture());
    await _open(tester);
    await tester.tap(_chip('Lyrics'));
    await tester.tap(_chip('Installed'));
    await tester.tap(_chip('bob'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.widget<KIconButton>(byIconButton('Filter')).badgeCount, 3);
  });

  testWidgets('a group with no values is left out', (tester) async {
    await pumpPlugins(
      tester,
      StoreFixture(
        items: [
          itemOf('l', StoreItemState.notInstalled, name: 'Lyr', author: ''),
        ],
        repos: const [],
      ),
    );
    await _open(tester);
    expect(find.text('Plugin type'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
    expect(find.text('Author'), findsNothing);
    expect(find.text('Repository'), findsNothing);
  });

  testWidgets('Esc closes the desktop panel like Done', (tester) async {
    await pumpPlugins(tester, _fixture(), size: const Size(1400, 900));
    await _open(tester);
    expect(find.text('Plugin type'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Plugin type'), findsNothing);
  });

  testWidgets('the desktop panel lines up with the Filter button', (
    tester,
  ) async {
    await pumpPlugins(tester, _fixture(), size: const Size(1400, 900));
    final button = tester.getRect(byIconButton('Filter'));
    await _open(tester);
    final panel = tester.getRect(find.byType(StoreFilterBody));
    expect(panel.right, closeTo(button.right, 1));
    expect(panel.width, 360);
  });
}
