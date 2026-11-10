import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';

void main() {
  test('defaults cover every list', () {
    final v = LibraryListViews();
    for (final l in BrowseList.values) {
      expect(v.of(l).sort, defaultSortOf(l));
    }
    expect(v.of(BrowseList.albums).view, CollectionView.grid);
    expect(v.of(BrowseList.artists).view, CollectionView.list);
    expect(v.of(BrowseList.songs).view, CollectionView.list);
    expect(v.folderView, FolderView.tree);
  });

  test('json round trip', () {
    final v = LibraryListViews()
        .withList(
          BrowseList.songs,
          const ListViewPrefs(
            sort: SortSpec(SortCriterion.year, descending: true),
            view: CollectionView.grid,
          ),
        )
        .withFolderView(FolderView.flat);
    expect(LibraryListViews.fromJson(v.toJson()), v);
  });

  test('unknown values fall back to defaults', () {
    final v = LibraryListViews.fromJson({
      'lists': {
        'songs': {'sort': 'nope', 'desc': true, 'view': 'cube'},
        // albumCount is not an albums criterion.
        'albums': {'sort': 'albumCount', 'view': 'list'},
        'bogus': {'sort': 'title'},
        'genres': 7,
      },
      'folderView': 'spiral',
    });
    expect(v.of(BrowseList.songs), ListViewPrefs.defaultsOf(BrowseList.songs));
    expect(v.of(BrowseList.albums).sort, defaultSortOf(BrowseList.albums));
    expect(v.of(BrowseList.albums).view, CollectionView.list);
    expect(
      v.of(BrowseList.genres),
      ListViewPrefs.defaultsOf(BrowseList.genres),
    );
    expect(v.folderView, FolderView.tree);
  });

  test('missing desc keeps the default direction of the default sort', () {
    final v = LibraryListViews.fromJson({
      'lists': {
        'detailSongs': {'sort': 'playCount'},
        'songs': {'sort': 'year'},
        'languages': {'sort': 'trackCount'},
      },
    });
    expect(v.of(BrowseList.languages).sort.descending, isTrue);
    expect(v.of(BrowseList.detailSongs).sort.descending, isTrue);
    expect(v.of(BrowseList.songs).sort, const SortSpec(SortCriterion.year));
  });

  test('non-map input throws FormatException', () {
    expect(() => LibraryListViews.fromJson(null), throwsFormatException);
    expect(() => LibraryListViews.fromJson([]), throwsFormatException);
  });

  test('empty map gives defaults', () {
    expect(LibraryListViews.fromJson(const {}), LibraryListViews());
  });
}
