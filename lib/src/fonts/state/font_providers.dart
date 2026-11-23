import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/state/platform_providers.dart';
import '../../platform/state/settings_providers.dart';
import '../data/font_registrar.dart';
import '../data/font_storage.dart';
import '../domain/builtin_fonts.dart';
import '../domain/font_setting.dart';

final fontStorageProvider = Provider<FontStorage>(
  (ref) => FontStorage(ref.watch(appPathsProvider)),
);

/// `runKanaru` overrides it with the instance used at startup, so the engine
/// state (loaded families) is shared.
final fontLoaderProvider = Provider<FontRegistrar>((ref) => FontRegistrar());

/// Id of the chosen font (`app.font`).
final activeFontIdProvider = settingNotifierProvider(fontSetting);

/// Family of the chosen font for the theme.
final activeFontFamilyProvider = Provider<String>(
  (ref) => appFontFor(ref.watch(activeFontIdProvider)).family,
);
