import '../../../media/domain/track_id.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/sort_order.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_sort.dart';
import '../../domain/playlists/playlist_text_rules.dart';

/// Pure logic of the "add to playlist" picker: rows, ticks, hits, the plan the
/// caller writes and the numbers of the toast. No Flutter, no I/O.

const _pendingPrefix = 'new:';

/// Option key of the [n]-th playlist typed in the picker, not created yet.
String pendingKey(int n) => '$_pendingPrefix$n';

/// Whether [key] names a playlist that does not exist yet.
bool isPendingKey(String key) => key.startsWith(_pendingPrefix);

/// One playlist row: [has] is how many distinct batch songs it already holds.
class PlaylistRow {
  const PlaylistRow({
    required this.summary,
    required this.has,
    required this.favorites,
  });

  final PlaylistSummary summary;
  final int has;
  final bool favorites;
}

/// Rows of the picker: [pinned] (Favorites, above the divider) and [rows]
/// (newest modified first).
typedef PickerRows = ({PlaylistRow? pinned, List<PlaylistRow> rows});

/// Builds the rows. [counts] maps a playlist uid to the batch songs it holds
/// (missing = 0). [excludeUid] (the playlist the songs come from) is hidden;
/// Favorites is not pinned when it is the excluded one.
PickerRows buildPickerRows({
  required List<PlaylistSummary> playlists,
  required PlaylistSummary favorites,
  required Map<String, int> counts,
  String? excludeUid,
}) {
  PlaylistRow row(PlaylistSummary s, {required bool isFavorites}) =>
      PlaylistRow(summary: s, has: counts[s.uid] ?? 0, favorites: isFavorites);

  final sorted = sortPlaylists(
    playlists,
    SortOrder.by(SortCriterion.dateModified, descending: true),
  );
  return (
    pinned: excludeUid == PlaylistUids.favorites
        ? null
        : row(favorites, isFavorites: true),
    rows: [
      for (final p in sorted)
        if (p.uid != excludeUid) row(p, isFavorites: false),
    ],
  );
}

/// The filter field shows above 10 playlists (Favorites not counted).
bool showFilter(int playlistCount) => playlistCount > 10;

/// Distinct songs of [tracks] (repeats of a queue count once).
int distinctCount(Iterable<TrackId> tracks) => tracks.toSet().length;

/// What a row's subtitle says about songs it already holds.
sealed class RowHint {
  const RowHint();
}

/// Holds none of the batch.
class NoHint extends RowHint {
  const NoHint();
}

/// The batch is one song and the playlist holds it.
class HasThisHint extends RowHint {
  const HasThisHint();
}

/// Holds [has] of the [of] distinct batch songs.
class HasSomeHint extends RowHint {
  const HasSomeHint(this.has, this.of);

  final int has;
  final int of;

  @override
  bool operator ==(Object other) =>
      other is HasSomeHint && other.has == has && other.of == of;

  @override
  int get hashCode => Object.hash(has, of);
}

/// Hint of [row] for a batch of [distinct] songs.
RowHint rowHint(PlaylistRow row, int distinct) {
  if (row.has <= 0) return const NoHint();
  if (distinct == 1) return const HasThisHint();
  return HasSomeHint(row.has, distinct);
}

/// Ticks that still point at a live target: pending keys and deleted
/// playlists are dropped; Favorites is always live.
Set<String> liveTicked(Set<String> selected, Iterable<String> liveUids) {
  final live = liveUids.toSet();
  return {
    for (final k in selected)
      if (!isPendingKey(k) && (k == PlaylistUids.favorites || live.contains(k)))
        k,
  };
}

/// A ticked playlist that already holds [has] batch songs.
typedef AffectedPlaylist = ({String uid, String name, int has});

/// Ticked playlists that hold at least one batch song, in tick order.
/// Favorites never counts: it always skips what it holds, without asking.
List<AffectedPlaylist> affected(
  Set<String> liveTicked,
  Map<String, int> counts,
  Map<String, String> names,
) => [
  for (final uid in liveTicked)
    if (uid != PlaylistUids.favorites && (counts[uid] ?? 0) > 0)
      (uid: uid, name: names[uid] ?? '', has: counts[uid]!),
];

