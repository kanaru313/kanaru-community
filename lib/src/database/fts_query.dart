/// Builds the input of an FTS `MATCH` from free text typed by the user.
///
/// Every whitespace-separated token becomes a quoted prefix term
/// (`"tok"*`, inner quotes doubled), so operators and column filters in the
/// text (`-`, `:`, `NEAR(`, `*`) are plain characters and can never cause
/// an FTS syntax error. Returns `null` when there is no token; the caller
/// then skips the `MATCH` clause. This is the only way to build `MATCH`
/// input. Control characters (NUL included) count as whitespace: FTS5 fails
/// on them with "unterminated string".
String? ftsPrefixQuery(String input) {
  final tokens = input
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return null;
  return tokens.map((t) => '"${t.replaceAll('"', '""')}"*').join(' ');
}
