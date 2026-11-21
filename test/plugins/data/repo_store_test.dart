import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/install/write_queue.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_cache.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_codec.dart';
import 'package:kanaru/src/plugins/data/repos/repo_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/domain/install/repo_results.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';

import '../../database/support/test_db.dart';
import '../fixtures/catalog_support.dart';
import 'services_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRepoRows rows;
  late FakeFetcher fetcher;
  late PluginRepositories repos;
  late CatalogCache catalogs;
  const address = 'https://repo.example.com/plugins.json';

  setUp(() {
    db = openTestDb();
    rows = PluginRepoRows(db);
    fetcher = FakeFetcher((_) async => served(catalogBytes(['a', 'b'])));
    catalogs = CatalogCache();
    repos = PluginRepositories(
      rows: rows,
      fetcher: fetcher,
      queue: PluginWriteQueue(firstJob: () async {}),
      catalogs: catalogs,
      clock: () => 5000,
    );
  });
  tearDown(() => db.close());

  Future<RepoError?> addError(String input) async {
    final result = await repos.add(input);
    return result is RepoAddFailed ? result.error : null;
  }

  group('add', () {
    test(
      'stores the canonical address, name, catalog and address class',
      () async {
        fetcher.answer = (_) async =>
            served(catalogBytes(['a', 'b']), kind: AddressKind.local);
        final result = await repos.add(
          '  HTTPS://Repo.Example.com:443/plugins.json ',
        );
        expect(result, isA<RepoAdded>());
        final row = (await rows.all()).single;
        expect(row.url, address);
        expect(row.name, 'Kho của hieu05');
        expect(row.addressKind, AddressKind.local);
        expect(row.refreshedAt, 5000);
        expect(catalogs.catalogOf(row)!.entries.map((e) => e.slug), ['a', 'b']);
        expect(fetcher.calls.single.uri, Uri.parse(address));
      },
    );

    test(
      'an address that is not http(s) is invalidUrl and no request is made',
      () async {
        expect(await addError('ftp://x.example.com/a'), RepoError.invalidUrl);
        expect(await addError('not a url'), RepoError.invalidUrl);
        expect(fetcher.calls, isEmpty);
      },
    );

    test(
      'a second add of the same address is a duplicate without a fetch',
      () async {
        await repos.add(address);
        fetcher.calls.clear();
        expect(
          await addError('HTTPS://repo.example.com/plugins.json'),
          RepoError.duplicate,
        );
        expect(fetcher.calls, isEmpty);
        expect(await rows.all(), hasLength(1));
      },
    );

    test(
      'concurrent adds of one address share one fetch and one row',
      () async {
        final gate = Completer<void>();
        fetcher.answer = (_) async {
          await gate.future;
          return served(catalogBytes(['a']));
        };
        final first = repos.add(address);
        final second = repos.add('HTTPS://REPO.example.com/plugins.json');
        gate.complete();
        final results = await Future.wait([first, second]);
        expect(results[0], same(results[1]));
        expect(fetcher.calls, hasLength(1));
        expect(await rows.all(), hasLength(1));
      },
    );

    final cases = <String, (Result<FetchResult, FetchFailure>, RepoError)>{
      'plain http on a public host is needsHttps': (
        failed(
          FetchFailureKind.blockedAddress,
          reason: AddressProblem.publicNeedsHttps,
        ),
        RepoError.needsHttps,
      ),
      'a refused address is blocked': (
        failed(
          FetchFailureKind.blockedAddress,
          reason: AddressProblem.refusedAddress,
        ),
        RepoError.blocked,
      ),
      'no connection is network': (
        failed(FetchFailureKind.network),
        RepoError.network,
      ),
      'a slow server is timeout': (
        failed(FetchFailureKind.timeout),
        RepoError.timeout,
      ),
      'an error status is badStatus': (
        failed(FetchFailureKind.badStatus),
        RepoError.badStatus,
      ),
      'an oversized body is tooLarge': (
        failed(FetchFailureKind.tooLarge),
        RepoError.tooLarge,
      ),
    };
    cases.forEach((name, c) {
      test('$name and nothing is stored', () async {
        fetcher.answer = (_) async => c.$1;
        expect(await addError(address), c.$2);
        expect(await rows.all(), isEmpty);
      });
    });

    test('the refused reason travels with a blocked error', () async {
      fetcher.answer = (_) async => failed(
        FetchFailureKind.blockedAddress,
        reason: AddressProblem.localFromPublic,
      );
      final result = await repos.add(address) as RepoAddFailed;
      expect(result.reason, AddressProblem.localFromPublic);
    });

    test('an answer that is not a catalog is notACatalog', () async {
      fetcher.answer = (_) async => served(jsonBytes({'hello': 1}));
      expect(await addError(address), RepoError.notACatalog);
      expect(await rows.all(), isEmpty);
    });

    test('a database failure is storageFailed, never thrown', () async {
      repos = PluginRepositories(
        rows: _BrokenRepoRows(db),
        fetcher: fetcher,
        queue: PluginWriteQueue(firstJob: () async {}),
        catalogs: catalogs,
      );
      expect(await addError(address), RepoError.storageFailed);
    });
  });

  group('remove', () {
    test('deletes the row only', () async {
      final id = (await repos.add(address) as RepoAdded).repoId;
      expect(await repos.remove(id), RepoRemoveResult.removed);
      expect(await rows.all(), isEmpty);
      expect(await repos.remove(id), RepoRemoveResult.missing);
    });

    test('a database failure is failed, never thrown', () async {
      repos = PluginRepositories(
        rows: _BrokenRepoRows(db),
        fetcher: fetcher,
        queue: PluginWriteQueue(firstJob: () async {}),
        catalogs: catalogs,
      );
      expect(await repos.remove(1), RepoRemoveResult.failed);
    });
  });

  group('catalog codec', () {
    test('stored text reads back to the same entries, references absolute', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'path': 'netease/plugin.zip', 'icon': 'icon.png'}),
          entryJson({
            'slug': 'future',
            'type': 'teleport',
            'sha256': 'a' * 64,
            'size': 1234,
            'languages': ['vi', 'en'],
          }),
        ]),
      );
      final back = decodeCatalog(
        encodeCatalog(catalog),
        catalogUrl,
        AddressKind.public,
      ).fold((c) => c, (e) => fail('$e'));
      expect(back.name, catalog.name);
      expect(back.entries, hasLength(2));
      expect(
        back.entries[0].path.toString(),
        'https://repo.example.com/netease/plugin.zip',
      );
      expect(
        back.entries[0].icon.toString(),
        'https://repo.example.com/icon.png',
      );
      expect(back.entries[1].needsNewerApp, isTrue);
      expect(back.entries[1].sha256, 'a' * 64);
      expect(back.entries[1].size, 1234);
      expect(back.entries[1].languages, catalog.entries[1].languages);
    });
  });
}

/// Rows whose reads and deletes fail, as a broken database would.
class _BrokenRepoRows extends PluginRepoRows {
  _BrokenRepoRows(super.db);

  @override
  Future<PluginRepoRow?> byUrl(String url) => throw StateError('db');

  @override
  Future<bool> remove(int id) => throw StateError('db');
}
