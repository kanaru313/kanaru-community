/// Cover keys for a playlist's automatic cover: walks [inOrder] (playlist
/// order), groups tracks by [group] (an album, or one track without album),
/// skips tracks with no cover, and returns the cover key of the first
/// [limit] distinct groups. A group seen again counts once, and a cover key already
/// picked is skipped (the first track in order wins).
List<String> pickAutoCoverKeys(
  Iterable<({String group, String? coverKey})> inOrder, {
  int limit = 4,
}) {
  final groups = <String>{};
  final picked = <String>{};
  final keys = <String>[];
  for (final item in inOrder) {
    if (keys.length >= limit) break;
    final key = item.coverKey;
    if (key == null) continue;
    if (picked.contains(key) || !groups.add(item.group)) continue;
    picked.add(key);
    keys.add(key);
  }
  return keys;
}
