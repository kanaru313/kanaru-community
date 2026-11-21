/// Where a track's lyrics were read from.
enum LyricsOrigin {
  /// Stored in the audio file's tags.
  tag,

  /// A `.lrc` file next to the audio file.
  lrc,
}

/// One word of an enhanced-LRC line: [start] is the absolute time in the
/// track. Kept for karaoke rendering later; the views ignore it.
class LyricWord {
  const LyricWord(this.start, this.text);

  final Duration start;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is LyricWord && other.start == start && other.text == text;

  @override
  int get hashCode => Object.hash(start, text);

  @override
  String toString() => 'LyricWord($start, $text)';
}

/// One line of lyrics. [time] is when it starts; for plain (unsynchronized)
/// lyrics every line has [Duration.zero].
class LyricLine {
  const LyricLine(this.time, this.text, {this.words = const []});

  final Duration time;

  /// May be empty: a timed blank line marks an instrumental gap.
  final String text;

  /// Word timings of enhanced LRC; empty for every other line.
  final List<LyricWord> words;

  bool get isGap => text.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is LyricLine &&
      other.time == time &&
      other.text == text &&
      _sameWords(other.words, words);

  @override
  int get hashCode => Object.hash(time, text, words.length);

  @override
  String toString() => 'LyricLine($time, $text)';
}

bool _sameWords(List<LyricWord> a, List<LyricWord> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The lyrics of one track: never empty. When [synced], [lines] are sorted by
/// time and follow playback; otherwise they are shown as they are.
class Lyrics {
  const Lyrics({
    required this.lines,
    required this.synced,
    required this.origin,
  });

  final List<LyricLine> lines;
  final bool synced;
  final LyricsOrigin origin;

  /// Index of the line being sung at [position]: the last line starting at
  /// or before it, `-1` before the first line or when not [synced].
  int lineAt(Duration position) {
    if (!synced) return -1;
    var low = 0;
    var high = lines.length - 1;
    var found = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lines[mid].time <= position) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  /// Total characters of line text; the loader's cache budget counts it.
  int get textLength {
    var n = 0;
    for (final line in lines) {
      n += line.text.length;
    }
    return n;
  }

  @override
  bool operator ==(Object other) =>
      other is Lyrics &&
      other.synced == synced &&
      other.origin == origin &&
      other.lines.length == lines.length &&
      _sameLines(other.lines, lines);

  @override
  int get hashCode => Object.hash(synced, origin, lines.length);

  @override
  String toString() =>
      'Lyrics(${lines.length} lines, synced: $synced, ${origin.name})';
}

bool _sameLines(List<LyricLine> a, List<LyricLine> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
