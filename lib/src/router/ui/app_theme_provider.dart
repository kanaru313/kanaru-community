import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/state/app_cover_seed.dart';
import '../../screens/settings/state/display_settings.dart';

/// Theme of the app for one [Brightness], from the stored cover seed (the
/// default brand seed when there is none).
///
/// Only the brightness in use is watched, so a cover change builds one
/// `ColorScheme` instead of two; the other brightness is built when the theme
/// mode or the system brightness switches to it (an unwatched instance is
/// rebuilt lazily, on its next read). Rebuilt only when the seed or the
/// pure black or motion setting changes, so a track change that keeps the seed costs nothing.
final appThemeProvider = Provider.family<ThemeData, Brightness>((
  ref,
  brightness,
) {
  final stored = ref.watch(appCoverSeedProvider);
  final seed = stored == null ? kanaruSeed : Color(stored);
  var theme = buildKanaruTheme(brightness: brightness, seed: seed);
  // Motion off: page routes get zero durations too (they read the theme).
  if (!ref.watch(appMotionProvider)) {
    theme = theme.copyWith(
      pageTransitionsTheme: kanaruPageTransitionsTheme(instant: true),
    );
  }
  if (brightness != Brightness.dark || !ref.watch(pureBlackProvider)) {
    return theme;
  }
  // Pure black only for the base surface; the container tiers keep their
  // tint so cards and sheets still separate from the background.
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(surface: Colors.black),
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
  );
});
