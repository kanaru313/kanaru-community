import 'list_sort.dart';
import 'sort_order.dart';

/// Grid or list layout of a collection.
enum CollectionView { grid, list }

/// Folder tree or every folder in one flat list.
enum FolderView { tree, flat }

/// Sort and layout remembered for one list.
class ListViewPrefs {
  const ListViewPrefs({required this.sort, required this.view});

  /// Defaults of [list]: its default sort; albums, genres, languages and
  /// playlists as a grid, every other list as rows (mobile first; one default for both
  /// shells).
  factory ListViewPrefs.defaultsOf(BrowseList list) => ListViewPrefs(
    sort: defaultSortOf(list),
    view:
        list == BrowseList.albums ||
            list == BrowseList.genres ||
            list == BrowseList.languages ||
            list == BrowseList.playlists
        ? CollectionView.grid
        : CollectionView.list,
  );

  final SortOrder sort;
  final CollectionView view;

  ListViewPrefs copyWith({SortOrder? sort, CollectionView? view}) =>
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

  /// JSON form: `{"lists": {list name: {"sort": [{"by", "desc"}, ...], "view"}},
  /// "folderView"}`.
  Object toJson() => {
    'lists': {
      for (final e in lists.entries)
        e.key.name: {
          'sort': sortOrderToJson(e.value.sort),
          'view': e.value.view.name,
        },
    },
    'folderView': folderView.name,
  };

  /// Reads [toJson] output and the older single-criterion form
  /// (`"sort": "year", "desc": true`). Unknown lists, criteria (also ones the list does
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
    return ListViewPrefs(
      sort: _sortFrom(list, m, base.sort),
      view:
          CollectionView.values.where((v) => v.name == m['view']).firstOrNull ??
          base.view,
    );
  }

  /// Never throws: an entry that is not understood is skipped, and a list
  /// with no usable criterion gets [base].
  static SortOrder _sortFrom(
    BrowseList list,
    Map<Object?, Object?> m,
    SortOrder base,
  ) {
    final raw = m['sort'];
    if (raw is List) return sortOrderFromJson(list, raw, fallback: base);
    final c = criteriaOf(list).where((c) => c.name == raw).firstOrNull;
    if (c == null) return base;
    final desc = m['desc'];
    return SortOrder.single(
      SortSpec(
        c,
        descending: desc is bool
            ? desc
            : c == base.primary.criterion && base.primary.descending,
      ),
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

/// JSON form of [order]: `[{"by": criterion name, "desc": bool}, ...]`.
List<Map<String, Object>> sortOrderToJson(SortOrder order) => [
  for (final s in order.specs) {'by': s.criterion.name, 'desc': s.descending},
];

/// Reads [sortOrderToJson] output for [list]. Never throws: entries that are
/// not understood, criteria [list] does not offer and repeats are dropped; no
/// usable entry (or a [json] that is not a list) gives [fallback].
SortOrder sortOrderFromJson(
  BrowseList list,
  Object? json, {
  required SortOrder fallback,
}) {
  if (json is! List) return fallback;
  final offered = criteriaOf(list);
  final specs = <SortSpec>[];
  for (final e in json) {
    if (e is! Map) continue;
    final c = offered.where((c) => c.name == e['by']).firstOrNull;
    if (c == null) continue;
    final desc = e['desc'];
    specs.add(SortSpec(c, descending: desc is bool && desc));
  }
  return SortOrder.normalized(specs, offered, fallback: fallback);
}
