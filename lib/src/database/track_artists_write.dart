import 'package:drift/drift.dart';

const _chunk = 500;

/// Replaces the artist rows of [trackId] with [artists], in order, in one
/// transaction. A repeated key (a tag listing an artist twice, or two
/// spellings with one group key) keeps its first occurrence; positions are
/// then numbered from 0 without gaps. Throws [ArgumentError] for an empty
/// key (the database would store a group nobody can open). Notifies
/// `track_artists`.
Future<void> replaceTrackArtists(
  DatabaseConnectionUser db,
  int trackId,
  List<({String key, String name})> artists,
) async {
  final seen = <String>{};
  final kept = <({String key, String name})>[];
  for (final a in artists) {
    if (a.key.isEmpty) {
      throw ArgumentError.value(a.name, 'artists', 'has an empty key');
    }
    if (seen.add(a.key)) kept.add(a);
  }
  await db.transaction(() async {
    await db.customUpdate(
      'DELETE FROM track_artists WHERE track_id = ?',
      variables: [Variable.withInt(trackId)],
    );
    for (var i = 0; i < kept.length; i += _chunk) {
      final end = i + _chunk > kept.length ? kept.length : i + _chunk;
      await db.customInsert(
        'INSERT INTO track_artists (track_id, artist_key, artist_name, position) '
        'VALUES ${List.filled(end - i, '(?, ?, ?, ?)').join(', ')}',
        variables: [
          for (var j = i; j < end; j++) ...[
            Variable.withInt(trackId),
            Variable.withString(kept[j].key),
            Variable.withString(kept[j].name),
            Variable.withInt(j),
          ],
        ],
      );
    }
  });
  db.notifyUpdates({const TableUpdate('track_artists')});
}
