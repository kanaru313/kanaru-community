import 'm3u_text.dart';

/// One entry to write. [path] is the line as it should appear (absolute, or
/// already relative to the target folder). A null [title] writes the path
/// alone, with no `#EXTINF`.
class M3uWriteItem {
  const M3uWriteItem({
    required this.path,
    this.title,
    this.artist,
    this.durationMs,
  });

  final String path;
  final String? title;
  final String? artist;
  final int? durationMs;
}

/// The M3U [text] and how many items were [skipped].
typedef M3uWriteResult = ({String text, int skipped});

/// Extended M3U text for [items] in order (LF endings, no BOM). An item whose
/// path is blank or holds a line break or NUL cannot be one line and is skipped. A
/// relative line that starts with `#` (read as a comment) or has a `:` before
/// its first `/` (read as a URL scheme) gets a `./` prefix.
M3uWriteResult writeM3u(List<M3uWriteItem> items) {
  final out = StringBuffer('#EXTM3U\n');
  var skipped = 0;
  for (final item in items) {
    final path = item.path;
    if (path.trim().isEmpty ||
        path.contains('\n') || path.contains('\r') || path.contains('\u0000')) {
      skipped++;
      continue;
    }
    final title = _oneLine(item.title ?? '');
    if (item.title != null && title.isNotEmpty) {
      final ms = item.durationMs;
      final seconds = ms == null || ms < 0 ? -1 : ms ~/ 1000;
      final artist = _oneLine(item.artist ?? '');
      final label = artist.isEmpty ? title : '$artist - $title';
      out.write('#EXTINF:$seconds,$label\n');
    }
    out.write('${_safeLine(path)}\n');
  }
  return (text: out.toString(), skipped: skipped);
}

String _oneLine(String text) => text.replaceAll(m3uUnsafeTextChars, ' ').trim();

String _safeLine(String path) {
  if (path.startsWith('/')) return path;
  final colon = path.indexOf(':');
  final slash = path.indexOf('/');
  final looksLikeScheme = colon >= 0 && (slash < 0 || colon < slash);
  return path.startsWith('#') || looksLikeScheme ? './$path' : path;
}
