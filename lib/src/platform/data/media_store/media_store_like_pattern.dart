/// SQL `LIKE` pattern (escape character `\`) matching everything below
/// [root], built here so the escaping is unit-tested (Kotlin only binds it).
///
/// `%`, `_` and `\` in [root] are escaped, so a folder called `100%_mix` is
/// matched literally. [suffix] is appended raw (for example `.lrc`). The root
/// keeps its spelling: SQLite's `LIKE` folds ASCII case only, so lower-casing
/// would stop `Đ` matching.
String mediaStoreLikePattern(String root, {String suffix = ''}) {
  final escaped = root
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '$escaped/%$suffix';
}
