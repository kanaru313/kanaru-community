import 'package:drift/drift.dart';

import '../../foundation/ids/ulid.dart';
import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';

/// Writes listens to `play_log`. The stats triggers keep `play_stats` in
/// step; rows are only inserted and updated here, never replaced.
class PlayLogWriter {
  PlayLogWriter(this._db);

  final DatabaseConnectionUser _db;

  /// Inserts one counted listen and returns its row id.
  Future<int> insertListen({
    required TrackId trackId,
    required int playedAt,
    required int listenedMs,
    required String deviceId,
    PlayContext? context,
    required int now,
  }) async {
    final id = await _db.customInsert(
      'INSERT INTO play_log (uid, track_id, played_at, listened_ms, device_id, '
      'context_kind, context_ref, skipped, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)',
      variables: [
        Variable.withString(newUlid(nowMs: now)),
        Variable.withInt(trackId.value),
        Variable.withInt(playedAt),
        Variable.withInt(listenedMs),
        Variable.withString(deviceId),
        Variable<String>(context?.kind.name),
        Variable<String>(context?.ref),
        Variable.withInt(now),
      ],
    );
    _db.notifyUpdates({const TableUpdate('play_log')});
    return id;
  }

  /// Sets the listened time of the row [id].
  Future<void> updateListened(int id, int listenedMs, int now) async {
    await _db.customUpdate(
      'UPDATE play_log SET listened_ms = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withInt(listenedMs),
        Variable.withInt(now),
        Variable.withInt(id),
      ],
    );
    _db.notifyUpdates({const TableUpdate('play_log', kind: UpdateKind.update)});
  }
}
