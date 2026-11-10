import '../../platform/state/settings_providers.dart';
import '../domain/playback_settings.dart';

/// Read side of the playback settings. Widgets only watch these; every change
/// goes through a player controller command, which is the single writer.
final shuffleSettingProvider = settingNotifierProvider(shuffleSetting);
final repeatSettingProvider = settingNotifierProvider(repeatSetting);
final volumeSettingProvider = settingNotifierProvider(volumeSetting);
final npTabSettingProvider = settingNotifierProvider(npTabSetting);
