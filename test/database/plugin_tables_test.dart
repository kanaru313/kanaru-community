import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';

import 'support/test_db.dart';

const _id = 'plugin-00000000000000000000000000000001';

/// INSERT of one `plugins` row; [over] replaces columns by name.
Future<void> _insertPlugin(
  AppDatabase db, [
  Map<String, Object?> over = const {},
]) {
  final row = <String, Object?>{
    'install_id': _id,
    'kind': 'lyrics',
    'name': 'Demo',
    'version': 1,
    'api_version': 1,
    'manifest_json': '{}',
    'package_dir': 'v1-1',
    'package_sha256': 'a' * 64,
    'origin': 'file',
    'consented_hosts_json': '[]',
    'installed_at': 1,
    'updated_at': 1,
    ...over,
  };
  return db.customStatement(
    'INSERT INTO plugins (${row.keys.join(', ')}) '
    'VALUES (${List.filled(row.length, '?').join(', ')})',
    row.values.toList(),
  );
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  group('plugins CHECK constraints', () {
    test('a file install with no repository columns is accepted', () async {
      await _insertPlugin(db);
      await _insertPlugin(db, {
        'install_id': 'plugin-00000000000000000000000000000002',
        'origin': 'link',
        'origin_label': 'https://x.example.com/p.zip',
      });
      await _insertPlugin(db, {
        'install_id': 'plugin-00000000000000000000000000000003',
        'origin': 'repo',
        'repo_url': 'https://r.example.com/plugins.json',
        'repo_slug': 'demo',
      });
      expect(await db.select(db.plugins).get(), hasLength(3));
    });

    test('origin repo needs both repository columns', () async {
      await expectLater(
        _insertPlugin(db, {'origin': 'repo'}),
        throwsConstraint('plugins_origin_repo'),
      );
      await expectLater(
        _insertPlugin(db, {
          'origin': 'repo',
          'repo_url': 'https://r.example.com/p.json',
        }),
        throwsConstraint('plugins_origin_repo'),
      );
      await expectLater(
        _insertPlugin(db, {'origin': 'repo', 'repo_slug': 'demo'}),
        throwsConstraint('plugins_origin_repo'),
      );
    });

    test('a file or link install never carries repository columns', () async {
      await expectLater(
        _insertPlugin(db, {
          'repo_url': 'https://r.example.com/p.json',
          'repo_slug': 'd',
        }),
        throwsConstraint('plugins_origin_repo'),
      );
      await expectLater(
        _insertPlugin(db, {'repo_slug': 'd'}),
        throwsConstraint('plugins_origin_repo'),
      );
    });

    test('origin link needs its link', () async {
      await expectLater(
        _insertPlugin(db, {'origin': 'link'}),
        throwsConstraint('plugins_origin_link'),
      );
    });

    test('unknown origin and kind are refused', () async {
      await expectLater(
        _insertPlugin(db, {'origin': 'zip'}),
        throwsConstraint('CHECK'),
      );
      await expectLater(
        _insertPlugin(db, {'kind': 'source'}),
        throwsConstraint('CHECK'),
      );
    });

    test('every kind of the app is accepted', () async {
      var n = 10;
      for (final kind in ['lyrics', 'translate', 'ai-translate', 'streaming']) {
        await _insertPlugin(db, {
          'install_id': 'plugin-${'${n++}'.padLeft(32, '0')}',
          'kind': kind,
        });
      }
      expect(await db.select(db.plugins).get(), hasLength(4));
    });
  });

  group('plugin_data', () {
    test('references plugins with RESTRICT', () async {
      final fks = await db
          .customSelect(
            'SELECT "table" AS parent, "from" AS col, on_delete AS action '
            "FROM pragma_foreign_key_list('plugin_data')",
          )
          .get();
      expect(fks, hasLength(1));
      expect(fks.single.data, {
        'parent': 'plugins',
        'col': 'install_id',
        'action': 'RESTRICT',
      });
    });

    test('a plugin with data cannot be deleted; without it can', () async {
      await _insertPlugin(db);
      await db.customStatement(
        'INSERT INTO plugin_data (install_id) VALUES (?)',
        [_id],
      );
      await expectLater(
        db.customStatement('DELETE FROM plugins WHERE install_id = ?', [_id]),
        throwsConstraint('FOREIGN KEY'),
      );
      await db.customStatement('DELETE FROM plugin_data');
      await db.customStatement('DELETE FROM plugins WHERE install_id = ?', [
        _id,
      ]);
    });

    test('a data row needs its plugin and defaults to empty objects', () async {
      await expectLater(
        db.customStatement('INSERT INTO plugin_data (install_id) VALUES (?)', [
          _id,
        ]),
        throwsConstraint('FOREIGN KEY'),
      );
      await _insertPlugin(db);
      await db.customStatement(
        'INSERT INTO plugin_data (install_id) VALUES (?)',
        [_id],
      );
      final row = (await db.select(db.pluginData).get()).single;
      expect(row.configJson, '{}');
      expect(row.customChoicesJson, '{}');
    });
  });

  group('plugin_repos', () {
    test('address_class only takes public or local', () async {
      for (final bad in ['refused', '', 'PUBLIC']) {
        await expectLater(
          db.customStatement(
            'INSERT INTO plugin_repos (url, name, added_at, address_class) '
            "VALUES ('u$bad', 'x', 1, ?)",
            [bad],
          ),
          throwsConstraint('CHECK'),
          reason: bad,
        );
      }
    });

    late PluginRepoRows repos;
    setUp(() => repos = PluginRepoRows(db));

    Future<(RepoWrite, int?)> add(
      String url, {
      String catalog = '{"data":[]}',
    }) => repos.add(
      url: url,
      name: 'Repo',
      catalogJson: catalog,
      addressKind: AddressKind.public,
      now: 10,
    );

    test('the url is unique, also against the raw table', () async {
      expect((await add('https://a.example.com/p.json')).$1, RepoWrite.written);
      expect(
        (await add('https://a.example.com/p.json')).$1,
        RepoWrite.duplicate,
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO plugin_repos (url, name, added_at, address_class) VALUES (?, 'x', 1, 'public')",
          ['https://a.example.com/p.json'],
        ),
        throwsConstraint('UNIQUE'),
      );
      expect(await repos.all(), hasLength(1));
    });

    test('a catalog over 1 MiB is refused and nothing is written', () async {
      final big = 'x' * (1024 * 1024 + 1);
      expect(
        (await add('https://a.example.com/p.json', catalog: big)).$1,
        RepoWrite.tooLarge,
      );
      expect(await repos.all(), isEmpty);
      final (_, id) = await add('https://b.example.com/p.json');
      expect(
        await repos.saveCatalog(
          id!,
          name: 'R',
          catalogJson: big,
          addressKind: AddressKind.public,
          now: 20,
        ),
        RepoWrite.tooLarge,
      );
      expect((await repos.byId(id))!.catalogJson, '{"data":[]}');
    });

    test('only an exact local reads as local', () {
      PluginRepoRow row(String value) => PluginRepoRow(
        id: 1,
        url: 'u',
        name: 'n',
        addedAt: 1,
        addressClass: value,
      );
      expect(row('local').addressKind, AddressKind.local);
      expect(row('public').addressKind, AddressKind.public);
      for (final odd in ['', 'Local', 'LOCAL', 'refused', 'localhost']) {
        expect(row(odd).addressKind, AddressKind.public, reason: odd);
      }
    });

    test('a failed refresh keeps the last good catalog', () async {
      final (_, id) = await add('https://a.example.com/p.json');
      expect(
        await repos.saveFailure(id!, errorKind: 'network', now: 30),
        RepoWrite.written,
      );
      var row = (await repos.byId(id))!;
      expect(row.catalogJson, '{"data":[]}');
      expect(row.lastError, 'network');
      expect(row.lastAttemptAt, 30);
      expect(row.refreshedAt, 10);
      await repos.saveCatalog(
        id,
        name: 'New',
        catalogJson: '{"data":[1]}',
        addressKind: AddressKind.local,
        now: 40,
      );
      row = (await repos.byId(id))!;
      expect(row.lastError, isNull);
      expect(row.refreshedAt, 40);
      expect(row.name, 'New');
      expect(row.addressKind, AddressKind.local);
    });

    test('removing a repository keeps the plugins installed from it', () async {
      final (_, id) = await add('https://a.example.com/p.json');
      await _insertPlugin(db, {
        'origin': 'repo',
        'repo_url': 'https://a.example.com/p.json',
        'repo_slug': 'demo',
      });
      expect(await repos.remove(id!), isTrue);
      expect(await repos.remove(id), isFalse);
      expect(await db.select(db.plugins).get(), hasLength(1));
      expect(
        await repos.saveFailure(id, errorKind: 'x', now: 1),
        RepoWrite.missing,
      );
    });
  });
}
