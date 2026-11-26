/// What the assistant's tools may touch, as ports with no Flutter and no
/// Riverpod. `data/tool_env_impl.dart` implements them on the real library,
/// playback, lyrics and history APIs; tests use fakes.
///
/// Every track id a model sends goes through [LibraryPort.visibleOf] first:
/// a hidden, missing, remote or duplicate-hidden track is "not found".
library;

/// One visible track as a tool answer shows it.
class TrackRow {
  const TrackRow({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.year,
  });

  final int id;
  final String title;
  final String? artist;
  final String? album;
  final int? year;
}

/// [TrackRow] plus what only a detail read has.
class TrackDetail {
  const TrackDetail({
    required this.row,
    this.genre,
    this.language,
    this.durationMs,
  });

  final TrackRow row;
  final String? genre;
  final String? language;
  final int? durationMs;
}

/// Track lookups and search over the library.
abstract interface class LibraryPort {
  /// Splits [ids] into visible tracks and absent ids, in input order, each id
  /// once.
  Future<({List<TrackRow> visible, List<int> absent})> visibleOf(List<int> ids);

  /// Visible tracks matching [query], best first; `total` counts all matches.
  Future<({List<TrackRow> rows, int total})> search(
    String query, {
    required int offset,
    required int limit,
  });

  /// Detail of the visible tracks among [ids] (genre, language, duration) and
  /// the absent ids.
  Future<({List<TrackDetail> found, List<int> absent})> details(List<int> ids);
}

/// What is loaded in the player.
class NowPlayingSnapshot {
  const NowPlayingSnapshot({
    required this.trackId,
    required this.playing,
    required this.index,
    required this.length,
    required this.positionMs,
    required this.durationMs,
  });

  /// Nothing loaded.
  static const none = NowPlayingSnapshot(
    trackId: null,
    playing: false,
    index: null,
    length: 0,
    positionMs: 0,
    durationMs: null,
  );

  final int? trackId;
  final bool playing;
  final int? index;
  final int length;
  final int positionMs;
  final int? durationMs;
}

/// One queue entry; [entryId] identifies it (the same track can be queued
/// twice).
class QueueEntryRef {
  const QueueEntryRef({required this.entryId, required this.trackId});

  final int entryId;
  final int trackId;
}

/// The queue in play order.
class QueueSnapshot {
  const QueueSnapshot({this.items = const [], this.current});

  final List<QueueEntryRef> items;

  /// Index of the loaded entry in [items], or null.
  final int? current;
}

abstract interface class PlaybackPort {
  Future<NowPlayingSnapshot> nowPlaying();
  Future<QueueSnapshot> queue();
}

/// The lyrics a track has, without ever starting an online lookup.
sealed class LyricsRead {
  const LyricsRead();
}

class LyricsFound extends LyricsRead {
  const LyricsFound({required this.lines, required this.synced});

  /// Text of each line, in order (blank lines kept as empty strings).
  final List<String> lines;
  final bool synced;
}

/// No lyrics to give: [reason] is a short English phrase for the model.
class LyricsAbsent extends LyricsRead {
  const LyricsAbsent(this.reason);

  final String reason;
}

abstract interface class LyricsPort {
  Future<LyricsRead> read(int trackId);
}

/// Time ranges of the listening stats.
enum StatsRange {
  today('today'),
  days7('7d'),
  days30('30d'),
  months6('6m'),
  year('1y'),
  all('all');

  const StatsRange(this.wire);

  final String wire;

  static StatsRange? fromWire(String wire) {
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}

class StatsRow {
  const StatsRow({
    required this.rank,
    required this.track,
    required this.plays,
  });

  final int rank;
  final TrackRow track;
  final int plays;
}

abstract interface class HistoryPort {
  /// Whether the user records listening history at all.
  Future<bool> isRecording();

  /// Most played visible songs of [range], starting after [offset] rows, at
  /// most [limit]; `songs` and `plays` are the totals of the whole range.
  Future<({List<StatsRow> rows, int songs, int plays})> mostPlayed(
    StatsRange range, {
    required int offset,
    required int limit,
  });
}

class PlaylistRow {
  const PlaylistRow({
    required this.id,
    required this.name,
    required this.trackCount,
  });

  final int id;
  final String name;
  final int trackCount;
}

/// One playlist entry with its visible track.
class PlaylistEntryRow {
  const PlaylistEntryRow({required this.entryId, required this.track});

  final int entryId;
  final TrackRow track;
}

abstract interface class PlaylistsPort {
  /// Favorites (id 0) then the user playlists; saved queues and mood
  /// playlists are not listed.
  Future<List<PlaylistRow>> list();

  /// The entries of playlist [id] whose track is visible; null when no such
  /// writable playlist exists.
  Future<({String name, List<PlaylistEntryRow> entries})?> entries(int id);
}

/// The set of ports one tool run may use.
class ToolEnv {
  const ToolEnv({
    required this.library,
    required this.playback,
    required this.lyrics,
    required this.history,
    required this.playlists,
  });

  final LibraryPort library;
  final PlaybackPort playback;
  final LyricsPort lyrics;
  final HistoryPort history;
  final PlaylistsPort playlists;
}
