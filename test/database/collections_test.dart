import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/row_uids.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/database/tombstone_upsert.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int sourceId;
  late int trackA;
  setUp(() async {
    db = openTestDb();
    sourceId = await addSource(db);
    trackA = await addTrack(db, sourceId, locator: 'a.flac');
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  test('deleting a playlist deletes its entries', () async {
    final pl = await addPlaylist(db);
    await addEntry(db, pl, trackA, sortKey: 'a0');
    await (db.delete(db.playlists)..where((p) => p.id.equals(pl))).go();
    expect(await count('playlist_entries'), 0);
  });

  test('a revived Favorites playlist gets no old entries back', () async {
    PlaylistsCompanion fav(int now) => PlaylistsCompanion.insert(
        uid: favoritesPlaylistUid,
        name: 'Favorites',
        kind: const Value(PlaylistKind.favorites),
        createdAt: now,
        updatedAt: now);
    final first = await insertOrRevive(db, db.playlists, fav(1), now: 1);
    await addEntry(db, first.id, trackA, sortKey: 'a0');
    await db.customStatement('UPDATE playlists SET deleted_at = 5');
    await db.customStatement('UPDATE playlist_entries SET deleted_at = 5');
    final again = await insertOrRevive(db, db.playlists, fav(9), now: 9);
    expect(again.id, first.id);
    final old = await db.select(db.playlistEntries).getSingle();
    expect(old.deletedAt, 5);
    final live = await (db.select(db.playlistEntries)
          ..where((e) => e.playlistId.equals(again.id) & e.deletedAt.isNull()))
        .get();
    expect(live, isEmpty);
  });

  test('a favorite entry revives with a new sort key', () async {
    final pl = await addPlaylist(db,
        kind: PlaylistKind.favorites, uid: favoritesPlaylistUid);
    final uid = favoriteEntryUid(favoritesPlaylistUid, 'trk');
    PlaylistEntriesCompanion entry(String key, int at) => PlaylistEntriesCompanion.insert(
        uid: uid, playlistId: pl, trackId: trackA, sortKey: key, addedAt: at, updatedAt: at);
    final first = await insertOrRevive(db, db.playlistEntries, entry('a0', 1), now: 1);
    await db.customStatement('UPDATE playlist_entries SET deleted_at = 3');
    final again = await insertOrRevive(db, db.playlistEntries, entry('a5', 8),
        now: 8, reviveColumns: {'sort_key', 'added_at'});
    expect(again.id, first.id);
    expect(again.sortKey, 'a5');
    expect(again.addedAt, 8);
    expect(again.deletedAt, isNull);
  });

  test('same track twice in a normal playlist is allowed', () async {
    final pl = await addPlaylist(db);
    await addEntry(db, pl, trackA, sortKey: 'a0');
    await addEntry(db, pl, trackA, sortKey: 'a1');
    expect(await count('playlist_entries'), 2);
  });

  test('a second live Favorites playlist is rejected', () async {
    await addPlaylist(db, kind: PlaylistKind.favorites, uid: favoritesPlaylistUid);
    await expectLater(
        addPlaylist(db, kind: PlaylistKind.favorites, uid: 'other'),
        throwsConstraint('playlists.kind'));
  });

  test('a tombstoned mood does not block a new mood of the same name', () async {
    final old = await addPlaylist(db, kind: PlaylistKind.mood, nameKey: 'chill');
    await db.customStatement('UPDATE playlists SET deleted_at = 5 WHERE id = $old');
    await addPlaylist(db, kind: PlaylistKind.mood, nameKey: 'chill');
    await expectLater(
        addPlaylist(db, kind: PlaylistKind.mood, nameKey: 'chill'),
        throwsConstraint('playlists.name_key'));
  });

  test('renaming a mood keeps its uid and frees the old name', () async {
    final id = await addPlaylist(db,
        name: 'Chill', kind: PlaylistKind.mood, nameKey: 'chill', uid: 'u-chill');
    await (db.update(db.playlists)..where((p) => p.id.equals(id)))
        .write(const PlaylistsCompanion(name: Value('Calm'), nameKey: Value('calm')));
    final fresh = await addPlaylist(db,
        name: 'Chill', kind: PlaylistKind.mood, nameKey: 'chill');
    final renamed = await (db.select(db.playlists)..where((p) => p.id.equals(id))).getSingle();
    expect(renamed.uid, 'u-chill');
    expect(fresh, isNot(id));
    final uids = (await db.select(db.playlists).get()).map((p) => p.uid).toSet();
    expect(uids, hasLength(2));
  });

  test('importing the same file twice is rejected', () async {
    Future<int> import(String uid) => db.into(db.playlists).insert(
        PlaylistsCompanion.insert(
            uid: uid,
            name: 'Imported',
            originSourceId: Value(sourceId),
            originLocator: const Value('x.m3u'),
            createdAt: 1,
            updatedAt: 1));
    await import('p-1');
    await expectLater(import('p-2'),
        throwsConstraint('playlists.origin_source_id, playlists.origin_locator'));
  });

  test('deleting a track that is in a playlist fails', () async {
    final pl = await addPlaylist(db);
    await addEntry(db, pl, trackA, sortKey: 'a0');
    expect(
      (db.delete(db.tracks)..where((t) => t.id.equals(trackA))).go(),
      throwsConstraint('FOREIGN KEY constraint failed'),
    );
  });

  test('deleting a source that has saved items fails', () async {
    await db.into(db.savedItems).insert(SavedItemsCompanion.insert(
        uid: 's1',
        kind: SavedItemKind.album,
        sourceId: sourceId,
        remoteId: 'r',
        snapshotJson: '{}',
        savedAt: 1,
        updatedAt: 1));
    expect(
      (db.delete(db.sources)..where((s) => s.id.equals(sourceId))).go(),
      throwsConstraint('FOREIGN KEY constraint failed'),
    );
  });
}
