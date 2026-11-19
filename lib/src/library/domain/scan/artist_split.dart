import '../../../media/domain/library_keys.dart';
import 'artist_split_rules.dart';

export 'artist_split_rules.dart' show ArtistSplitRules;

final RegExp _controls = RegExp(r'[\x00-\x1F\x7F]');

// Fixed rules that no setting changes: a bracketed "(feat. X)" names another
// artist, and NUL is how some tag formats join several values.
final RegExp _bracketed = RegExp(
  r'\s*[(\[]\s*(?:featuring|feat\.?|ft\.?)\s+([^)\]]*)[)\]]',
  caseSensitive: false,
);
final RegExp _nul = RegExp(r'\s*\u0000\s*');

List<String> _splitOne(String value, ArtistSplitRules rules) {
  final (masked, kept) = rules.mask(value.replaceAll(_controls, ' '));
  final text = masked.replaceAllMapped(_bracketed, (m) => '\u0000${m[1]}');
  final pieces = text.split(_nul).expand(rules.splitPlain);
  return [
    for (final piece in pieces)
      if (ArtistSplitRules.unmask(piece, kept).trim() case final name
          when name.isNotEmpty)
        name,
  ];
}

/// The artist names in the raw artist [values] of a tag, in order, trimmed,
/// without empty parts and without repeats (compared by [groupKey]; the
/// first spelling is kept). Kept-whole names of [rules] are never cut by any
/// of its separators.
List<String> splitArtists(List<String> values, {ArtistSplitRules? rules}) {
  final active = rules ?? ArtistSplitRules.defaults;
  final names = <String>[];
  final seen = <String>{};
  for (final value in values) {
    for (final name in _splitOne(value, active)) {
      if (seen.add(groupKey(name))) names.add(name);
    }
  }
  return names;
}

/// `(key, name)` pairs for `track_artists`: [splitArtists] with the
/// [groupKey] of each name; names whose key is empty are dropped.
List<({String key, String name})> artistsForRow(
  List<String> values, {
  ArtistSplitRules? rules,
}) => [
  for (final name in splitArtists(values, rules: rules))
    if (groupKey(name) case final key when key.isNotEmpty)
      (key: key, name: name),
];
