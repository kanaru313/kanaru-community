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

  test('notes follow the alerts, a missing setting is only a dot', () async {
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
    expect(rows['A']!.note, StoreRowNote.none);
    expect(rows['B']!.note, StoreRowNote.reinstallFromFile);
  });

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
}
