import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/ai/domain/variables/chip_ref.dart';
import 'package:kanaru/src/ai/domain/variables/chip_resolver.dart';
import 'package:kanaru/src/library/domain/ask_ai_target.dart';

import '../tools/fake_tool_env.dart';

class _Scopes implements ChipScopePort {
  final Map<String, int> playlistIds = {'uid-1': 7};
  final List<(ChipKind, String)> asked = [];

  @override
  Future<int?> playlistModelId(String uid) async => playlistIds[uid];

  @override
  Future<({List<TrackRow> rows, int total})?> scopeTracks(
    ChipKind kind,
    String ref,
  ) async {
    asked.add((kind, ref));
    return (rows: [fakeTrack(1), fakeTrack(2)], total: 2);
  }
}

ChipResolver _resolver(
  _Scopes scopes, {
  bool Function(AiToolGroup)? on,
  bool bypass = false,
  ToolEnv? env,
}) => ChipResolver(
  env: env ?? fakeEnv(),
  scopes: scopes,
  groupEnabled: on ?? (_) => true,
  varBypass: bypass,
);

void main() {
  test('the library menu limit equals the rows one chip sends', () {
    expect(askAiMaxSongs, chipMaxRows);
  });

  test('album chip blocked when trackInfo off', () async {
    final scopes = _Scopes();
    final r = await _resolver(
      scopes,
      on: (g) => g != AiToolGroup.trackInfo,
    ).resolve(chipRefOf(const AskAiTarget.album('k', 'Abbey')));
    expect((r as ChipBlocked).group, AiToolGroup.trackInfo);
    expect(scopes.asked, isEmpty);
  });

  test('album chip allowed with bypass', () async {
    final r = await _resolver(
      _Scopes(),
      on: (g) => g != AiToolGroup.trackInfo,
      bypass: true,
    ).resolve(chipRefOf(const AskAiTarget.album('k', 'Abbey')));
    expect(r, isA<ChipResolved>());
  });

  test('playlist uid resolves to model id', () async {
    final env = fakeEnv(
      playlists: FakePlaylists(
        entriesById: {
          7: (
            name: 'Road',
            entries: [PlaylistEntryRow(entryId: 5, track: fakeTrack(2))],
          ),
        },
      ),
    );
    final r = await _resolver(_Scopes(), env: env).resolve(
      chipRefOf(const AskAiTarget.playlist('uid-1', 'Road')),
    ) as ChipResolved;
    expect(r.chip.ref, '7');
    expect(r.chip.kind, ChipKind.playlist);
    expect(r.data.source, DataSource.playlist);
    expect(r.data.text, contains('2|Song 2|'));
  });

  test('playlist that is gone is missing', () async {
    final r = await _resolver(_Scopes())
        .resolve(chipRefOf(const AskAiTarget.playlist('nope', 'X')));
    expect(r, isA<ChipMissing>());
  });

  test('genre and language chips use trackInfo', () {
    for (final t in const [
      AskAiTarget.genre('pop', 'Pop'),
      AskAiTarget.language('vie', 'Vietnamese'),
      AskAiTarget.language(null, 'None'),
      AskAiTarget.album('a', 'A'),
      AskAiTarget.artist('b', 'B'),
      AskAiTarget.song(AskAiTrack(id: 1, title: 'x')),
      AskAiTarget.songs([AskAiTrack(id: 1, title: 'x')]),
    ]) {
      expect(chipRefOf(t).group, AiToolGroup.trackInfo);
    }
    expect(
      chipRefOf(const AskAiTarget.nowPlaying()).group,
      AiToolGroup.nowPlaying,
    );
    expect(
      chipRefOf(const AskAiTarget.playlist('u', 'P')).group,
      AiToolGroup.playlists,
    );
    expect(chipRefOf(const AskAiTarget.language(null, 'None')).ref, '');
  });

  test('song chip sends details as a track data part', () async {
    final r = await _resolver(_Scopes()).resolve(
      chipRefOf(const AskAiTarget.song(AskAiTrack(id: 2, title: 'Song 2'))),
    ) as ChipResolved;
    expect(r.data.source, DataSource.track);
    expect(r.data.text, contains('2|Song 2|Artist|Album|2002|Pop|vi'));
    expect(r.chip.tracks.single.trackId, 2);
  });

  test('song chip of a hidden track is missing', () async {
    final r = await _resolver(_Scopes()).resolve(
      chipRefOf(const AskAiTarget.song(AskAiTrack(id: 99, title: 'gone'))),
    );
    expect(r, isA<ChipMissing>());
  });
}
