import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/repos/icon_cache.dart';
import 'package:kanaru/src/plugins/data/repos/repo_address_guard.dart';
import 'package:kanaru/src/plugins/data/store/plugin_files.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';

import '../../database/support/test_db.dart';
import '../fixtures/catalog_support.dart';
import '../fixtures/zip_builders.dart';
import 'services_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeFetcher fetcher;
  late Directory dir;
  late PluginRepoRows rows;
  late PluginRepoRow repo;
  var now = DateTime(2026);
  var resolved = [publicIp()];
  var lookups = 0;

  PluginIconCache cache({
    int maxBytes = iconCacheMaxBytes,
    int maxConcurrent = iconMaxConcurrent,
  }) => PluginIconCache(
    fetcher: fetcher,
    guard: RepoAddressGuard(
      resolver: (_) async {
        lookups++;
        return resolved;
      },
      clock: () => now,
    ),
    files: PluginFiles(dir),
    maxBytes: maxBytes,
    maxConcurrent: maxConcurrent,
    clock: () => now,
  );

  CatalogEntry entry(String slug) => CatalogEntry(
    slug: slug,
    kind: PluginKind.lyrics,
    name: slug,
    version: 1,
    apiVersion: 1,
    hosts: const ['music.example.com'],
    path: Uri.parse('https://cdn.example.com/$slug.zip'),
    icon: Uri.parse('https://cdn.example.com/$slug.png'),
  );

  setUp(() async {
    db = openTestDb();
    rows = PluginRepoRows(db);
    dir = tempDir();
    now = DateTime(2026);
    resolved = [publicIp()];
    lookups = 0;
    final png = pngHeader(16, 16);
    fetcher = FakeFetcher((_) async => served(png));
    final (_, id) = await rows.add(
      url: catalogUrl.toString(),
      name: 'Kho',
      catalogJson: '{}',
      addressKind: AddressKind.public,
      now: 1,
    );
    repo = (await rows.byId(id!))!;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'fetches under the icon policy with the narrowed class and keeps it',
    () async {
      final icons = cache();
      final first = await icons.catalogIcon(repo, entry('a'));
      final second = await icons.catalogIcon(repo, entry('a'));
      expect(first, isNotNull);
      expect(second, same(first));
      expect(fetcher.calls, hasLength(1));
      expect(fetcher.calls.single.policy, NetPolicy.icon);
      expect(fetcher.calls.single.catalogKind, AddressKind.public);
    },
  );

  test('an entry without an icon gives null and no request', () async {
    final noIcon = CatalogEntry(
      slug: 'x',
      kind: PluginKind.lyrics,
      name: 'x',
      version: 1,
      apiVersion: 1,
      hosts: const ['a.example.com'],
      path: Uri.parse('https://cdn.example.com/x.zip'),
    );
    expect(await cache().catalogIcon(repo, noIcon), isNull);
    expect(fetcher.calls, isEmpty);
  });

  test(
    'a stored local class is narrowed to public when the address is public',
    () async {
      await db.customStatement(
        "UPDATE plugin_repos SET address_class = 'local' WHERE id = ${repo.id}",
      );
      repo = (await rows.byId(repo.id))!;
      expect(repo.addressKind, AddressKind.local);
      await cache().catalogIcon(repo, entry('a'));
      expect(fetcher.calls.single.catalogKind, AddressKind.public);
    },
  );

  test(
    'a repository address that no longer resolves refuses the fetch',
    () async {
      final icons = cache();
      resolved = [InternetAddress('0.0.0.0')];
      expect(await icons.catalogIcon(repo, entry('a')), isNull);
      expect(fetcher.calls, isEmpty);
    },
  );

  test('a failure is remembered for 60 seconds, then tried again', () async {
    fetcher.answer = (_) async => failed(FetchFailureKind.network);
    final icons = cache();
    expect(await icons.catalogIcon(repo, entry('a')), isNull);
    expect(await icons.catalogIcon(repo, entry('a')), isNull);
    expect(fetcher.calls, hasLength(1));

    now = now.add(const Duration(seconds: 61));
    fetcher.answer = (_) async => served(pngHeader(16, 16));
    expect(await icons.catalogIcon(repo, entry('a')), isNotNull);
    expect(fetcher.calls, hasLength(2));
  });

  test('clearFailures lets the next ask try at once', () async {
    fetcher.answer = (_) async => failed(FetchFailureKind.timeout);
    final icons = cache();
    await icons.catalogIcon(repo, entry('a'));
    fetcher.answer = (_) async => served(pngHeader(16, 16));
    icons.clearFailures();
    expect(await icons.catalogIcon(repo, entry('a')), isNotNull);
  });

  test('bytes that are not a PNG count as a failure', () async {
    fetcher.answer = (_) async => served(Uint8List.fromList([1, 2, 3]));
    final icons = cache();
    expect(await icons.catalogIcon(repo, entry('a')), isNull);
    expect(icons.cachedBytes, 0);
  });

  test('concurrent asks share one fetch', () async {
    final gate = Completer<void>();
    fetcher.answer = (_) async {
      await gate.future;
      return served(pngHeader(16, 16));
    };
    final icons = cache();
    final a = icons.catalogIcon(repo, entry('a'));
    final b = icons.catalogIcon(repo, entry('a'));
    gate.complete();
    expect(await a, same(await b));
    expect(fetcher.calls, hasLength(1));
  });

  test(
    'a burst of icons of one repository looks the address up once',
    () async {
      final icons = cache();
      await Future.wait([
        for (final s in ['a', 'b', 'c']) icons.catalogIcon(repo, entry(s)),
      ]);
      expect(lookups, 1);
    },
  );

  test('the least recently used icon goes when the budget is passed', () async {
    final icons = cache(maxBytes: 70); // two 33-byte icons fit, three do not
    await icons.catalogIcon(repo, entry('a'));
    await icons.catalogIcon(repo, entry('b'));
    await icons.catalogIcon(repo, entry('a')); // a is now the newest
    await icons.catalogIcon(repo, entry('c')); // evicts b
    expect(icons.cachedBytes, 66);
    fetcher.calls.clear();
    await icons.catalogIcon(repo, entry('a'));
    await icons.catalogIcon(repo, entry('c'));
    expect(fetcher.calls, isEmpty);
    await icons.catalogIcon(repo, entry('b'));
    expect(fetcher.calls, hasLength(1));
  });

  test(
    'a burst of icons runs at most the cap at once, the rest wait',
    () async {
      final gate = Completer<void>();
      fetcher.answer = (_) async {
        await gate.future;
        return served(pngHeader(16, 16));
      };
      final icons = cache(maxConcurrent: 3);
      final all = Future.wait([
        for (var i = 0; i < 10; i++) icons.catalogIcon(repo, entry('s$i')),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fetcher.running, 3);
      gate.complete();
      final got = await all;
      expect(got.every((b) => b != null), isTrue);
      expect(fetcher.calls, hasLength(10));
      expect(fetcher.maxRunning, 3);
    },
  );

  test('a failed fetch gives its slot to the next one', () async {
    fetcher.answer = (uri) async => uri.path.contains('bad')
        ? throw StateError('boom')
        : served(pngHeader(16, 16));
    final icons = cache(maxConcurrent: 1);
    final got = await Future.wait([
      icons.catalogIcon(repo, entry('bad1')),
      icons.catalogIcon(repo, entry('good')),
    ]);
    expect(got[0], isNull);
    expect(got[1], isNotNull);
  });
}
