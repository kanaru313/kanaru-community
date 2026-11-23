/// SQL and path rules shared by the queries that read a track's place on
/// disk (the song menu links and the song info details).
library;

final _cueSuffix = RegExp(r'#\d+$');

/// Folder key of `t.locator`: everything before the last `/`, `''` when
/// there is none. `rtrim` with the locator's own non-slash characters strips
/// the file name.
const trackDirSql =
    "CASE WHEN instr(t.locator, '/') = 0 THEN '' ELSE "
    "substr(rtrim(t.locator, replace(t.locator, '/', '')), 1, "
    "length(rtrim(t.locator, replace(t.locator, '/', ''))) - 1) END";

/// Absolute path of the file of [locator] under the mount [root] (a CUE
/// `#n` suffix dropped); null when the source has no mounted local root.
String? trackFilePath(String? root, String locator) {
  if (root == null) return null;
  final base = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
  return '$base/${locator.replaceFirst(_cueSuffix, '')}';
}

/// [root] without a trailing slash; null stays null.
String? trimMountRoot(String? root) => root == null
    ? null
    : (root.endsWith('/') ? root.substring(0, root.length - 1) : root);
