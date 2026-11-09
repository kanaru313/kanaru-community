import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/row_uids.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/database/tombstone_upsert.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  Future<void> tombstone(String table, String uid) => db.customStatement(
      'UPDATE $table SET deleted_at = 500 WHERE uid = ?', [uid]);

  test('revives a remote source with the same id', () async {
    final uid = sourceUidForRemote('webdav', 'me', 'https://dav.example.com');
    SourcesCompanion src(String name, int now) => SourcesCompanion.insert(
        uid: uid, kind: SourceKind.webdav, name: name, addedAt: now, updatedAt: now);
    final first = await insertOrRevive(db, db.sources, src('Old', 100), now: 100);
    await tombstone('sources', uid);
    final again = await insertOrRevive(db, db.sources, src('New', 900),
        now: 900, reviveColumns: {'name'});
    expect(again.id, first.id);
    expect(again.deletedAt, isNull);
    expect(again.updatedAt, 900);
    expect(again.name, 'New');
    expect(again.addedAt, 100);
    expect(await db.select(db.sources).get(), hasLength(1));
  });

  test('revives an excluded folder', () async {
    final sourceId = await addSource(db);
    final uid = excludedFolderUid('src', 'Album/Live');
    ExcludedFoldersCompanion folder(String shown) => ExcludedFoldersCompanion.insert(
        uid: uid,
        sourceId: sourceId,
        folderKey: 'Album/Live',
        displayPath: shown,
        addedAt: 1,
        updatedAt: 1);
    final first = await insertOrRevive(db, db.excludedFolders, folder('a'), now: 1);
    await tombstone('excluded_folders', uid);
    final again = await insertOrRevive(db, db.excludedFolders, folder('b'),
        now: 2, reviveColumns: {'display_path'});
    expect(again.id, first.id);
    expect(again.deletedAt, isNull);
    expect(again.displayPath, 'b');
  });

  test('revives a saved item', () async {
    final sourceId = await addSource(db, kind: SourceKind.subsonic);
    final uid = savedItemUid('src', SavedItemKind.album, 'alb-1');
    SavedItemsCompanion item(String json) => SavedItemsCompanion.insert(
        uid: uid,
        kind: SavedItemKind.album,
        sourceId: sourceId,
        remoteId: 'alb-1',
        snapshotJson: json,
        savedAt: 1,
        updatedAt: 1);
    final first = await insertOrRevive(db, db.savedItems, item('{}'), now: 1);
    await tombstone('saved_items', uid);
    final again = await insertOrRevive(db, db.savedItems, item('{"v":2}'),
        now: 7, reviveColumns: {'snapshot_json'});
    expect(again.id, first.id);
    expect(again.deletedAt, isNull);
    expect(again.updatedAt, 7);
    expect(again.snapshotJson, '{"v":2}');
  });

  test('revives the Favorites playlist', () async {
    PlaylistsCompanion fav(int now) => PlaylistsCompanion.insert(
        uid: favoritesPlaylistUid,
        name: 'Favorites',
        kind: const Value(PlaylistKind.favorites),
        createdAt: now,
        updatedAt: now);
    final first = await insertOrRevive(db, db.playlists, fav(1), now: 1);
    await tombstone('playlists', favoritesPlaylistUid);
    final again = await insertOrRevive(db, db.playlists, fav(9), now: 9);
    expect(again.id, first.id);
    expect(again.deletedAt, isNull);
    expect(again.updatedAt, 9);
  });

  test('a live row only gets a new updated_at', () async {
    final first = await insertOrRevive(
        db,
        db.playlists,
        PlaylistsCompanion.insert(
            uid: 'p', name: 'Keep', createdAt: 1, updatedAt: 1),
        now: 1);
    final again = await insertOrRevive(
        db,
        db.playlists,
        PlaylistsCompanion.insert(
            uid: 'p', name: 'Other', createdAt: 5, updatedAt: 5),
        now: 5);
    expect(again.id, first.id);
    expect(again.name, 'Keep');
    expect(again.createdAt, 1);
    expect(again.updatedAt, 5);
  });

  test('a revive touches no other row', () async {
    final a = await addSource(db, uid: 'a');
    await addSource(db, uid: 'b');
    await tombstone('sources', 'a');
    await tombstone('sources', 'b');
    await insertOrRevive(
        db,
        db.sources,
        SourcesCompanion.insert(
            uid: 'a', kind: 'local', name: 'x', addedAt: 1, updatedAt: 1),
        now: 3);
    final rows = await db.select(db.sources).get();
    expect(rows.singleWhere((r) => r.id == a).deletedAt, isNull);
    expect(rows.singleWhere((r) => r.uid == 'b').deletedAt, 500);
  });

  test('re-emits a watching stream', () async {
    final events = <int>[];
    final sub = db.select(db.playlists).watch().listen((r) => events.add(r.length));
    await pumpEventQueue();
    await insertOrRevive(
        db,
        db.playlists,
        PlaylistsCompanion.insert(
            uid: 'p', name: 'A', createdAt: 1, updatedAt: 1),
        now: 1);
    await pumpEventQueue();
    await sub.cancel();
    expect(events, [0, 1]);
  });

  test('a live row keeps its revive columns, a tombstone takes them', () async {
    final pl = await addPlaylist(db);
    final t = await addTrack(db, await addSource(db), locator: 'a.flac');
    PlaylistEntriesCompanion entry(String key, int at) =>
        PlaylistEntriesCompanion.insert(
            uid: 'fav-e', playlistId: pl, trackId: t, sortKey: key, addedAt: at, updatedAt: at);
    const cols = {'sort_key', 'added_at'};
    await insertOrRevive(db, db.playlistEntries, entry('a0', 1), now: 1);
    final live = await insertOrRevive(db, db.playlistEntries, entry('a9', 5),
        now: 5, reviveColumns: cols);
    expect(live.sortKey, 'a0');
    expect(live.addedAt, 1);
    expect(live.updatedAt, 5);
    await db.customStatement('UPDATE playlist_entries SET deleted_at = 6');
    final revived = await insertOrRevive(db, db.playlistEntries, entry('a9', 8),
        now: 8, reviveColumns: cols);
    expect(revived.id, live.id);
    expect(revived.sortKey, 'a9');
    expect(revived.addedAt, 8);
    expect(revived.deletedAt, isNull);
  });

  test('rejects a table without uid', () async {
    await expectLater(
      insertOrRevive(db, db.sourceMounts,
          SourceMountsCompanion.insert(addedAt: 1), now: 1),
      throwsArgumentError,
    );
  });

  test('rejects bad revive columns', () async {
    final row = PlaylistsCompanion.insert(
        uid: 'p', name: 'A', createdAt: 1, updatedAt: 1);
    for (final key in [
      'nope', 'id', 'uid', 'deleted_at', 'updated_at', 'description'
    ]) {
      await expectLater(
        insertOrRevive(db, db.playlists, row, now: 1, reviveColumns: {key}),
        throwsArgumentError,
        reason: key,
      );
    }
  });
}
