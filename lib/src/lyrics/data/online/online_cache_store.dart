import 'dart:async';

import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../domain/online/online_resolution.dart' show notFoundTtl;
import 'store_result.dart';

/// Rows and bytes of the cached lyrics of one plugin.
typedef CacheStats = ({int rows, int bytes});

/// The lookup cache: what each source answered for a song key. Safe to drop.
class OnlineCacheStore {
  OnlineCacheStore(this._db);

  final AppDatabase _db;

  /// Caches the result [remoteId] of [providerId] for [cacheKey], replacing
  /// an older answer. [StoreResult.notStored] for a result with no text and
  /// not instrumental, or a text over 1 MiB (never cached).
  Future<StoreResult> putFound(
    String cacheKey,
    String providerId, {
    required String remoteId,
    String? syncedText,
    String? plainText,
    bool instrumental = false,
    int? remoteDurationMs,
    required int now,
  }) async {
    final synced = storableLyrics(syncedText);
    final plain = storableLyrics(plainText);
    if (synced == null && plain == null && !instrumental) {
      return StoreResult.notStored;
    }
    if (textTooLarge(synced) || textTooLarge(plain)) {
      return StoreResult.notStored;
    }
    await _db
        .into(_db.onlineLyrics)
        .insertOnConflictUpdate(
          OnlineLyricsCompanion.insert(
            cacheKey: cacheKey,
            providerId: providerId,
            status: OnlineLyricsStatus.found,
            remoteId: Value(remoteId),
            syncedText: Value(synced),
            plainText: Value(plain),
            instrumental: Value(instrumental),
            remoteDurationMs: Value(remoteDurationMs),
            fetchedAt: now,
          ),
        );
    return StoreResult.stored;
  }

  /// Records that [providerId] has nothing for [cacheKey]; trusted for
  /// [notFoundTtl]. Only for a real "no match": a failure is never cached.
  Future<void> putNotFound(
    String cacheKey,
    String providerId, {
    required int now,
  }) => _db
      .into(_db.onlineLyrics)
      .insertOnConflictUpdate(
        OnlineLyricsCompanion.insert(
          cacheKey: cacheKey,
          providerId: providerId,
          status: OnlineLyricsStatus.notFound,
          fetchedAt: now,
        ),
      );

  /// The rows of [cacheKey] that are still good at [now]: every result, and a
  /// "not found" younger than [notFoundTtl].
  Future<List<OnlineLyricsRow>> readFresh(
    String cacheKey, {
    required int now,
  }) => _freshSelect(cacheKey, now).get();

  /// Every row of [cacheKey], re-emitted on change; the resolver applies the
  /// TTL itself so an expiry needs no write.
  Stream<List<OnlineLyricsRow>> watch(String cacheKey) =>
      (_db.select(_db.onlineLyrics)
            ..where((t) => t.cacheKey.equals(cacheKey))
            ..orderBy([(t) => OrderingTerm.asc(t.providerId)]))
          .watch();

  /// Like [watch], but built on the table-update signal instead of a drift
  /// query stream: a screen whose key changes with a tag edit swaps streams
  /// without leaving a drift stream closing behind it. Emits the rows of
  /// [cacheKey] once on listen and again after every write to the table.
  Stream<List<OnlineLyricsRow>> watchByKey(String cacheKey) {
    final controller = StreamController<List<OnlineLyricsRow>>();
    StreamSubscription<Set<TableUpdate>>? updates;
    var round = 0;
    Future<void> refresh() async {
      final mine = ++round;
      try {
        final rows =
            await (_db.select(_db.onlineLyrics)
                  ..where((t) => t.cacheKey.equals(cacheKey))
                  ..orderBy([(t) => OrderingTerm.asc(t.providerId)]))
                .get();
        // A newer read supersedes this one; a closed stream takes nothing.
        if (mine == round && !controller.isClosed) controller.add(rows);
      } on Object catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller.onListen = () {
      updates = _db
          .tableUpdates(TableUpdateQuery.onTable(_db.onlineLyrics))
          .listen((_) => unawaited(refresh()));
      unawaited(refresh());
    };
    controller.onCancel = () async {
      await updates?.cancel();
      await controller.close();
    };
    return controller.stream;
  }

  /// Drops one source's answer for [cacheKey] (a rejected result).
  Future<void> deleteRow(String cacheKey, String providerId) =>
      (_db.delete(_db.onlineLyrics)..where(
            (t) =>
                t.cacheKey.equals(cacheKey) & t.providerId.equals(providerId),
          ))
          .go();

  /// "Xoá lời đã lưu": drops everything cached for [providerId]; returns how
  /// many rows went.
  Future<int> deleteByProvider(String providerId) => (_db.delete(
    _db.onlineLyrics,
  )..where((t) => t.providerId.equals(providerId))).go();

  /// Rows holding a result and their text size in UTF-8 bytes, per plugin.
  /// "Not found" rows are not counted: they hold no lyrics.
  Future<Map<String, CacheStats>> statsByProvider() async {
    final rows = await _db
        .customSelect(
          'SELECT provider_id, COUNT(*) AS n, '
          'SUM(COALESCE(LENGTH(CAST(synced_text AS BLOB)), 0) '
          '+ COALESCE(LENGTH(CAST(plain_text AS BLOB)), 0)) AS bytes '
          "FROM online_lyrics WHERE status = 'found' GROUP BY provider_id",
          readsFrom: {_db.onlineLyrics},
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('provider_id'): (
          rows: r.read<int>('n'),
          bytes: r.read<int>('bytes'),
        ),
    };
  }

  SimpleSelectStatement<$OnlineLyricsTable, OnlineLyricsRow> _freshSelect(
    String cacheKey,
    int now,
  ) {
    final oldest = now - notFoundTtl.inMilliseconds;
    return _db.select(_db.onlineLyrics)
      ..where(
        (t) =>
            t.cacheKey.equals(cacheKey) &
            (t.status.equals(OnlineLyricsStatus.found) |
                t.fetchedAt.isBiggerThanValue(oldest)),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.providerId)]);
  }
}
