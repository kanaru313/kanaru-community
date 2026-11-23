import 'app_font.dart';
import 'font_catalog.dart';

const systemFontId = 'system';
const defaultFontId = 'nunito';

const nunitoFont = AppFont(
  id: defaultFontId,
  label: 'Nunito',
  family: 'Nunito',
  kind: AppFontKind.builtIn,
);

const interFont = AppFont(
  id: 'inter',
  label: 'Inter',
  family: 'Inter',
  kind: AppFontKind.builtIn,
);

// 'sans-serif' (not null): Flutter's default family on Linux is its own list,
// while 'sans-serif' follows the fontconfig default.
const systemFont = AppFont(
  id: systemFontId,
  label: 'System',
  family: 'sans-serif',
  kind: AppFontKind.builtIn,
);

const builtInFonts = <AppFont>[systemFont, interFont, nunitoFont];

/// The font with [id] among built-in fonts, catalog fonts and custom ids.
/// An unknown or invalid id gives the default font.
AppFont appFontFor(String id) {
  if (!isValidFontId(id)) return nunitoFont;
  for (final f in builtInFonts) {
    if (f.id == id) return f;
  }
  final catalogFont = catalogFontById(id);
  if (catalogFont != null) return catalogFont.asAppFont;
  if (isCustomFontId(id)) {
    return AppFont(
      id: id,
      label: customFontFallbackLabel(id),
      family: id,
      kind: AppFontKind.custom,
    );
  }
  return nunitoFont;
}