/// Sum of the songs already held over [list].
int heldTotal(List<AffectedPlaylist> list) =>
    list.fold(0, (sum, a) => sum + a.has);

/// What to write: existing targets, names of new playlists (typed order) and
/// how to treat songs a target already holds.
class AddPlan {
  AddPlan({
    required List<String> playlistUids,
    required List<String> newNames,
    required this.policy,
  }) : playlistUids = List.unmodifiable(playlistUids),
       newNames = List.unmodifiable(newNames);

  final List<String> playlistUids;
  final List<String> newNames;
  final DuplicatePolicy policy;
}

/// The plan for the ticked keys [selected], or null when no live playlist and
/// no pending one is ticked. [pendingNames] maps a pending key to its name in
/// typed order (cleaned here; the caller validates them, e.g. the name
/// dialog); [policy] is the user's answer (default: skip existing).
AddPlan? buildPlan({
  required Set<String> selected,
  required Iterable<String> liveUids,
  required Map<String, String> pendingNames,
  DuplicatePolicy policy = DuplicatePolicy.skipExisting,
}) {
  final uids = liveTicked(selected, liveUids).toList();
  final names = [
    for (final e in pendingNames.entries)
      if (selected.contains(e.key)) cleanPlaylistName(e.value),
  ];
  if (uids.isEmpty && names.isEmpty) return null;
  return AddPlan(playlistUids: uids, newNames: names, policy: policy);
}

/// [base] when no name in [taken] equals it, else `numbered(i)` for the first
/// free `i >= 2`. Names compare after [cleanPlaylistName].
String nextDefaultName(
  String base,
  String Function(int) numbered,
  Iterable<String> taken,
) {
  final used = {for (final t in taken) cleanPlaylistName(t)};
  if (!used.contains(cleanPlaylistName(base))) return base;
  var i = 2;
  while (used.contains(cleanPlaylistName(numbered(i)))) {
    i++;
  }
  return numbered(i);
}

/// Numbers behind the toast. Songs are distinct (a song put in two playlists
/// counts once), as the store reports them.
class AddSummary {
  const AddSummary({
    required this.failed,
    required this.songs,
    required this.playlists,
    required this.singleName,
    required this.singleAdded,
    required this.singleSkipped,
    required this.created,
    required this.skipped,
    required this.moved,
    required this.dropped,
    required this.gone,
    required this.nothingNew,
  });

  /// No target was written (all gone, or none left).
  final bool failed;
  final int songs;
  final int playlists;

  /// Set when exactly one target was written.
  final String? singleName;
  final int singleAdded;
  final int singleSkipped;
  final int created;
  final int skipped;
  final int moved;

  /// Songs left out because they no longer exist in the library.
  final int dropped;
  final int gone;

  /// Targets were written but nothing was added or moved.
  final bool nothingNew;
}

/// Reads [r] into the numbers of the toast. [namesByUid] names existing
/// targets; [newNames] names the created ones in the order they were typed.
AddSummary summarize(
  AddToPlaylistsResult r, {
  required int dropped,
  required Map<String, String> namesByUid,
  required List<String> newNames,
}) {
  final outcomes = r.outcomes;
  String? singleName;
  if (outcomes.length == 1) {
    final o = outcomes.single;
    singleName = o.created
        ? (newNames.isEmpty ? '' : newNames.first)
        : (namesByUid[o.uid] ?? '');
  }
  return AddSummary(
    failed: outcomes.isEmpty,
    songs: r.addedTrackCount,
    playlists: outcomes.length,
    singleName: singleName,
    singleAdded: outcomes.length == 1 ? outcomes.single.added : 0,
    singleSkipped: outcomes.length == 1 ? outcomes.single.skipped : 0,
    created: outcomes.where((o) => o.created).length,
    skipped: r.skippedTrackCount,
    moved: outcomes.fold(0, (s, o) => s + o.movedToEnd),
    dropped: dropped,
    gone: r.goneUids.length,
    nothingNew:
        outcomes.isNotEmpty &&
        outcomes.fold(0, (s, o) => s + o.added) == 0 &&
        outcomes.fold(0, (s, o) => s + o.movedToEnd) == 0,
  );
}
