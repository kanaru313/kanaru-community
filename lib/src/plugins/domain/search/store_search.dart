import '../package/plugin_kind.dart';

/// A kind a `#tag` in the store search can name. Tags are English only and
/// ignore case.
enum StoreTagKind {
  lyrics(['lyric', 'lyrics'], {PluginKind.lyrics}),
  translate(
    ['translate', 'translation'],
    {PluginKind.translate, PluginKind.aiTranslate},
  ),
  streaming(['streaming', 'music', 'source'], {PluginKind.streaming});

  const StoreTagKind(this.aliases, this.kinds);

  final List<String> aliases;

  /// The plugin kinds the tag stands for.
  final Set<PluginKind> kinds;
}

/// The search box split into kind tags and plain words.
class StoreSearch {
  const StoreSearch({this.tags = const {}, this.words = const []});

  /// Kinds named by complete `#tags`; several mean any of them.
  final Set<StoreTagKind> tags;

  /// The remaining words as typed.
  final List<String> words;

  /// The plugin kinds the tags allow; empty = no tag, every kind.
  Set<PluginKind> get kinds => {for (final t in tags) ...t.kinds};
}

/// The search text a route `?kind=` opens the store with: the kind's first
/// alias and a space (`#lyric `), or empty for a kind without a tag.
String storeSearchForKind(String? kind) {
  for (final k in StoreTagKind.values) {
    if (k.name == kind) return '#${k.aliases.first} ';
  }
  return '';
}

final _blank = RegExp(r'\s+');

StoreTagKind? _kindOf(String word) {
  final w = word.toLowerCase();
  for (final kind in StoreTagKind.values) {
    if (kind.aliases.contains(w)) return kind;
  }
  return null;
}

/// Splits [query] on whitespace. `#word` naming an alias is a kind tag; an
/// unknown `#word` stays plain text; a `#…` that still starts some alias (a
/// tag being typed) is dropped so the list does not empty while typing.
StoreSearch parseStoreSearch(String query) {
  final tags = <StoreTagKind>{};
  final words = <String>[];
  for (final w in query.trim().split(_blank).where((w) => w.isNotEmpty)) {
    if (w.startsWith('#')) {
      final kind = w.length > 1 ? _kindOf(w.substring(1)) : null;
      if (kind != null) {
        tags.add(kind);
        continue;
      }
      final part = w.substring(1).toLowerCase();
      if (StoreTagKind.values.any(
        (k) => k.aliases.any((a) => a.startsWith(part)),
      )) {
        continue;
      }
    }
    words.add(w);
  }
  return StoreSearch(tags: tags, words: words);
}
