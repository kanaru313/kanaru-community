import '../../platform/domain/setting.dart';
import 'seek_bar_options.dart';

/// How the seek bar of Now Playing and the lyrics screen is drawn.
enum SeekBarStyle {
  /// Vertical bars from the track's waveform.
  bars,

  /// Dots from the track's waveform.
  dots,

  /// A line from the track's waveform.
  line,

  /// Bars mirrored around the centre line, from the track's waveform.
  mirror,

  /// A wavy line; it needs a waveform only while its motion follows the music.
  squiggle,

  /// A plain flat bar for every track; no waveform is ever decoded.
  flat,
}

/// Kinds that draw the track's waveform.
const Set<SeekBarStyle> waveSeekBarStyles = {
  SeekBarStyle.bars,
  SeekBarStyle.dots,
  SeekBarStyle.line,
  SeekBarStyle.mirror,
};

/// Whether the chosen [style] needs the waveform decoded: the wave kinds, or
/// the squiggle while its motion follows the music. The squiggle used as the
/// fallback style never does (its music motion behaves as drift there).
bool needsWaveform(SeekBarStyle style, SquiggleSeekOptions squiggle) =>
    waveSeekBarStyles.contains(style) ||
    (style == SeekBarStyle.squiggle && squiggle.motion == SquiggleMotion.music);

/// Settings key `playback.seek_bar_style`, default [SeekBarStyle.bars]. The
/// names stored before the styles were split map to their successors
/// (`waveform` is [SeekBarStyle.bars]); an unknown name falls back to the
/// default. Reading never rewrites the stored value.
final Setting<SeekBarStyle> seekBarStyleSetting = Setting(
  'playback.seek_bar_style',
  SeekBarStyle.bars,
  decode: (json) =>
      enumByName(SeekBarStyle.values, json == 'waveform' ? 'bars' : json),
  encode: (v) => v.name,
);

/// The style shown while the chosen one cannot be drawn (no waveform).
enum SeekBarFallback { squiggle, flat }

/// Settings key `playback.seek_bar_fallback`, default [SeekBarFallback.flat].
final Setting<SeekBarFallback> seekBarFallbackSetting = Setting(
  'playback.seek_bar_fallback',
  SeekBarFallback.flat,
  decode: (json) => enumByName(SeekBarFallback.values, json),
  encode: (v) => v.name,
);
