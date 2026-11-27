import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/online/data/tracks/online_track_writer.dart';
import 'package:kanaru/src/online/domain/contract/online_card.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';

import '../../database/support/test_db.dart';
import '../../plugins/data/store_test_support.dart';
import 'tracks_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  late OnlineTrackWriter writer;
  var clock = 1000;
  final id = testInstallId();

  setUp(() async {
    clock = 1000;
    db = openTestDb();
    rows = PluginRows(db, clock: () => clock);
    writer = OnlineTrackWriter(db, rows, configOf(db, rows), now: () => clock);
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> trackRow(int trackId) async =>
      (await db
              .customSelect(
                'SELECT * FROM tracks WHERE id = ?',
                variables: [Variable<int>(trackId)],
              )
              .getSingle())
          .data;

  group('upsertCards', () {
    test('writes aligned remote rows with no format or artist rows', () async {
      await installStreaming(rows);
      final ids = await writer.upsertCards(id, [
        track('a1', title: 'Blinding Lights', artist: 'The Weeknd'),
        track('b2', title: 'Shape of You'),
        track(
          'c3',
          title: 'Levitating',
          duration: const Duration(seconds: 203),
        ),
      ]);
      expect(ids, hasLength(3));
      expect({for (final t in ids) t.value}, hasLength(3));
      final first = await trackRow(ids[0].value);
      final second = await trackRow(ids[1].value);
      final third = await trackRow(ids[2].value);
      expect(first['locator'], 'a1');
      expect(second['locator'], 'b2');
      expect(third['locator'], 'c3');
      for (final r in [first, second, third]) {
        expect(r['status'], 'remote');
        expect(r['rel_path'], r['locator']);
        expect(r['codec'], isNull);
        expect(r['title_search'], isNotEmpty);
      }
      expect(first['artist'], 'The Weeknd');
      expect(third['duration_ms'], 203000);
      expect(await db.select(db.trackArtists).get(), isEmpty);
    });

    test(
      'a second write updates the title, keeps added_at and artist',
      () async {
        await installStreaming(rows);
        final first = await writer.upsertCards(id, [
          track('a1', title: 'Old', artist: 'The Weeknd'),
        ]);
        clock = 2000;
        final second = await writer.upsertCards(id, [
          track('a1', title: 'New'),
        ]);
        expect(second, first);
        final r = await trackRow(first.single.value);
        expect(r['title'], 'New');
        expect(r['title_search'], 'new');
        expect(r['artist'], 'The Weeknd');
        expect(r['added_at'], 1000);
        expect(r['updated_at'], 2000);
      },
    );

    test('an album card writes the album and its keys together', () async {
      await installStreaming(rows);
      final ids = await writer.upsertCards(id, [
        track(
          'a1',
          artist: 'Ed Sheeran',
          album: const CardRef(name: 'Divide'),
        ),
      ]);
      final r = await trackRow(ids.single.value);
      expect(r['album'], 'Divide');
      expect(r['album_title_key'], 'divide');
      expect(r['album_artist_key'], 'ed sheeran');
    });

    test('caps and bad cards write nothing', () async {
      await installStreaming(rows);
      final before = await counts(db);
      await expectLater(
        writer.upsertCards(id, [for (var i = 0; i < 201; i++) track('t$i')]),
        throwsArgumentError,
      );
      await expectLater(writer.upsertCards(id, []), throwsArgumentError);
      await expectLater(
        writer.upsertCards(id, [track('a1', kind: OnlineCardKind.album)]),
        throwsArgumentError,
      );
      await expectLater(
        writer.upsertCards(id, [
          track('a1'),
          track('a2'),
          track('https://example.com/x'),
        ]),
        throwsArgumentError,
      );
      await expectLater(
        writer.upsertCards(id, [track('a1'), track('//host/x')]),
        throwsArgumentError,
      );
      final after = await counts(db);
      expect(after, before);
      expect(after.tracks, 0);
      expect(after.sources, 0);
    });

    test('200 cards are accepted', () async {
      await installStreaming(rows);
      final ids = await writer.upsertCards(id, [
        for (var i = 0; i < 200; i++) track('t$i'),
      ]);
      expect(ids, hasLength(200));
    });
  });

  group('cover url', () {
    test('a Subsonic-style link never reaches a row', () async {
      await installStreaming(
        rows,
        manifest: streamingWith(hosts: ['music.example.net']),
      );
      final ids = await writer.upsertCards(id, [
        track(
          'a1',
          artworkUrl: 'https://music.example.net/rest/getCoverArt.view?id=1&u=me&t=abc&s=salt',
        ),
      ]);
      expect((await trackRow(ids.single.value))['cover_url'], isNull);
      final dump = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM tracks WHERE cover_url LIKE '%salt%'",
          )
          .getSingle();
      expect(dump.read<int>('c'), 0);
    });

    test('a safe link is stored; one with a config value is not', () async {
      await installStreaming(
        rows,
        manifest: streamingWith(
          config: {
            'clientId': {'title': 'Client', 'mode': 'input', 'format': 'text'},
          },
        ),
      );
      await configOf(db, rows).setValue(id, 'clientId', 'secret123');
      final ids = await writer.upsertCards(id, [
        track('a1', artworkUrl: 'https://cdn.example.com/x.jpg?w=300'),
        track('b2', artworkUrl: 'https://cdn.example.com/x.jpg?cid=secret123'),
      ]);
      expect(
        (await trackRow(ids[0].value))['cover_url'],
        'https://cdn.example.com/x.jpg?w=300',
      );
      expect((await trackRow(ids[1].value))['cover_url'], isNull);
    });
  });

  group('refused plugins', () {
    test('missing, removed and lyrics plugins', () async {
      await expectLater(
        writer.upsertCards(id, [track('a1')]),
        throwsA(isA<OnlineWriteRefused>()),
      );
      await installStreaming(rows);
      await rows.remove(id);
      await expectLater(
        writer.upsertCards(id, [track('a1')]),
        throwsA(isA<OnlineWriteRefused>()),
      );
      final lyrics = testInstallId(2);
      await rows.installOrRevive(
        lyrics,
        draftOf(packageOf()),
        const PluginSource.file('lyrics.zip'),
      );
      await expectLater(
        writer.saveAsNewPlaylist(lyrics, name: 'x', cards: [track('a1')]),
        throwsA(isA<OnlineWriteRefused>()),
      );
      expect((await counts(db)).sources, 0);
    });
  });

  group('saveAsNewPlaylist', () {
    Future<List<String>> entryLocators(String uid) async => [
      for (final r
          in await db
              .customSelect(
                'SELECT t.locator AS l FROM playlist_entries e '
                'JOIN tracks t ON t.id = e.track_id '
                'JOIN playlists p ON p.id = e.playlist_id '
                'WHERE p.uid = ? ORDER BY e.sort_key',
                variables: [Variable<String>(uid)],
              )
              .get())
        r.read<String>('l'),
    ];

    test('500 cards become one playlist in order', () async {
      await installStreaming(rows);
      final saved = await writer.saveAsNewPlaylist(
        id,
        name: 'Road trip',
        cards: [for (var i = 0; i < 500; i++) track('t$i')],
      );
      expect(saved.trackCount, 500);
      expect(await entryLocators(saved.playlistUid), [
        for (var i = 0; i < 500; i++) 't$i',
      ]);
    });

    test('a repeated id is saved once, the first wins', () async {
      await installStreaming(rows);
      final saved = await writer.saveAsNewPlaylist(
        id,
        name: 'Mix',
        cards: [
          track('a', title: 'First'),
          track('b'),
          track('a', title: 'Second'),
        ],
      );
      expect(saved.trackCount, 2);
      expect(await entryLocators(saved.playlistUid), ['a', 'b']);
      final r = await db
          .customSelect("SELECT title FROM tracks WHERE locator = 'a'")
          .getSingle();
      expect(r.read<String>('title'), 'First');
    });

    test('an empty name rolls back the playlist, tracks and source', () async {
      await installStreaming(rows);
      final before = await counts(db);
      await expectLater(
        writer.saveAsNewPlaylist(
          id,
          name: '  ',
          cards: [track('a'), track('b')],
        ),
        throwsArgumentError,
      );
      expect(await counts(db), before);
    });

    test('1001 cards and none are refused', () async {
      await installStreaming(rows);
      await expectLater(
        writer.saveAsNewPlaylist(
          id,
          name: 'x',
          cards: [for (var i = 0; i < 1001; i++) track('t$i')],
        ),
        throwsArgumentError,
      );
      await expectLater(
        writer.saveAsNewPlaylist(id, name: 'x', cards: []),
        throwsArgumentError,
      );
    });

    test('the playlist is seen only after the commit, once', () async {
      await installStreaming(rows);
      final seen = <List<String>>[];
      final sub = db
          .select(db.playlists)
          .watch()
          .listen((l) => seen.add([for (final p in l) p.name]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final base = seen.length;
      await writer.saveAsNewPlaylist(
        id,
        name: 'Fresh',
        cards: [for (var i = 0; i < 50; i++) track('t$i')],
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(seen.length - base, 1);
      expect(seen.last, contains('Fresh'));
    });
  });
}
