import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_codec.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/updates_provider.dart';

import '../data/store_test_support.dart';
import '../domain/plugin_test_support.dart';
import '../fixtures/catalog_support.dart';
import 'state_test_support.dart';

const _url = 'https://repo.example.com/plugins.json';

void main() {
  late StateHarness h;
  setUp(() => h = StateHarness());
  tearDown(() => h.dispose());

  Future<void> setUpRepo(List<Map<String, Object?>> entries) async {
    final catalog = okCatalog(
      catalogJson([
        for (final e in entries)
          entryJson({
            'hosts': ['music.example.com'],
            ...e,
          }),
      ]),
      url: Uri.parse(_url),
    );
    await h.container
        .read(pluginRepoRowsProvider)
        .add(
          url: _url,
          name: 'Kho',
          catalogJson: encodeCatalog(catalog),
          addressKind: AddressKind.public,
          now: 1,
        );
  }

  Future<void> install(String slug) => h.container
      .read(pluginRowsProvider)
      .installOrRevive(
        repoInstallId(_url, slug),
        draftOf(packageOf(), 'v3-1'),
        PluginSource.repo(_url, slug),
      );

  Future<PluginUpdates> updates() async =>
      (await h.settled(updatesProvider)).requireValue;

  test('counts silent updates and the ones that need review', () async {
    await setUpRepo([
      {'slug': 'a', 'version': 4},
      {
        'slug': 'b',
        'version': 4,
        'hosts': ['music.example.com', 'new.example.com'],
      },
      {'slug': 'c'},
      {'slug': 'd', 'version': 4, 'type': 'translate'},
    ]);
    for (final s in ['a', 'b', 'c', 'd']) {
      await install(s);
    }

    final u = await updates();

    expect([for (final x in u.silent) x.entry.slug], ['a']);
    expect([for (final x in u.needsReview) x.entry.slug], ['b']);
    expect(u.count, 2);
    expect(u.updateAllCount, 1);
  });

  test('a plugin flagged after a download moves to review', () async {
    await setUpRepo([
      {'slug': 'a', 'version': 4},
    ]);
    await install('a');
    expect((await updates()).updateAllCount, 1);

    h.container
        .read(pluginActionsProvider)
        .activity
        .flagReview(repoInstallId(_url, 'a'));

    final u = await updates();
    expect(u.updateAllCount, 0);
    expect(u.needsReview.length, 1);
  });

  test('a streaming plugin without the slot is no update', () async {
    final entry = {
      'type': 'streaming',
      'version': 2,
      'hosts': ['www.youtube.com', '*.googlevideo.com'],
    };
    await setUpRepo([
      {'slug': 'a', ...entry},
      {'slug': 'b', ...entry},
    ]);
    for (final s in ['a', 'b']) {
      await h.container
          .read(pluginRowsProvider)
          .installOrRevive(
            repoInstallId(_url, s),
            draftOf(
              packageOf(streamingManifest(), {'src/stream.js': 'x'}),
              'v1-1',
            ),
            PluginSource.repo(_url, s),
          );
    }

    final u = await updates();

    expect([for (final x in u.silent) x.entry.slug], ['a']);
    expect(u.count, 1);
  });

  test('a plugin from a removed repository has no update', () async {
    await install('a');
    expect((await updates()).count, 0);
  });

  test('updating ids follow the work in flight', () async {
    final actions = h.container.read(pluginActionsProvider);
    expect(await h.settled(updatingIdsProvider), isEmpty);
    final done = actions.activity.track('plugin-x', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(await h.settled(updatingIdsProvider), {'plugin-x'});
    await done;
    expect(await h.settled(updatingIdsProvider), isEmpty);
  });

  test('a database error is the error state', () async {
    final failing = StateHarness(
      more: [
        installedPluginsProvider.overrideWith(
          (ref) => Stream<List<PluginRow>>.error(StateError('db gone')),
        ),
      ],
    );
    addTearDown(failing.dispose);
    expect((await failing.settled(updatesProvider)).hasError, isTrue);
  });
}
