import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/lyrics/domain/online/online_resolution.dart';

import 'support/test_db.dart';

const _day = 24 * 60 * 60 * 1000;
const _now = 100 * _day;

void main() {
  late AppDatabase db;
  late OnlineCacheStore cache;

  setUp(() {
    db = openTestDb();
    cache = OnlineCacheStore(db);
  });
  tearDown(() => db.close());

  Future<StoreResult> found(
    String key,
    String provider, {
    String? synced,
    String? plain = 'words',
    bool instrumental = false,
    int now = _now,
  }) => cache.putFound(
    key,
    provider,
    remoteId: 'r-$provider',
    syncedText: synced,
    plainText: plain,
    instrumental: instrumental,
    remoteDurationMs: 200000,
    now: now,
  );

  test('putFound stores the result and replaces an older answer', () async {
    await cache.putNotFound('k', 'p1', now: 1);
    expect(await found('k', 'p1'), StoreResult.stored);
    final rows = await cache.readFresh('k', now: _now);
    expect(rows, hasLength(1));
    expect(
      (rows.single.status, rows.single.remoteId, rows.single.plainText),
      ('found', 'r-p1', 'words'),
    );
    expect(rows.single.remoteDurationMs, 200000);
  });

  test('a result with nothing to show or over 1 MiB is not cached', () async {
    expect(await found('k', 'p1', plain: null), StoreResult.notStored);
    expect(
      await found('k', 'p1', plain: 'x' * (1024 * 1024 + 1)),
      StoreResult.notStored,
    );
    expect(
      await found('k', 'p1', plain: null, instrumental: true),
      StoreResult.stored,
    );
    expect(await cache.readFresh('k', now: _now), hasLength(1));
  });

  test('not found is fresh for 14 days, a result never expires', () async {
    await cache.putNotFound('k', 'p1', now: _now - notFoundTtl.inMilliseconds);
    await cache.putNotFound(
      'k',
      'p2',
      now: _now - notFoundTtl.inMilliseconds + 1,
    );
    await found('k', 'p3', now: 1);
    final fresh = await cache.readFresh('k', now: _now);
    expect([for (final r in fresh) r.providerId], ['p2', 'p3']);
    expect(await cache.watch('k').first, hasLength(3));
  });

  test('rows of another key are not read', () async {
    await found('k1', 'p1');
    await found('k2', 'p1');
    expect(await cache.readFresh('k1', now: _now), hasLength(1));
  });

  test('a not-found of one source never hides another source', () async {
    await cache.putNotFound('k', 'off-source', now: _now);
    await found('k', 'p1');
    final rows = await cache.readFresh('k', now: _now);
    expect(
      {for (final r in rows) r.providerId: r.status},
      {'off-source': 'not_found', 'p1': 'found'},
    );
  });

  test('deleteRow drops one source answer only', () async {
    await found('k', 'p1');
    await found('k', 'p2');
    await cache.deleteRow('k', 'p1');
    expect(
      [for (final r in await cache.readFresh('k', now: _now)) r.providerId],
      ['p2'],
    );
  });

  test(
    'deleteByProvider drops every row of the plugin and counts them',
    () async {
      await found('k1', 'p1');
      await found('k2', 'p1');
      await cache.putNotFound('k3', 'p1', now: _now);
      await found('k1', 'p2');
      expect(await cache.deleteByProvider('p1'), 3);
      expect(await cache.deleteByProvider('p1'), 0);
      expect(await cache.readFresh('k1', now: _now), hasLength(1));
    },
  );

  test('stats count result rows and UTF-8 bytes per plugin', () async {
    await found('k1', 'p1', synced: '[00:01.00] a', plain: 'あい');
    await found('k2', 'p1', plain: 'abc');
    await found('k3', 'p1', plain: null, instrumental: true);
    await cache.putNotFound('k4', 'p1', now: _now);
    await found('k1', 'p2', plain: 'z');
    final stats = await cache.statsByProvider();
    expect(stats['p1'], (rows: 3, bytes: 12 + 6 + 3));
    expect(stats['p2'], (rows: 1, bytes: 1));
    expect(stats.containsKey('p3'), isFalse);
  });

  test('the table refuses a status other than found and not_found', () async {
    await expectLater(
      db.customStatement(
        "INSERT INTO online_lyrics (cache_key, provider_id, status, fetched_at) VALUES ('k', 'p', 'maybe', 1)",
      ),
      throwsConstraint('CHECK'),
    );
  });

  test('the cache has no foreign key and needs no track or plugin', () async {
    await found('k', 'unknown-plugin');
    expect(await cache.readFresh('k', now: _now), hasLength(1));
  });
}
