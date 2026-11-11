/// Removes the directory part of every absolute path or `file://` URI in
/// [text], keeping the file name, so a log line never carries a directory
/// layout or a user name.
///
/// A path may contain spaces, so it is not cut at whitespace: from its first
/// `/` the match runs to the last `/` before a quote or the end of the line.
/// Text after a path on the same line that comes before a later `/` is dropped
/// too; losing a few words is better than leaking a directory name.
String scrubPaths(String text) => text.replaceAll(_dirPart, '');

final _dirPart = RegExp('(?:file://)?(?<![\\w.])/(?=\\S)[^\'"\\n]*/');

/// Which mpv log messages reach the app log: every `error`/`fatal`, and
/// `warn` only from the prefixes that explain a rejected command or a file
/// that cannot play. Codec warnings (damaged frames, underruns) come per
/// packet and are dropped.
///
/// Pure: the caller gives the time. At most [budget] distinct lines per
/// second pass, a repeated `(prefix, text)` within the second is dropped, and
/// the first line of the next second is preceded by one summary of what was
/// dropped.
class MpvLogFilter {
  MpvLogFilter({this.budget = 5});

  final int budget;
  static const _warnPrefixes = {'cplayer', 'main', 'file', 'media_kit'};

  int _second = -1;
  int _passed = 0;
  int _dropped = 0;
  final _seen = <String>{};

  /// The lines to log for one mpv message (empty when it is dropped).
  List<String> accept({
    required String level,
    required String prefix,
    required String text,
    required int nowMs,
  }) {
    final relevant =
        level == 'error' ||
        level == 'fatal' ||
        (level == 'warn' && _warnPrefixes.contains(prefix));
    if (!relevant) return const [];
    final out = <String>[];
    final second = nowMs ~/ 1000;
    if (second != _second) {
      if (_dropped > 0) out.add('mpv: $_dropped messages suppressed');
      _second = second;
      _passed = 0;
      _dropped = 0;
      _seen.clear();
    }
    if (!_seen.add('$prefix\u0000$text') || _passed >= budget) {
      _dropped++;
      return out;
    }
    _passed++;
    out.add('mpv $level [$prefix] ${scrubPaths(text)}');
    return out;
  }
}
