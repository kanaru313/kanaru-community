import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/read_tools.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';

import 'fake_tool_env.dart';

Map<String, Object?> _decode(ToolOutcome o) {
  expect(o.isError, isFalse, reason: o.text);
  return jsonDecode(o.text) as Map<String, Object?>;
}

void main() {
  final registry = AiToolRegistry([readToolProvider]);
  AiTool tool(String name) => registry.byName(name)!;

  test('each tool reports its privacy group', () {
    final groups = {for (final t in registry.all) t.name: t.group};
    expect(groups, {
      'get_now_playing': AiToolGroup.nowPlaying,
      'get_queue': AiToolGroup.queue,
      'search_library': AiToolGroup.librarySearch,
      'get_lyrics': AiToolGroup.lyrics,
      'get_track_info': AiToolGroup.trackInfo,
      'get_listening_stats': AiToolGroup.listeningStats,
      'list_playlists': AiToolGroup.playlists,
      'get_playlist_tracks': AiToolGroup.playlists,
    });
    for (final t in registry.all) {
      expect(t.risk, ToolRisk.read);
      expect(t.source, ToolSource.builtin);
      expect(t.group.isWrite, isFalse);
    }
  });

  test('registry rejects duplicate names', () {
    expect(
      () => AiToolRegistry([readToolProvider, readToolProvider]),
      throwsArgumentError,
    );
  });

  test('wire entries carry name, description and a schema object', () {
    for (final t in registry.all) {
      final wire = t.toWire();
      expect(wire['name'], t.name);
      expect((wire['description'] as String), isNotEmpty);
      expect((wire['parameters'] as Map)['type'], 'object');
    }
  });

  group('get_now_playing', () {
    test('nothing loaded', () async {
      final r = _decode(await tool('get_now_playing').run({}, fakeEnv()));
      expect(r, {'loaded': false});
    });

    test('a visible track, a hidden one', () async {
      const snapshot = NowPlayingSnapshot(
        trackId: 3,
        playing: true,
        index: 0,
        length: 4,
        positionMs: 61000,
        durationMs: 200000,
      );
      final r = _decode(
        await tool('get_now_playing')
            .run({}, fakeEnv(playback: FakePlayback(now: snapshot))),
      );
      expect(r['track'], '3|Song 3|Artist|Album|2003');
      expect(r['positionSec'], 61);
      expect(r['queueLength'], 4);

      final hidden = _decode(
        await tool('get_now_playing').run(
          {},
          fakeEnv(
            library: FakeLibrary(trackCount: 1),
            playback: FakePlayback(now: snapshot),
          ),
        ),
      );
      expect(hidden['track'], 'unavailable');
    });

    test('rejects an unexpected argument', () async {
      final o = await tool('get_now_playing').run({'x': 1}, fakeEnv());
      expect(o.isError, isTrue);
    });
  });

  group('get_queue', () {
    QueueSnapshot queue(int n, {int? current}) => QueueSnapshot(
      items: [
        for (var i = 0; i < n; i++)
          QueueEntryRef(entryId: 100 + i, trackId: i + 1),
      ],
      current: current,
    );

    test('empty queue', () async {
      final r = _decode(await tool('get_queue').run({}, fakeEnv()));
      expect(r['total'], 0);
      expect(r['items'], isEmpty);
    });

    test(
      'window starts before the current entry and carries entry ids',
      () async {
        final env = fakeEnv(
          library: FakeLibrary(trackCount: 200),
          playback: FakePlayback(q: queue(120, current: 60)),
        );
        final r = _decode(await tool('get_queue').run({}, env));
        expect(r['total'], 120);
        expect(r['offset'], 50);
        expect(r['current'], 60);
        final items = (r['items'] as List).cast<String>();
        expect(items, hasLength(50));
        expect(items.first, startsWith('150|51|Song 51'));
      },
    );

    test('offset and limit page the queue, hidden tracks marked', () async {
      final env = fakeEnv(
        library: FakeLibrary(trackCount: 2),
        playback: FakePlayback(q: queue(5, current: 0)),
      );
      final r = _decode(
        await tool('get_queue').run({'offset': 1, 'limit': 3}, env),
      );
      expect(r['items'], [
        '101|2|Song 2|Artist|Album|2002',
        r'102|3|(unavailable)',
        r'103|4|(unavailable)',
      ]);
    });

    test('limit over 50 is refused', () async {
      final o = await tool('get_queue').run({'limit': 51}, fakeEnv());
      expect(o.isError, isTrue);
    });
  });

  group('search_library', () {
    test('requires a query', () async {
      expect((await tool('search_library').run({}, fakeEnv())).isError, isTrue);
    });

    test('pages with total and offset', () async {
      final env = fakeEnv(library: FakeLibrary(trackCount: 7));
      final r = _decode(
        await tool('search_library')
            .run({'query': 'x', 'offset': 5, 'limit': 5}, env),
      );
      expect(r['total'], 7);
      expect(r['offset'], 5);
      expect(r['items'], hasLength(2));
    });

    test('no matches', () async {
      final env = fakeEnv(library: FakeLibrary(trackCount: 0));
      final r = _decode(
        await tool('search_library').run({'query': 'zzz'}, env),
      );
      expect(r['total'], 0);
      expect(r['items'], isEmpty);
    });
  });

  group('get_track_info', () {
    test('rows with details, absent ids listed', () async {
      final r = _decode(
        await tool('get_track_info').run({
          'trackIds': [1, 99],
        }, fakeEnv()),
      );
      expect(r['items'], ['1|Song 1|Artist|Album|2001|Pop|vi|215']);
      expect(r['notFound'], [99]);
    });

    test('empty list and more than 50 ids are refused', () async {
      final empty = await tool('get_track_info')
          .run({'trackIds': []}, fakeEnv());
      expect(empty.isError, isTrue);
      final many = await tool('get_track_info')
          .run({'trackIds': List.generate(51, (i) => i)}, fakeEnv());
      expect(many.isError, isTrue);
    });
  });

  group('get_lyrics', () {
    test('plain text without timestamps, control chars stripped', () async {
      final env = fakeEnv(
        lyrics: FakeLyrics(
          const LyricsFound(lines: ['one\u202E', '', 'two'], synced: true),
        ),
      );
      final r = _decode(await tool('get_lyrics').run({'trackId': 1}, env));
      expect(r['text'], 'one\n\ntwo');
      expect(r['synced'], true);
      expect(r['truncated'], false);
    });

    test('cut at a line boundary over the character limit', () async {
      final line = 'x' * 999;
      final env = fakeEnv(
        lyrics: FakeLyrics(
          LyricsFound(lines: List.filled(20, line), synced: false),
        ),
      );
      final r = _decode(await tool('get_lyrics').run({'trackId': 1}, env));
      final text = r['text'] as String;
      expect(r['truncated'], true);
      expect(text.length, lessThanOrEqualTo(lyricsMaxChars));
      expect(text.split('\n').every((l) => l.length == 999), isTrue);
    });

    test('hidden track is not found and lyrics are never read', () async {
      final env = fakeEnv(
        library: FakeLibrary(trackCount: 1),
        lyrics: FakeLyrics(const LyricsFound(lines: ['secret'], synced: false)),
      );
      final o = await tool('get_lyrics').run({'trackId': 5}, env);
      expect(o.isError, isTrue);
      expect(o.text, isNot(contains('secret')));
    });

    test('a track without lyrics says so', () async {
      final r = _decode(
        await tool('get_lyrics').run({'trackId': 1}, fakeEnv()),
      );
      expect(r['lyrics'], 'none');
    });
  });

  group('get_listening_stats', () {
    test('listening stats unavailable when history is off', () async {
      final o = await tool('get_listening_stats')
          .run({}, fakeEnv(history: FakeHistory(recording: false)));
      expect(o.isError, isTrue);
      expect(o.text, contains('history is turned off'));
    });

    test('default range, rows with plays and totals', () async {
      final history = FakeHistory();
      final r = _decode(
        await tool('get_listening_stats').run({}, fakeEnv(history: history)),
      );
      expect(history.lastRange, StatsRange.days30);
      expect(r['range'], '30d');
      expect(r['totalPlays'], 27);
      expect(r['total'], 3);
      expect((r['items'] as List).first, '1|1|Song 1|Artist|Album|2001|10');
    });

    test('an unknown range is refused', () async {
      final o = await tool('get_listening_stats')
          .run({'range': 'week'}, fakeEnv());
      expect(o.isError, isTrue);
    });
  });

  group('playlists', () {
    final playlists = FakePlaylists(
      rows: [
        for (var i = 0; i < 60; i++)
          PlaylistRow(
            id: i,
            name: i == 0 ? 'Favorites' : 'List $i',
            trackCount: i,
          ),
      ],
      entriesById: {
        4: (
          name: 'Road|trip',
          entries: [
            PlaylistEntryRow(entryId: 900, track: fakeTrack(2)),
            PlaylistEntryRow(entryId: 901, track: fakeTrack(3)),
          ],
        ),
      },
    );

    test('list_playlists pages 50 at a time', () async {
      final env = fakeEnv(playlists: playlists);
      final first = _decode(await tool('list_playlists').run({}, env));
      expect(first['total'], 60);
      expect(first['items'], hasLength(50));
      expect((first['items'] as List).first, '0|Favorites|0');
      final second = _decode(
        await tool('list_playlists').run({'offset': 50}, env),
      );
      expect(second['items'], hasLength(10));
    });

    test('list_playlists with none', () async {
      final r = _decode(await tool('list_playlists').run({}, fakeEnv()));
      expect(r['total'], 0);
      expect(r['items'], isEmpty);
    });

    test('get_playlist_tracks rows carry entry ids', () async {
      final r = _decode(
        await tool('get_playlist_tracks')
            .run({'playlistId': 4}, fakeEnv(playlists: playlists)),
      );
      expect(r['name'], 'Road|trip');
      expect(r['total'], 2);
      expect((r['items'] as List).first, '900|2|Song 2|Artist|Album|2002');
    });

    test(
      'get_playlist_tracks of an unknown playlist, and offset past end',
      () async {
        final env = fakeEnv(playlists: playlists);
        final missing = await tool('get_playlist_tracks')
            .run({'playlistId': 77}, env);
        expect(missing.isError, isTrue);
        final r = _decode(
          await tool('get_playlist_tracks')
              .run({'playlistId': 4, 'offset': 5}, env),
        );
        expect(r['items'], isEmpty);
        expect(r['total'], 2);
      },
    );
  });

  test('a failing port becomes an error outcome without details', () async {
    final env = fakeEnv(playlists: _ThrowingPlaylists());
    final o = await tool('list_playlists').run({}, env);
    expect(o.isError, isTrue);
    expect(o.text, isNot(contains('/secret/path')));
  });
}

class _ThrowingPlaylists extends FakePlaylists {
  @override
  Future<List<PlaylistRow>> list() async =>
      throw StateError('/secret/path exploded');
}
