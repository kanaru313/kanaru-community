import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../../media/domain/track_id.dart';
import 'store_result.dart';

/// What the user refused for one track, ready for the match gate.
class RejectedSet {
  const RejectedSet({this.refs = const {}, this.hashes = const {}});

  factory RejectedSet.of(Iterable<LyricsRejectRow> rows) => RejectedSet(
    refs: {
      for (final r in rows) (providerId: r.providerId, remoteId: r.remoteId),
    },
    hashes: {
      for (final r in rows)
        if (r.contentHash != null) r.contentHash!,
    },
  );

  final Set<({String providerId, String remoteId})> refs;
  final Set<String> hashes;
}

/// "Không đúng bài": results the user refused for a track.
class RejectStore {
  RejectStore(this._db);

  final AppDatabase _db;

  /// Remembers that [remoteId] of [providerId] is not the lyrics of [track].
  /// A repeat refreshes the time and keeps an earlier [contentHash] when the
  /// new one is null. [StoreResult.notStored] when the track is gone.
  Future<StoreResult> add(
    TrackId track, {
    required String providerId,
    required String remoteId,
    String? contentHash,
    required int now,
  }) async {
    final changed = await _db.customUpdate(
      'INSERT INTO lyrics_rejects (track_id, provider_id, remote_id, '
      'content_hash, rejected_at) '
      'SELECT t.id, ?, ?, ?, ? FROM tracks t WHERE t.id = ? '
      'ON CONFLICT(track_id, provider_id, remote_id) DO UPDATE SET '
      'content_hash = COALESCE(excluded.content_hash, content_hash), '
      'rejected_at = excluded.rejected_at',
      variables: [
        Variable.withString(providerId),
        Variable.withString(remoteId),
        Variable<String>(contentHash),
        Variable.withInt(now),
        Variable.withInt(track.value),
      ],
      updates: {_db.lyricsRejects},
      updateKind: UpdateKind.insert,
    );
    return changed > 0 ? StoreResult.stored : StoreResult.notStored;
  }

  Future<List<LyricsRejectRow>> list(TrackId track) => _select(track).get();

  Stream<List<LyricsRejectRow>> watch(TrackId track) => _select(track).watch();

  SimpleSelectStatement<$LyricsRejectsTable, LyricsRejectRow> _select(
    TrackId track,
  ) => _db.select(_db.lyricsRejects)
    ..where((t) => t.trackId.equals(track.value))
    ..orderBy([(t) => OrderingTerm.desc(t.rejectedAt)]);
}
