import '../../platform/domain/setting.dart';

enum WaveDensity { loose, mid, dense }

enum WavePlayed { single, gradient, height }

enum WaveRest { dim, outline, hidden }

enum WaveFeedback { jelly, lens, off }

enum SquiggleAmplitude { low, mid, high }

enum SquiggleWavelength { short, mid, long }

enum SquiggleMotion { drift, music, still }

enum SeekThumb { bar, dot, none }

enum FlatThickness { thin, mid, thick }

enum FlatPlayed { single, gradient }

enum FlatEffect { off, shine, comet, sparks }

/// One field of an options map: the value of [map] under [key] when it names
/// a member of [values], else [fallback]. A bad field never affects the
/// others.
T _field<T extends Enum>(
  List<T> values,
  Map<String, Object?> map,
  String key,
  T fallback,
) {
  try {
    return enumByName(values, map[key]);
  } on FormatException {
    return fallback;
  }
}

Map<String, Object?> _asMap(Object? json) {
  if (json is Map) {
    return {for (final e in json.entries) e.key.toString(): e.value};
  }
  throw FormatException('not an options map: $json');
}

/// Options of the four wave kinds (bars, dots, line, mirror).
class WaveSeekOptions {
  const WaveSeekOptions({
    this.density = WaveDensity.mid,
    this.played = WavePlayed.single,
    this.rest = WaveRest.dim,
    this.feedback = WaveFeedback.off,
  });

  static const defaults = WaveSeekOptions();

  final WaveDensity density;
  final WavePlayed played;
  final WaveRest rest;
  final WaveFeedback feedback;

  bool get isDefault => this == defaults;

  WaveSeekOptions copyWith({
    WaveDensity? density,
    WavePlayed? played,
    WaveRest? rest,
    WaveFeedback? feedback,
  }) => WaveSeekOptions(
    density: density ?? this.density,
    played: played ?? this.played,
    rest: rest ?? this.rest,
    feedback: feedback ?? this.feedback,
  );

  factory WaveSeekOptions.fromJson(Object? json) {
    final m = _asMap(json);
    return WaveSeekOptions(
      density: _field(WaveDensity.values, m, 'density', defaults.density),
      played: _field(WavePlayed.values, m, 'played', defaults.played),
      rest: _field(WaveRest.values, m, 'rest', defaults.rest),
      feedback: _field(WaveFeedback.values, m, 'feedback', defaults.feedback),
    );
  }

  Map<String, Object?> toJson() => {
    'density': density.name,
    'played': played.name,
    'rest': rest.name,
    'feedback': feedback.name,
  };

  @override
  bool operator ==(Object other) =>
      other is WaveSeekOptions &&
      other.density == density &&
      other.played == played &&
      other.rest == rest &&
      other.feedback == feedback;

  @override
  int get hashCode => Object.hash(density, played, rest, feedback);
}

/// Options of the squiggle kind.
class SquiggleSeekOptions {
  const SquiggleSeekOptions({
    this.amplitude = SquiggleAmplitude.mid,
    this.wavelength = SquiggleWavelength.mid,
    this.motion = SquiggleMotion.drift,
    this.thumb = SeekThumb.bar,
  });

  static const defaults = SquiggleSeekOptions();

  final SquiggleAmplitude amplitude;
  final SquiggleWavelength wavelength;
  final SquiggleMotion motion;
  final SeekThumb thumb;

  bool get isDefault => this == defaults;

  SquiggleSeekOptions copyWith({
    SquiggleAmplitude? amplitude,
    SquiggleWavelength? wavelength,
    SquiggleMotion? motion,
    SeekThumb? thumb,
  }) => SquiggleSeekOptions(
    amplitude: amplitude ?? this.amplitude,
    wavelength: wavelength ?? this.wavelength,
    motion: motion ?? this.motion,
    thumb: thumb ?? this.thumb,
  );

  factory SquiggleSeekOptions.fromJson(Object? json) {
    final m = _asMap(json);
    return SquiggleSeekOptions(
      amplitude: _field(
        SquiggleAmplitude.values,
        m,
        'amplitude',
        defaults.amplitude,
      ),
      wavelength: _field(
        SquiggleWavelength.values,
        m,
        'wavelength',
        defaults.wavelength,
      ),
      motion: _field(SquiggleMotion.values, m, 'motion', defaults.motion),
      thumb: _field(SeekThumb.values, m, 'thumb', defaults.thumb),
    );
  }

  Map<String, Object?> toJson() => {
    'amplitude': amplitude.name,
    'wavelength': wavelength.name,
    'motion': motion.name,
    'thumb': thumb.name,
  };

  @override
  bool operator ==(Object other) =>
      other is SquiggleSeekOptions &&
      other.amplitude == amplitude &&
      other.wavelength == wavelength &&
      other.motion == motion &&
      other.thumb == thumb;

  @override
  int get hashCode => Object.hash(amplitude, wavelength, motion, thumb);
}

/// Options of the flat bar kind.
class FlatSeekOptions {
  const FlatSeekOptions({
    this.thickness = FlatThickness.mid,
    this.thumb = SeekThumb.bar,
    this.played = FlatPlayed.single,
    this.effect = FlatEffect.off,
  });

  static const defaults = FlatSeekOptions();

  final FlatThickness thickness;
  final SeekThumb thumb;
  final FlatPlayed played;
  final FlatEffect effect;

  bool get isDefault => this == defaults;

  FlatSeekOptions copyWith({
    FlatThickness? thickness,
    SeekThumb? thumb,
    FlatPlayed? played,
    FlatEffect? effect,
  }) => FlatSeekOptions(
    thickness: thickness ?? this.thickness,
    thumb: thumb ?? this.thumb,
    played: played ?? this.played,
    effect: effect ?? this.effect,
  );

  factory FlatSeekOptions.fromJson(Object? json) {
    final m = _asMap(json);
    return FlatSeekOptions(
      thickness: _field(
        FlatThickness.values,
        m,
        'thickness',
        defaults.thickness,
      ),
      thumb: _field(SeekThumb.values, m, 'thumb', defaults.thumb),
      played: _field(FlatPlayed.values, m, 'played', defaults.played),
      effect: _field(FlatEffect.values, m, 'effect', defaults.effect),
    );
  }

  Map<String, Object?> toJson() => {
    'thickness': thickness.name,
    'thumb': thumb.name,
    'played': played.name,
    'effect': effect.name,
  };

  @override
  bool operator ==(Object other) =>
      other is FlatSeekOptions &&
      other.thickness == thickness &&
      other.thumb == thumb &&
      other.played == played &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(thickness, thumb, played, effect);
}

/// Settings key `playback.seek_bar_wave`.
final Setting<WaveSeekOptions> waveSeekOptionsSetting = Setting(
  'playback.seek_bar_wave',
  WaveSeekOptions.defaults,
  decode: WaveSeekOptions.fromJson,
  encode: (v) => v.toJson(),
);

/// Settings key `playback.seek_bar_squiggle`.
final Setting<SquiggleSeekOptions> squiggleSeekOptionsSetting = Setting(
  'playback.seek_bar_squiggle',
  SquiggleSeekOptions.defaults,
  decode: SquiggleSeekOptions.fromJson,
  encode: (v) => v.toJson(),
);

/// Settings key `playback.seek_bar_flat`.
final Setting<FlatSeekOptions> flatSeekOptionsSetting = Setting(
  'playback.seek_bar_flat',
  FlatSeekOptions.defaults,
  decode: FlatSeekOptions.fromJson,
  encode: (v) => v.toJson(),
);
