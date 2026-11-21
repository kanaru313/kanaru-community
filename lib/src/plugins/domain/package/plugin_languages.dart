import '../../../media/domain/library_keys.dart' show languageCodeTable;

/// The JSON wildcard that marks a plugin as global (any language).
const pluginLanguagesGlobal = '*';

/// Most items of a `languages` list that are read; a longer list is ignored.
const _maxListLength = 50;

/// Most distinct languages kept for one plugin.
const _maxKept = 20;

final _validKey = RegExp(r'^[a-z]{2,3}$');

/// A two or three letter code followed only by BCP 47 shaped subtags (script,
/// region): `en-US`, `pt_BR`, `zh-Hant-TW`. Group 1 is the language code.
final _regionTag = RegExp(
  r'^([a-z]{2,3})(?:[-_](?:[a-z]{4}|[a-z]{2}|\d{3}))+$',
);

/// Keys that say nothing about a language: undetermined, no linguistic
/// content, several languages.
const _unusableKeys = {'und', 'zxx', 'mul'};

/// Items that mean "any language": the whole plugin is global.
const _globalAliases = {pluginLanguagesGlobal, 'all', 'any'};

/// Common English names (the table of codes has none).
const _englishNames = {
  'english': 'eng',
  'vietnamese': 'vie',
  'japanese': 'jpn',
  'korean': 'kor',
  'chinese': 'zho',
  'french': 'fra',
  'german': 'deu',
  'spanish': 'spa',
  'italian': 'ita',
  'russian': 'rus',
  'portuguese': 'por',
  'thai': 'tha',
  'indonesian': 'ind',
  'hindi': 'hin',
  'arabic': 'ara',
};

String _keyOf(String text) {
  var lower = text.toLowerCase();
  final base = _regionTag.firstMatch(lower)?.group(1);
  if (base != null) lower = base;
  return languageCodeTable[lower] ?? _englishNames[lower] ?? lower;
}

/// Reads the optional `languages` field of a manifest or catalog entry into
/// the library's language keys (ISO 639-3: `vi` becomes `vie`), so the store's
/// Language filter compares like with like.
///
/// An empty result means "global": the plugin serves any language. The field
/// never makes a plugin invalid, so this never throws: a value that is not a
/// list, a list over 50 items, or a list with no usable item is global. Items
/// that are not strings, are empty, are `und`, `zxx` or `mul`, or are not a
/// 2 to 3 letter code are skipped; repeats are removed; at most 20 are kept.
/// A `*`, `all` or `any` item (any case) makes the whole plugin global.
List<String> parsePluginLanguages(Object? value) {
  if (value is! List || value.length > _maxListLength) return const [];
  final keys = <String>[];
  for (final item in value) {
    if (item is! String) continue;
    final text = item.trim();
    if (_globalAliases.contains(text.toLowerCase())) return const [];
    if (text.isEmpty) continue;
    final key = _keyOf(text);
    if (!_validKey.hasMatch(key) || _unusableKeys.contains(key)) continue;
    if (keys.contains(key) || keys.length >= _maxKept) continue;
    keys.add(key);
  }
  return List.unmodifiable(keys);
}
