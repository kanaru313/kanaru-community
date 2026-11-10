import '../../../media/domain/library_keys.dart';

/// Stand-in for the `/` inside a kept-whole name while splitting.
const String _protectedSlash = '';

/// Names that hold a separator and are one artist.
const List<String> _keepWhole = ['AC/DC'];

final RegExp _controls = RegExp(r'[\x00-\x1F\x7F]');

// `;` and `/` split wherever they appear; `feat.`, `feat`, `ft.`, `ft` and
// `featuring` split only between whitespace, so "Featherweight" stays whole.
// `,`, `&` and ` with ` never split: they are part of names ("Earth, Wind &
// Fire").
final RegExp _symbols = RegExp(r'\s*[;/]\s*');
final RegExp _words = RegExp(
  r'\s+(?:featuring|feat\.?|ft\.?)\s+',
  caseSensitive: false,
);
final RegExp _bracketed = RegExp(
  r'\s*[(\[]\s*(?:featuring|feat\.?|ft\.?)\s+([^)\]]*)[)\]]',
  caseSensitive: false,
);
final RegExp _nul = RegExp(r'\s*\u0000\s*');

final List<RegExp> _keepWholePatterns = [
  for (final name in _keepWhole)
    RegExp(
      '(?<![\\p{L}\\p{N}])${RegExp.escape(name)}(?![\\p{L}\\p{N}])',
      caseSensitive: false,
      unicode: true,
    ),
];

List<String> _splitOne(String value) {
  var text = value.replaceAll(_controls, ' ');
  for (final pattern in _keepWholePatterns) {
    text = text.replaceAllMapped(
      pattern,
      (m) => m[0]!.replaceAll('/', _protectedSlash),
    );
  }
  text = text.replaceAllMapped(_bracketed, (m) => '\u0000${m[1]}');
  final pieces = text
      .split(_nul)
      .expand((p) => p.split(_symbols))
      .expand((p) => p.split(_words));
  return [
    for (final piece in pieces)
      if (piece.replaceAll(_protectedSlash, '/').trim() case final name
          when name.isNotEmpty)
        name,
  ];
}

/// The artist names in the raw artist [values] of a tag, in order, trimmed,
/// without empty parts and without repeats (compared by [groupKey]; the
/// first spelling is kept).
List<String> splitArtists(List<String> values) {
  final names = <String>[];
  final seen = <String>{};
  for (final value in values) {
    for (final name in _splitOne(value)) {
      if (seen.add(groupKey(name))) names.add(name);
    }
  }
  return names;
}

/// `(key, name)` pairs for `track_artists`: [splitArtists] with the
/// [groupKey] of each name; names whose key is empty are dropped.
List<({String key, String name})> artistsForRow(List<String> values) => [
  for (final name in splitArtists(values))
    if (groupKey(name) case final key when key.isNotEmpty)
      (key: key, name: name),
];
