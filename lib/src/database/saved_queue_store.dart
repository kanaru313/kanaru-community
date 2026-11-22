import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'playlist_entry_sql.dart';
import 'tables.dart';

/// Most saved queues kept; saving one more drops the oldest.
const savedQueueLimit = 20;

/// A queue with fewer tracks (after the local filter) is not worth saving.
const savedQueueMinTracks = 2;

/// Neutral `playlists.name` of a saved queue. The UI never shows it: it names
/// a queue from `saved_at`.
const savedQueueName = 'Queue';

/// What [recordSavedQueue] did.
enum SavedQueueOutcome {
  /// Fewer than [savedQueueMinTracks] saveable tracks: nothing written.
  tooShort,

  /// A saved queue already holds these tracks in this order (or in the
  /// user's order, see `userOrderIds`): only its `saved_at` (and context, when
  /// given) moved, its entries stay.
  touched,

  /// A new saved queue was inserted (and the oldest beyond
  /// [savedQueueLimit] dropped).
  saved,
}

/// `saved_at` for a write at [now]: never below the newest saved queue + 1, so
/// a clock that stepped back cannot make the row just written the oldest (and
/// pruned at once), and two writes in one millisecond still order.
const _nextSavedAt =
    'MAX(?, COALESCE((SELECT MAX(saved_at) FROM playlists '
    "WHERE kind = 'queue'), 0) + 1)";

/// Saves [trackIds] (play order, repeats kept) as the newest saved queue, in
/// one transaction:
///
/// 1. keeps ids of local tracks that are `present` or `missing` (a `hidden`
///    track is dropped, so is an id that no longer exists: the orphan GC may
///    have removed it), in order;
/// 2. fewer than [savedQueueMinTracks] left: [SavedQueueOutcome.tooShort];
/// 3. some saved queue (any of the at most [savedQueueLimit]) holds the same
///    playable (`present`) track ids in the same order, or in the same order
///    as [userOrderIds] (filtered like [trackIds]); `missing` tracks are
///    ignored on both sides, so a queue replayed without them is still found:
///    the newest such row is moved to the front
///    instead and keeps its entries ([SavedQueueOutcome.touched]). With
///    shuffle on, [trackIds] is the play order and [userOrderIds] the order
///    before shuffling, so replaying a saved queue shuffled finds it again;
/// 4. otherwise inserts a row plus its entries and prunes to
///    [savedQueueLimit] ([SavedQueueOutcome.saved]).
///
/// Takes plain types only: the caller turns its play context into
/// [contextKind] / [contextRef] / [contextLabel]. The comparison and the
/// insert run in SQL over one JSON array, so a 10 000 track queue never
/// travels back and forth. Watchers of `playlists` and `playlist_entries`
/// are notified only when something was written.
Future<SavedQueueOutcome> recordSavedQueue(
  AppDatabase db, {
  required List<int> trackIds,
  List<int>? userOrderIds,
  String? contextKind,
  String? contextRef,
  String? contextLabel,
  required int now,
}) {
  if (trackIds.length < savedQueueMinTracks) {
    return Future.value(SavedQueueOutcome.tooShort);
  }
  return db.transaction(() async {
    final kept = await _saveable(db, trackIds);
    if (kept.length < savedQueueMinTracks) return SavedQueueOutcome.tooShort;
    final keptIds = [for (final k in kept) k.id];

    // The user order is a permutation of the same queue: when the filter
    // leaves a different number of ids it is not, so it is ignored.
    var userKept = userOrderIds == null
        ? null
        : await _saveable(db, userOrderIds);
    if (userKept != null && userKept.length != kept.length) userKept = null;
    // Matching looks at playable tracks only, on both sides, so a queue whose
    // track went missing or hidden since it was saved (or that is replayed
    // without it) is still recognised. With fewer than two playable ids left,
    // the full saveable ids are compared against every stored entry instead.
    final presentIds = [
      for (final k in kept)
        if (k.present) k.id,
    ];
    final playableOnly = presentIds.length >= savedQueueMinTracks;
    final match = await _matchingSavedQueueId(
      db,
      playableOnly ? presentIds : keptIds,
      userKept == null
          ? null
          : [
              for (final k in userKept)
                if (!playableOnly || k.present) k.id,
            ],
      playableOnly: playableOnly,
    );
    if (match != null) {
      await _moveToFront(
        db,
        'WHERE id = ?',
        Variable.withInt(match),
        now,
        contextKind,
        contextRef,
        contextLabel,
      );
      return SavedQueueOutcome.touched;
    }

    final savedAt =
        (await db
                .customSelect(
                  'SELECT $_nextSavedAt AS t',
                  variables: [Variable.withInt(now)],
                )
                .getSingle())
            .read<int>('t');
    final id = await insertPlaylistRow(
      db,
      name: savedQueueName,
      now: now,
      kind: PlaylistKind.queue,
      savedAt: savedAt,
      contextKind: contextKind,
      contextRef: contextRef,
      contextLabel: contextLabel,
    );
    await appendEntries(db, id, keptIds, now);
    await _pruneSavedQueues(db);
    return SavedQueueOutcome.saved;
  });
}

