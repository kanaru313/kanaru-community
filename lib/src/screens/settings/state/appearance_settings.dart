import 'package:material_ui/material_ui.dart' show ThemeMode, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';

enum ThemeChoice {
  system(ThemeMode.system),
  dark(ThemeMode.dark),
  light(ThemeMode.light);

  const ThemeChoice(this.mode);
  final ThemeMode mode;
}

enum AppLanguage { vi, en }

T _byName<T extends Enum>(List<T> values, Object? json) {
  if (json is String) {
    for (final v in values) {
      if (v.name == json) return v;
    }
  }
  throw FormatException('unknown value: $json');
}

/// Settings key `app.theme`, default [ThemeChoice.system].
final Setting<ThemeChoice> themeChoiceSetting = Setting(
  'app.theme',
  ThemeChoice.system,
  decode: (j) => _byName(ThemeChoice.values, j),
  encode: (v) => v.name,
);

/// The first of the device's preferred languages (in order) that the app
/// ships; English when none matches or the device reports none (Linux `C` /
/// `POSIX`). Used only as the default before the user picks a language.
AppLanguage defaultLanguageFor(Iterable<String> deviceLanguageCodes) {
  for (final code in deviceLanguageCodes) {
    for (final language in AppLanguage.values) {
      if (language.name == code.toLowerCase()) return language;
    }
  }
  return AppLanguage.en;
}

/// The device's preferred languages, most preferred first.
List<String> _deviceLanguageCodes() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final locales = dispatcher.locales.isEmpty
      ? [dispatcher.locale]
      : dispatcher.locales;
  return [for (final l in locales) l.languageCode];
}

Setting<AppLanguage> _languageSetting(List<String> deviceLanguageCodes) =>
    Setting(
      'app.language',
      defaultLanguageFor(deviceLanguageCodes),
      decode: (j) => _byName(AppLanguage.values, j),
      encode: (v) => v.name,
    );

final themeChoiceProvider =
    NotifierProvider<SettingNotifier<ThemeChoice>, ThemeChoice>(
      () => SettingNotifier(themeChoiceSetting),
    );

/// Settings key `app.language`; default from the device locale.
final appLanguageProvider =
    NotifierProvider<SettingNotifier<AppLanguage>, AppLanguage>(
      () => SettingNotifier(_languageSetting(_deviceLanguageCodes())),
    );
