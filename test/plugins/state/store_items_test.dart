import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_codec.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/store_items_provider.dart';

import '../data/store_test_support.dart';
import '../domain/plugin_test_support.dart';
import '../fixtures/catalog_support.dart';
import 'state_test_support.dart';

const _url = 'https://repo.example.com/plugins.json';

void main() {
  late StateHarness h;
  tearDown(() => h.dispose());

  Future<void> addRepo(
    List<Map<String, Object?>> entries, {
    String url = _url,
    String name = 'Kho',
  }) async {
    final catalog = okCatalog(
      catalogJson([for (final e in entries) entryJson(e)]),
      url: Uri.parse(url),
    );
    await h.container
        .read(pluginRepoRowsProvider)
        .add(
          url: url,
          name: name,
          catalogJson: encodeCatalog(catalog),
          addressKind: AddressKind.public,
          now: 1,
        );
  }

  Future<void> install(String slug, {int version = 3, String? kind}) async {
    final package = kind == 'streaming'
        ? packageOf(streamingManifest(), {'src/stream.js': 'x'})
        : packageOf(withMeta((m) => m['version'] = version));
    await h.container
        .read(pluginRowsProvider)
        .installOrRevive(
          repoInstallId(_url, slug),
          draftOf(package, 'v$version-1'),
          PluginSource.repo(_url, slug),
        );
  }

  Future<StoreSections> sections() async {
    final value = await h.settled(storeSectionsProvider);
    return value.requireValue;
  }

  List<String> slugs(List<StoreItem> items) => [
    for (final i in items) i.entry.slug,
  ];

  test('states and sections: an updatable plugin only under updates', () async {
    h = StateHarness();
    await addRepo([
      {'slug': 'new', 'name': 'Brand new'},
      {'slug': 'have'},
      {'slug': 'old', 'version': 4},
      {'slug': 'future', 'apiVersion': 99},
    ]);
    await install('have');
    await install('old');

    final s = await sections();

    expect(slugs(s.updates), ['old']);
    expect(slugs(s.installed), ['have']);
    expect(slugs(s.notInstalled)..sort(), ['future', 'new']);
    expect(
      s.notInstalled.firstWhere((i) => i.entry.slug == 'future').state,
      StoreItemState.needsNewerApp,
    );
  });

  test(
    'search folds case and diacritics over name, author, repo, host',
    () async {
      h = StateHarness();
      await addRepo([
        {'slug': 'a', 'name': 'Nhạc của tui', 'author': 'Hiếu'},
        {
          'slug': 'b',
          'name': 'Other',
          'hosts': ['api.zing.vn'],
        },
      ], name: 'Kho Việt');
      final notifier = h.container.read(storeFilterProvider.notifier);

      notifier.set(const StoreFilter(query: 'NHAC tui'));
      expect(slugs((await sections()).notInstalled), ['a']);
      notifier.set(const StoreFilter(query: 'hieu'));
      expect(slugs((await sections()).notInstalled), ['a']);
      notifier.set(const StoreFilter(query: 'zing'));
      expect(slugs((await sections()).notInstalled), ['b']);
      notifier.set(const StoreFilter(query: 'kho viet'));
      expect((await sections()).length, 2);
      notifier.set(const StoreFilter(query: 'nope'));
      expect((await sections()).isEmpty, isTrue);
    },
  );

  test('filters: kind, state, language, author, repository', () async {
    h = StateHarness();
    await addRepo([
      {
        'slug': 'ly',
        'languages': ['vi'],
        'author': 'x',
      },
      {'slug': 'tr', 'type': 'translate', 'author': 'y'},
      {
        'slug': 'en',
        'languages': ['en'],
      },
    ]);
    await install('ly');
    final n = h.container.read(storeFilterProvider.notifier);

    n.set(const StoreFilter(kinds: {PluginKind.translate}));
    expect(slugs((await sections()).notInstalled), ['tr']);
    n.set(const StoreFilter(states: {StoreItemState.installed}));
    expect(slugs((await sections()).installed), ['ly']);
    // A global plugin matches every language.
    final key = (await h.settled(storeItemsProvider)).requireValue
        .firstWhere((i) => i.entry.slug == 'ly')
        .entry
        .languages
        .single;
    n.set(StoreFilter(languages: {key}));
    final vi = await sections();
    expect([...slugs(vi.installed), ...slugs(vi.notInstalled)]..sort(), [
      'ly',
      'tr',
    ]);
    n.set(const StoreFilter(authors: {'y'}));
    expect(slugs((await sections()).notInstalled), ['tr']);
    final repoId =
        (await h.container.read(pluginRepoRowsProvider).all()).single.id;
    n.set(StoreFilter(repoIds: {repoId + 1}));
    expect((await sections()).isEmpty, isTrue);
  });

  test('a second streaming entry is locked without Pro, not with it', () async {
    h = StateHarness();
    Map<String, Object?> entry(String slug) => {
      'slug': slug,
      'type': 'streaming',
      'hosts': ['www.youtube.com'],
    };
    await addRepo([entry('a'), entry('b')]);
    await install('a', kind: 'streaming');

    final locked = (await sections()).notInstalled.single;
    expect(locked.entry.slug, 'b');
    expect(locked.state, StoreItemState.locked);
    await h.dispose();

    h = StateHarness(unlocked: true);
    await addRepo([entry('a'), entry('b')]);
    await install('a', kind: 'streaming');
    expect(
      (await sections()).notInstalled.single.state,
      StoreItemState.notInstalled,
    );
  });

  test(
    'a locked streaming plugin with a newer entry is not under updates',
    () async {
      h = StateHarness();
      Map<String, Object?> entry(String slug) => {
        'slug': slug,
        'type': 'streaming',
        'version': 2,
        'hosts': ['www.youtube.com'],
      };
      await addRepo([entry('a'), entry('b')]);
      await install('a', kind: 'streaming');
      await install('b', kind: 'streaming');

      final s = await sections();

      expect(slugs(s.updates), ['a']);
      expect(slugs(s.installed), ['b']);
    },
  );

  test('a database error is the error state', () async {
    h = StateHarness(
      more: [
        installedPluginsProvider.overrideWith(
          (ref) => Stream<List<PluginRow>>.error(StateError('db gone')),
        ),
      ],
    );
    final value = await h.settled(storeItemsProvider);
    expect(value.hasError, isTrue);
  });
}
