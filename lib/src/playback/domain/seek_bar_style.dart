import '../../platform/domain/setting.dart';

/// How the seek bar of Now Playing and the lyrics screen is drawn.
enum SeekBarStyle {
  /// Bars from the track's waveform; a flat bar while there are no levels.
  waveform,

  /// A plain flat bar for every track; no waveform is ever decoded.
  flat,
}

/// Settings key `playback.seek_bar_style`, default [SeekBarStyle.waveform]. An
/// unknown stored name falls back to the default.
final Setting<SeekBarStyle> seekBarStyleSetting = Setting(
  'playback.seek_bar_style',
  SeekBarStyle.waveform,
  decode: (json) => enumByName(SeekBarStyle.values, json),
  encode: (v) => v.name,
);
