import '../../domain/playlists/playlist_models.dart';

/// Pure edits of the entry list that mirror what a write is expected to do,
/// so the page can show the result before the database answers. The settled
/// read replaces them, so a mismatch only shows until the write ends.
typedef DetailEdit = PlaylistDetail Function(PlaylistDetail detail);

PlaylistDetail _withEntries(
  PlaylistDetail d,
  List<PlaylistEntryView> entries,
) => PlaylistDetail(summary: d.summary, entries: entries);

/// Moves [entryUid] behind [afterEntryUid] (null: to the top). Unchanged when
/// either entry is not shown.
DetailEdit moveEdit(String entryUid, String? afterEntryUid) => (d) {
  if (entryUid == afterEntryUid) return d;
  final entries = [...d.entries];
  final from = entries.indexWhere((e) => e.uid == entryUid);
  if (from < 0) return d;
  final moving = entries.removeAt(from);
  var to = 0;
  if (afterEntryUid != null) {
    final after = entries.indexWhere((e) => e.uid == afterEntryUid);
    if (after < 0) return d;
    to = after + 1;
  }
  entries.insert(to, moving);
  return _withEntries(d, entries);
};

/// Drops the entries in [uids].
DetailEdit removeEdit(Set<String> uids) =>
    (d) => _withEntries(d, [
      for (final e in d.entries)
        if (!uids.contains(e.uid)) e,
    ]);

/// Keeps the first entry of every track.
PlaylistDetail removeDuplicatesEdit(PlaylistDetail d) {
  final seen = <int>{};
  return _withEntries(d, [
    for (final e in d.entries)
      if (seen.add(e.info.id.value)) e,
  ]);
}
