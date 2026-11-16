import 'package:material_ui/material_ui.dart';

/// Colours of a list row (`KMediaCard`): the neutral fill every row draws and
/// the gradient of the row that is playing. Theme-only: neither follows a
/// cover.
abstract final class KRowColors {
  /// Fill of a plain row: white 5 % on a dark theme, black 4.5 % on a light
  /// one. Translucent, so it keeps the tone of whatever is under the row
  /// (page, sheet, tinted album page).
  static Color fill(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.045);

  /// Left-to-right (start to end) gradient of the playing row:
  /// `primaryContainer`, solid to 25 %, then `tertiaryContainer`.
  static LinearGradient playingGradient(ColorScheme scheme) => LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [
      scheme.primaryContainer,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
    ],
    stops: const [0, 0.25, 1],
  );

  /// Alpha of the secondary text and icons on a playing or selected row.
  static const double containerSoftAlpha = 0.85;

  /// Alpha of the `onSurface` state layer over a row.
  static const double hoverAlpha = 0.08;
  static const double pressAlpha = 0.10;
}
