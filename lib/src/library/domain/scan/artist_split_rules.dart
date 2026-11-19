/// What separates the names in an artist tag out of the box: `;` and `/`
/// anywhere, the word entries only between whitespace.
const List<String> defaultArtistSeparators = [
  ';',
  '/',
  'feat.',
  'feat',
  'ft.',
  'ft',
  'featuring',
];

/// Artist names that hold a separator and are one artist, out of the box.
const List<String> defaultArtistKeepWhole = ['AC/DC'];

final RegExp _startsWithLetter = RegExp(r'^\p{L}', unicode: true);

/// First private-use code unit used to stand in for a kept-whole name.
const int _placeholderBase = 0xE000;
const int _placeholderLimit = 0xF8FF;

/// Whether [entry] is a word separator: it starts with a letter (`feat.`,
/// `ft`, `with`) and splits only between whitespace. Any other entry is a
/// symbol (`;`, `/`, `&`, `,`) and splits wherever it appears.
bool isWordSeparator(String entry) => _startsWithLetter.hasMatch(entry);

/// Whether [unit] is one of the private-use code units reserved for
/// placeholders.
bool _isPlaceholderUnit(int unit) =>
    unit >= _placeholderBase && unit <= _placeholderLimit;

/// The separators and kept-whole names an artist tag is split with, compiled
/// once. Entries are escaped, so none can act as a pattern.
class ArtistSplitRules {
  ArtistSplitRules({
    required List<String> separators,
    required List<String> keepWhole,
  }) : _symbols = _alternation(
         [
           for (final s in separators)
             if (!isWordSeparator(s)) s,
         ],
         before: r'\s*',
         after: r'\s*',
       ),
       _words = _alternation(
         [
           for (final s in separators)
             if (isWordSeparator(s)) s,
         ],
         before: r'\s+',
         after: r'\s+',
       ),
       // Longest first, so a name that contains another is masked whole.
       _keep = [
         for (final name in [...keepWhole]..sort((a, b) => b.length - a.length))
           RegExp(
             '(?<![\\p{L}\\p{N}])${RegExp.escape(name)}(?![\\p{L}\\p{N}])',
             caseSensitive: false,
             unicode: true,
           ),
       ];

  /// The rules the app ships with.
  static final ArtistSplitRules defaults = ArtistSplitRules(
    separators: defaultArtistSeparators,
    keepWhole: defaultArtistKeepWhole,
  );

  final RegExp? _symbols;
  final RegExp? _words;
  final List<RegExp> _keep;

  static RegExp? _alternation(
    List<String> entries, {
    required String before,
    required String after,
  }) {
    if (entries.isEmpty) return null;
    // Longest first, so "feat." wins over "feat" when both are active.
    final sorted = [...entries]..sort((a, b) => b.length - a.length);
    return RegExp(
      '$before(?:${sorted.map(RegExp.escape).join('|')})$after',
      caseSensitive: false,
      unicode: true,
    );
  }

  /// [text] with every kept-whole name swapped for one private-use character
  /// (so no separator can cut it) and the names found, by placeholder.
  /// Placeholders are taken from the private-use code units [text] does not
  /// hold, so a private-use character already in a tag is left alone and
  /// never mistaken for a placeholder.
  (String, Map<int, String>) mask(String text) {
    final used = {
      for (final unit in text.codeUnits)
        if (_isPlaceholderUnit(unit)) unit,
    };
    var next = _placeholderBase;
    final found = <int, String>{};
    var out = text;
    for (final pattern in _keep) {
      out = out.replaceAllMapped(pattern, (m) {
        while (next <= _placeholderLimit && used.contains(next)) {
          next++;
        }
        // No free placeholder left: the name stays in the text.
        if (next > _placeholderLimit) return m[0]!;
        final unit = next++;
        found[unit] = m[0]!;
        return String.fromCharCode(unit);
      });
    }
    return (out, found);
  }

  /// Puts the names back in a piece of masked text.
  static String unmask(String text, Map<int, String> found) {
    if (found.isEmpty) return text;
    final out = StringBuffer();
    for (final r in text.runes) {
      final name = found[r];
      if (name == null) {
        out.writeCharCode(r);
      } else {
        out.write(name);
      }
    }
    return out.toString();
  }

  /// [text] cut into the parts the active separators match and the text
  /// between them, for showing where a line would be split. Kept-whole names
  /// stay inside the text parts. Only the separator lists are looked at (not
  /// the bracketed "(feat. B)" part).
  List<({String text, bool separator})> segments(String text) {
    final (masked, kept) = mask(text);
    final spans = <(int, int)>[
      for (final re in [_symbols, _words])
        if (re != null)
          for (final m in re.allMatches(masked))
            if (m.end > m.start) (m.start, m.end),
    ]..sort((a, b) => a.$1 - b.$1);
    final out = <({String text, bool separator})>[];
    var at = 0;
    void plain(int end) {
      if (end > at) {
        out.add((
          text: unmask(masked.substring(at, end), kept),
          separator: false,
        ));
      }
    }

    for (final (start, end) in spans) {
      if (start < at) continue;
      plain(start);
      out.add((
        text: unmask(masked.substring(start, end), kept),
        separator: true,
      ));
      at = end;
    }
    plain(masked.length);
    return out;
  }

  /// Splits [text] on the symbol entries, then the word entries.
  List<String> splitPlain(String text) {
    final symbols = _symbols;
    final words = _words;
    final bySymbol = symbols == null ? [text] : text.split(symbols);
    return [
      for (final piece in bySymbol)
        if (words == null) piece else ...piece.split(words),
    ];
  }
}
