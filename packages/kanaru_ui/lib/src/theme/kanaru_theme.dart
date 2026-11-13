import 'package:material_color_utilities/material_color_utilities.dart'
    show Cam16, Hct;
import 'package:material_ui/material_ui.dart';

import '../tokens/k_shape.dart';

/// Default brand seed colour.
const Color kanaruSeed = Color(0xFFFFB4A2);

final _noAnimation = ButtonStyle(animationDuration: Duration.zero);

/// Soft Material 3 theme. The Nunito font asset is declared by the app; the
/// theme only names the family.
ThemeData buildKanaruTheme({
  required Brightness brightness,
  Color seed = kanaruSeed,
}) {
  final scheme = _withDistinctError(
    ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: const OutlineInputBorder(
        borderRadius: KRadius.md,
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      shape: KShape.of(KRadius.lg),
      elevation: 0,
      color: scheme.surfaceContainerLow,
    ),
    dialogTheme: DialogThemeData(
      shape: KShape.of(KRadius.xl, continuous: true),
    ),
    popupMenuTheme: PopupMenuThemeData(shape: KShape.of(KRadius.md)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: KShape.of(KRadius.lg),
    ),
    // A theme change would otherwise make every button lerp its own style
    // for 200 ms (one animated theme per button, on the frame that re-themes
    // the app). Colours switch at once instead.
    iconButtonTheme: IconButtonThemeData(style: _noAnimation),
    filledButtonTheme: FilledButtonThemeData(style: _noAnimation),
    textButtonTheme: TextButtonThemeData(style: _noAnimation),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _noAnimation),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _noAnimation),
    segmentedButtonTheme: SegmentedButtonThemeData(style: _noAnimation),
    // Groups are separated by space, not by lines.
    dividerTheme: const DividerThemeData(space: 0, thickness: 0),
  );
}

/// Below this CAM16-UCS distance an error colour reads as the primary. Dark
/// tonal-spot schemes put both at tone 80, where reds hold little chroma, so a
/// red-family seed (the brand seed included) lands very close to the error.
/// Light pairs stay clear of it, since the light error keeps full chroma.
const double _minErrorDistance = 7;

/// Dark error tone used on a collision: low enough for the requested chroma to
/// show, high enough for 4.5:1 on the dark surfaces and with `onError`.
const double _collidingDarkErrorTone = 65;

/// Chroma of the Material 3 error palette.
const double _errorChroma = 84;

/// In dark mode, swaps `error` for a lower-tone, high-chroma red of the same
/// hue when it sits too close to `primary`. Returns [scheme] itself otherwise.
ColorScheme _withDistinctError(ColorScheme scheme) {
  if (scheme.brightness != Brightness.dark) return scheme;
  final error = scheme.error.toARGB32();
  final distance = Cam16.fromInt(scheme.primary.toARGB32())
      .distance(Cam16.fromInt(error));
  if (distance >= _minErrorDistance) return scheme;
  final hue = Hct.fromInt(error).hue;
  return scheme.copyWith(
    error: Color(Hct.from(hue, _errorChroma, _collidingDarkErrorTone).toInt()),
  );
}
