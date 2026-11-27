import 'json_read.dart';
import 'package_problem.dart';
import 'seekbar_features.dart';
import 'seekbar_field_read.dart';
import 'seekbar_limits.dart';
import 'seekbar_spec.dart';

const _spriteKeys = {
  'image',
  'frames',
  'fps',
  'size',
  'anchor',
  'tint',
  'paused',
};
const _lottieKeys = {'lottie', 'size', 'anchor', 'recolor', 'paused'};
const _emitterKeys = {
  'image',
  'tint',
  'size',
  'rate',
  'life',
  'velocity',
  'spin',
  'fade',
};

/// Reads `seekbar.thumb`. Strict also refuses a Lottie thumb with
/// `UnsupportedFeature('seekbar.thumb.lottie')` once the rest of the block
/// reads cleanly: the app cannot draw it yet. Lenient: throws for a part that
/// cannot be repaired; the caller drops it.
SeekbarThumb readSeekbarThumb(Object? value, SeekbarFields f) {
  const path = 'seekbar.thumb';
  final raw = asObject(value);
  if (raw == null) invalid(path);
  final lottie = raw.containsKey('lottie');
  if (lottie == raw.containsKey('image')) invalid(path);
  f.noUnknownKeys(raw, lottie ? _lottieKeys : _spriteKeys, path);
  final size = _size(raw, f, path);
  // Absent gives the default; a present `null` is a wrong value (strict
  // refuses it, lenient falls back to the default).
  final anchor = raw.containsKey('anchor')
      ? f.pair(
          raw['anchor'],
          '$path.anchor',
          lo: seekbarAnchorRange.min,
          hi: seekbarAnchorRange.max,
          fallback: seekbarDefaultAnchor,
        )
      : seekbarDefaultAnchor;
  if (lottie) return _lottie(raw, f, size, anchor);
  final image = _asset(raw['image'], seekbarImageAsset, '$path.image');
  final frames = f.integer(
    raw,
    'frames',
    path,
    lo: seekbarFramesRange.min,
    hi: seekbarFramesRange.max,
    fallback: 1,
  );
  return SpriteThumb(
    image: image,
    width: size[0],
    height: size[1],
    anchorX: anchor[0],
    anchorY: anchor[1],
    frames: frames,
    fps: f.integer(
      raw,
      'fps',
      path,
      lo: seekbarFpsRange.min,
      hi: seekbarFpsRange.max,
      fallback: seekbarDefaultFps,
    ),
    tint: f.optionalColour(raw, 'tint', path),
    paused: f.integer(raw, 'paused', path, lo: 0, hi: frames - 1, fallback: 0),
  );
}

SeekbarThumb _lottie(
  JsonObject raw,
  SeekbarFields f,
  List<double> size,
  List<double> anchor,
) {
  const path = 'seekbar.thumb';
  final file = _asset(raw['lottie'], seekbarLottieAsset, '$path.lottie');
  final recolor = <String, SkinColor>{};
  if (raw.containsKey('recolor')) {
    final map = asObject(raw['recolor']);
    if (map == null) invalid('$path.recolor');
    for (final e in map.entries) {
      final c = f.colour(e.value, '$path.recolor.${e.key}');
      if (c != null) recolor[e.key] = c;
    }
  }
  final paused = raw['paused'];
  int? pausedFrame = 0;
  if (paused == 'freeze') {
    pausedFrame = null;
  } else if (raw.containsKey('paused')) {
    pausedFrame = paused is int && paused >= 0
        ? paused
        : f.refuse('$path.paused', 0);
  }
  if (f.strict) {
    throw const PackageProblemError(UnsupportedFeature(lottieFeature));
  }
  return LottieThumb(
    lottie: file,
    width: size[0],
    height: size[1],
    anchorX: anchor[0],
    anchorY: anchor[1],
    recolor: Map.unmodifiable(recolor),
    pausedFrame: pausedFrame,
  );
}

/// Reads `seekbar.emitter`; same strict / lenient contract as the thumb.
SeekbarEmitter readSeekbarEmitter(Object? value, SeekbarFields f) {
  const path = 'seekbar.emitter';
  final raw = asObject(value);
  if (raw == null) invalid(path);
  f.noUnknownKeys(raw, _emitterKeys, path);
  final image = _asset(raw['image'], seekbarImageAsset, '$path.image');
  final size = _size(raw, f, path);
  for (final key in const ['rate', 'life', 'velocity']) {
    if (!raw.containsKey(key)) invalid('$path.$key');
  }
  final rawRate = raw['rate'];
  if (rawRate is! num) invalid('$path.rate');
  if (f.strict && (rawRate <= 0 || rawRate > emitterRateRange.max)) {
    invalid('$path.rate');
  }
  final life = f.range(
    raw['life'],
    '$path.life',
    lo: f.strict ? 0 : emitterLifeRange.min,
    hi: emitterLifeRange.max,
  );
  if (life[0] <= 0) invalid('$path.life');
  final velocity = asObject(raw['velocity']);
  // Extra keys are refused in strict mode only; lenient ignores them.
  if (velocity == null ||
      (f.strict && velocity.length != 2) ||
      !velocity.containsKey('x') ||
      !velocity.containsKey('y')) {
    invalid('$path.velocity');
  }
  final vx = _velocity(velocity, 'x', f);
  final vy = _velocity(velocity, 'y', f);
  final spin = raw.containsKey('spin')
      ? f.range(
          raw['spin'],
          '$path.spin',
          lo: emitterSpinRange.min,
          hi: emitterSpinRange.max,
        )
      : const [0.0, 0.0];
  return SeekbarEmitter(
    image: image,
    width: size[0],
    height: size[1],
    tint: f.optionalColour(raw, 'tint', path),
    rate: f.strict
        ? rawRate.toDouble()
        : rawRate.toDouble().clamp(emitterRateRange.min, emitterRateRange.max),
    lifeMin: life[0],
    lifeMax: life[1],
    velocityXMin: vx[0],
    velocityXMax: vx[1],
    velocityYMin: vy[0],
    velocityYMax: vy[1],
    spinMin: spin[0],
    spinMax: spin[1],
    fade: f.flag(raw, 'fade', path),
  );
}

List<double> _velocity(JsonObject velocity, String axis, SeekbarFields f) =>
    f.range(
      velocity[axis],
      'seekbar.emitter.velocity.$axis',
      lo: emitterVelocityRange.min,
      hi: emitterVelocityRange.max,
    );

/// `size` is required: `[w, h]` in dp, each with its own range.
List<double> _size(JsonObject raw, SeekbarFields f, String path) {
  final v = raw['size'];
  const at = 'size';
  if (v is! List || v.length != 2 || v.any((x) => x is! num)) {
    invalid('$path.$at');
  }
  return [
    f.numberIn(
      v[0],
      '$path.$at',
      seekbarSizeWidthRange.min,
      seekbarSizeWidthRange.max,
      null,
    ),
    f.numberIn(
      v[1],
      '$path.$at',
      seekbarSizeHeightRange.min,
      seekbarSizeHeightRange.max,
      null,
    ),
  ];
}

String _asset(Object? v, RegExp pattern, String path) {
  if (v is! String || !pattern.hasMatch(v)) invalid(path);
  return v;
}
