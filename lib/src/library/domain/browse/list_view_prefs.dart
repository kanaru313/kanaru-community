import 'list_sort.dart';

/// Grid or list layout of a collection.
enum CollectionView { grid, list }

/// Folder tree or every folder in one flat list.
enum FolderView { tree, flat }

/// Sort and layout remembered for one list.
class ListViewPrefs {
  const ListViewPrefs({required this.sort, required this.view});

  /// Defaults of [list]: its default sort; albums as a grid, every other list
  /// as rows (mobile first; one default for both shells).
  factory ListViewPrefs.defaultsOf(BrowseList list) => ListViewPrefs(
    sort: defaultSortOf(list),
    view: list == BrowseList.albums ? CollectionView.grid : CollectionView.list,
  );

  final SortSpec sort;
  final CollectionView view;

  ListViewPrefs copyWith({SortSpec? sort, CollectionView? view}) =>
      ListViewPrefs(sort: sort ?? this.sort, view: view ?? this.view);

  @override
  bool operator ==(Object other) =>
      other is ListViewPrefs && other.sort == sort && other.view == view;

  @override
  int get hashCode => Object.hash(sort, view);
}

/// Remembered state of every list plus the folder tab's layout.
class LibraryListViews {
  LibraryListViews({
    Map<BrowseList, ListViewPrefs> lists = const {},
    this.folderView = FolderView.tree,
  }) : lists = Map.unmodifiable({
         for (final l in BrowseList.values)
           l: lists[l] ?? ListViewPrefs.defaultsOf(l),
       });

  /// Prefs of every [BrowseList] (defaults fill the gaps).
  final Map<BrowseList, ListViewPrefs> lists;
  final FolderView folderView;

  ListViewPrefs of(BrowseList list) => lists[list]!;

  LibraryListViews withList(BrowseList list, ListViewPrefs prefs) =>
      LibraryListViews(lists: {...lists, list: prefs}, folderView: folderView);

  LibraryListViews withFolderView(FolderView view) =>
      LibraryListViews(lists: lists, folderView: view);

  /// JSON form: `{"lists": {<list>: {"sort", "desc", "view"}}, "folderView"}`.
  Object toJson() => {
    'lists': {
      for (final e in lists.entries)
        e.key.name: {
          'sort': e.value.sort.criterion.name,
          'desc': e.value.sort.descending,
          'view': e.value.view.name,
        },
    },
    'folderView': folderView.name,
  };

  /// Reads [toJson] output. Unknown lists, criteria (also ones the list does
  /// not offer) and views fall back to defaults. Throws [FormatException]
  /// when [json] is not a map.
  static LibraryListViews fromJson(Object? json) {
    if (json is! Map) throw const FormatException('list views: not a map');
    final raw = json['lists'];
    final lists = <BrowseList, ListViewPrefs>{};
    if (raw is Map) {
      for (final list in BrowseList.values) {
        final entry = raw[list.name];
        if (entry is Map) lists[list] = _prefsFrom(list, entry);
      }
    }
    return LibraryListViews(
      lists: lists,
      folderView:
          FolderView.values
              .where((v) => v.name == json['folderView'])
              .firstOrNull ??
          FolderView.tree,
    );
  }

  static ListViewPrefs _prefsFrom(BrowseList list, Map<Object?, Object?> m) {
    final base = ListViewPrefs.defaultsOf(list);
    final criterion = criteriaOf(list)
        .where((c) => c.name == m['sort'])
        .firstOrNull;
    final desc = m['desc'];
    return ListViewPrefs(
      sort: criterion == null
          ? base.sort
          : SortSpec(
              criterion,
              descending: desc is bool
                  ? desc
                  : criterion == base.sort.criterion && base.sort.descending,
            ),
      view:
          CollectionView.values.where((v) => v.name == m['view']).firstOrNull ??
          base.view,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryListViews &&
      other.folderView == folderView &&
      BrowseList.values.every((l) => other.lists[l] == lists[l]);

  @override
  int get hashCode => Object.hash(
    folderView,
    Object.hashAll([for (final l in BrowseList.values) lists[l]]),
  );
}
