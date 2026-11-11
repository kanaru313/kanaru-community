import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';

void main() {
  const c = SortCriterion.values;
  final expected = <BrowseList, List<SortCriterion>>{
    BrowseList.songs: [
      c[0], // title
      SortCriterion.artist,
      SortCriterion.album,
      SortCriterion.year,
      SortCriterion.dateAdded,
      SortCriterion.playCount,
      SortCriterion.duration,
    ],
    BrowseList.albums: [
      SortCriterion.title,
      SortCriterion.artist,
      SortCriterion.year,
      SortCriterion.dateAdded,
      SortCriterion.trackCount,
    ],
    BrowseList.artists: [
      SortCriterion.title,
      SortCriterion.trackCount,
      SortCriterion.albumCount,
    ],
    BrowseList.genres: [SortCriterion.title, SortCriterion.trackCount],
    BrowseList.languages: [SortCriterion.trackCount, SortCriterion.title],
    BrowseList.folders: [SortCriterion.title, SortCriterion.trackCount],
    BrowseList.albumTracks: [
      SortCriterion.trackNumber,
      SortCriterion.title,
      SortCriterion.duration,
      SortCriterion.playCount,
    ],
    BrowseList.detailSongs: [
      SortCriterion.playCount,
      SortCriterion.title,
      SortCriterion.artist,
      SortCriterion.album,
      SortCriterion.year,
      SortCriterion.duration,
    ],
  };

  test('criteria per list match the mockup, first is default', () {
    expect(expected.keys.toSet(), BrowseList.values.toSet());
    for (final e in expected.entries) {
      expect(criteriaOf(e.key), e.value, reason: e.key.name);
      expect(defaultSortOf(e.key).criterion, e.value.first);
    }
  });

  test('detail songs and languages default to descending', () {
    for (final l in BrowseList.values) {
      expect(
        defaultSortOf(l).descending,
        l == BrowseList.detailSongs || l == BrowseList.languages,
        reason: l.name,
      );
    }
    expect(
      defaultSortOf(BrowseList.detailSongs),
      const SortSpec(SortCriterion.playCount, descending: true),
    );
  });

  test('numeric criteria', () {
    expect(SortCriterion.title.isNumeric, isFalse);
    expect(SortCriterion.artist.isNumeric, isFalse);
    expect(SortCriterion.album.isNumeric, isFalse);
    for (final n in SortCriterion.values.where(
      (x) => x.index > SortCriterion.album.index,
    )) {
      expect(n.isNumeric, isTrue, reason: n.name);
    }
  });

  test('SortSpec equality', () {
    const a = SortSpec(SortCriterion.year, descending: true);
    expect(a, const SortSpec(SortCriterion.year, descending: true));
    expect(
      a.hashCode,
      const SortSpec(SortCriterion.year, descending: true).hashCode,
    );
    expect(a == const SortSpec(SortCriterion.year), isFalse);
    expect(
      a.withDirection(descending: false),
      const SortSpec(SortCriterion.year),
    );
  });
}
