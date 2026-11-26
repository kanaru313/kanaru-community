import 'package:kanaru/src/ai/domain/tools/tool_env.dart';

TrackRow fakeTrack(int id, {String? title}) => TrackRow(
  id: id,
  title: title ?? 'Song $id',
  artist: 'Artist',
  album: 'Album',
  year: 2000 + id,
);

/// Fakes for the tool ports: a small library where ids 1..[trackCount] are
/// visible and every other id is absent.
class FakeLibrary implements LibraryPort {
  FakeLibrary({this.trackCount = 10, this.titles = const {}});

  final int trackCount;
  final Map<int, String> titles;
  final List<List<int>> lookups = [];

  TrackRow _t(int id) => fakeTrack(id, title: titles[id]);

  @override
  Future<({List<TrackRow> visible, List<int> absent})> visibleOf(
    List<int> ids,
  ) async {
    lookups.add(ids);
    final unique = ids.toSet().toList();
    return (
      visible: [
        for (final id in unique)
          if (id >= 1 && id <= trackCount) _t(id),
      ],
      absent: [
        for (final id in unique)
          if (id < 1 || id > trackCount) id,
      ],
    );
  }

  @override
  Future<({List<TrackRow> rows, int total})> search(
    String query, {
    required int offset,
    required int limit,
  }) async {
    final all = [for (var i = 1; i <= trackCount; i++) _t(i)];
    return (rows: all.skip(offset).take(limit).toList(), total: all.length);
  }

  @override
  Future<({List<TrackDetail> found, List<int> absent})> details(
    List<int> ids,
  ) async {
    final r = await visibleOf(ids);
    return (
      found: [
        for (final t in r.visible)
          TrackDetail(row: t, genre: 'Pop', language: 'vi', durationMs: 215000),
      ],
      absent: r.absent,
    );
  }
}

class FakePlayback implements PlaybackPort {
  FakePlayback({
    this.now = NowPlayingSnapshot.none,
    this.q = const QueueSnapshot(),
  });

  NowPlayingSnapshot now;
  QueueSnapshot q;

  @override
  Future<NowPlayingSnapshot> nowPlaying() async => now;

  @override
  Future<QueueSnapshot> queue() async => q;
}

class FakeLyrics implements LyricsPort {
  FakeLyrics(this.result);

  LyricsRead result;

  @override
  Future<LyricsRead> read(int trackId) async => result;
}

class FakeHistory implements HistoryPort {
  FakeHistory({this.recording = true});

  bool recording;
  StatsRange? lastRange;

  @override
  Future<bool> isRecording() async => recording;

  @override
  Future<({List<StatsRow> rows, int songs, int plays})> mostPlayed(
    StatsRange range, {
    required int offset,
    required int limit,
  }) async {
    lastRange = range;
    return (
      rows: [
        for (var i = 0; i < 3; i++)
          StatsRow(rank: i + 1, track: fakeTrack(i + 1), plays: 10 - i),
      ],
      songs: 3,
      plays: 27,
    );
  }
}

class FakePlaylists implements PlaylistsPort {
  FakePlaylists({this.rows = const [], this.entriesById = const {}});

  List<PlaylistRow> rows;
  Map<int, ({String name, List<PlaylistEntryRow> entries})> entriesById;

  @override
  Future<List<PlaylistRow>> list() async => rows;

  @override
  Future<({String name, List<PlaylistEntryRow> entries})?> entries(
    int id,
  ) async => entriesById[id];
}

ToolEnv fakeEnv({
  FakeLibrary? library,
  FakePlayback? playback,
  FakeLyrics? lyrics,
  FakeHistory? history,
  FakePlaylists? playlists,
}) => ToolEnv(
  library: library ?? FakeLibrary(),
  playback: playback ?? FakePlayback(),
  lyrics: lyrics ?? FakeLyrics(const LyricsAbsent('none')),
  history: history ?? FakeHistory(),
  playlists: playlists ?? FakePlaylists(),
);
