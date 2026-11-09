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

/// Vietnamese devices start in Vietnamese, every other in English.
AppLanguage defaultLanguageFor(String deviceLanguageCode) =>
    deviceLanguageCode == 'vi' ? AppLanguage.vi : AppLanguage.en;

/// First preferred language of the device.
String _deviceLanguageCode() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  return (dispatcher.locales.firstOrNull ?? dispatcher.locale).languageCode;
}

Setting<AppLanguage> _languageSetting(String deviceLanguageCode) => Setting(
  'app.language',
  defaultLanguageFor(deviceLanguageCode),
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
      () => SettingNotifier(_languageSetting(_deviceLanguageCode())),
    );
