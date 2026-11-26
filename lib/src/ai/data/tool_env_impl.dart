import '../../library/domain/history/history_ranges.dart';
import '../../library/domain/history/history_store.dart';
import '../../library/domain/playlists/playlist_store.dart';
import '../../library/domain/search/track_hit.dart';
import '../../library/domain/search/track_lookup.dart';
import '../../library/domain/search/track_search.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../domain/tools/tool_env.dart';

TrackRow _row(TrackHit t) => TrackRow(
  id: t.id.value,
  title: t.title,
  artist: t.artist,
  album: t.album,
  year: t.year,
);

/// [LibraryPort] over the shared search and lookup backends. Ids that are
/// hidden, missing, remote or duplicate-hidden come back absent.
class LibraryPortImpl implements LibraryPort {
  LibraryPortImpl({
    required this.trackSearch,
    required this.trackLookup,
    required this.trackInfo,
  });

  final TrackSearch trackSearch;
  final TrackLookup trackLookup;
  final Future<TrackInfo?> Function(TrackId id) trackInfo;

  @override
  Future<({List<TrackRow> visible, List<int> absent})> visibleOf(
    List<int> ids,
  ) async {
    final r = await trackLookup.visibleOf(ids);
    return (visible: [for (final t in r.visible) _row(t)], absent: r.absent);
  }

  @override
  Future<({List<TrackRow> rows, int total})> search(
    String query, {
    required int offset,
    required int limit,
  }) async {
    final r = await trackSearch.searchTracks(
      query,
      offset: offset,
      limit: limit,
    );
    return (rows: [for (final t in r.rows) _row(t)], total: r.total);
  }

  @override
  Future<({List<TrackDetail> found, List<int> absent})> details(
    List<int> ids,
  ) async {
    final r = await trackLookup.visibleOf(ids);
    final found = <TrackDetail>[];
    final absent = [...r.absent];
    // `TrackHit` has no genre, language or length, and there is no batch
    // read: one query per id (at most 50).
    for (final hit in r.visible) {
      final info = await trackInfo(hit.id);
      if (info == null) {
        absent.add(hit.id.value);
        continue;
      }
      found.add(
        TrackDetail(
          row: _row(hit),
          genre: info.genre,
          language: info.language,
          durationMs: info.durationMs,
        ),
      );
    }
    return (found: found, absent: absent);
  }
}

/// [PlaylistsPort] over the playlist store. Entries whose track is not
/// visible are left out, like everywhere a track id reaches the model.
class PlaylistsPortImpl implements PlaylistsPort {
  PlaylistsPortImpl({required this.store, required this.lookup});

  final PlaylistStore store;
  final TrackLookup lookup;

  @override
  Future<List<PlaylistRow>> list() async {
    final writable = await store.listWritable();
    final summaries = await store.watchSummaries().first;
    final counts = {
      summaries.favorites.uid: summaries.favorites.trackCount,
      for (final p in summaries.playlists) p.uid: p.trackCount,
    };
    return [
      for (final p in writable)
        PlaylistRow(id: p.id, name: p.name, trackCount: counts[p.uid] ?? 0),
    ];
  }

  @override
  Future<({String name, List<PlaylistEntryRow> entries})?> entries(
    int id,
  ) async {
    final uid = (await store.resolvePlaylistIds([id]))[id];
    if (uid == null) return null;
    final detail = await store.loadPlaylist(uid);
    if (detail == null) return null;
    final visible = await lookup.visibleOf([
      for (final e in detail.entries) e.info.id.value,
    ]);
    final byId = {for (final t in visible.visible) t.id.value: t};
    return (
      name: detail.summary.name,
      entries: [
        for (final e in detail.entries)
          if (byId[e.info.id.value] case final hit?)
            PlaylistEntryRow(entryId: e.id, track: _row(hit)),
      ],
    );
  }
}

/// [HistoryPort] over the history store.
class HistoryPortImpl implements HistoryPort {
  HistoryPortImpl({
    required this.store,
    required this.lookup,
    required this.enabled,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HistoryStore store;
  final TrackLookup lookup;
  final Future<bool> Function() enabled;
  final DateTime Function() _now;

  @override
  Future<bool> isRecording() => enabled();

  @override
  Future<({List<StatsRow> rows, int songs, int plays})> mostPlayed(
    StatsRange range, {
    required int offset,
    required int limit,
  }) async {
    final preset = switch (range) {
      StatsRange.today => MostPlayedPreset.today,
      StatsRange.days7 => MostPlayedPreset.days7,
      StatsRange.days30 => MostPlayedPreset.days30,
      StatsRange.months6 => MostPlayedPreset.months6,
      StatsRange.year => MostPlayedPreset.year,
      StatsRange.all => MostPlayedPreset.all,
    };
    final window = MostPlayedRange(preset: preset).window(_now());
    // The store's list and its totals count hidden and missing songs, which
    // must not reach the model: read the longest list the store gives, keep
    // the visible rows and total those. Past that length (1000 songs) the
    // totals cover the visible part of the top list only.
    final top = await store.top(window: window, limit: maxMostPlayedLimit);
    final visible = await lookup.visibleOf([
      for (final e in top.entries) e.track.id.value,
    ]);
    final byId = {for (final t in visible.visible) t.id.value: t};
    final rows = <StatsRow>[
      for (final e in top.entries)
        if (byId[e.track.id.value] case final hit?)
          StatsRow(rank: e.rank, track: _row(hit), plays: e.count),
    ];
    return (
      rows: rows.skip(offset).take(limit).toList(),
      songs: rows.length,
      plays: rows.fold(0, (sum, r) => sum + r.plays),
    );
  }
}
