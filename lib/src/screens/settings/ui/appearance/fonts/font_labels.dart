import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/app_font.dart';
import '../../../../../fonts/domain/builtin_fonts.dart';

/// Name of [font] for the UI: the System entry is localized, every other font
/// keeps its proper name.
String fontLabel(AppLocalizations l10n, AppFont font) =>
    font.id == systemFontId ? l10n.fontsSystemFont : font.label;
