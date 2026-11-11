import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/browse/folder_tree.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../domain/browse/natural_compare.dart';
import '../../state/browse/folder_providers.dart';
import '../../../foundation/text/text_fold.dart';
import 'folder_locations.dart';

/// What the Folders page shows for a [FolderLocation] and the folder trees.
sealed class FolderPlace {
  const FolderPlace();

  /// Where Back goes from here inside the tab; null at the top of the tab.
  FolderLocation? get parent;
}

/// There is no music folder (yet).
final class NoFoldersPlace extends FolderPlace {
  const NoFoldersPlace();

  @override
  FolderLocation? get parent => null;
}

/// The top with several music folders: one row per music folder.
final class RootsPlace extends FolderPlace {
  const RootsPlace(this.roots);

  final List<FolderRoot> roots;

  @override
  FolderLocation? get parent => null;
}

/// A folder of the tree view; [root] is the music folder it belongs to and
/// [multiRoot] whether the top is the list of music folders.
final class LevelPlace extends FolderPlace {
  const LevelPlace(
    this.root,
    this.node, {
    required this.multiRoot,
    this.compact = true,
  });

  final FolderRoot root;
  final FolderNode node;
  final bool multiRoot;

  /// Single-subfolder chains are merged into one row, so Back does not stop
  /// at a folder that no row ever opens.
  final bool compact;

  String get sourceUid => root.folder.sourceUid;

  @override
  FolderLocation? get parent {
    if (node.key.isEmpty) return multiRoot ? FolderLocation.top : null;
    var key = _parentKey(node.key);
    while (compact && key.isNotEmpty) {
      final up = root.nodeAt(key);
      // A folder with no files and one subfolder is a link of a chain.
      if (up == null || up.directSongs > 0 || up.children.length != 1) break;
      key = _parentKey(key);
    }
    return FolderLocation(sourceUid: sourceUid, key: key);
  }
}

String _parentKey(String key) {
  final slash = key.lastIndexOf('/');
  return slash < 0 ? '' : key.substring(0, slash);
}

/// The flat view: every folder that holds songs of its own.
final class FlatListPlace extends FolderPlace {
  const FlatListPlace(this.folders);

  final List<FlatFolder> folders;

  @override
  FolderLocation? get parent => null;
}

/// One folder opened from the flat list: its direct songs only.
final class FlatOpenPlace extends FolderPlace {
  const FlatOpenPlace(this.root, this.node);

  final FolderRoot root;
  final FolderNode node;

  @override
  FolderLocation? get parent => FolderLocation.flatList;
}

/// Resolves [location] against [roots]. A folder that is gone (excluded, or
/// rescanned away) opens its nearest existing ancestor; an unknown music
/// folder is the top. The top is the flat list when [location] or [view] say
/// so, the only music folder when there is one, else the list of them.
FolderPlace resolveFolderPlace(
  List<FolderRoot> roots,
  FolderLocation location,
  FolderView view, {
  bool compact = true,
}) {
  if (roots.isEmpty) return const NoFoldersPlace();
  final uid = location.sourceUid;
  if (uid != null) {
    final root = roots.where((r) => r.folder.sourceUid == uid).firstOrNull;
    if (root != null) {
      var key = location.key;
      var node = root.nodeAt(key);
      while (node == null && key.isNotEmpty) {
        final slash = key.lastIndexOf('/');
        key = slash < 0 ? '' : key.substring(0, slash);
        node = root.nodeAt(key);
      }
      node ??= root.node;
      return location.flat
          ? FlatOpenPlace(root, node)
          : LevelPlace(
              root,
              node,
              multiRoot: roots.length > 1,
              compact: compact,
            );
    }
  }
  if (location.flat || view == FolderView.flat) {
    return FlatListPlace(flatFolders(roots));
  }
  if (roots.length == 1) {
    return LevelPlace(
      roots.first,
      roots.first.node,
      multiRoot: false,
      compact: compact,
    );
  }
  return RootsPlace(roots);
}

/// Key of [folderPlaceProvider].
typedef FolderPlaceKey = ({
  FolderLocation location,
  FolderView view,
  bool compact,
});

/// The place for a location in the live folder trees.
final folderPlaceProvider = Provider.autoDispose
    .family<AsyncValue<FolderPlace>, FolderPlaceKey>((ref, key) {
      return ref
          .watch(folderTreesProvider)
          .whenData(
            (roots) => resolveFolderPlace(
              roots,
              key.location,
              key.view,
              compact: key.compact,
            ),
          );
    });

/// A row of a level: a folder, or a chain of single-subfolder folders that
/// opens its last one. [target] is the folder the row opens.
class FolderRowItem {
  const FolderRowItem(this.chain);

  final List<FolderNode> chain;

  FolderNode get target => chain.last;

  /// Names of the chain joined with ` › `.
  String get label => chain.map((n) => n.name).join(' › ');
}

/// The sub-folders of [node] as rows: merged into chains when [compact], then
/// filtered by name and ordered by [sort] (name = natural order, or by the
/// number of songs below; ties keep name order).
List<FolderRowItem> levelRows(
  FolderNode node, {
  required bool compact,
  required SortSpec sort,
  required String filter,
}) {
  final match = foldedMatcher(filter);
  final rows = [
    for (final child in node.children)
      FolderRowItem(compact ? compactChain(child) : [child]),
  ].where((r) => match(r.label)).toList();
  return _ordered(
    rows,
    sort,
    name: (r) => r.label,
    songs: (r) => r.target.deepSongs,
  );
}

/// The folders of the flat view, filtered by name and the folders above, and
/// ordered by [sort] (by direct songs for the count).
List<FlatFolder> flatRows(
  List<FlatFolder> all, {
  required SortSpec sort,
  required String filter,
}) {
  final match = foldedMatcher(filter);
  final rows = [
    for (final f in all)
      if (match('${f.name} ${f.ancestors.join(' ')}')) f,
  ];
  return _ordered(rows, sort, name: (f) => f.name, songs: (f) => f.songCount);
}

List<T> _ordered<T>(
  List<T> rows,
  SortSpec sort, {
  required String Function(T) name,
  required int Function(T) songs,
}) {
  // Each name is folded and split once, not on every comparison.
  final keyed = [for (final r in rows) (naturalKeyOf(name(r)), r)]
    ..sort((a, b) => a.$1.compareTo(b.$1));
  final byName = [for (final e in keyed) e.$2];
  if (sort.criterion == SortCriterion.trackCount) {
    final indexed = [for (var i = 0; i < byName.length; i++) (i, byName[i])];
    indexed.sort((a, b) {
      final c = songs(a.$2).compareTo(songs(b.$2));
      if (c != 0) return sort.descending ? -c : c;
      return a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
  return sort.descending ? byName.reversed.toList() : byName;
}

/// Key of [flatRowsProvider].
typedef FlatRowsKey = ({FolderPlaceKey place, SortSpec sort, String filter});

/// The rows of the flat folder list, filtered and ordered once per place,
/// sort and filter, and shared by the list and the bar's count. Null when the
/// place is not the flat list.
final flatRowsProvider = Provider.autoDispose
    .family<List<FlatFolder>?, FlatRowsKey>((ref, key) {
      final place = ref.watch(folderPlaceProvider(key.place)).value;
      if (place is! FlatListPlace) return null;
      return flatRows(place.folders, sort: key.sort, filter: key.filter);
    });
