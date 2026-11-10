/// Locator bounds of every file under [folderKey] (a relative path without a
/// slash at either end; `''` is the mount root): `locator >= from AND
/// locator < to`. The root has no bound and returns null.
///
/// `'/'` is 0x2F and `'0'` is 0x30, the next code unit, so the half-open
/// range holds `a/...` and nothing else: not `a b/x` (space sorts before
/// `/`), not `a.b/x`, not `a0`. Only for path-based sources; an id-based
/// source compares folder ids by equality instead.
///
/// Throws [ArgumentError] for a key with a leading or trailing slash.
({String from, String to})? folderLocatorRange(String folderKey) {
  if (folderKey.isEmpty) return null;
  if (folderKey.startsWith('/') || folderKey.endsWith('/')) {
    throw ArgumentError.value(
      folderKey,
      'folderKey',
      'must not start or end with a slash',
    );
  }
  return (from: '$folderKey/', to: '${folderKey}0');
}
