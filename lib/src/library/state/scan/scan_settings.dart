import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';

bool _bool(Object? json) {
  if (json is bool) return json;
  throw FormatException('not a bool: $json');
}

/// `library.setup_done`: the user pressed the arrow on the first-run screen.
/// While false the scanner does nothing and the router shows `/welcome`.
final Setting<bool> setupDoneSetting = Setting(
  'library.setup_done',
  false,
  decode: _bool,
  encode: (v) => v,
);

/// `library.skip_short_tracks`: files under 30 seconds are not scanned.
/// No screen changes it yet.
final Setting<bool> skipShortTracksSetting = Setting(
  'library.skip_short_tracks',
  true,
  decode: _bool,
  encode: (v) => v,
);

/// `library.setup_defaults_applied`: the first-run default folders were
/// added once; removing them later does not bring them back.
final Setting<bool> setupDefaultsAppliedSetting = Setting(
  'library.setup_defaults_applied',
  false,
  decode: _bool,
  encode: (v) => v,
);

final setupDoneProvider = settingNotifierProvider(setupDoneSetting);
final skipShortTracksProvider = settingNotifierProvider(skipShortTracksSetting);
final setupDefaultsAppliedProvider = settingNotifierProvider(
  setupDefaultsAppliedSetting,
);
