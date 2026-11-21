import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/plugins/data/install/write_queue.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_cache.dart';
import 'package:kanaru/src/plugins/data/repos/repo_refresher.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/domain/install/repo_results.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';

import '../../database/support/test_db.dart';
import 'services_test_support.dart';

const _hour = 3600 * 1000;

void main() {
  late AppDatabase db;
  late PluginRepoRows rows;
  late FakeFetcher fetcher;
  late RepoRefresher refresher;
  var now = 0;

  setUp(() {
    db = openTestDb();
    rows = PluginRepoRows(db);
    now = 100 * _hour;
    fetcher = FakeFetcher((_) async => served(catalogBytes(['new'])));
    refresher = RepoRefresher(
      rows: rows,
      fetcher: fetcher,
      queue: PluginWriteQueue(firstJob: () async {}),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  /// A stored repository with the catalog of [slugs], fetched at [at].
  Future<int> addRepo(
    String host, {
    int? at,
    List<String> slugs = const ['old'],
  }) async {
    final (_, id) = await rows.add(
      url: 'https://$host/plugins.json',
      name: 'Kho $host',
      catalogJson: String.fromCharCodes(catalogBytes(slugs)),
      addressKind: AddressKind.public,
      now: at ?? now,
    );
    return id!;
  }

  Future<List<String>> slugsOf(int id) async {
    final row = (await rows.byId(id))!;
    return [for (final e in CatalogCache().catalogOf(row)!.entries) e.slug];
  }

  group('refresh', () {
    test(
      'stores the fresh catalog, name, class and clears the error',
      () async {
        final id = await addRepo('a.example.com');
        await rows.saveFailure(id, errorKind: 'network', now: now);
        await db.customStatement(
          "UPDATE plugin_repos SET address_class = 'local' WHERE id = $id",
        );
        fetcher.answer = (_) async => served(catalogBytes(['new']));
        now += _hour;

        final result = await refresher.refresh(id);

        expect(result!.error, isNull);
        final row = (await rows.byId(id))!;
        expect(row.lastError, isNull);
        expect(row.refreshedAt, now);
        expect(row.addressKind, AddressKind.public);
        expect(await slugsOf(id), ['new']);
        expect(fetcher.calls.single.uri.host, 'a.example.com');
      },
    );

    test(
      'a failure keeps the last good catalog and records the kind',
      () async {
        final id = await addRepo('a.example.com');
        fetcher.answer = (_) async => failed(FetchFailureKind.timeout);
        now += _hour;

        final result = await refresher.refresh(id);

        expect(result!.error, RepoError.timeout);
        final row = (await rows.byId(id))!;
        expect(row.lastError, 'timeout');
        expect(row.refreshedAt, 100 * _hour);
        expect(row.lastAttemptAt, now);
        expect(await slugsOf(id), ['old']);
      },
    );

    test('a body that is not a catalog keeps the old one', () async {
      final id = await addRepo('a.example.com');
      fetcher.answer = (_) async => served(catalogBytes([]).sublist(0, 5));
      final result = await refresher.refresh(id);
      expect(result!.error, RepoError.notACatalog);
      expect(await slugsOf(id), ['old']);
    });

    test('a repository that is not stored gives null', () async {
      expect(await refresher.refresh(99), isNull);
      expect(fetcher.calls, isEmpty);
    });

    test(
      'a repository removed while its fetch runs is not written back',
      () async {
        final id = await addRepo('a.example.com');
        final gate = Completer<void>();
        fetcher.answer = (_) async {
          await gate.future;
          return served(catalogBytes(['new']));
        };
        final pending = refresher.refresh(id);
        await Future<void>.delayed(Duration.zero);
        await rows.remove(id);
        gate.complete();
        expect(await pending, isNull);
        expect(await rows.all(), isEmpty);
      },
    );

    test('calls for one repository in flight share one fetch', () async {
      final id = await addRepo('a.example.com');
      final gate = Completer<void>();
      fetcher.answer = (_) async {
        await gate.future;
        return served(catalogBytes(['new']));
      };
      final a = refresher.refresh(id);
      final b = refresher.refresh(id);
      gate.complete();
      expect(await a, same(await b));
      expect(fetcher.calls, hasLength(1));
    });
  });

  group('address class', () {
    Future<void> setClass(int id, String value) => db.customStatement(
      "UPDATE plugin_repos SET address_class = '$value' WHERE id = $id",
    );

    test('a refresh never lowers a stored public class to local', () async {
      final id = await addRepo('a.example.com');
      fetcher.answer = (_) async =>
          served(catalogBytes(['new']), kind: AddressKind.local);
      await refresher.refresh(id);
      expect((await rows.byId(id))!.addressKind, AddressKind.public);
      expect(await slugsOf(id), ['new']);
    });

    test('a local class can rise to public', () async {
      final id = await addRepo('a.example.com');
      await setClass(id, 'local');
      await refresher.refresh(id);
      expect((await rows.byId(id))!.addressKind, AddressKind.public);
    });
  });

  test('refreshAll tells the icon cache to forget failures', () async {
    var told = 0;
    refresher = RepoRefresher(
      rows: rows,
      fetcher: fetcher,
      queue: PluginWriteQueue(firstJob: () async {}),
      onRefreshedAll: () => told++,
      clock: () => now,
    );
    await addRepo('a.example.com');
    await refresher.refreshAll();
    expect(told, 1);
  });

  group('refreshStale', () {
    test(
      'fetches never-fetched, failed, old and future-dated, not fresh',
      () async {
        final fresh = await addRepo('fresh.example.com', at: now - _hour);
        final old = await addRepo('old.example.com', at: now - 7 * _hour);
        final future = await addRepo('future.example.com', at: now + _hour);
        final failedId = await addRepo('failed.example.com', at: now);
        await rows.saveFailure(failedId, errorKind: 'network', now: now);
        final (_, never) = await rows.add(
          url: 'https://never.example.com/plugins.json',
          name: 'never',
          catalogJson: '{}',
          addressKind: AddressKind.public,
          now: now,
        );
        await db.customStatement(
          'UPDATE plugin_repos SET refreshed_at = NULL WHERE id = $never',
        );

        final results = await refresher.refreshStale();

        expect(
          {for (final r in results) r.repoId},
          {old, future, failedId, never},
        );
        expect({
          for (final c in fetcher.calls) c.uri.host,
        }, isNot(contains('fresh.example.com')));
        expect(fresh, isNot(old));
      },
    );

    test('exactly six hours old is stale', () async {
      final id = await addRepo('edge.example.com', at: now - 6 * _hour);
      expect([for (final r in await refresher.refreshStale()) r.repoId], [id]);
    });
  });

  group('refreshAll', () {
    test(
      'runs at most four fetches at once and covers every repository',
      () async {
        for (var i = 0; i < 9; i++) {
          await addRepo('r$i.example.com');
        }
        fetcher.answer = (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 15));
          return served(catalogBytes(['new']));
        };
        final results = await refresher.refreshAll();
        expect(results, hasLength(9));
        expect(fetcher.calls, hasLength(9));
        expect(fetcher.maxRunning, lessThanOrEqualTo(repoRefreshParallelism));
        expect(fetcher.maxRunning, greaterThan(1));
      },
    );

    test('calls made while it runs share it', () async {
      await addRepo('a.example.com');
      final gate = Completer<void>();
      fetcher.answer = (_) async {
        await gate.future;
        return served(catalogBytes(['new']));
      };
      final a = refresher.refreshAll();
      final b = refresher.refreshAll();
      final stale = refresher.refreshStale();
      gate.complete();
      expect(await a, same(await b));
      expect(await stale, same(await a));
      expect(fetcher.calls, hasLength(1));
    });

    test('one failing repository does not stop the others', () async {
      final bad = await addRepo('bad.example.com');
      final good = await addRepo('good.example.com');
      fetcher.answer = (uri) async => uri.host == 'bad.example.com'
          ? failed(FetchFailureKind.network)
          : served(catalogBytes(['new']));
      final results = await refresher.refreshAll();
      expect(
        {for (final r in results) r.repoId: r.error},
        {bad: RepoError.network, good: null},
      );
    });
  });
}
