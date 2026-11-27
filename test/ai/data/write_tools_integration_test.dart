import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/tool_env_impl.dart';
import 'package:kanaru/src/ai/data/tool_env_write.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/ai/domain/tools/write_tools.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/library_overview_query.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/data/search/track_lookup_query.dart';
import 'package:kanaru/src/library/data/search/track_search_query.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';

import '../../database/support/test_db.dart';
import '../../library/search/search_test_support.dart';
import '../../playback/support/controller_harness.dart';
import '../domain/tools/fake_tool_env.dart';

void main() {
  final registry = AiToolRegistry([writeToolProvider]);

  group('playlists on a real store', () {
    late AppDatabase db;
    late int source;
    late PlaylistRepository store;
    late ToolEnv env;

    setUp(() async {
      db = openTestDb();
      addTearDown(db.close);
      source = await addSource(db, uid: 'src-write');
      store = PlaylistRepository(db);
      final lookup = TrackLookupQuery(db);
      env = ToolEnv(
        library: LibraryPortImpl(
          trackSearch: TrackSearchQuery(db),
          trackLookup: lookup,
          trackInfo: (id) => watchTrackInfo(db, id).first,
          overviewReader: LibraryOverviewQuery(db),
        ),
        playback: FakePlayback(),
        lyrics: FakeLyrics(const LyricsAbsent('none')),
        history: FakeHistory(),
        playlists: PlaylistsPortImpl(store: store, lookup: lookup),
        playbackWrite: FakePlaybackWrite(),
        playlistsWrite: PlaylistsWritePortImpl(store: store),
      );
    });

    Future<int> track(String title, {String status = 'present'}) =>
        addSearchTrack(
          db,
          source,
          locator: '$title.flac',
          title: title,
          status: status,
        );

    test('user removes 2 of 5 entries before Allow -> done lists 3', () async {
      final ids = [for (var i = 0; i < 5; i++) await track('Song $i')];
      final uid = await store.createPlaylist(
        name: 'Five',
        tracks: [for (final id in ids) TrackId(id)],
      );
      final detail = (await store.loadPlaylist(uid))!;
      final playlistId = detail.summary.id;
      final entryIds = [for (final e in detail.entries) e.id];
      final args = {'playlistId': playlistId, 'entryIds': entryIds};
      final tool = registry.byName('remove_from_playlist')!;

      final card = await tool.describe(args, env);
      expect(card!.tracks, hasLength(5));

      // The user removes two entries while the card waits.
      await store.removeEntriesNow(uid, [
        detail.entries[0].uid,
        detail.entries[1].uid,
      ]);

      final o = await tool.run(args, env);
      expect(o.isError, isFalse, reason: o.text);
      expect(o.done!.removed.map((t) => t.trackId), ids.sublist(2));
      final r = jsonDecode(o.text) as Map<String, Object?>;
      expect(r['removed'], 3);
      expect(r['notInPlaylist'], entryIds.sublist(0, 2));
      expect((await store.loadPlaylist(uid))!.entries, isEmpty);
    });

    test('remove_from_playlist on a saved queue id fails', () async {
      final t = await track('Queued');
      await addPlaylist(db, kind: 'queue', uid: 'q1', name: 'Saved queue');
      final saved = (await db.select(db.playlists).get()).single;
      final o = await registry.byName('remove_from_playlist')!.run({
        'playlistId': saved.id,
        'entryIds': [t],
      }, env);
      expect(o.isError, isTrue);
      expect(o.text, contains('not found'));
    });

    test('add to Favorites before any favorite exists', () async {
      final a = await track('Fav A');
      final b = await track('Fav B');
      final hidden = await track('Fav hidden', status: 'hidden');
      final o = await registry.byName('add_to_playlist')!.run({
        'playlistId': favoritesPlaylistId,
        'trackIds': [a, b, hidden],
      }, env);
      expect(o.isError, isFalse, reason: o.text);
      expect(o.done!.added.map((t) => t.trackId), [a, b]);
      expect(o.done!.absent, [hidden]);
      final favorites = (await store.loadPlaylist(
        (await store.resolvePlaylistIds([favoritesPlaylistId])).values.single,
      ))!;
      expect(favorites.entries.map((e) => e.info.id.value), [a, b]);

      // A second call finds both already there.
      final again = await registry.byName('add_to_playlist')!.run({
        'playlistId': favoritesPlaylistId,
        'trackIds': [a, b],
      }, env);
      expect(again.done!.added, isEmpty);
      expect((jsonDecode(again.text) as Map)['alreadyThere'], 2);
    });

    test('create_playlist returns the id list_playlists shows', () async {
      final a = await track('Created');
      final o = await registry.byName('create_playlist')!.run({
        'name': 'Fresh',
        'trackIds': [a],
      }, env);
      final id = (jsonDecode(o.text) as Map)['playlistId'] as int;
      final writable = await store.listWritable();
      expect(writable.singleWhere((p) => p.name == 'Fresh').id, id);
    });

    test(
      'a failing read-back after create does not undo or repeat it',
      () async {
        final a = await track('Once');
        final port = PlaylistsWritePortImpl(store: _FlakyStore(db));
        final made = await port.create('Once', [a]);
        expect(made.id, isNull);
        expect(made.count, 1);
        final all = await db.select(db.playlists).get();
        expect(all.where((p) => p.name == 'Once'), hasLength(1));
      },
    );
  });

  group('queue on the real player', () {
    late Harness h;

    setUp(() async {
      h = await Harness.create();
      await h.play();
      await h.settle();
    });
    tearDown(() => h.close());

    test('player undo token unchanged after AI removal', () async {
      final items = h.c.queueState.items;
      final token = await h.c.remove({items[5].entryId});
      expect(token, isNotNull);

      final env = fakeEnv(
        library: FakeLibrary(trackCount: 1 << 30),
        playback: FakePlayback(
          q: QueueSnapshot(
            items: [
              for (final i in items)
                QueueEntryRef(entryId: i.entryId, trackId: i.trackId.value),
            ],
          ),
        ),
      );
      final wired = ToolEnv(
        library: env.library,
        playback: env.playback,
        lyrics: env.lyrics,
        history: env.history,
        playlists: env.playlists,
        playbackWrite: PlaybackWritePortImpl(
          playTracks: h.c.playTracksForTool,
          playNext: h.c.playNext,
          enqueue: h.c.enqueue,
          removeQueueEntries: h.c.removeEntriesForTool,
          queueIsEmpty: () => h.c.queueState.items.isEmpty,
        ),
        playlistsWrite: FakePlaylistsWrite(),
      );
      final o = await registry.byName('remove_from_queue')!.run({
        'entryIds': [items[2].entryId],
      }, wired);
      expect(o.done!.removed.single.trackId, items[2].trackId.value);
      await h.settle();

      // The user's own undo still brings their entry back.
      await h.c.undo(token!);
      await h.settle();
      final left = [for (final i in h.c.queueState.items) i.entryId];
      expect(left, contains(items[5].entryId));
      expect(left, isNot(contains(items[2].entryId)));
    });
  });
}

/// A store whose read-back after a create fails.
class _FlakyStore extends PlaylistRepository {
  _FlakyStore(super.db);

  @override
  Future<List<WritablePlaylist>> listWritable() =>
      Future.error(StateError('db went away'));
}
