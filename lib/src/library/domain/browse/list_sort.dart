/// The lists that have their own sort criteria and remembered view.
enum BrowseList {
  songs,
  albums,
  artists,
  genres,
  languages,
  folders,
  albumTracks,
  detailSongs,
  playlists,
  playlistTracks,
}

/// What a list can be ordered by. Which criteria a list offers is
/// [criteriaOf].
enum SortCriterion {
  title(SortKind.text),
  artist(SortKind.text),
  album(SortKind.text),
  year(SortKind.date),
  dateAdded(SortKind.date),
  playCount(SortKind.number),
  duration(SortKind.number),
  trackCount(SortKind.number),
  albumCount(SortKind.number),
  trackNumber(SortKind.number),
  name(SortKind.text),
  dateModified(SortKind.date),
  playlistOrder(SortKind.position);

  const SortCriterion(this.kind);

  /// Words of its direction: text "A → Z / Z → A", number "Tăng dần /
  /// Giảm dần", date "Cũ trước / Mới trước"; dates are added newest first.
  final SortKind kind;
}

/// What kind of value a [SortCriterion] orders by.
/// [position] is the order of a hand-arranged list ("First → last").
enum SortKind { text, number, date, position }

/// A criterion and its direction.
class SortSpec {
  const SortSpec(this.criterion, {this.descending = false});

  final SortCriterion criterion;
  final bool descending;

  SortSpec withDirection({required bool descending}) =>
      SortSpec(criterion, descending: descending);

  @override
  bool operator ==(Object other) =>
      other is SortSpec &&
      other.criterion == criterion &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(criterion, descending);

  @override
  String toString() => 'SortSpec(${criterion.name}, desc: $descending)';
}

const _songCriteria = [
  SortCriterion.title,
  SortCriterion.artist,
  SortCriterion.album,
  SortCriterion.year,
  SortCriterion.dateAdded,
  SortCriterion.playCount,
  SortCriterion.duration,
];

/// Criteria of [list] in menu order; the first one is the default.
List<SortCriterion> criteriaOf(BrowseList list) => switch (list) {
  BrowseList.songs => _songCriteria,
  BrowseList.albums => const [
    SortCriterion.title,
    SortCriterion.artist,
    SortCriterion.year,
    SortCriterion.dateAdded,
    SortCriterion.trackCount,
  ],
  BrowseList.artists => const [
    SortCriterion.title,
    SortCriterion.trackCount,
    SortCriterion.albumCount,
  ],
  BrowseList.genres => const [SortCriterion.title, SortCriterion.trackCount],
  BrowseList.languages => const [SortCriterion.trackCount, SortCriterion.title],
  BrowseList.folders => const [SortCriterion.title, SortCriterion.trackCount],
  BrowseList.albumTracks => const [
    SortCriterion.trackNumber,
    SortCriterion.title,
    SortCriterion.duration,
    SortCriterion.playCount,
  ],
  BrowseList.detailSongs => const [
    SortCriterion.playCount,
    SortCriterion.title,
    SortCriterion.artist,
    SortCriterion.album,
    SortCriterion.year,
    SortCriterion.duration,
  ],
  BrowseList.playlists => const [
    SortCriterion.dateModified,
    SortCriterion.name,
  ],
  BrowseList.playlistTracks => const [
    SortCriterion.playlistOrder,
    SortCriterion.title,
    SortCriterion.artist,
    SortCriterion.album,
    SortCriterion.duration,
    SortCriterion.playCount,
  ],
};
