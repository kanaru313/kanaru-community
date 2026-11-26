import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/ai/domain/tools/write_tools.dart';

import 'fake_tool_env.dart';

final _rlo = String.fromCharCode(0x202E);
final _zw = String.fromCharCode(0x200B);

AiTool tool(String name) => AiToolRegistry([writeToolProvider]).byName(name)!;

Map<String, Object?> json(ToolOutcome o) =>
    jsonDecode(o.text) as Map<String, Object?>;

TurnItemUsage usageOf({int added = 0, int removed = 0}) =>
    TurnItemUsage.fromParts([
      DonePart(
        callId: 'c1',
        added: [
          for (var i = 0; i < added; i++)
            TrackRefSnapshot(trackId: i, title: 't'),
        ],
        removed: [
          for (var i = 0; i < removed; i++)
            TrackRefSnapshot(trackId: i, title: 't'),
        ],
      ),
    ]);

void main() {
  test('the six write tools are write risk with their groups', () {
    final tools = AiToolRegistry([writeToolProvider]).all;
    expect(tools.map((t) => t.name), [
      'play_tracks',
      'queue_tracks',
      'remove_from_queue',
      'create_playlist',
      'add_to_playlist',
      'remove_from_playlist',
    ]);
    expect(tools.every((t) => t.risk == ToolRisk.write), isTrue);
  });

  group('play_tracks', () {
    test('done part holds the replaced queue', () async {
      final pw = FakePlaybackWrite()
        ..replaced = const ReplacedQueueSnapshot(
          tracks: [4, 5],
          userOrder: [5, 4],
          shuffled: true,
          previousIndex: 1,
        );
      final o = await tool('play_tracks').run({
        'trackIds': [1, 2, 3],
        'startIndex': 1,
      }, fakeEnv(playbackWrite: pw));
      expect(o.isError, isFalse);
      expect(pw.plays.single.ids, [1, 2, 3]);
      expect(pw.plays.single.startIndex, 1);
      expect(pw.plays.single.label, 'Trợ lý AI');
      expect(o.done!.replacedQueue, pw.replaced);
      expect(o.done!.added.map((t) => t.trackId), [1, 2, 3]);
    });

    test('start index counts in the given ids, not the visible ones', () async {
      final pw = FakePlaybackWrite();
      await tool('play_tracks').run({
        'trackIds': [99, 2, 3],
        'startIndex': 2,
      }, fakeEnv(playbackWrite: pw));
      expect(pw.plays.single.ids, [2, 3]);
      expect(pw.plays.single.startIndex, 1);
    });

    test('a start on an absent id or past the end is refused', () async {
      final pw = FakePlaybackWrite();
      final env = fakeEnv(playbackWrite: pw);
      final onAbsent = await tool('play_tracks').run({
        'trackIds': [99, 2],
      }, env);
      final past = await tool('play_tracks').run({
        'trackIds': [1],
        'startIndex': 1,
      }, env);
      expect(onAbsent.isError, isTrue);
      expect(past.isError, isTrue);
      expect(pw.plays, isEmpty);
    });

    test(
      'refuses remote rows (not visible), nothing reaches the player',
      () async {
        final pw = FakePlaybackWrite();
        final o = await tool('play_tracks').run({
          'trackIds': [500, 501],
        }, fakeEnv(playbackWrite: pw));
        expect(o.isError, isTrue);
        expect(o.limitReached, isFalse);
        expect(pw.plays, isEmpty);
      },
    );

    test('over 200 ids refused', () async {
      final pw = FakePlaybackWrite();
      final o = await tool('play_tracks').run({
        'trackIds': [for (var i = 1; i <= 201; i++) i],
      }, fakeEnv(library: FakeLibrary(trackCount: 300), playbackWrite: pw));
      expect(o.isError, isTrue);
      expect(o.text, contains('at most 200'));
      expect(pw.plays, isEmpty);
    });
  });

  group('queue_tracks', () {
    test('absent track ids reported, rest added', () async {
      final pw = FakePlaybackWrite()..startedPlayback = true;
      final o = await tool('queue_tracks').run({
        'trackIds': [1, 77, 2],
        'position': 'next',
      }, fakeEnv(playbackWrite: pw));
      expect(pw.queued.single.ids, [1, 2]);
      expect(pw.queued.single.next, isTrue);
      expect(json(o)['notFound'], [77]);
      expect(json(o)['note'], contains('started'));
      expect(o.done!.absent, [77]);
      expect(o.done!.added.map((t) => t.trackId), [1, 2]);
    });

    test('position defaults to end', () async {
      final pw = FakePlaybackWrite();
      await tool('queue_tracks').run({
        'trackIds': [1],
      }, fakeEnv(playbackWrite: pw));
      expect(pw.queued.single.next, isFalse);
    });

    test(
      'added items over the turn limit are refused with the limit flag',
      () async {
        final pw = FakePlaybackWrite();
        final o = await tool('queue_tracks').run({
          'trackIds': [1, 2],
        }, fakeEnv(playbackWrite: pw, usage: usageOf(added: 199)));
        expect(o.limitReached, isTrue);
        expect(o.isError, isTrue);
        expect(pw.queued, isEmpty);
      },
    );
  });

  group('remove_from_queue', () {
    final entries = [
      for (var i = 1; i <= 3; i++) QueueEntryRef(entryId: 100 + i, trackId: i),
    ];

    test('lists only entries the API removed', () async {
      final pw = FakePlaybackWrite()..entries = entries;
      final o = await tool('remove_from_queue').run({
        'entryIds': [101, 103, 999],
      }, fakeEnv(playbackWrite: pw));
      expect(o.done!.removed.map((t) => t.trackId), [1, 3]);
      expect(json(o)['removed'], 2);
      expect(json(o)['notInQueue'], [999]);
    });

    test('describe shows the entries in the queue now', () async {
      final env = fakeEnv(
        playback: FakePlayback(q: QueueSnapshot(items: entries)),
        playbackWrite: FakePlaybackWrite()..entries = entries,
      );
      final p = await tool('remove_from_queue').describe({
        'entryIds': [102, 999],
      }, env);
      expect(p!.tracks.map((t) => t.trackId), [2]);
    });

    test('51st removal in a turn refused with the limit card', () async {
      final pw = FakePlaybackWrite()..entries = entries;
      final env = fakeEnv(playbackWrite: pw, usage: usageOf(removed: 50));
      final o = await tool('remove_from_queue').run({
        'entryIds': [101],
      }, env);
      expect(o.limitReached, isTrue);
      expect(pw.removals, isEmpty);
      final preview = await tool('remove_from_queue').describe({
        'entryIds': [101],
      }, env);
      expect(preview!.limitReached, isTrue);
      expect(preview.refusal, isNotNull);
    });

    test('exactly 50 are allowed, a batch crossing 50 is refused', () async {
      final pw = FakePlaybackWrite();
      final ok = await tool('remove_from_queue').run({
        'entryIds': [for (var i = 0; i < 50; i++) i],
      }, fakeEnv(playbackWrite: pw));
      expect(ok.isError, isFalse);
      final over = await tool('remove_from_queue').run({
        'entryIds': [for (var i = 0; i < 11; i++) i],
      }, fakeEnv(playbackWrite: pw, usage: usageOf(removed: 40)));
      expect(over.limitReached, isTrue);
    });

    test('retry after the cap does not reset the count', () {
      // The count comes from the persisted parts of the turn, so a retried
      // call sees the same total however often it is made.
      final parts = <AiPart>[
        const TextPart('go'),
        DonePart(
          callId: 'a',
          removed: [
            for (var i = 0; i < 50; i++)
              TrackRefSnapshot(trackId: i, title: 't'),
          ],
        ),
      ];
      for (var attempt = 0; attempt < 3; attempt++) {
        final usage = TurnItemUsage.fromParts(parts);
        expect(usage.removed, 50);
        expect(usage.canRemove(1), isFalse);
      }
    });
  });

  group('playlists', () {
    test('playlist name with RLO and zero-width chars cleaned before card and '
        'store', () async {
      final pw = FakePlaylistsWrite();
      final env = fakeEnv(playlistsWrite: pw);
      final raw = '${_rlo}Gym$_zw  mix\n';
      final card = await tool('create_playlist').describe({
        'name': raw,
        'trackIds': [1],
      }, env);
      expect(card!.summary, 'Gym mix');
      final o = await tool('create_playlist').run({
        'name': raw,
        'trackIds': [1, 2],
      }, env);
      expect(pw.created.single.name, 'Gym mix');
      expect(json(o)['playlistId'], 11);
      expect(json(o)['name'], 'Gym mix');
    });

    test(
      'a name empty after cleaning is refused by describe and run',
      () async {
        final pw = FakePlaylistsWrite();
        final env = fakeEnv(playlistsWrite: pw);
        final args = {
          'name': '$_zw$_rlo ',
          'trackIds': [1],
        };
        final card = await tool('create_playlist').describe(args, env);
        expect(card!.refusal, isNotNull);
        expect((await tool('create_playlist').run(args, env)).isError, isTrue);
        expect(pw.created, isEmpty);
      },
    );

    test(
      'create with only absent ids is refused; absent ids are reported',
      () async {
        final pw = FakePlaylistsWrite();
        final env = fakeEnv(playlistsWrite: pw);
        expect(
          (await tool('create_playlist').run({
            'name': 'X',
            'trackIds': [900],
          }, env)).isError,
          isTrue,
        );
        final o = await tool('create_playlist').run({
          'name': 'X',
          'trackIds': [1, 900],
        }, env);
        expect(o.done!.absent, [900]);
        expect(pw.created.single.ids, [1]);
      },
    );

    test('add_to_playlist reports tracks the playlist already held', () async {
      final pw = FakePlaylistsWrite()..alreadyThere = [2];
      final env = fakeEnv(
        playlists: FakePlaylists(
          rows: const [PlaylistRow(id: 7, name: 'Mine', trackCount: 1)],
        ),
        playlistsWrite: pw,
      );
      final o = await tool('add_to_playlist').run({
        'playlistId': 7,
        'trackIds': [1, 2, 55],
      }, env);
      expect(pw.adds.single.ids, [1, 2]);
      expect(o.done!.added.map((t) => t.trackId), [1]);
      expect(o.done!.absent, [55]);
      expect(json(o)['alreadyThere'], 1);
    });

    test('add_to_playlist to a playlist that is not listed fails', () async {
      final pw = FakePlaylistsWrite();
      final o = await tool('add_to_playlist').run({
        'playlistId': 9,
        'trackIds': [1],
      }, fakeEnv(playlistsWrite: pw));
      expect(o.isError, isTrue);
      expect(pw.adds, isEmpty);
    });

    test('remove_from_playlist on a saved queue id fails', () async {
      final pw = FakePlaylistsWrite()..known = {0};
      final env = fakeEnv(
        playlists: FakePlaylists(entriesById: {}),
        playlistsWrite: pw,
      );
      final o = await tool('remove_from_playlist').run({
        'playlistId': 42,
        'entryIds': [1],
      }, env);
      expect(o.isError, isTrue);
      expect(o.text, contains('not found'));
      expect(pw.removals, isEmpty);
    });

    test('remove_from_playlist lists only entries the API removed', () async {
      final pw = FakePlaylistsWrite()
        ..held = const [QueueEntryRef(entryId: 5, trackId: 2)];
      final env = fakeEnv(
        playlists: FakePlaylists(
          entriesById: {
            7: (
              name: 'Mine',
              entries: [
                PlaylistEntryRow(entryId: 5, track: fakeTrack(2)),
                PlaylistEntryRow(entryId: 6, track: fakeTrack(3)),
              ],
            ),
          },
        ),
        playlistsWrite: pw,
      );
      final o = await tool('remove_from_playlist').run({
        'playlistId': 7,
        'entryIds': [5, 6],
      }, env);
      expect(o.done!.removed.single.trackId, 2);
      expect(json(o)['notInPlaylist'], [6]);
    });
  });
}
