import 'package:drift/drift.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

/// Writes one track the way the scanner does: through `upsertTrackSnapshot`
/// and `replaceTrackArtists`, with every stored search, sort and key column
/// derived by the key functions. Returns the track id.
///
/// [artists] are the track artists in tag order; [artist] (the raw tag)
/// defaults to them joined. [status] other than present is applied after the
/// upsert (the upsert itself always yields present).
Future<int> addLibraryTrack(
  AppDatabase db, {
  required int source,
  required String locator,
  String? title,
  List<String> artists = const [],
  String? artist,
  String? album,
  String? albumArtist,
  String? albumDisplayArtist,
  String? genre,
  String? language,
  bool languageDetected = false,
  int? year,
  int? trackNo,
  int? discNo,
  int? durationMs,
  String? coverKey,
  int addedAt = 1000,
  String status = TrackStatus.present,
}) async {
  final name = title ?? locator.split('/').last;
  final artistTag = artist ?? (artists.isEmpty ? null : artists.join(', '));
  final albumKey = albumKeyFor(
    album: album,
    albumArtist: albumArtist,
    artists: artists,
  );
  final id = await upsertTrackSnapshot(
    db,
    db.tracks,
    TracksCompanion.insert(
      uid: trackUid('source-$source', locator),
      sourceId: source,
      locator: locator,
      relPath: locator,
      title: name,
      titleSort: Value(sortForm(name)),
      titleSearch: Value(searchForm(name)),
      artist: Value(artistTag),
      artistSearch: Value(artistTag == null ? null : searchForm(artistTag)),
      album: Value(album),
      albumSearch: Value(album == null ? null : searchForm(album)),
      albumSort: Value(album == null ? null : sortForm(album)),
      albumArtist: Value(albumArtist),
      albumDisplayArtist: Value(albumDisplayArtist),
      albumArtistKey: Value(albumKey?.artistKey),
      albumTitleKey: Value(albumKey?.titleKey),
      genre: Value(genre),
      genreKey: Value(genre == null ? null : groupKey(genre)),
      genreSearch: Value(genre == null ? null : searchForm(genre)),
      language: Value(languageKey(language)),
      languageDetected: Value(languageDetected ? 1 : 0),
      year: Value(year),
      trackNo: Value(trackNo),
      discNo: Value(discNo),
      durationMs: Value(durationMs),
      coverKey: Value(coverKey),
      addedAt: addedAt,
      updatedAt: addedAt,
    ),
  );
  await replaceTrackArtists(db, id, [
    for (final a in artists) (key: groupKey(a), name: a),
  ]);
  if (status != TrackStatus.present) {
    await db.customUpdate(
      'UPDATE tracks SET status = ?, missing_since = ? WHERE id = ?',
      variables: [
        Variable.withString(status),
        Variable<int>(status == TrackStatus.missing ? 1 : null),
        Variable.withInt(id),
      ],
      updates: {db.tracks},
    );
  }
  return id;
}

int _playSeq = 0;

/// Adds [count] plays to of [trackId] through `play_log`, so the
/// stats triggers fill `play_stats` like a real listener.
Future<void> addPlays(AppDatabase db, int trackId, int count) async {
  for (var i = 0; i < count; i++) {
    await db.customInsert(
      'INSERT INTO play_log (uid, track_id, played_at, device_id, skipped, '
      'updated_at) VALUES (?, ?, ?, ?, 0, ?)',
      variables: [
        Variable.withString('play-${_playSeq++}'),
        Variable.withInt(trackId),
        Variable.withInt(1000 + i),
        Variable.withString('device-1'),
        Variable.withInt(1000 + i),
      ],
      updates: {db.playLog},
    );
  }
}
