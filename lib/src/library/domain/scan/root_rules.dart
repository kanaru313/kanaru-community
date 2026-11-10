/// Result of [checkNewRoot].
sealed class RootCheck {
  const RootCheck();
}

final class RootOk extends RootCheck {
  const RootOk();
}

/// The candidate is `/` (or empty): it would walk the whole system.
final class RootTooBroad extends RootCheck {
  const RootTooBroad();
}

/// The candidate is the same as, or inside, [root]; [root] already covers it.
final class RootInsideExisting extends RootCheck {
  const RootInsideExisting(this.root);
  final String root;
}

/// The candidate contains [root]; adding it would list [root] twice.
final class RootContainsExisting extends RootCheck {
  const RootContainsExisting(this.root);
  final String root;
}

/// [path] without trailing slashes; `/` stays `/`, an empty path stays empty.
String normalizeRootPath(String path) {
  var end = path.length;
  while (end > 1 && path[end - 1] == '/') {
    end--;
  }
  return path.substring(0, end);
}

/// Whether [inner] is [outer] or lies below it (compared as whole path
/// segments, so `Live Albums` is not inside `Live`). Both normalised.
bool isSameOrInside(String inner, String outer) =>
    inner == outer ||
    (outer == '/' ? inner.startsWith('/') : inner.startsWith('$outer/'));

/// Whether the absolute path [candidate] may become a music folder next to
/// [existingRoots]. Paths must already be canonical (links resolved); a
/// trailing slash is ignored.
RootCheck checkNewRoot(String candidate, Iterable<String> existingRoots) {
  final path = normalizeRootPath(candidate.trim());
  if (path.isEmpty || path == '/') return const RootTooBroad();
  for (final existing in existingRoots) {
    final root = normalizeRootPath(existing);
    if (isSameOrInside(path, root)) return RootInsideExisting(existing);
  }
  for (final existing in existingRoots) {
    final root = normalizeRootPath(existing);
    if (isSameOrInside(root, path)) return RootContainsExisting(existing);
  }
  return const RootOk();
}
