import 'package:drift/drift.dart' show Variable;

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/online_lyrics_ref.dart';
import '../../domain/online/online_text.dart';
import '../lyrics_choice_store.dart';
import '../lyrics_parse_jobs.dart';
import 'online_cache_store.dart';
import 'pin_store.dart';
import 'reject_store.dart';
import 'store_result.dart';

/// What the user does with online lyrics. Every write is database-only (the
/// text was fetched before; no network inside a transaction). The lookup
/// reacts to the rows: a deleted cache row makes the playing track look the
/// song up again.
class OnlineLyricsCommands {
  OnlineLyricsCommands({
    required this.db,
    required this.pins,
    required this.cache,
    required this.rejects,
    required this.now,
    required this.shownOnline,
    required this.cacheKeyOf,
    required this.onRejected,
    this.run = runInIsolate,
  });

  final AppDatabase db;
  final PinStore pins;
  final OnlineCacheStore cache;
  final RejectStore rejects;

  /// Milliseconds since the epoch.
  final int Function() now;

  /// The online source of what [TrackId] shows now, or null.
  final OnlineLyricsRef? Function(TrackId) shownOnline;

  /// The online cache key of the track, or null when it has none.
  final String? Function(TrackId) cacheKeyOf;

  /// Called with the cache key once a result was refused.
  final void Function(String cacheKey) onRejected;
  final IsolateRunner run;

  /// "Dùng bản này": keeps [result] (its lyrics already fetched) for [track]
  /// and drops a `file` choice, so the kept copy shows.
  Future<StoreResult> keep(
    TrackId track,
    LyricsCandidate result, {
    required String providerName,
  }) async {
    final body = result.body;
    if (body == null || !body.isUsable) return StoreResult.notStored;
    return db.transaction(() async {
      final stored = await pins.put(
        track,
        providerId: result.providerId,
        providerName: providerName,
        remoteId: result.remoteId,
        syncedText: body.syncedLrc,
        plainText: body.plain,
        instrumental: body.instrumental,
        remoteDurationMs: result.duration?.inMilliseconds,
        now: now(),
      );
      if (stored == StoreResult.stored) await _dropFileChoice(track);
      return stored;
    });
  }

  /// "Giữ bản này": keeps the automatically found copy that [track] shows.
  Future<StoreResult> keepAuto(TrackId track) async {
    final shown = shownOnline(track);
    final key = cacheKeyOf(track);
    if (shown == null || key == null || shown.how != OnlineHow.auto) {
      return StoreResult.notStored;
    }
    return db.transaction(() async {
      final row = await _cacheRow(key, shown.providerId);
      if (row == null || row.remoteId == null) return StoreResult.notStored;
      final stored = await pins.put(
        track,
        providerId: shown.providerId,
        providerName: shown.providerName,
        remoteId: row.remoteId!,
        syncedText: row.syncedText,
        plainText: row.plainText,
        instrumental: row.instrumental,
        remoteDurationMs: row.remoteDurationMs,
        now: now(),
      );
      if (stored == StoreResult.stored) await _dropFileChoice(track);
      return stored;
    });
  }

  /// "Không đúng bài": refuses the online copy [track] shows (by id and by
  /// text), drops it (the cache row, and the kept copy when that is the one
  /// shown) and lets the lookup go on with the next candidate.
  Future<void> reject(TrackId track) async {
    final shown = shownOnline(track);
    final key = cacheKeyOf(track);
    if (shown == null || key == null) return;
    // The text is read first so the hash is computed off the transaction.
    final String? syncedText;
    final String? plainText;
    if (shown.how == OnlineHow.kept) {
      final pin = await pins.read(track);
      syncedText = pin?.syncedText;
      plainText = pin?.plainText;
    } else {
      final row = await _cacheRow(key, shown.providerId);
      syncedText = row?.syncedText;
      plainText = row?.plainText;
    }
    final hash = await _hashOf(syncedText, plainText);
    await db.transaction(() async {
      await rejects.add(
        track,
        providerId: shown.providerId,
        remoteId: shown.remoteId,
        contentHash: hash,
        now: now(),
      );
      final cached = await _cacheRow(key, shown.providerId);
      if (cached != null && cached.remoteId == shown.remoteId) {
        await cache.deleteRow(key, shown.providerId);
      }
      if (shown.how == OnlineHow.kept) await pins.clear(track);
    });
    onRejected(key);
  }

  /// "Lời trong file": the file's lyrics win over a kept online copy.
  Future<void> useFile(TrackId track) => setLyricsFile(db, track, now: now());

  /// Back to automatic selection.
  Future<void> useOnline(TrackId track) => clearLyricsChoice(db, track);

  Future<void> _dropFileChoice(TrackId track) async {
    final row = await db
        .customSelect(
          'SELECT mode FROM track_lyrics_choices WHERE track_id = ?',
          variables: [Variable.withInt(track.value)],
        )
        .getSingleOrNull();
    if (row?.read<String>('mode') == lyricsModeFile) {
      await clearLyricsChoice(db, track);
    }
  }

  Future<OnlineLyricsRow?> _cacheRow(String key, String providerId) async {
    final rows = await cache.readFresh(key, now: now());
    for (final row in rows) {
      if (row.providerId == providerId) return row;
    }
    return null;
  }

  Future<String?> _hashOf(String? synced, String? plain) async {
    final size = (synced?.length ?? 0) + (plain?.length ?? 0);
    String? compute() {
      final text = parseOnlineText(synced: synced, plain: plain);
      return text == null ? null : lyricsContentHash(text.lines);
    }

    return size > lyricsIsolateThreshold ? run(compute) : compute();
  }
}
