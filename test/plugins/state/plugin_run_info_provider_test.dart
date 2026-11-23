import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/state/plugin_run_info_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../data/store_test_support.dart';
import 'state_test_support.dart';

void main() {
  late StateHarness h;
  final id = testInstallId();

  setUp(() async {
    h = StateHarness();
    await h.container
        .read(pluginRowsProvider)
        .installOrRevive(
          id,
          draftOf(packageOf()),
          const PluginSource.repo('https://repo.example.com/plugins.json', 'x'),
        );
  });
  tearDown(() => h.dispose());

  Future<void> addLyrics(
    String key,
    String provider, {
    String? synced,
    String? plain,
    bool found = true,
  }) => h.db
      .into(h.db.onlineLyrics)
      .insert(
        found
            ? OnlineLyricsCompanion.insert(
                cacheKey: key,
                providerId: provider,
                status: OnlineLyricsStatus.found,
                remoteId: const Value('r'),
                syncedText: Value(synced),
                plainText: Value(plain),
                fetchedAt: 1,
              )
            : OnlineLyricsCompanion.insert(
                cacheKey: key,
                providerId: provider,
                status: OnlineLyricsStatus.notFound,
                fetchedAt: 1,
              ),
      );

  Future<void> setStorage(String json) => h.db.customUpdate(
    'UPDATE plugin_data SET storage_json = ?1 WHERE install_id = ?2',
    variables: [Variable<String>(json), Variable<String>(id)],
  );

  group('own storage', () {
    test('is 0 bytes when nothing is stored', () async {
      expect(await h.container.read(pluginStorageBytesProvider(id).future), 0);
    });

    test('measures the stored keys and values', () async {
      await setStorage('{"token":"abcdef"}');
      expect(
        await h.container.read(pluginStorageBytesProvider(id).future),
        'token'.length + 'abcdef'.length,
      );
    });

    test('clearing empties it and bumps the clear counter', () async {
      await setStorage('{"token":"abcdef"}');
      final before = await h.container
          .read(pluginStorageStoreProvider)
          .read(id);
      await h.container.read(pluginDataOpsProvider).clearStorage(id);
      final after = await h.container.read(pluginStorageStoreProvider).read(id);
      expect(after.json, isEmpty);
      expect(after.rev, before.rev + 1);
      expect(await h.container.read(pluginStorageBytesProvider(id).future), 0);
    });
  });

  group('saved lyrics', () {
    test('none for a plugin that saved nothing', () async {
      final stats = await h.container.read(savedLyricsStatsProvider(id).future);
      expect(stats.count, 0);
      expect(stats.bytes, 0);
    });

    test(
      'counts only found rows of that plugin, with their text size',
      () async {
        await addLyrics('a', id, synced: 'abcd', plain: 'xy');
        await addLyrics('b', id, plain: 'é'); // two bytes in UTF-8
        await addLyrics('c', id, found: false);
        await addLyrics('a', 'other', plain: 'zzzz');
        final stats = await h.container.read(
          savedLyricsStatsProvider(id).future,
        );
        expect(stats.count, 2);
        expect(stats.bytes, 4 + 2 + 2);
      },
    );

    test('clearing deletes that plugin\'s rows only, never pins', () async {
      await addLyrics('a', id, plain: 'one');
      await addLyrics('a', 'other', plain: 'two');
      await h.container.read(pluginDataOpsProvider).clearSavedLyrics(id);
      final left = await h.db.select(h.db.onlineLyrics).get();
      expect(left.map((r) => r.providerId), ['other']);
      expect(
        (await h.container.read(savedLyricsStatsProvider(id).future)).count,
        0,
      );
      expect(await h.db.select(h.db.lyricsPins).get(), isEmpty);
    });
  });
}
