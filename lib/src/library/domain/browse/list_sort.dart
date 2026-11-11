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
}

/// What a list can be ordered by. Which criteria a list offers is
/// [criteriaOf].
enum SortCriterion {
  title(isNumeric: false),
  artist(isNumeric: false),
  album(isNumeric: false),
  year(isNumeric: true),
  dateAdded(isNumeric: true),
  playCount(isNumeric: true),
  duration(isNumeric: true),
  trackCount(isNumeric: true),
  albumCount(isNumeric: true),
  trackNumber(isNumeric: true);

  const SortCriterion({required this.isNumeric});

  /// Numeric criteria read "Tăng dần/Giảm dần", text ones "A → Z / Z → A".
  final bool isNumeric;
}

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
};

/// The first criterion of [list], ascending, except where the biggest comes
/// first: songs on a detail page start with the most played and languages with
/// the largest one.
SortSpec defaultSortOf(BrowseList list) => SortSpec(
  criteriaOf(list).first,
  descending: list == BrowseList.detailSongs || list == BrowseList.languages,
);
