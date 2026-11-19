import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'artist_split_rules.dart';

export 'artist_split_rules.dart'
    show defaultArtistKeepWhole, defaultArtistSeparators, isWordSeparator;

/// Longest entry of a separator or keep-whole list, in characters.
const int maxSplitEntryLength = 64;

/// Most entries in one separator or keep-whole list.
const int maxSplitEntries = 64;

/// Which language the library keeps for a track.
enum LanguageSource {
  /// The language tag, else the language detected from the lyrics / text.
  tagThenDetected,

  /// Only the language tag.
  tagOnly,

  /// Only the detected language.
  detectedOnly,
}

/// Why an entry of a separator or keep-whole list was refused.
enum SplitEntryProblem { empty, tooLong, duplicate, listFull }

/// Thrown by [cleanSeparator] and [cleanKeepWhole]. A [FormatException], so
/// a stored list with a refused entry counts as damaged.
class SplitEntryException extends FormatException {
  SplitEntryException(this.problem) : super('split entry refused: $problem');

  final SplitEntryProblem problem;
}

String _cleanEntry(String raw, Iterable<String> existing) {
  final text = String.fromCharCodes([
    for (final unit in raw.codeUnits)
      if (unit >= 0x20 && unit != 0x7f) unit,
  ]).trim();
  if (text.isEmpty) throw SplitEntryException(SplitEntryProblem.empty);
  if (text.runes.length > maxSplitEntryLength) {
    throw SplitEntryException(SplitEntryProblem.tooLong);
  }
  final lower = text.toLowerCase();
  var count = 0;
  for (final e in existing) {
    count++;
    if (e.toLowerCase() == lower) {
      throw SplitEntryException(SplitEntryProblem.duplicate);
    }
  }
  if (count >= maxSplitEntries) {
    throw SplitEntryException(SplitEntryProblem.listFull);
  }
  return text;
}

/// A separator as the list stores it: without control characters, trimmed.
/// Throws [SplitEntryException] when it is empty, longer than
/// [maxSplitEntryLength], already in [existing] (any case) or [existing] is
/// full. The entry check of the page and [decodeSplitEntries] both use it.
String cleanSeparator(String raw, {Iterable<String> existing = const []}) =>
    _cleanEntry(raw, existing);

/// A keep-whole name as the list stores it; same rules as [cleanSeparator].
String cleanKeepWhole(String raw, {Iterable<String> existing = const []}) =>
    _cleanEntry(raw, existing);

/// A stored list of entries. Throws [FormatException] when [json] is not a
/// list of strings or any entry would be refused, so a damaged list falls
/// back to the default as a whole. An empty list is valid.
List<String> decodeSplitEntries(Object? json) {
  if (json is! List) throw FormatException('not a list: $json');
  final out = <String>[];
  for (final item in json) {
    if (item is! String) throw FormatException('not a string: $item');
    out.add(_cleanEntry(item, out));
  }
  return out;
}

/// How tags become library rows, beyond the scan rules: the artist
/// separators, the names kept whole and the language source. A change
/// re-reads every music folder ([fingerprint] tells).
///
/// Fixed, not in the lists: the NUL separator and the bracketed
/// "(feat. ...)" part always split (see `artist_split.dart`).
class LibraryReadRules {
  LibraryReadRules({
    List<String> separators = defaultArtistSeparators,
    List<String> keepWhole = defaultArtistKeepWhole,
    this.languageSource = LanguageSource.tagThenDetected,
  }) : separators = List.unmodifiable(separators),
       keepWhole = List.unmodifiable(keepWhole);

  /// Today's behaviour.
  static final LibraryReadRules defaults = LibraryReadRules();

  final List<String> separators;
  final List<String> keepWhole;
  final LanguageSource languageSource;

  /// The compiled split rules, built on first use.
  late final ArtistSplitRules artistSplit = ArtistSplitRules(
    separators: separators,
    keepWhole: keepWhole,
  );

  /// Lower-hex SHA-1 of the canonical JSON of these rules. Stable across
  /// runs and builds (never a `hashCode`).
  late final String fingerprint = sha1
      .convert(
        utf8.encode(
          jsonEncode({
            'v': 1,
            'sep': separators,
            'keep': keepWhole,
            'lang': languageSource.name,
          }),
        ),
      )
      .toString();

  @override
  bool operator ==(Object other) =>
      other is LibraryReadRules && other.fingerprint == fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;
}
