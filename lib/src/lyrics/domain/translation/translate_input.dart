import 'translation_lines.dart';

/// What a translator may know about the song besides the lines. Both are
/// absent when unknown.
class SongContext {
  const SongContext({this.title, this.artist});

  final String? title;
  final String? artist;

  @override
  bool operator ==(Object other) =>
      other is SongContext && other.title == title && other.artist == artist;

  @override
  int get hashCode => Object.hash(title, artist);
}

/// The JSON input of one `translate` run: the chunk [lines], the target
/// language [to] and the song with all its [allLines] as context. No
/// instruction or note is added here; that is the plugin's own setting.
Map<String, Object?> buildTranslateInput(
  List<String> lines,
  String to, {
  SongContext? song,
  List<String>? allLines,
}) => {
  'lines': lines,
  'to': to,
  'song': {
    'title': song?.title ?? '',
    'artist': song?.artist ?? '',
    'lyrics': _capped((allLines ?? lines).join('\n')),
  },
};

// At most [maxTranslatedChars] UTF-16 units, never ending inside a pair.
String _capped(String text) {
  if (text.length <= maxTranslatedChars) return text;
  var end = maxTranslatedChars;
  final last = text.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return text.substring(0, end);
}
