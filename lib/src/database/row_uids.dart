import '../foundation/ids/stable_uid.dart';

/// Matches `[scheme://]user[:pass]@host`, the userinfo form of a URL.
final _userInfo = RegExp(r'^(?:[A-Za-z][A-Za-z0-9+.\-]*://)?[^/?#]*@');

/// Uid of a remote or plugin source: `src:` + hash(kind, account, root).
///
/// Throws [ArgumentError] when [root] carries URL userinfo (`user:pass@`) or
/// a query string, because uids and roots are synced and must not hold
/// secrets. Local sources use a ULID instead.
String sourceUidForRemote(String kind, String? account, String root) {
  if (_userInfo.hasMatch(root) || root.contains('?')) {
    // The root is not echoed: it may hold the secret being rejected.
    throw ArgumentError('root must not contain URL userinfo or a query string');
  }
  return stableUid('src', [kind, account ?? '', root]);
}

/// Uid of a track: `trk:` + hash(source uid, locator). Compute once, when the
/// row is created.
String trackUid(String sourceUid, String locator) =>
    stableUid('trk', [sourceUid, locator]);

/// Uid of an excluded folder: `exc:` + hash(source uid, folder key).
String excludedFolderUid(String sourceUid, String folderKey) =>
    stableUid('exc', [sourceUid, folderKey]);

/// Uid of the Favorites playlist. Fixed, so every device agrees on it.
const favoritesPlaylistUid = 'favorites';

/// Uid of a Favorites entry: `fav:` + hash(playlist uid, track uid).
String favoriteEntryUid(String playlistUid, String trackUid) =>
    stableUid('fav', [playlistUid, trackUid]);

/// Uid of a saved item: `saved:` + hash(source uid, kind, remote id).
String savedItemUid(String sourceUid, String kind, String remoteId) =>
    stableUid('saved', [sourceUid, kind, remoteId]);
