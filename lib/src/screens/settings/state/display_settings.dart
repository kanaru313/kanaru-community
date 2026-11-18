import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';

/// Text scale steps in percent, as offered by the Settings page.
const List<int> textScaleSteps = [80, 90, 100, 110, 125, 150];

/// Integers decoded from a JSON double must stay exactly representable.
const double _maxExactInt = 9007199254740992; // 2^53

bool _decodeBool(Object? json) {
  if (json is bool) return json;
  throw FormatException('not a bool: $json');
}

/// A whole number from JSON (an int, or a finite double below 2^53 with no
/// fraction); anything else throws.
int _decodeWholeNumber(Object? json) {
  if (json is int) return json;
  if (json is double && json.isFinite && json.abs() < _maxExactInt) {
    final whole = json.truncate();
    if (whole == json) return whole;
  }
  throw FormatException('not a whole number: $json');
}

/// The step nearest to [percent]; the lower step wins a tie.
int _snapToStep(int percent) {
  var best = textScaleSteps.first;
  for (final step in textScaleSteps) {
    if ((step - percent).abs() < (best - percent).abs()) best = step;
  }
  return best;
}

/// Settings key `app.pure_black`, default false: dark theme surfaces in pure
/// black (AMOLED).
final Setting<bool> pureBlackSetting = Setting(
  'app.pure_black',
  false,
  decode: _decodeBool,
  encode: (v) => v,
);

/// Settings key `app.motion`, default true: true follows the system, false
/// turns animations off app-wide.
final Setting<bool> motionSetting = Setting(
  'app.motion',
  true,
  decode: _decodeBool,
  encode: (v) => v,
);

/// Settings key `app.text_scale`, default 100: percent, one of
/// [textScaleSteps]. A stored whole number snaps to the nearest step; a value
/// of another type or a non-finite number throws (default used).
final Setting<int> textScaleSetting = Setting(
  'app.text_scale',
  100,
  decode: (json) => _snapToStep(_decodeWholeNumber(json)),
  encode: (v) => v,
);

final pureBlackProvider = NotifierProvider<SettingNotifier<bool>, bool>(
  () => SettingNotifier(pureBlackSetting),
);

final appMotionProvider = NotifierProvider<SettingNotifier<bool>, bool>(
  () => SettingNotifier(motionSetting),
);

final appTextScaleProvider = NotifierProvider<SettingNotifier<int>, int>(
  () => SettingNotifier(textScaleSetting),
);
