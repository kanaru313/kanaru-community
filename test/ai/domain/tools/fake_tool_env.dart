import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/tools/item_caps.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env_write.dart';

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
  FakeLibrary({
    this.trackCount = 10,
    this.titles = const {},
    this.totals = const LibraryTotals(
      songs: 1284,
      albums: 97,
      artists: 210,
      playlists: 5,
      totalDurationMs: 312345678,
    ),
  });

  final LibraryTotals totals;

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
  Future<LibraryTotals> overview() async => totals;

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

/// Records what the write tools sent and answers like the real player.
class FakePlaybackWrite implements PlaybackWritePort {
  ReplacedQueueSnapshot? replaced;
  bool startedPlayback = false;

  /// Entries the "player" really holds; removal returns the ones asked for
  /// that are in it.
  List<QueueEntryRef> entries = [];

  final List<({List<int> ids, int startIndex, String label})> plays = [];
  final List<({List<int> ids, bool next})> queued = [];
  final List<List<int>> removals = [];

  @override
  Future<ReplacedQueueSnapshot?> play(
    List<int> trackIds, {
    required int startIndex,
    required String contextLabel,
  }) async {
    plays.add((ids: trackIds, startIndex: startIndex, label: contextLabel));
    return replaced;
  }

  @override
  Future<({bool startedPlayback})> queue(
    List<int> trackIds, {
    required bool next,
  }) async {
    queued.add((ids: trackIds, next: next));
    return (startedPlayback: startedPlayback);
  }

  @override
  Future<List<QueueEntryRef>> removeEntries(List<int> entryIds) async {
    removals.add(entryIds);
    return [
      for (final e in entries)
        if (entryIds.contains(e.entryId)) e,
    ];
  }
}

class FakePlaylistsWrite implements PlaylistsWritePort {
  /// Ids of playlists that exist (0 = Favorites).
  Set<int> known = {0, 7};
  int? nextId = 11;
  List<int> alreadyThere = [];
  List<QueueEntryRef> held = [];
  final List<({String name, List<int> ids})> created = [];
  final List<({int id, List<int> ids})> adds = [];
  final List<({int id, List<int> ids})> removals = [];

  @override
  Future<({int? id, int count})> create(String name, List<int> trackIds) async {
    created.add((name: name, ids: trackIds));
    return (id: nextId, count: trackIds.length);
  }

  @override
  Future<({String name, List<int> addedTrackIds, int skipped})?> add(
    int playlistId,
    List<int> trackIds,
  ) async {
    if (!known.contains(playlistId)) return null;
    adds.add((id: playlistId, ids: trackIds));
    return (
      name: 'P',
      addedTrackIds: [
        for (final t in trackIds)
          if (!alreadyThere.contains(t)) t,
      ],
      skipped: alreadyThere.length,
    );
  }

  @override
  Future<({String name, List<QueueEntryRef> removed})?> removeEntries(
    int playlistId,
    List<int> entryIds,
  ) async {
    if (!known.contains(playlistId)) return null;
    removals.add((id: playlistId, ids: entryIds));
    return (
      name: 'P',
      removed: [
        for (final e in held)
          if (entryIds.contains(e.entryId)) e,
      ],
    );
  }
}

ToolEnv fakeEnv({
  FakeLibrary? library,
  FakePlayback? playback,
  FakeLyrics? lyrics,
  FakeHistory? history,
  FakePlaylists? playlists,
  FakePlaybackWrite? playbackWrite,
  FakePlaylistsWrite? playlistsWrite,
  TurnItemUsage usage = TurnItemUsage.none,
}) => ToolEnv(
  library: library ?? FakeLibrary(),
  playback: playback ?? FakePlayback(),
  lyrics: lyrics ?? FakeLyrics(const LyricsAbsent('none')),
  history: history ?? FakeHistory(),
  playlists: playlists ?? FakePlaylists(),
  playbackWrite: playbackWrite ?? FakePlaybackWrite(),
  playlistsWrite: playlistsWrite ?? FakePlaylistsWrite(),
  playContextLabel: 'Trợ lý AI',
  turnUsage: () async => usage,
);
