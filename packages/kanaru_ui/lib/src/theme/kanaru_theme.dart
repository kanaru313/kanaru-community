import 'package:flutter/material.dart';

import '../tokens/k_shape.dart';

/// Default brand seed colour.
const Color kanaruSeed = Color(0xFFFFB4A2);

/// Soft Material 3 theme. The Nunito font asset is declared by the app; the
/// theme only names the family.
ThemeData buildKanaruTheme({
  required Brightness brightness,
  Color seed = kanaruSeed,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none),
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
    dialogTheme: DialogThemeData(shape: KShape.of(KRadius.xl, continuous: true)),
    popupMenuTheme: PopupMenuThemeData(shape: KShape.of(KRadius.md)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: KShape.of(KRadius.lg),
    ),
    // Groups are separated by space, not by lines.
    dividerTheme: const DividerThemeData(space: 0, thickness: 0),
  );
}
