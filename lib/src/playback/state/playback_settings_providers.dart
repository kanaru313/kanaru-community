import '../../platform/state/settings_providers.dart';
import '../domain/playback_settings.dart';

/// Read side of the playback settings. Widgets only watch these; every change
/// goes through a player controller command, which is the single writer.
/// Exception: the last three are plain preferences the Settings
/// page writes itself; the player reads them from the store when it needs them.
final shuffleSettingProvider = settingNotifierProvider(shuffleSetting);
final repeatSettingProvider = settingNotifierProvider(repeatSetting);
final volumeSettingProvider = settingNotifierProvider(volumeSetting);
final volumeBeforeMuteSettingProvider = settingNotifierProvider(
  volumeBeforeMuteSetting,
);

final previousButtonProvider = settingNotifierProvider(previousButtonSetting);
final listenRuleProvider = settingNotifierProvider(listenRuleSetting);
final historyEnabledProvider = settingNotifierProvider(historyEnabledSetting);
