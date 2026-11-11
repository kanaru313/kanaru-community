import '../../../media/domain/library_keys.dart';
import '../../domain/library_tabs.dart';
import '../library_locations.dart';

/// Where the Folders page is, as it appears in the URL:
/// `/library/folders` (the top), `?at=<encodeKey('<sourceUid>/<folderKey>')>`
/// for one folder, `view=flat` for the flat view.
///
/// The level lives in the location so a pushed page, a breadcrumb jump and
/// Back all move through the router. [sourceUid] null is the top: the list of
/// music folders (several), or the only music folder (one).
class FolderLocation {
  const FolderLocation({this.sourceUid, this.key = '', this.flat = false});

  /// The top of the tab in the tree view.
  static const FolderLocation top = FolderLocation();

  /// The flat list of every folder that holds songs.
  static const FolderLocation flatList = FolderLocation(flat: true);

  /// Uid of the music folder (source) the level is in; null = the top.
  final String? sourceUid;

  /// Relative path of the folder inside its music folder (`''` = the music
  /// folder itself); no leading or trailing slash.
  final String key;

  /// The level was opened from the flat list: only its direct songs show.
  final bool flat;

  bool get isTop => sourceUid == null;

  /// The location string to navigate to.
  String get path {
    final query = <String, String>{
      if (sourceUid != null) 'at': encodeKey('$sourceUid/$key'),
      if (flat) 'view': 'flat',
    };
    final base = LibraryLocations.list(_foldersTab);
    return query.isEmpty
        ? base
        : Uri(path: base, queryParameters: query).toString();
  }

  /// Reads the location from [uri]. Anything malformed (a level that does
  /// not decode, an empty music folder uid) is the top.
  static FolderLocation parse(Uri uri) {
    final flat = uri.queryParameters['view'] == 'flat';
    final at = uri.queryParameters['at'];
    if (at == null) return flat ? flatList : top;
    final raw = decodeKey(at);
    if (raw == null) return flat ? flatList : top;
    final slash = raw.indexOf('/');
    if (slash <= 0) return flat ? flatList : top;
    final key = raw.substring(slash + 1).replaceAll(RegExp(r'^/+|/+$'), '');
    return FolderLocation(
      sourceUid: raw.substring(0, slash),
      key: key,
      flat: flat,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FolderLocation &&
      other.sourceUid == sourceUid &&
      other.key == key &&
      other.flat == flat;

  @override
  int get hashCode => Object.hash(sourceUid, key, flat);

  @override
  String toString() => 'FolderLocation($path)';
}

const _foldersTab = LibraryTab.folders;
