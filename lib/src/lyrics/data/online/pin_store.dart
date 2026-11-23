import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../../foundation/ids/stable_uid.dart';
import '../../../media/domain/track_id.dart';
import 'store_result.dart';

/// The kept online copy of a track's lyrics ("Bản đã giữ"), one per track.
class PinStore {
  PinStore(this._db);

  final AppDatabase _db;

  /// Keeps (or replaces) the copy of [track]. A repeated keep keeps the
  /// original `pinned_at` and uid. [StoreResult.notStored] when the track is
  /// gone (insert-select: no row of a deleted track is ever written) or the
  /// data cannot be stored: no text and not [instrumental], or a text over
  /// 1 MiB.
  Future<StoreResult> put(
    TrackId track, {
    required String providerId,
    required String providerName,
    required String remoteId,
    String? syncedText,
    String? plainText,
    bool instrumental = false,
    int? remoteDurationMs,
    required int now,
  }) async {
    final synced = storableText(syncedText);
    final plain = storableText(plainText);
    if (synced == null && plain == null && !instrumental) {
      return StoreResult.notStored;
    }
    if (textTooLarge(synced) || textTooLarge(plain)) {
      return StoreResult.notStored;
    }
    final trackUid =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([_db.tracks.uid])
              ..where(_db.tracks.id.equals(track.value)))
            .map((r) => r.read(_db.tracks.uid))
            .getSingleOrNull();
    if (trackUid == null) return StoreResult.notStored;
    final changed = await _db.customUpdate(
      'INSERT INTO lyrics_pins (track_id, uid, provider_id, provider_name, '
      'remote_id, synced_text, plain_text, instrumental, remote_duration_ms, '
      'pinned_at, updated_at) '
      'SELECT t.id, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? FROM tracks t '
      'WHERE t.id = ? '
      'ON CONFLICT(track_id) DO UPDATE SET '
      'provider_id = excluded.provider_id, '
      'provider_name = excluded.provider_name, '
      'remote_id = excluded.remote_id, '
      'synced_text = excluded.synced_text, '
      'plain_text = excluded.plain_text, '
      'instrumental = excluded.instrumental, '
      'remote_duration_ms = excluded.remote_duration_ms, '
      'updated_at = excluded.updated_at',
      variables: [
        Variable.withString(stableUid('pin', [trackUid])),
        Variable.withString(providerId),
        Variable.withString(providerName),
        Variable.withString(remoteId),
        Variable<String>(synced),
        Variable<String>(plain),
        Variable.withBool(instrumental),
        Variable<int>(remoteDurationMs),
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withInt(track.value),
      ],
      updates: {_db.lyricsPins},
      updateKind: UpdateKind.insert,
    );
    return changed > 0 ? StoreResult.stored : StoreResult.notStored;
  }

  /// Drops the copy of [track]; harmless without one.
  Future<void> clear(TrackId track) => (_db.delete(
    _db.lyricsPins,
  )..where((t) => t.trackId.equals(track.value))).go();

  Future<LyricsPinRow?> read(TrackId track) => _select(track).getSingleOrNull();

  /// The copy of [track], re-emitted on every change; null without one.
  Stream<LyricsPinRow?> watch(TrackId track) =>
      _select(track).watchSingleOrNull();

  SimpleSelectStatement<$LyricsPinsTable, LyricsPinRow> _select(
    TrackId track,
  ) => _db.select(_db.lyricsPins)..where((t) => t.trackId.equals(track.value));
}
