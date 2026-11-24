import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_cache_store.dart';

import '../../../database/support/test_db.dart';

TranslationKey _key({String install = 'plugin-a', String lang = 'vi'}) =>
    (contentHash: 'h1', installId: install, targetLang: lang);

void main() {
  late AppDatabase db;
  late TranslationCacheStore store;

  setUp(() {
    db = openTestDb();
    store = TranslationCacheStore(db);
  });
  tearDown(() => db.close());

  Future<void> addPlugin(
    String id, {
    String kind = 'translate',
    int? removedAt,
  }) => db.customStatement(
    'INSERT INTO plugins (install_id, kind, name, version, api_version, '
    'manifest_json, package_dir, package_sha256, origin, '
    'consented_hosts_json, installed_at, updated_at, removed_at) '
    "VALUES (?, ?, 'P', 1, 1, '{}', 'v1-1', ?, 'file', '[]', 1, 1, ?)",
    [id, kind, 'a' * 64, removedAt],
  );

  Future<void> addComplete(
    String install,
    int createdAt, {
    bool complete = true,
  }) async {
    final key = _key(install: install);
    await store.replace(
      TranslationCacheRow(
        key: key,
        sourceLang: 'en',
        lines: {'hello': 'xin chao $install'},
        settingsJson: '{}',
        complete: complete,
        createdAt: createdAt,
      ),
    );
  }

  group('chunks', () {
    test(
      'mergeChunk creates the row incomplete, a later chunk keeps the first',
      () async {
        expect(
          await store.mergeChunk(
            _key(),
            {'a': 'A'},
            settingsJson: '{"m":1}',
            now: 5,
          ),
          TranslationWrite.stored,
        );
        await store.mergeChunk(
          _key(),
          {'b': 'B'},
          settingsJson: '{"m":1}',
          now: 9,
        );
        final row = await store.lookup(_key());
        expect(row!.lines, {'a': 'A', 'b': 'B'});
        expect(row.complete, isFalse);
        expect(row.createdAt, 5);
      },
    );

    test('markComplete finishes the row; a later chunk reopens it', () async {
      await store.mergeChunk(_key(), {'a': 'A'}, settingsJson: '{}', now: 1);
      expect(
        await store.lookup(_key()),
        isA<TranslationCacheRow>().having(
          (r) => r.complete,
          'complete',
          isFalse,
        ),
      );
      expect(
        await store.markComplete(_key(), sourceLang: 'en'),
        TranslationWrite.stored,
      );
      final done = await store.lookup(_key());
      expect(done!.complete, isTrue);
      expect(done.sourceLang, 'en');
      await store.mergeChunk(_key(), {'b': 'B'}, settingsJson: '{}', now: 2);
      final again = await store.lookup(_key());
      expect(again!.complete, isFalse);
      expect(again.sourceLang, 'en');
    });

    test('markComplete without a row says missing', () async {
      expect(await store.markComplete(_key()), TranslationWrite.missing);
    });

    test('a merge past the size cap writes nothing', () async {
      await store.mergeChunk(_key(), {'a': 'A'}, settingsJson: '{}', now: 1);
      final big = {'k': 'x' * 2100000};
      expect(
        await store.mergeChunk(_key(), big, settingsJson: '{}', now: 2),
        TranslationWrite.tooLarge,
      );
      expect((await store.lookup(_key()))!.lines, {'a': 'A'});
    });

    test('replace swaps the whole row', () async {
      await store.mergeChunk(_key(), {'old': 'O'}, settingsJson: '{}', now: 1);
      await addComplete('plugin-a', 7);
      final row = await store.lookup(_key());
      expect(row!.lines.keys, ['hello']);
      expect(row.complete, isTrue);
      expect(row.createdAt, 7);
    });

    test('a damaged lines_json reads as no lines', () async {
      await db.customStatement(
        "INSERT INTO lyrics_translations (content_hash, install_id, target_lang, "
        "lines_json, settings_json, complete, created_at) VALUES ('h1', 'plugin-a', 'vi', 'not json', '{}', 1, 1)",
      );
      final row = await store.lookup(_key());
      expect(row!.lines, isEmpty);
    });
  });

  group('newestOther', () {
    test(
      'returns the newest complete row of another live translate plugin',
      () async {
        await addPlugin('plugin-a');
        await addPlugin('plugin-b');
        await addPlugin('plugin-c', kind: 'ai-translate');
        await addComplete('plugin-a', 30);
        await addComplete('plugin-b', 10);
        await addComplete('plugin-c', 20);
        final row = await store.newestOther('h1', 'vi', excluding: 'plugin-a');
        expect(row!.key.installId, 'plugin-c');
        expect(jsonEncode(row.lines), contains('plugin-c'));
      },
    );

    test(
      'skips removed plugins, other kinds, incomplete rows and other languages',
      () async {
        await addPlugin('plugin-a');
        await addPlugin('gone', removedAt: 5);
        await addPlugin('lyr', kind: 'lyrics');
        await addPlugin('half');
        await addPlugin('plugin-en');
        await addComplete('gone', 90);
        await addComplete('lyr', 80);
        await addComplete('half', 70, complete: false);
        await store.replace(
          TranslationCacheRow(
            key: _key(install: 'plugin-en', lang: 'en'),
            sourceLang: null,
            lines: const {'x': 'y'},
            settingsJson: '{}',
            complete: true,
            createdAt: 60,
          ),
        );
        expect(
          await store.newestOther('h1', 'vi', excluding: 'plugin-a'),
          isNull,
        );
      },
    );

    test('a plugin without a plugins row never counts', () async {
      await addComplete('ghost', 5);
      expect(
        await store.newestOther('h1', 'vi', excluding: 'plugin-a'),
        isNull,
      );
    });
  });

  test('the cache survives removing the plugin row state', () async {
    await addPlugin('plugin-a');
    await addComplete('plugin-a', 1);
    await db.customStatement('UPDATE plugins SET removed_at = 9');
    expect(await store.lookup(_key()), isNotNull);
  });

  test('watch follows writes', () async {
    final seen = <bool?>[];
    final sub = store.watch(_key()).listen((r) => seen.add(r?.complete));
    await pumpEventQueue();
    await store.mergeChunk(_key(), {'a': 'A'}, settingsJson: '{}', now: 1);
    await pumpEventQueue();
    await store.markComplete(_key());
    await pumpEventQueue();
    expect(seen, [null, false, true]);
    await sub.cancel();
  });
}
