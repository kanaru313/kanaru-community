import 'json_read.dart';
import 'package_problem.dart';
import 'seekbar_field_read.dart';
import 'seekbar_limits.dart';
import 'seekbar_part_read.dart';
import 'seekbar_spec.dart';
import 'seekbar_track_read.dart';

const _topKeys = {'track', 'colors', 'baseline', 'glow', 'thumb', 'emitter'};

/// Parses the `seekbar` block, the one reader of the wire format.
///
/// [strict] (install): the first wrong value stops with
/// `InvalidManifest('seekbar.<path>')`; an unknown key at any level is wrong
/// too; a Lottie thumb stops with `UnsupportedFeature`. Not strict (load):
/// never throws; unknown keys are ignored, numbers are clamped, a thumb or
/// emitter that cannot be read is dropped, an unreadable track becomes a flat
/// one.
SeekbarSpec readSeekbarSpec(Object? value, {required bool strict}) {
  final f = SeekbarFields(strict: strict);
  final raw = asObject(value);
  if (raw == null) {
    if (strict) invalid('seekbar');
    return const SeekbarSpec(track: defaultSeekbarTrack);
  }
  f.noUnknownKeys(raw, _topKeys, 'seekbar');
  if (strict && !raw.containsKey('track')) invalid('seekbar.track');
  final track = readSeekbarTrack(raw['track'], f);
  final colors = _colors(raw, f);
  final baseline = f.number(
    raw,
    'baseline',
    'seekbar',
    lo: seekbarBaselineRange.min,
    hi: seekbarBaselineRange.max,
    fallback: seekbarDefaultBaseline,
  );
  final glow = f.number(
    raw,
    'glow',
    'seekbar',
    lo: seekbarGlowRange.min,
    hi: seekbarGlowRange.max,
    fallback: seekbarGlowRange.min,
  );
  return SeekbarSpec(
    track: track,
    primary: colors.primary,
    secondary: colors.secondary,
    baseline: baseline,
    glow: glow,
    thumb: _part(raw, 'thumb', f, readSeekbarThumb),
    emitter: _part(raw, 'emitter', f, readSeekbarEmitter),
  );
}

/// An optional part: strict passes its problem on, lenient drops the part.
T? _part<T>(
  JsonObject raw,
  String key,
  SeekbarFields f,
  T Function(Object?, SeekbarFields) read,
) {
  if (!raw.containsKey(key)) return null;
  try {
    return read(raw[key], f);
  } on PackageProblemError {
    if (f.strict) rethrow;
    return null;
  }
}

({SkinColor? primary, SkinColor? secondary}) _colors(
  JsonObject block,
  SeekbarFields f,
) {
  const none = (primary: null, secondary: null);
  if (!block.containsKey('colors')) return none;
  final raw = asObject(block['colors']);
  if (raw == null) return f.refuse('seekbar.colors', none);
  f.noUnknownKeys(raw, const {'primary', 'secondary'}, 'seekbar.colors');
  return (
    primary: f.optionalColour(raw, 'primary', 'seekbar.colors'),
    secondary: f.optionalColour(raw, 'secondary', 'seekbar.colors'),
  );
}
