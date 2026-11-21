import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/repos/repo_address_guard.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';

import '../../database/support/test_db.dart';
import '../fixtures/catalog_support.dart';

void main() {
  late AppDatabase db;
  late PluginRepoRow repo;
  var now = DateTime(2026);
  var lookups = 0;
  Future<List<InternetAddress>> Function(String) resolver = (_) async => [];

  RepoAddressGuard guard() => RepoAddressGuard(
    resolver: (host) {
      lookups++;
      return resolver(host);
    },
    clock: () => now,
  );

  setUp(() async {
    db = openTestDb();
    now = DateTime(2026);
    lookups = 0;
    resolver = (_) async => [InternetAddress('93.184.216.34')];
    final rows = PluginRepoRows(db);
    final (_, id) = await rows.add(
      url: catalogUrl.toString(),
      name: 'Kho',
      catalogJson: '{}',
      addressKind: AddressKind.public,
      now: 1,
    );
    repo = (await rows.byId(id!))!;
  });
  tearDown(() => db.close());

  test('a good answer is reused for 60 s, then looked up again', () async {
    final g = guard();
    expect((await g.kindFor(repo) as Ok).value, AddressKind.public);
    await g.kindFor(repo);
    expect(lookups, 1);
    now = now.add(const Duration(seconds: 59));
    await g.kindFor(repo);
    expect(lookups, 1);
    now = now.add(const Duration(seconds: 2));
    await g.kindFor(repo);
    expect(lookups, 2);
  });

  test('a failure is not reused', () async {
    final g = guard();
    resolver = (_) async => throw StateError('dns');
    expect(await g.kindFor(repo), isA<Err>());
    resolver = (_) async => [InternetAddress('93.184.216.34')];
    expect(await g.kindFor(repo), isA<Ok>());
    expect(lookups, 2);
  });

  test('clear forgets what was looked up', () async {
    final g = guard();
    await g.kindFor(repo);
    g.clear();
    await g.kindFor(repo);
    expect(lookups, 2);
  });
}
