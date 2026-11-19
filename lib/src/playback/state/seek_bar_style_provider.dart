import '../../platform/state/settings_providers.dart';
import '../domain/seek_bar_style.dart';

/// Read and write side of the seek bar style.
final seekBarStyleProvider = settingNotifierProvider(seekBarStyleSetting);
