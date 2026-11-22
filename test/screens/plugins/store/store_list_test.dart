import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/store/store_card_slice.dart';
import 'package:kanaru/src/screens/plugins/store/store_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show ListView, ThemeData;

import '../../../support/icon_button_finders.dart';
import '../support/plugin_fixtures.dart';

const _repo = RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1000);

void main() {
  testWidgets('a store of 1000 entries builds only the rows in view', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 1000; i++)
        itemOf(
          'n$i',
          StoreItemState.notInstalled,
          name: 'Plugin ${i.toString().padLeft(4, '0')}',
        ),
    ];
    await pumpPlugins(tester, StoreFixture(items: items, repos: const [_repo]));
    expect(tester.takeException(), isNull);
    expect(find.text('Not installed (1000)'), findsOneWidget);
    final built = tester.widgetList(find.byType(StoreRowFrame)).length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40), reason: 'only the visible rows are built');

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Plugin 0000'), findsNothing);
    expect(tester.widgetList(find.byType(StoreRowFrame)).length, lessThan(40));
  });

  testWidgets('the same on the wide shell', (tester) async {
    final items = [
      for (var i = 0; i < 500; i++)
        itemOf('n$i', StoreItemState.notInstalled, name: 'Plugin $i'),
    ];
    await pumpPlugins(
      tester,
      StoreFixture(items: items, repos: const [_repo]),
      size: const Size(1400, 900),
    );
    expect(tester.takeException(), isNull);
    expect(tester.widgetList(find.byType(StoreRowFrame)).length, lessThan(40));
  });

  testWidgets('the first and last row of a block carry the card corners', (
    tester,
  ) async {
    await pumpPlugins(
      tester,
      StoreFixture(
        items: [
          itemOf('a', StoreItemState.notInstalled, name: 'Alpha'),
          itemOf('b', StoreItemState.notInstalled, name: 'Beta'),
          itemOf('c', StoreItemState.notInstalled, name: 'Gamma'),
        ],
        repos: const [_repo],
      ),
    );
    final slices = tester
        .widgetList<CardSlice>(find.byType(CardSlice))
        .toList();
    expect([for (final s in slices) s.first], [true, false, false]);
    expect([for (final s in slices) s.last], [false, false, true]);
  });

  group('row contents', () {
    StoreFixture fixture() => StoreFixture(
      items: [
        itemOf('u', StoreItemState.updateAvailable, name: 'Upd', author: 'ann'),
        itemOf('h', StoreItemState.installed, name: 'Have', author: 'bob'),
        itemOf('n', StoreItemState.notInstalled, name: 'Fresh', author: 'cat'),
      ],
      live: [
        liveRow('id-u', name: 'Upd'),
        liveRow('id-h', name: 'Have'),
      ],
      repos: const [_repo],
    );

    void expectRows(WidgetTester tester) {
      expect(tester.widgetList(find.byType(StoreRowFrame)), hasLength(3));
      for (final name in ['Upd', 'Have', 'Fresh']) {
        final frame = find.ancestor(
          of: find.text(name),
          matching: find.byType(StoreRowFrame),
        );
        expect(frame, findsOneWidget, reason: name);
        // icon, kind tag, author tag
        expect(
          find.descendant(of: frame, matching: find.text('Lyrics')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: frame, matching: find.byType(KChip)),
          findsNWidgets(2),
        );
      }
      // Installed rows show the author of the installed plugin.
      expect(find.text('kanaru313'), findsNWidgets(2));
      expect(find.text('cat'), findsOneWidget);
      // Exactly one control per row: Update, trash, Install.
      expect(byIconButton('Update Upd'), findsOneWidget);
      expect(byIconButton('Remove Have'), findsOneWidget);
      expect(byIconButton('Install Fresh'), findsOneWidget);
      expect(byIconButton('Remove Upd'), findsNothing);
      expect(byIconButton('Install Have'), findsNothing);
      // No label beside the name, no version text.
      for (final text in ['AI', 'Built in', 'Pro', 'Needs review', 'v1']) {
        expect(find.text(text), findsNothing, reason: text);
      }
    }

    testWidgets('light theme', (tester) async {
      await pumpPlugins(tester, fixture());
      expectRows(tester);
    });

    testWidgets('dark theme with animations off', (tester) async {
      await pumpPlugins(
        tester,
        fixture(),
        theme: ThemeData.dark(),
        reduceMotion: true,
      );
      expectRows(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
