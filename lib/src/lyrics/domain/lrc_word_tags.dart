import 'lyrics.dart';

/// A word-time tag of enhanced LRC: `<mm:ss>`, `<mm:ss.f>` .. `<mm:ss.fff>`,
/// `<mm:ss:ff>`. Anything else in angle brackets stays text.
final _wordTag = RegExp(r'<(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?>');

/// Milliseconds of a `mm`, `ss`, fraction tag group (one fraction digit is
/// tenths, two hundredths, three milliseconds).
Duration lrcTimeOf(String minutes, String seconds, String? fraction) {
  final ms = fraction == null
      ? 0
      : int.parse(fraction) * const [100, 10, 1][fraction.length - 1];
  return Duration(
    minutes: int.parse(minutes),
    seconds: int.parse(seconds),
    milliseconds: ms,
  );
}

/// Whether [rest] holds a word tag (cheap test before splitting).
bool hasWordTags(String rest) => rest.contains('<') && _wordTag.hasMatch(rest);

/// [rest] without its word tags.
String stripWordTags(String rest) => rest.replaceAll(_wordTag, '');

/// The words of [rest]: each tag starts a word that runs until the next tag;
/// text before the first tag is a word starting at [lineTime]. Empty words
/// are dropped. Times are as written; the parser applies `[offset:]` later.
List<LyricWord> splitWordTags(String rest, {required Duration lineTime}) {
  final words = <LyricWord>[];
  var start = lineTime;
  var from = 0;
  void add(int end) {
    final text = rest.substring(from, end);
    if (text.isNotEmpty) words.add(LyricWord(start, text));
  }

  for (final m in _wordTag.allMatches(rest)) {
    add(m.start);
    start = lrcTimeOf(m.group(1)!, m.group(2)!, m.group(3));
    from = m.end;
  }
  add(rest.length);
  return words;
}
