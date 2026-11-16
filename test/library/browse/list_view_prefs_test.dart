import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';

void main() {
  test('defaults cover every list', () {
    final v = LibraryListViews();
    for (final l in BrowseList.values) {
      expect(v.of(l).sort, defaultSortOf(l));
    }
    expect(v.of(BrowseList.albums).view, CollectionView.grid);
    expect(v.of(BrowseList.genres).view, CollectionView.grid);
    expect(v.of(BrowseList.languages).view, CollectionView.list);
    expect(v.of(BrowseList.artists).view, CollectionView.list);
    expect(v.of(BrowseList.songs).view, CollectionView.list);
    expect(v.folderView, FolderView.tree);
  });

  test('json round trip', () {
    final v = LibraryListViews()
        .withList(
          BrowseList.songs,
          ListViewPrefs(
            sort: SortOrder.by(SortCriterion.year, descending: true),
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
    expect(v.of(BrowseList.languages).sort.primary.descending, isTrue);
    expect(v.of(BrowseList.detailSongs).sort.primary.descending, isTrue);
    expect(v.of(BrowseList.songs).sort, SortOrder.by(SortCriterion.year));
  });

  test('non-map input throws FormatException', () {
    expect(() => LibraryListViews.fromJson(null), throwsFormatException);
    expect(() => LibraryListViews.fromJson([]), throwsFormatException);
  });

  test('empty map gives defaults', () {
    expect(LibraryListViews.fromJson(const {}), LibraryListViews());
  });

  group('sort json', () {
    Map<String, Object?> one(BrowseList l, Map<String, Object?> entry) => {
      'lists': {l.name: entry},
    };
    SortOrder read(BrowseList l, Map<String, Object?> entry) =>
        LibraryListViews.fromJson(one(l, entry)).of(l).sort;

    test('writes the list form only', () {
      final v = LibraryListViews().withList(
        BrowseList.songs,
        ListViewPrefs(
          sort: SortOrder([
            const SortSpec(SortCriterion.artist),
            const SortSpec(SortCriterion.year, descending: true),
          ]),
          view: CollectionView.list,
        ),
      );
      final songs = ((v.toJson() as Map)['lists'] as Map)['songs'] as Map;
      expect(songs['sort'], [
        {'by': 'artist', 'desc': false},
        {'by': 'year', 'desc': true},
      ]);
      expect(songs.containsKey('desc'), isFalse);
    });

    test('several criteria round trip', () {
      final v = LibraryListViews().withList(
        BrowseList.albums,
        ListViewPrefs(
          sort: SortOrder([
            const SortSpec(SortCriterion.artist, descending: true),
            const SortSpec(SortCriterion.year),
            const SortSpec(SortCriterion.trackCount, descending: true),
          ]),
          view: CollectionView.list,
        ),
      );
      expect(LibraryListViews.fromJson(v.toJson()), v);
    });

    test('reads the old single-criterion form', () {
      expect(
        read(BrowseList.songs, {'sort': 'year', 'desc': true}),
        SortOrder.by(SortCriterion.year, descending: true),
      );
      expect(
        read(BrowseList.songs, {'sort': 'year'}),
        SortOrder.by(SortCriterion.year),
      );
      expect(
        read(BrowseList.songs, {'sort': 'nope', 'desc': true}),
        defaultSortOf(BrowseList.songs),
      );
    });

    test('garbage entries are skipped without throwing', () {
      expect(
        read(BrowseList.songs, {
          'sort': [
            1,
            null,
            {'by': 5},
            {'by': 'year', 'desc': 'x'},
          ],
        }),
        SortOrder.by(SortCriterion.year),
      );
      expect(
        read(BrowseList.songs, {'sort': {}}),
        defaultSortOf(BrowseList.songs),
      );
      expect(
        read(BrowseList.songs, {'sort': []}),
        defaultSortOf(BrowseList.songs),
      );
      expect(
        read(BrowseList.languages, {
          'sort': [1, 2],
        }),
        defaultSortOf(BrowseList.languages),
      );
    });

    test('duplicates and not offered criteria are dropped', () {
      expect(
        read(BrowseList.albums, {
          'sort': [
            {'by': 'artist', 'desc': true},
            {'by': 'albumCount'},
            {'by': 'artist'},
            {'by': 'year'},
          ],
        }).specs,
        [
          const SortSpec(SortCriterion.artist, descending: true),
          const SortSpec(SortCriterion.year),
        ],
      );
    });

    test('a bad list does not touch the others, view survives', () {
      final v = LibraryListViews.fromJson({
        'lists': {
          'songs': {'sort': 'year', 'desc': true, 'view': 'grid'},
          'albums': {
            'sort': [
              {'by': 'year', 'desc': true},
            ],
            'view': 'list',
          },
          'artists': {
            'sort': [7],
            'view': 'grid',
          },
        },
      });
      expect(
        v.of(BrowseList.songs).sort,
        SortOrder.by(SortCriterion.year, descending: true),
      );
      expect(v.of(BrowseList.songs).view, CollectionView.grid);
      expect(
        v.of(BrowseList.albums).sort,
        SortOrder.by(SortCriterion.year, descending: true),
      );
      expect(v.of(BrowseList.artists).sort, defaultSortOf(BrowseList.artists));
      expect(v.of(BrowseList.artists).view, CollectionView.grid);
    });
  });
}
