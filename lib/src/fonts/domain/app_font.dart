/// Where a font comes from.
enum AppFontKind {
  /// Shipped in the app (declared in pubspec); nothing to load.
  builtIn,

  /// Downloaded from the font catalog into the data folder.
  catalog,

  /// Imported by the user into the data folder.
  custom,
}

/// A font the app can use for all its text.
class AppFont {
  const AppFont({
    required this.id,
    required this.label,
    required this.family,
    required this.kind,
  });

  /// Stored in `settings.json`; never changes once shipped.
  final String id;

  /// Proper name of the font; the UI localizes the System entry.
  final String label;

  /// Family name in the theme and in the engine.
  final String family;

  final AppFontKind kind;

  bool get isBuiltIn => kind == AppFontKind.builtIn;
}

const customFontIdPrefix = 'custom_';

final _validFontIdRegExp = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');

/// Whether [id] is well formed and safe to use as a folder name (no
/// separators, dots or traversal).
bool isValidFontId(String? id) => id != null && _validFontIdRegExp.hasMatch(id);

bool isCustomFontId(String id) =>
    isValidFontId(id) && id.startsWith(customFontIdPrefix);

/// Readable fallback for a custom id, e.g. `custom_my_font_1a2b3c4d` becomes
/// `my font`. Used only when the imported font has no stored label.
String customFontFallbackLabel(String id) {
  if (!id.startsWith(customFontIdPrefix)) return id;
  return id
      .substring(customFontIdPrefix.length)
      .replaceFirst(RegExp(r'_[0-9a-f]{8}$'), '')
      .replaceAll('_', ' ')
      .trim();
}
