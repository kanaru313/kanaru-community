import 'lrc_word_tags.dart';
import 'lyrics.dart';

/// Most lines kept from one lyrics text; the rest is dropped. Matches the
/// cap on synchronized lines read from tags.
const maxLyricLines = 10000;

/// Most time tags read from the start of one row (`[00:01][00:02]text`); the
/// rest of the row stays text.
const maxTimeTagsPerRow = 100;

/// Most characters of line text kept in total, after tags repeat a line.
/// A line that would pass it, and every later one, is dropped.
const maxLyricsTextChars = 1 << 20;

/// A time tag: `[mm:ss]`, `[mm:ss.f]` up to `[mm:ss.fff]`, or `[mm:ss:ff]`.
/// Matched with `matchAsPrefix` at an index, so a row is never re-sliced per
/// tag (the cost stays linear).
final _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

/// An LRC meta tag line: `[ar:Artist]`, `[offset:+250]`, `[by:]`. Only the
/// known keys: a section header such as `[Chorus: Someone]` is lyrics.
final _metaTag = RegExp(
  r'\[(ar|al|ti|au|by|re|ve|tool|length|offset|lang|la|id|#):([^\]]*)\]\s*$',
  caseSensitive: false,
);

/// Parses lyrics [text]: LRC when at least one timed line has words, plain
/// lyrics otherwise (timed lines that are all blank are ignored, so only the
/// untimed text is left). `null` when nothing is left to show.
///
/// LRC: a line may carry several time tags (one line per tag, at most
/// [maxTimeTagsPerRow]); known meta tags are skipped, and `[offset:ms]`
/// (positive means earlier) applies to every line and word wherever it
/// stands; times below zero become zero. Lines without a time tag are
/// dropped, timed blank lines kept. Lines are sorted by time, keeping the
/// file's order for equal times. Enhanced-LRC word times (`<mm:ss.xx>`) fill
/// [LyricLine.words] (of the first tag's line only) and are stripped from the
/// text.
///
/// Plain: meta tag lines are dropped and blank lines around the text
/// trimmed. Either way at most [maxLyricLines] lines and
/// [maxLyricsTextChars] characters are kept.
Lyrics? parseLyricsText(String text, LyricsOrigin origin) {
  final rows = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final timed = <LyricLine>[];
  final plain = <String>[];
  var offsetMs = 0;
  var timedChars = 0;
  var plainChars = 0;
  // Set by the first line of that kind the cap refuses: every later line of
  // the kind is dropped (synced and plain lines are capped separately).
  var timedCapped = false;
  var plainCapped = false;
  for (final row in rows) {
    var pos = _skipSpace(row, 0);
    final times = <Duration>[];
    while (times.length < maxTimeTagsPerRow) {
      final m = _timeTag.matchAsPrefix(row, pos);
      if (m == null) break;
      times.add(lrcTimeOf(m.group(1)!, m.group(2)!, m.group(3)));
      // Stacked tags may be spaced: `[00:01] [00:02]text`.
      pos = _skipSpace(row, m.end);
    }
    if (times.isNotEmpty) {
      final rest = row.substring(pos);
      final withWords = hasWordTags(rest);
      final words = (withWords ? stripWordTags(rest) : rest).trim();
      for (var i = 0; i < times.length; i++) {
        if (timedCapped ||
            timed.length >= maxLyricLines ||
            timedChars + words.length > maxLyricsTextChars) {
          timedCapped = true;
          break;
        }
        timedChars += words.length;
        timed.add(
          LyricLine(
            times[i],
            words,
            // Word times belong to the first copy of the line only.
            words: i == 0 && withWords
                ? splitWordTags(rest, lineTime: times[0])
                : const [],
          ),
        );
      }
      continue;
    }
    final meta = _metaTag.matchAsPrefix(row, _skipSpace(row, 0));
    if (meta != null) {
      if (meta.group(1)!.toLowerCase() == 'offset') {
        offsetMs = int.tryParse(meta.group(2)!.trim()) ?? offsetMs;
      }
      continue;
    }
    final kept = row.trimRight();
    if (!plainCapped &&
        plain.length < maxLyricLines &&
        plainChars + kept.length <= maxLyricsTextChars) {
      plainChars += kept.length;
      plain.add(kept);
    } else {
      plainCapped = true;
    }
  }

  // Timed lines that are all blank leave nothing to show.
  if (timed.any((line) => line.text.isNotEmpty)) {
    final shift = Duration(milliseconds: offsetMs);
    final lines = [for (final line in timed) _shifted(line, shift)];
    _stableSortByTime(lines);
    return Lyrics(lines: lines, synced: true, origin: origin);
  }

  var start = 0;
  var end = plain.length;
  while (start < end && plain[start].trim().isEmpty) {
    start++;
  }
  while (end > start && plain[end - 1].trim().isEmpty) {
    end--;
  }
  if (start == end) return null;
  return Lyrics(
    lines: [
      for (final text in plain.sublist(start, end))
        LyricLine(Duration.zero, text),
    ],
    synced: false,
    origin: origin,
  );
}

LyricLine _shifted(LyricLine line, Duration shift) {
  if (shift == Duration.zero) return line;
  return LyricLine(
    _clamped(line.time - shift),
    line.text,
    words: [
      for (final w in line.words) LyricWord(_clamped(w.start - shift), w.text),
    ],
  );
}

Duration _clamped(Duration d) => d < Duration.zero ? Duration.zero : d;

/// The index of the first non-whitespace code unit of [s] from [from]
/// (what `trimLeft` skips), without copying the string.
int _skipSpace(String s, int from) {
  var i = from;
  while (i < s.length && _isSpace(s.codeUnitAt(i))) {
    i++;
  }
  return i;
}

bool _isSpace(int c) =>
    c == 0x20 ||
    (c >= 0x09 && c <= 0x0D) ||
    c == 0x85 ||
    c == 0xA0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202F ||
    c == 0x205F ||
    c == 0x3000 ||
    c == 0xFEFF;

/// `List.sort` is not stable; lines with the same time keep their order.
void _stableSortByTime(List<LyricLine> lines) {
  final indexed = [for (var i = 0; i < lines.length; i++) (i, lines[i])];
  indexed.sort((a, b) {
    final byTime = a.$2.time.compareTo(b.$2.time);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < lines.length; i++) {
    lines[i] = indexed[i].$2;
  }
}
