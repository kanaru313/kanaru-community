import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_provider.dart';

import '../../screens/plugins/support/plugin_fixtures.dart';

ProviderContainer _container(StoreFixture fixture) {
  final container = ProviderContainer(overrides: fixture.overrides);
  addTearDown(container.dispose);
  addTearDown(fixture.close);
  return container;
}

Future<StoreView> _view(ProviderContainer c) async {
  final sub = c.listen(storeViewProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read().requireValue;
}

List<String> _names(List<StoreRowView> rows) => [for (final r in rows) r.name];

void main() {
  test('a plugin from a file is installed and follows the search', () async {
    final c = _container(
      StoreFixture(
        items: [itemOf('a', StoreItemState.installed, name: 'Alpha')],
        live: [
          liveRow('id-a', name: 'Alpha'),
          liveRow('f1', name: 'Zeta file', origin: 'file', author: 'dev'),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
      ),
    );
    var view = await _view(c);
    expect(_names(view.installed), ['Alpha', 'Zeta file']);
    expect(view.installedCount, 2);

    c.read(storeFilterProvider.notifier).set(const StoreFilter(query: 'ZETA'));
    view = await _view(c);
    expect(_names(view.installed), ['Zeta file']);

    // A repository filter cannot match a plugin that has no repository.
    c.read(storeFilterProvider.notifier).set(const StoreFilter(repoIds: {1}));
    view = await _view(c);
    expect(_names(view.installed), ['Alpha']);

    c
        .read(storeFilterProvider.notifier)
        .set(const StoreFilter(kinds: {PluginKind.translate}));
    view = await _view(c);
    expect(view.noMatch, isTrue);
    expect(view.installedCount, 2, reason: 'the unfiltered count');
  });

  test('an entry that needs a newer app is counted, not listed', () async {
    final c = _container(
      StoreFixture(
        items: [
          itemOf('n', StoreItemState.notInstalled, name: 'New'),
          itemOf('f', StoreItemState.needsNewerApp, name: 'Future'),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      ),
    );
    final view = await _view(c);
    expect(_names(view.notInstalled), ['New']);
    expect(view.needsNewerAppCount, 1);
  });

  test('an alerted plugin carries the flag and no status text', () async {
    final c = _container(
      StoreFixture(
        items: [
          itemOf('a', StoreItemState.installed, name: 'A'),
          itemOf('b', StoreItemState.installed, name: 'B'),
        ],
        live: [
          liveRow('id-a', name: 'A'),
          liveRow('id-b', name: 'B'),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
        alerts: {
          'id-a': {PluginAlert.missingRequiredConfig},
          'id-b': {PluginAlert.reinstallFromFile, PluginAlert.proRequired},
        },
      ),
    );
    final rows = {for (final r in (await _view(c)).installed) r.name: r};
    expect(rows['A']!.alerted, isTrue);
    expect(rows['B']!.alerted, isTrue);
  });

  test(
    'Đã cài keeps a plugin with an update, Có bản cập nhật only it',
    () async {
      final c = _container(
        StoreFixture(
          items: [
            itemOf('a', StoreItemState.updateAvailable, name: 'Alpha'),
            itemOf('b', StoreItemState.installed, name: 'Beta'),
            itemOf('c', StoreItemState.notInstalled, name: 'Gamma'),
          ],
          live: [
            liveRow('id-a', name: 'Alpha'),
            liveRow('id-b', name: 'Beta'),
          ],
          repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 3)],
        ),
      );
      final n = c.read(storeFilterProvider.notifier);
      n.set(const StoreFilter(states: {StoreStateChip.installed}));
      var view = await _view(c);
      expect(_names(view.updates), ['Alpha']);
      expect(_names(view.installed), ['Beta']);
      expect(view.notInstalled, isEmpty);

      n.set(const StoreFilter(states: {StoreStateChip.updatable}));
      view = await _view(c);
      expect(_names(view.updates), ['Alpha']);
      expect(view.installed, isEmpty);

      n.set(const StoreFilter(states: {StoreStateChip.notInstalled}));
      view = await _view(c);
      expect(_names(view.notInstalled), ['Gamma']);
      expect(view.updates, isEmpty);
    },
  );

  test('facets list each language and author once', () async {
    final c = _container(
      StoreFixture(
        items: [
          itemOf(
            'a',
            StoreItemState.notInstalled,
            author: 'ann',
            languages: ['vie'],
          ),
          itemOf(
            'b',
            StoreItemState.notInstalled,
            author: 'ann',
            languages: ['vie', 'eng'],
          ),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 2)],
      ),
    );
    final facets = c.read(storeFacetsProvider);
    expect(facets.languages, ['eng', 'vie']);
    expect(facets.authors, ['ann']);
  });

  test('#tags filter by kind, independent of the Lọc kinds', () async {
    final c = _container(
      StoreFixture(
        items: [
          itemOf('a', StoreItemState.installed, name: 'Alpha'),
          itemOf(
            'b',
            StoreItemState.notInstalled,
            name: 'Beta',
            kind: PluginKind.streaming,
          ),
          itemOf(
            'c',
            StoreItemState.notInstalled,
            name: 'Gamma',
            kind: PluginKind.aiTranslate,
          ),
        ],
        live: [liveRow('id-a', name: 'Alpha')],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 3)],
      ),
    );
    final notifier = c.read(storeFilterProvider.notifier);
    notifier.set(const StoreFilter(query: '#lyric'));
    var view = await _view(c);
    expect(_names(view.installed), ['Alpha']);
    expect(_names(view.notInstalled), isEmpty);

    notifier.set(const StoreFilter(query: '#music #translate'));
    view = await _view(c);
    expect(_names(view.notInstalled), ['Beta', 'Gamma']);

    // The tag is ANDed with Lọc, and the partial tag filters nothing.
    notifier.set(
      const StoreFilter(query: '#music #translate', kinds: {PluginKind.lyrics}),
    );
    expect((await _view(c)).noMatch, isTrue);
    notifier.set(const StoreFilter(query: '#ly'));
    expect((await _view(c)).noMatch, isFalse);
    notifier.set(const StoreFilter(query: '#music gam'));
    expect((await _view(c)).noMatch, isTrue);
  });

  test('#tags apply to a plugin installed from a file', () async {
    final c = _container(
      StoreFixture(
        items: [itemOf('a', StoreItemState.installed, name: 'Alpha')],
        live: [
          liveRow('id-a', name: 'Alpha'),
          liveRow('f1', name: 'Zeta file', kind: 'translate', origin: 'file'),
        ],
        repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
      ),
    );
    c
        .read(storeFilterProvider.notifier)
        .set(const StoreFilter(query: '#translate'));
    expect(_names((await _view(c)).installed), ['Zeta file']);
  });

  group('seek bar plugins in the default store', () {
    StoreFixture fixture() => StoreFixture(
      items: [
        itemOf('l', StoreItemState.notInstalled, name: 'Lyr'),
        itemOf(
          'sa',
          StoreItemState.installed,
          name: 'Have style',
          kind: PluginKind.seekbar,
        ),
        itemOf(
          'sb',
          StoreItemState.notInstalled,
          name: 'New style',
          kind: PluginKind.seekbar,
        ),
        itemOf(
          'sc',
          StoreItemState.needsNewerApp,
          name: 'Lottie style',
          kind: PluginKind.seekbar,
        ),
      ],
      live: [liveRow('id-sa', name: 'Have style', kind: 'seekbar')],
      repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 4)],
    );

    test('hides the uninstalled ones, lists the installed one', () async {
      final c = _container(fixture());
      final view = await _view(c);
      expect(_names(view.installed), ['Have style']);
      expect(_names(view.notInstalled), ['Lyr']);
      expect(
        view.needsNewerAppCount,
        1,
        reason: 'the default hides only the row, the footer still counts it',
      );
      expect(c.read(storeFilterProvider).isEmpty, isTrue);
    });

    test('the Thanh tua chip lists them all', () async {
      final c = _container(fixture());
      c
          .read(storeFilterProvider.notifier)
          .set(
            const StoreFilter(
              kinds: {...defaultStoreKinds, PluginKind.seekbar},
            ),
          );
      final view = await _view(c);
      expect(_names(view.installed), ['Have style']);
      expect(_names(view.notInstalled), ['Lyr', 'New style']);
      expect(view.needsNewerAppCount, 1, reason: 'the Lottie entry');
    });

    test('#seekbar and #seek list only them, chips untouched', () async {
      final c = _container(fixture());
      for (final query in ['#seekbar ', '#seek', '#SEEK ']) {
        c.read(storeFilterProvider.notifier).set(StoreFilter(query: query));
        final view = await _view(c);
        expect(_names(view.installed), ['Have style'], reason: query);
        expect(_names(view.notInstalled), ['New style'], reason: query);
        expect(view.needsNewerAppCount, 1, reason: query);
      }
    });

    test(
      'an installed style stays listed while deselected functional kinds hide',
      () async {
        final c = _container(fixture());
        c
            .read(storeFilterProvider.notifier)
            .set(const StoreFilter(kinds: {PluginKind.translate}));
        expect(
          (await _view(c)).noMatch,
          isFalse,
          reason: 'the installed style',
        );
        c.read(storeFilterProvider.notifier).set(const StoreFilter(kinds: {}));
        final view = await _view(c);
        expect(_names(view.installed), ['Have style']);
        expect(view.notInstalled, isEmpty);
      },
    );

    test('clear returns to the default, not to nothing selected', () async {
      final c = _container(fixture());
      final notifier = c.read(storeFilterProvider.notifier);
      notifier.set(const StoreFilter(query: '#seekbar', kinds: {}));
      notifier.clear();
      final filter = c.read(storeFilterProvider);
      expect(filter.kinds, defaultStoreKinds);
      expect(filter.isEmpty, isTrue);
      expect(_names((await _view(c)).notInstalled), ['Lyr']);
    });

    test('a seek bar plugin from a file follows the same rule', () async {
      final c = _container(
        StoreFixture(
          items: [itemOf('l', StoreItemState.notInstalled, name: 'Lyr')],
          live: [
            liveRow('f1', name: 'File style', kind: 'seekbar', origin: 'file'),
          ],
          repos: const [RepoView(id: 1, name: 'Kho', url: 'u', pluginCount: 1)],
        ),
      );
      expect(_names((await _view(c)).installed), ['File style']);
    });
  });
}