/// Moves the saved queue [uid] to the front (`saved_at` above every other),
/// the same way a repeated save does. Call just before playing it, so that
/// saving the queue it replaces cannot prune it. Returns false when [uid] is
/// not a saved queue.
Future<bool> touchSavedQueue(AppDatabase db, String uid, {required int now}) =>
    _moveToFront(
      db,
      "WHERE uid = ? AND kind = 'queue'",
      Variable.withString(uid),
      now,
      null,
      null,
      null,
    ).then((n) => n > 0);

/// Ids of [trackIds] that are local and `present` / `missing`, in order,
/// repeats kept, with whether each is `present`. Unknown ids drop out through
/// the join.
Future<List<({int id, bool present})>> _saveable(
  AppDatabase db,
  List<int> trackIds,
) async {
  final rows = await db
      .customSelect(
        'SELECT t.id AS id, t.status AS status FROM json_each(?) j '
        'JOIN tracks t ON t.id = j.value '
        'JOIN sources s ON s.id = t.source_id '
        "WHERE s.kind = 'local' AND t.status IN ('present', 'missing') "
        'ORDER BY j.key',
        variables: [jsonList(trackIds)],
      )
      .get();
  return [
    for (final r in rows)
      (id: r.read<int>('id'), present: r.read<String>('status') == 'present'),
  ];
}

/// Newest saved queue whose `present` entries, in `sort_key, uid` order, equal
/// [kept] or [userKept] (null: not compared), or null. [kept] and [userKept]
/// hold playable ids only when [playableOnly], else every saveable id and
/// every stored entry; fewer than [savedQueueMinTracks] never match.
/// Candidates are every queue row (at most [savedQueueLimit]), prefiltered by
/// playable entry count; the order is compared as one JSON array in order
/// against the JSON of the ids (both compact, so equal lists give equal text).
/// One pass: a position join against `json_each` is quadratic (14 s for 10 000
/// tracks).
Future<int?> _matchingSavedQueueId(
  AppDatabase db,
  List<int> kept,
  List<int>? userKept, {
  required bool playableOnly,
}) async {
  if (kept.length < savedQueueMinTracks) return null;
  final shapes = [kept, ?userKept];
  final texts = {for (final s in shapes) jsonEncode(s)}.toList();
  String marks(int n) => List.filled(n, '?').join(', ');
  final live =
      'FROM playlist_entries e JOIN tracks t ON t.id = e.track_id '
      'WHERE e.playlist_id = p.id AND e.deleted_at IS NULL'
      "${playableOnly ? " AND t.status = 'present'" : ''}";
  final rows = await db
      .customSelect(
        'SELECT x.id AS id FROM ('
        'SELECT p.id AS id, p.saved_at AS saved_at, '
        '(SELECT json_group_array(e.track_id ORDER BY e.sort_key, e.uid) '
        '$live) AS ids '
        "FROM playlists p WHERE p.kind = 'queue' AND "
        '(SELECT COUNT(*) $live) = ?'
        ') x WHERE x.ids IN (${marks(texts.length)}) '
        'ORDER BY x.saved_at DESC, x.id DESC LIMIT 1',
        variables: [
          Variable.withInt(kept.length),
          for (final t in texts) Variable.withString(t),
        ],
      )
      .get();
  return rows.isEmpty ? null : rows.single.read<int>('id');
}

/// Runs the move and notifies `playlists` only when a row changed.
Future<int> _moveToFront(
  AppDatabase db,
  String where,
  Variable key,
  int now,
  String? contextKind,
  String? contextRef,
  String? contextLabel,
) {
  final withContext = contextKind != null;
  return db
      .customUpdate(
        'UPDATE playlists SET saved_at = $_nextSavedAt'
        '${withContext ? ', context_kind = ?, context_ref = ?, context_label = ?' : ''} '
        '$where',
        variables: [
          Variable.withInt(now),
          if (withContext) ...[
            Variable.withString(contextKind),
            Variable<String>(contextRef),
            Variable<String>(contextLabel),
          ],
          key,
        ],
        updates: const {},
      )
      .then((n) {
        if (n > 0) {
          db.notifyUpdates({
            TableUpdate.onTable(db.playlists, kind: UpdateKind.update),
          });
        }
        return n;
      });
}

/// Deletes every saved queue beyond the newest [savedQueueLimit]; entries go
/// with them (cascade).
Future<void> _pruneSavedQueues(AppDatabase db) => db.customUpdate(
  "DELETE FROM playlists WHERE kind = 'queue' AND id NOT IN "
  "(SELECT id FROM playlists WHERE kind = 'queue' "
  'ORDER BY saved_at DESC, id DESC LIMIT $savedQueueLimit)',
  updates: {db.playlists, db.playlistEntries, db.customCovers},
  updateKind: UpdateKind.delete,
);
