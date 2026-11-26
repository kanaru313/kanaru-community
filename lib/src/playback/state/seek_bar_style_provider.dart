import '../../platform/state/settings_providers.dart';
import '../domain/seek_bar_options.dart';
import '../domain/seek_bar_style.dart';

/// Read and write side of the seek bar style.
final seekBarStyleProvider = settingNotifierProvider(seekBarStyleSetting);

/// The style shown while the chosen one has no waveform to draw.
final seekBarFallbackProvider = settingNotifierProvider(seekBarFallbackSetting);

/// Options shared by the wave kinds.
final waveSeekOptionsProvider = settingNotifierProvider(waveSeekOptionsSetting);

/// Options of the squiggle kind.
final squiggleSeekOptionsProvider = settingNotifierProvider(
  squiggleSeekOptionsSetting,
);

/// Options of the flat bar kind.
final flatSeekOptionsProvider = settingNotifierProvider(flatSeekOptionsSetting);
