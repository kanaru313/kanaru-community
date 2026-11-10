import '../music_folder.dart';
import 'natural_compare.dart';

/// A music file seen by the folder tree: its source, `/`-separated locator
/// relative to the source root, and cover key. A record, so a large list can
/// be sent to another isolate.
typedef FolderRow = ({int sourceId, String locator, String? coverKey});

/// One folder. [key] is the relative path without leading or trailing slash
/// (`''` = the music folder itself).
class FolderNode {
  FolderNode._({
    required this.key,
    required this.name,
    required this.directSongs,
    required this.directCoverKey,
  });

  final String key;
  final String name;

  /// Files directly in this folder.
  final int directSongs;

  /// Files in this folder and everything below it.
  int get deepSongs => _deepSongs;
  int _deepSongs = 0;

  /// Direct subfolders in natural name order.
  List<FolderNode> get children => _children;
  List<FolderNode> _children = const [];

  int get subfolders => _children.length;

  /// Cover held by most direct files, null when none has one.
  final String? directCoverKey;

  /// [directCoverKey], else the cover of the subfolder with most files that
  /// has one (ties: first in natural order).
  String? get coverKey => _coverKey;
  String? _coverKey;
}

/// One music folder with its tree. [ambiguous]: another root has the same
/// name, so the UI shows where each one is.
class FolderRoot {
  FolderRoot({
    required this.folder,
    required this.node,
    required this.ambiguous,
  });

  final MusicFolder folder;
  final FolderNode node;
  final bool ambiguous;

  Map<String, FolderNode>? _byKey;

  /// The folder at [key] (`''` = the root), or null when it is not in the
  /// tree (emptied or excluded since).
  FolderNode? nodeAt(String key) {
    final index = _byKey ??= _index(node);
    return index[key];
  }
}

Map<String, FolderNode> _index(FolderNode root) {
  final out = <String, FolderNode>{};
  void walk(FolderNode n) {
    out[n.key] = n;
    n.children.forEach(walk);
  }

  walk(root);
  return out;
}

/// `nodeAt` on a list of roots; null when [sourceId] has no root.
FolderNode? nodeAt(List<FolderRoot> roots, int sourceId, String key) {
  for (final r in roots) {
    if (r.folder.sourceId == sourceId) return r.nodeAt(key);
  }
  return null;
}

/// Builds the tree of every root in [roots] from the present files [rows]
/// (rows of other sources are ignored). Roots keep their order.
List<FolderRoot> buildFolderTrees(
  List<MusicFolder> roots,
  List<FolderRow> rows,
) {
  final bySource = <int, List<FolderRow>>{};
  for (final r in rows) {
    bySource.putIfAbsent(r.sourceId, () => []).add(r);
  }
  final nameCount = <String, int>{};
  for (final f in roots) {
    nameCount[f.name] = (nameCount[f.name] ?? 0) + 1;
  }
  return [
    for (final f in roots)
      FolderRoot(
        folder: f,
        node: _buildTree(f.name, bySource[f.sourceId] ?? const []),
        ambiguous: nameCount[f.name]! > 1,
      ),
  ];
}

class _Dir {
  _Dir(this.key);
  final String key;
  int songs = 0;
  int deep = 0;
  final covers = <String, int>{};
  final children = <_Dir>[];
}

String _dirOf(String locator) {
  final i = locator.lastIndexOf('/');
  return i < 0 ? '' : locator.substring(0, i);
}

String _parentOf(String key) {
  final i = key.lastIndexOf('/');
  return i < 0 ? '' : key.substring(0, i);
}

FolderNode _buildTree(String rootName, List<FolderRow> rows) {
  final dirs = <String, _Dir>{'': _Dir('')};
  for (final r in rows) {
    final key = _dirOf(r.locator);
    var d = dirs[key];
    if (d == null) {
      d = dirs[key] = _Dir(key);
      // Create the missing ancestors, linking each to its parent.
      var child = d;
      while (child.key.isNotEmpty) {
        final parentKey = _parentOf(child.key);
        final existing = dirs[parentKey];
        if (existing != null) {
          existing.children.add(child);
          break;
        }
        final parent = dirs[parentKey] = _Dir(parentKey);
        parent.children.add(child);
        child = parent;
      }
    }
    d.songs++;
    final cover = r.coverKey;
    if (cover != null) d.covers[cover] = (d.covers[cover] ?? 0) + 1;
  }
  return _finish(dirs['']!, rootName);
}

/// Turns [dir] and everything below it into nodes; deep counts and covers
/// are computed bottom-up.
FolderNode _finish(_Dir d, String name) {
  final kids = [
    for (final c in d.children)
      _finish(c, c.key.substring(c.key.lastIndexOf('/') + 1)),
  ]..sort((a, b) => naturalCompare(a.name, b.name));
  final node = FolderNode._(
    key: d.key,
    name: name,
    directSongs: d.songs,
    directCoverKey: _topCover(d.covers),
  );
  node._children = kids;
  node._deepSongs = d.songs + kids.fold(0, (sum, k) => sum + k.deepSongs);
  var cover = node.directCoverKey;
  if (cover == null) {
    var best = 0;
    for (final k in kids) {
      if (k.coverKey != null && k.deepSongs > best) {
        best = k.deepSongs;
        cover = k.coverKey;
      }
    }
  }
  node._coverKey = cover;
  return node;
}

String? _topCover(Map<String, int> covers) {
  String? best;
  var count = 0;
  covers.forEach((cover, n) {
    // Ties: the smaller key, so the result does not depend on row order.
    if (n > count || (n == count && cover.compareTo(best!) < 0)) {
      best = cover;
      count = n;
    }
  });
  return best;
}

/// The chain a row shows for [child]: [child] and, while the last folder has
/// no files of its own and exactly one subfolder, that subfolder. The row
/// shows the names joined by ` › ` and opens the last one.
List<FolderNode> compactChain(FolderNode child) {
  final chain = [child];
  var last = child;
  while (last.directSongs == 0 && last.children.length == 1) {
    last = last.children.first;
    chain.add(last);
  }
  return chain;
}

/// A folder with files of its own, for the flat view. [ancestors] are the
/// names above it, starting with the music folder's name.
class FlatFolder {
  const FlatFolder({
    required this.root,
    required this.node,
    required this.ancestors,
  });

  final FolderRoot root;
  final FolderNode node;
  final List<String> ancestors;

  String get name => node.name;

  /// Files directly in the folder.
  int get songCount => node.directSongs;
}

/// Every folder with direct files, root included, per root in tree order.
List<FlatFolder> flatFolders(List<FolderRoot> roots) {
  final out = <FlatFolder>[];
  for (final root in roots) {
    void walk(FolderNode n, List<String> above) {
      if (n.directSongs > 0) {
        out.add(FlatFolder(root: root, node: n, ancestors: above));
      }
      final next = [...above, n.name];
      for (final c in n.children) {
        walk(c, next);
      }
    }

    walk(root.node, const []);
  }
  return out;
}
