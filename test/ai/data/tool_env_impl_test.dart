import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/tool_env_impl.dart';
import 'package:kanaru/src/ai/data/tool_env_write.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/read_tools.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/data/search/track_lookup_query.dart';
import 'package:kanaru/src/library/data/search/track_search_query.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';

import '../../database/support/test_db.dart';
import '../../library/search/search_test_support.dart';
import '../domain/tools/fake_tool_env.dart';

void main() {
  late AppDatabase db;
  late int source;
  late PlaylistRepository playlists;
  late ToolEnv env;
  late AiToolRegistry registry;
  var recording = true;
  final now = DateTime(2026, 11, 20, 12);

  setUp(() async {
    recording = true;
    db = openTestDb();
    addTearDown(db.close);
    source = await addSource(db, uid: 'src-tools');
    playlists = PlaylistRepository(db);
    final lookup = TrackLookupQuery(db);
    env = ToolEnv(
      library: LibraryPortImpl(
        trackSearch: TrackSearchQuery(db),
        trackLookup: lookup,
        trackInfo: (id) => watchTrackInfo(db, id).first,
      ),
      playback: FakePlayback(),
      lyrics: FakeLyrics(const LyricsAbsent('none')),
      history: HistoryPortImpl(
        store: HistoryRepository(db),
        lookup: lookup,
        enabled: () async => recording,
        now: () => now,
      ),
      playlists: PlaylistsPortImpl(store: playlists, lookup: lookup),
      playbackWrite: FakePlaybackWrite(),
      playlistsWrite: PlaylistsWritePortImpl(store: playlists),
    );
    registry = AiToolRegistry([readToolProvider]);
  });

  Future<int> track(
    String title, {
    String? artist,
    String status = 'present',
  }) => addSearchTrack(
    db,
    source,
    locator: '$title.flac',
    title: title,
    artist: artist,
    status: status,
  );

  Future<Map<String, Object?>> run(
    String tool,
    Map<String, Object?> args,
  ) async {
    final o = await registry.byName(tool)!.run(args, env);
    expect(o.isError, isFalse, reason: o.text);
    return jsonDecode(o.text) as Map<String, Object?>;
  }

  test('get_track_info of a hidden track returns not found', () async {
    final shown = await track('Shown', artist: 'Ann');
    final hidden = await track('Hidden', status: 'hidden');
    final missing = await track('Gone', status: 'missing');
    final r = await run('get_track_info', {
      'trackIds': [shown, hidden, missing, 9999],
    });
    expect((r['items'] as List).single, startsWith('$shown|Shown|Ann'));
    expect(r['notFound'], [hidden, missing, 9999]);
  });

  test('search_library returns visible tracks only', () async {
    final a = await track('Moon river');
    await track('Moon hidden', status: 'hidden');
    await track('Moon gone', status: 'missing');
    final r = await run('search_library', {'query': 'moon'});
    expect(r['total'], 1);
    expect((r['items'] as List).single, startsWith('$a|Moon river'));
  });

  test('list_playlists excludes saved queues and mood playlists, includes '
      'Favorites id 0', () async {
    final t = await track('One');
    final uid = await playlists.createPlaylist(
      name: 'Mine',
      tracks: [TrackId(t)],
    );
    await addPlaylist(db, kind: 'queue', uid: 'q1', name: 'Saved queue');
    await addPlaylist(
      db,
      kind: 'mood',
      nameKey: 'calm',
      uid: 'm1',
      name: 'Calm',
    );
    final r = await run('list_playlists', {});
    final items = (r['items'] as List).cast<String>();
    expect(items.first, '$favoritesPlaylistId|Favorites|0');
    expect(items, hasLength(2));
    expect(items[1], endsWith('|Mine|1'));
    expect(uid, isNotEmpty);
  });

  test(
    'get_playlist_tracks leaves out hidden tracks and gives entry ids',
    () async {
      final a = await track('Alpha');
      final b = await track('Beta');
      final uid = await playlists.createPlaylist(
        name: 'P',
        tracks: [TrackId(a), TrackId(b)],
      );
      await db.customStatement(
        "UPDATE tracks SET status = 'hidden' WHERE id = ?",
        [b],
      );
      final detail = (await playlists.loadPlaylist(uid))!;
      final id = detail.summary.id;
      final r = await run('get_playlist_tracks', {'playlistId': id});
      expect(r['total'], 1);
      expect(
        (r['items'] as List).single,
        startsWith('${detail.entries.first.id}|$a|Alpha'),
      );
    },
  );

  test('get_playlist_tracks of a saved queue id is not found', () async {
    final id = await addPlaylist(db, kind: 'queue', uid: 'q2');
    final o = await registry.byName('get_playlist_tracks')!.run({
      'playlistId': id,
    }, env);
    expect(o.isError, isTrue);
  });

  test('Favorites (id 0) reads before any favorite exists', () async {
    final r = await run('get_playlist_tracks', {
      'playlistId': favoritesPlaylistId,
    });
    expect(r['total'], 0);
  });

  test(
    'get_listening_stats drops hidden songs and respects the switch',
    () async {
      final a = await track('Often');
      final b = await track('Secret', status: 'hidden');
      final at = now.subtract(const Duration(days: 2)).millisecondsSinceEpoch;
      for (var i = 0; i < 3; i++) {
        await addPlay(db, a, playedAt: at + i);
      }
      for (var i = 0; i < 5; i++) {
        await addPlay(db, b, playedAt: at + 10 + i);
      }
      final r = await run('get_listening_stats', {'range': '7d'});
      final items = (r['items'] as List).cast<String>();
      expect(items, hasLength(1));
      expect(items.single, startsWith('2|$a|Often'));
      expect(items.single, endsWith('|3'));
      // Totals count visible songs only: the hidden song's 5 plays stay out.
      expect(r['total'], 1);
      expect(r['totalPlays'], 3);

      recording = false;
      final off = await registry.byName('get_listening_stats')!.run({}, env);
      expect(off.isError, isTrue);
    },
  );
}
