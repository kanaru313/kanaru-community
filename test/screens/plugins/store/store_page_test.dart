import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/plugin_paths.dart';
import 'package:kanaru/src/screens/plugins/store/store_actions.dart';
import 'package:kanaru/src/screens/plugins/store/store_filter_toggles.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show ListView;

import '../../../support/icon_button_finders.dart';
import '../support/plugin_fixtures.dart';
import '../support/run_fixtures.dart';

const _wide = Size(1400, 1000);

StoreFixture _full({int updateAllCount = 1}) => StoreFixture(
  items: [
    itemOf('upd', StoreItemState.updateAvailable, name: 'Updatable'),
    itemOf('have', StoreItemState.installed, name: 'Installed one'),
    itemOf('new', StoreItemState.notInstalled, name: 'Fresh'),
    itemOf('future', StoreItemState.needsNewerApp, name: 'Future'),
  ],
  live: [
    liveRow('id-upd', name: 'Updatable'),
    liveRow('id-have', name: 'Installed one'),
  ],
  repos: const [
    RepoView(
      id: 1,
      name: 'Kho',
      url: 'https://r.example.com/p.json',
      pluginCount: 4,
    ),
  ],
  updateAllCount: updateAllCount,
);

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  for (final (name, size) in [
    ('narrow', const Size(400, 1000)),
    ('wide', _wide),
  ]) {
    group(name, () {
      testWidgets('blocks run Updates, Installed, Not installed', (
        tester,
      ) async {
        await pumpPlugins(tester, _full(), size: size);
        expect(find.text('Updates (1)'), findsOneWidget);
        expect(find.text('Installed (1)'), findsOneWidget);
        expect(find.text('Not installed (1)'), findsOneWidget);
        expect(
          _top(tester, 'Updates (1)'),
          lessThan(_top(tester, 'Installed (1)')),
        );
        expect(
          _top(tester, 'Installed (1)'),
          lessThan(_top(tester, 'Not installed (1)')),
        );
        // An updatable plugin is listed once, under Updates.
        expect(find.text('Updatable'), findsOneWidget);
        expect(find.text('Installed one'), findsOneWidget);
        expect(find.text('Fresh'), findsOneWidget);
        // An entry that needs a newer app has no row, only the footer count.
        expect(find.text('Future'), findsNothing);
        expect(find.text('1 plugin needs a newer Kanaru'), findsOneWidget);
        expect(
          find.text(
            'Plugins run in a sandbox and can only connect to the '
            'addresses declared when installed.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('an empty block is left out', (tester) async {
        await pumpPlugins(
          tester,
          StoreFixture(
            items: [itemOf('new', StoreItemState.notInstalled)],
            repos: const [
              RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1),
            ],
          ),
          size: size,
        );
        expect(find.textContaining('Updates ('), findsNothing);
        expect(find.textContaining('Installed ('), findsNothing);
        expect(find.text('Not installed (1)'), findsOneWidget);
      });
    });
  }

  testWidgets('update rows: one button, Review when hosts are new', (
    tester,
  ) async {
    final fixture = StoreFixture(
      items: [
        itemOf('a', StoreItemState.updateAvailable, name: 'Alpha'),
        itemOf('b', StoreItemState.updateAvailable, name: 'Beta'),
      ],
      live: [
        liveRow('id-a', name: 'Alpha'),
        liveRow('id-b', name: 'Beta'),
      ],
      repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      reviewIds: ['id-b'],
      updateAllCount: 1,
    );
    await pumpPlugins(tester, fixture);
    expect(find.bySemanticsLabel('Update Alpha'), findsOneWidget);
    expect(find.bySemanticsLabel('Review the update of Beta'), findsOneWidget);
    // Icon buttons only: no text button on an update row.
    expect(find.text('Update'), findsNothing);
    expect(find.text('Review'), findsNothing);
    // The title button counts what "update all" installs, not Review ones.
    expect(find.text('Update all (1)'), findsOneWidget);
  });

  testWidgets('no update-all button when every update needs review', (
    tester,
  ) async {
    final fixture = StoreFixture(
      items: [itemOf('b', StoreItemState.updateAvailable, name: 'Beta')],
      live: [liveRow('id-b', name: 'Beta')],
      repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
      reviewIds: ['id-b'],
    );
    await pumpPlugins(tester, fixture);
    expect(find.textContaining('Update all'), findsNothing);
  });

  testWidgets('a row button runs the flow behind it', (tester) async {
    final calls = <String>[];
    final h = await pumpPlugins(
      tester,
      _full(),
      overrides: [
        storeActionsProvider.overrideWithValue(
          StoreActions(
            onOpenPlugin: (_, row) => calls.add('open ${row.name}'),
            onInstall: (_, row) => calls.add('install ${row.name}'),
            onUpdate: (_, row) => calls.add('update ${row.name}'),
            onRemove: (_, row) => calls.add('remove ${row.name}'),
            onUpdateAll: (_) => calls.add('all'),
          ),
        ),
      ],
    );
    expect(h.container, isNotNull);
    await tester.tap(find.text('Update all (1)'));
    await tester.tap(find.bySemanticsLabel('Update Updatable'));
    await tester.tap(byIconButton('Install Fresh'));
    await tester.tap(byIconButton('Remove Installed one'));
    await tester.tap(find.text('Installed one'));
    expect(calls, [
      'all',
      'update Updatable',
      'install Fresh',
      'remove Installed one',
      'open Installed one',
    ]);
  });

  testWidgets('a second streaming plugin says why instead of installing', (
    tester,
  ) async {
    var installs = 0;
    await pumpPlugins(
      tester,
      StoreFixture(
        items: [
          itemOf(
            'two',
            StoreItemState.locked,
            name: 'Second',
            kind: PluginKind.streaming,
          ),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
      ),
      overrides: [
        storeActionsProvider.overrideWithValue(
          StoreActions(onInstall: (_, _) => installs++),
        ),
      ],
    );
    await tester.tap(byIconButton('Install Second'));
    await tester.pump();
    expect(
      find.text(
        'The Free edition installs only one music source plugin. '
        'Remove the current one to install this.',
      ),
      findsOneWidget,
    );
    expect(installs, 0);
  });

  testWidgets('an alerted plugin shows only the dot, no status text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPlugins(
      tester,
      StoreFixture(
        items: [itemOf('have', StoreItemState.installed, name: 'Broken')],
        live: [liveRow('id-have', name: 'Broken')],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
        alerts: {
          'id-have': {
            PluginAlert.proRequired,
            PluginAlert.missingRequiredConfig,
          },
        },
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Has a problem')), findsOneWidget);
    expect(find.text('Needs Kanaru Pro'), findsNothing);
    expect(find.text('Reinstall from file'), findsNothing);
    handle.dispose();
  });

  testWidgets('a plugin installed from a file is listed as installed', (
    tester,
  ) async {
    await pumpPlugins(
      tester,
      StoreFixture(
        live: [liveRow('file-1', name: 'From file', origin: 'file')],
        repos: const [],
      ),
    );
    expect(find.text('Installed (1)'), findsOneWidget);
    expect(find.text('From file'), findsOneWidget);
    // Nothing from a repository, but this plugin: no guide card in its place
    // of the search; the guide card stands where Not installed would be.
    expect(find.text('No repository yet'), findsOneWidget);
  });

  group('kind from the route', () {
    testWidgets('?kind=translate fills the search with its tag, Lọc empty', (
      tester,
    ) async {
      final fixture = StoreFixture(
        items: [
          itemOf('l', StoreItemState.notInstalled, name: 'Lyr'),
          itemOf(
            't',
            StoreItemState.notInstalled,
            name: 'Trans',
            kind: PluginKind.translate,
          ),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      );
      final h = await pumpPlugins(
        tester,
        fixture,
        location: '/settings/plugins?kind=translate',
      );
      expect(find.text('Trans'), findsOneWidget);
      expect(find.text('Lyr'), findsNothing);
      expect(
        tester.widget<KFilterField>(find.byType(KFilterField)).controller.text,
        '#translate ',
      );
      expect(h.container.read(storeFilterProvider).kinds, defaultStoreKinds);
      final badge = tester.widget<KIconButton>(byIconButton('Filter'));
      expect(badge.badgeCount, 0);
      expect(badge.selected, isFalse);
    });

    testWidgets('?kind=seekbar lists the uninstalled seek bar plugins only', (
      tester,
    ) async {
      final fixture = StoreFixture(
        items: [
          itemOf('l', StoreItemState.notInstalled, name: 'Lyr'),
          itemOf(
            's',
            StoreItemState.notInstalled,
            name: 'Neon',
            kind: PluginKind.seekbar,
          ),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      );
      await pumpPlugins(
        tester,
        fixture,
        location: PluginPaths.storeForKind('seekbar'),
      );
      expect(find.text('Neon'), findsOneWidget);
      expect(find.text('Lyr'), findsNothing);
      expect(
        tester.widget<KFilterField>(find.byType(KFilterField)).controller.text,
        '#seekbar ',
      );
      expect(tester.widget<KIconButton>(byIconButton('Filter')).badgeCount, 0);
    });

    testWidgets('another ?kind= on the open store updates the search', (
      tester,
    ) async {
      final fixture = StoreFixture(
        items: [
          itemOf('l', StoreItemState.notInstalled, name: 'Lyr'),
          itemOf(
            't',
            StoreItemState.notInstalled,
            name: 'Trans',
            kind: PluginKind.translate,
          ),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      );
      final h = await pumpPlugins(
        tester,
        fixture,
        location: '/settings/plugins?kind=translate',
      );
      expect(find.text('Lyr'), findsNothing);
      h.router.go('/settings/plugins?kind=lyrics');
      await tester.pumpAndSettle();
      expect(
        tester.widget<KFilterField>(find.byType(KFilterField)).controller.text,
        '#lyric ',
      );
      expect(find.text('Lyr'), findsOneWidget);
      expect(find.text('Trans'), findsNothing);
      expect(h.container.read(storeFilterProvider).query, '#lyric ');
    });

    testWidgets('an unknown kind or none leaves the search empty', (
      tester,
    ) async {
      final fixture = StoreFixture(
        items: [itemOf('l', StoreItemState.notInstalled, name: 'Lyr')],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
      );
      final h = await pumpPlugins(
        tester,
        fixture,
        location: '/settings/plugins?kind=skill',
      );
      expect(h.container.read(storeFilterProvider).isEmpty, isTrue);
      expect(find.text('Lyr'), findsOneWidget);
    });
  });

  testWidgets('opening the store refreshes and retries once', (tester) async {
    final fixture = _full();
    await pumpPlugins(tester, fixture);
    expect(fixture.ops.opens, 1);
  });

  group('search and no match', () {
    testWidgets('typing filters; Clear filters resets search and kinds', (
      tester,
    ) async {
      final fixture = _full();
      final h = await pumpPlugins(tester, fixture);
      await tester.enterText(find.byType(KFilterField), 'zzz');
      await tester.pump();
      expect(find.text('No matching plugins.'), findsOneWidget);
      h.container
          .read(storeFilterProvider.notifier)
          .set(
            h.container
                .read(storeFilterProvider)
                .copyWith(kinds: {PluginKind.streaming}),
          );
      await tester.pump();
      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      expect(h.container.read(storeFilterProvider).isEmpty, isTrue);
      expect(find.text('Fresh'), findsOneWidget);
      // The field is emptied too.
      expect(
        tester.widget<KFilterField>(find.byType(KFilterField)).controller.text,
        isEmpty,
      );
    });
  });

  group('search tags', () {
    testWidgets(
      '#tag filters, leaves the Lọc badge alone, clears with the text',
      (tester) async {
        final fixture = StoreFixture(
          items: [
            itemOf('a', StoreItemState.notInstalled, name: 'Lyric one'),
            itemOf(
              'b',
              StoreItemState.notInstalled,
              name: 'Stream one',
              kind: PluginKind.streaming,
            ),
          ],
          live: const [],
          repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
        );
        final h = await pumpPlugins(tester, fixture);
        await tester.enterText(find.byType(KFilterField), '#ly');
        await tester.pump();
        expect(find.text('Lyric one'), findsOneWidget);
        expect(find.text('Stream one'), findsOneWidget, reason: 'partial tag');

        await tester.enterText(find.byType(KFilterField), '#streaming');
        await tester.pump();
        expect(find.text('Lyric one'), findsNothing);
        expect(find.text('Stream one'), findsOneWidget);
        expect(h.container.read(storeFilterProvider).kinds, defaultStoreKinds);
        expect(h.container.read(storeFilterProvider).valueCount, 0);

        await tester.enterText(find.byType(KFilterField), '#lyric #music');
        await tester.pump();
        expect(find.text('Lyric one'), findsOneWidget);
        expect(find.text('Stream one'), findsOneWidget);

        await tester.enterText(find.byType(KFilterField), '');
        await tester.pump();
        expect(find.text('Lyric one'), findsOneWidget);
      },
    );
  });

  group('no repository', () {
    testWidgets('nothing at all: only the guide card, no search', (
      tester,
    ) async {
      var files = 0;
      await pumpPlugins(
        tester,
        StoreFixture(),
        overrides: [
          storeActionsProvider.overrideWithValue(
            StoreActions(onInstallFromFile: (_) => files++),
          ),
        ],
      );
      expect(find.text('No repository yet'), findsOneWidget);
      expect(find.byType(KFilterField), findsNothing);
      expect(find.text('Add repository'), findsOneWidget);
      await tester.tap(find.text('Install from file…'));
      expect(files, 1);
      // Lọc stays tappable on an empty store.
      expect(
        tester.widget<KIconButton>(byIconButton('Filter')).onPressed,
        isNotNull,
      );
    });
  });

  group('bands', () {
    testWidgets('one failed repository: its name, why, retry', (tester) async {
      final fixture = StoreFixture(
        items: [itemOf('new', StoreItemState.notInstalled)],
        repos: const [
          RepoView(id: 1, name: 'Good', url: 'a', pluginCount: 1),
          RepoView(
            id: 2,
            name: 'Nhạc Việt',
            url: 'b',
            pluginCount: 0,
            errorKind: 'badStatus',
          ),
        ],
      );
      await pumpPlugins(tester, fixture);
      expect(
        find.text('Couldn\'t load Nhạc Việt: file not found'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      expect(fixture.ops.refreshed, [2]);
    });

    testWidgets(
      'two or more repositories all failing for the network: offline',
      (tester) async {
        final fixture = StoreFixture(
          items: [itemOf('new', StoreItemState.notInstalled)],
          repos: const [
            RepoView(
              id: 1,
              name: 'A',
              url: 'a',
              pluginCount: 1,
              errorKind: 'network',
            ),
            RepoView(
              id: 2,
              name: 'B',
              url: 'b',
              pluginCount: 1,
              errorKind: 'timeout',
            ),
          ],
        );
        await pumpPlugins(tester, fixture);
        expect(find.text('No network connection'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        expect(fixture.ops.refreshAlls, 1);
      },
    );

    testWidgets(
      'a single repository failing for the network keeps its own band',
      (tester) async {
        final fixture = StoreFixture(
          items: [itemOf('new', StoreItemState.notInstalled)],
          repos: const [
            RepoView(
              id: 1,
              name: 'Solo',
              url: 'a',
              pluginCount: 1,
              errorKind: 'network',
            ),
          ],
        );
        await pumpPlugins(tester, fixture);
        expect(find.text('No network connection'), findsNothing);
        expect(find.textContaining('Couldn\'t load Solo'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        expect(fixture.ops.refreshed, [1]);
      },
    );

    testWidgets('no band when every repository loaded', (tester) async {
      await pumpPlugins(tester, _full());
      expect(find.text('Retry'), findsNothing);
    });
  });

  testWidgets('header and search stay while the list scrolls', (tester) async {
    final items = [
      for (var i = 0; i < 40; i++)
        itemOf('n$i', StoreItemState.notInstalled, name: 'Plugin $i'),
    ];
    await pumpPlugins(
      tester,
      StoreFixture(
        items: items,
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 40)],
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Plugin store'), findsOneWidget);
    expect(find.byType(KFilterField), findsOneWidget);
    expect(find.text('Not installed (40)'), findsNothing);
  });

  testWidgets('200 % text keeps every row action reachable', (tester) async {
    await pumpPlugins(tester, _full(), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Update all (1)'), findsOneWidget);
    expect(byIconButton('Remove Installed one'), findsOneWidget);
  });

  group('the log entry of the ⋮ menu', () {
    Future<FakeFileManager> openMenu(WidgetTester tester, Size size) async {
      final files = FakeFileManager();
      await pumpPlugins(
        tester,
        _full(),
        size: size,
        overrides: RunState(files: files).overrides,
      );
      await tester.tap(byIconButton('More options'));
      await tester.pumpAndSettle();
      return files;
    }

    testWidgets('desktop: "Open log folder" shows the folder', (tester) async {
      final files = await openMenu(tester, _wide);
      expect(find.text('Share plugin logs…'), findsNothing);
      expect(find.text('Coming soon'), findsNothing);
      await tester.tap(find.text('Open log folder'));
      await tester.pumpAndSettle();
      expect(files.revealed, ['/data/plugin-logs']);
    });

    testWidgets('desktop: a folder that cannot be opened says so', (
      tester,
    ) async {
      final files = await openMenu(tester, _wide);
      files.fails = true;
      await tester.tap(find.text('Open log folder'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t open the log folder'), findsOneWidget);
    });

    testWidgets('phone: sharing is dimmed "Coming soon" and does nothing', (
      tester,
    ) async {
      final files = await openMenu(tester, const Size(400, 1000));
      expect(find.text('Open log folder'), findsNothing);
      // The only dimmed row of the menu is the share entry.
      expect(find.text('Coming soon'), findsOneWidget);
      await tester.tap(find.text('Share plugin logs…'));
      await tester.pumpAndSettle();
      expect(files.revealed, isEmpty);
      expect(find.text('Share plugin logs…'), findsOneWidget, reason: 'open');
    });
  });
}
