import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/state/app_cover_seed.dart';

/// Light and dark theme of the app.
typedef AppThemes = ({ThemeData light, ThemeData dark});

/// Both themes from the stored cover seed (the default brand seed when there
/// is none). Rebuilt only when the seed changes, so a track change that keeps
/// the seed costs nothing.
final appThemeProvider = Provider<AppThemes>((ref) {
  final stored = ref.watch(appCoverSeedProvider);
  final seed = stored == null ? kanaruSeed : Color(stored);
  return (
    light: buildKanaruTheme(brightness: Brightness.light, seed: seed),
    dark: buildKanaruTheme(brightness: Brightness.dark, seed: seed),
  );
});
