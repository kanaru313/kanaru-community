// The `seekbar` block of a seekbar plugin's `plugin.json`, as plain values.
// Read by `readSeekbarSpec` (strict at install, lenient at load).

enum WaveKind { bars, dots, line, mirror }

enum WaveDensity { loose, mid, dense }

enum WaveColor { solid, grad, height }

enum WaveRest { dim, outline, hide }

enum SquigAmplitude { low, mid, high }

enum SquigWavelength { short, mid, long }

enum SquigMotion { drift, music, still }

enum FlatThickness { thin, mid, thick }

enum FlatColor { solid, grad }

/// The marker at the head of a squiggle or flat track.
enum TrackThumb { bar, dot, none }

/// Theme colour a skin may name; resolved against the app scheme at draw
/// time.
enum SkinRole { primary, secondary, tertiary, onSurface, onSurfaceVariant }

/// A colour of the block: a theme role or a fixed `#rrggbb`.
sealed class SkinColor {
  const SkinColor();
}

final class SkinRoleColor extends SkinColor {
  const SkinRoleColor(this.role);

  final SkinRole role;
}

final class SkinRgbColor extends SkinColor {
  const SkinRgbColor(this.rgb);

  /// `0xRRGGBB`, no alpha.
  final int rgb;
}

/// How the track is drawn. One subtype per family of `track.kind`.
sealed class SeekbarTrack {
  const SeekbarTrack();
}

/// `bars`, `dots`, `line` or `mirror`.
final class WaveTrack extends SeekbarTrack {
  const WaveTrack({
    required this.kind,
    this.density = WaveDensity.mid,
    this.color = WaveColor.solid,
    this.rest = WaveRest.dim,
  });

  final WaveKind kind;
  final WaveDensity density;
  final WaveColor color;
  final WaveRest rest;
}

/// `squig`.
final class SquigTrack extends SeekbarTrack {
  const SquigTrack({
    this.amplitude = SquigAmplitude.mid,
    this.wavelength = SquigWavelength.mid,
    this.motion = SquigMotion.drift,
    this.thumb = TrackThumb.bar,
  });

  final SquigAmplitude amplitude;
  final SquigWavelength wavelength;
  final SquigMotion motion;
  final TrackThumb thumb;
}

/// `flat`.
final class FlatTrack extends SeekbarTrack {
  const FlatTrack({
    this.thickness = FlatThickness.mid,
    this.thumb = TrackThumb.bar,
    this.color = FlatColor.solid,
  });

  final FlatThickness thickness;
  final TrackThumb thumb;
  final FlatColor color;
}

/// Image or Lottie drawn at the head of the track.
sealed class SeekbarThumb {
  const SeekbarThumb({
    required this.width,
    required this.height,
    required this.anchorX,
    required this.anchorY,
  });

  /// Draw box in dp.
  final double width;
  final double height;

  /// Where the box sits on (head, baseline), 0..1 of the box.
  final double anchorX;
  final double anchorY;
}

/// A horizontal sprite strip: [frames] equal frames, frame = floor(t * fps)
/// mod frames.
final class SpriteThumb extends SeekbarThumb {
  const SpriteThumb({
    required this.image,
    required super.width,
    required super.height,
    required super.anchorX,
    required super.anchorY,
    this.frames = 1,
    this.fps = 12,
    this.tint,
    this.paused = 0,
  });

  /// Package path, `assets/<name>.png|webp`.
  final String image;
  final int frames;
  final int fps;
  final SkinColor? tint;

  /// Frame shown while paused and with reduced motion, 0..frames-1.
  final int paused;
}

/// A Lottie thumb. Parsed so the format is complete; install refuses it
/// until the app can draw it.
final class LottieThumb extends SeekbarThumb {
  const LottieThumb({
    required this.lottie,
    required super.width,
    required super.height,
    required super.anchorX,
    required super.anchorY,
    this.recolor = const {},
    this.pausedFrame,
  });

  /// Package path, `assets/<name>.json`.
  final String lottie;

  /// Colour per named Lottie group.
  final Map<String, SkinColor> recolor;

  /// Frame shown while paused; null means `"freeze"` (keep the current one).
  final int? pausedFrame;
}

/// Particles spawned at the head while playing.
final class SeekbarEmitter {
  const SeekbarEmitter({
    required this.image,
    required this.width,
    required this.height,
    required this.rate,
    required this.lifeMin,
    required this.lifeMax,
    required this.velocityXMin,
    required this.velocityXMax,
    required this.velocityYMin,
    required this.velocityYMax,
    this.tint,
    this.spinMin = 0,
    this.spinMax = 0,
    this.fade = false,
  });

  final String image;
  final double width;
  final double height;
  final SkinColor? tint;

  /// Particles per second.
  final double rate;
  final double lifeMin;
  final double lifeMax;

  /// px per second; y below 0 goes up.
  final double velocityXMin;
  final double velocityXMax;
  final double velocityYMin;
  final double velocityYMax;

  /// Degrees per second.
  final double spinMin;
  final double spinMax;

  /// Alpha follows 1 - age / life.
  final bool fade;
}

/// The whole block.
class SeekbarSpec {
  const SeekbarSpec({
    required this.track,
    this.primary,
    this.secondary,
    this.baseline = 0.5,
    this.glow = 0,
    this.thumb,
    this.emitter,
  });

  final SeekbarTrack track;

  /// Track colour A and B; null follows the theme.
  final SkinColor? primary;
  final SkinColor? secondary;

  /// Vertical position of the track in the band, 0.2..0.9.
  final double baseline;

  /// Glow blur, 0..16 (sigma = glow / 2).
  final double glow;
  final SeekbarThumb? thumb;
  final SeekbarEmitter? emitter;
}
