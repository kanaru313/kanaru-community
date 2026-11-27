import 'json_read.dart';
import 'seekbar_field_read.dart';
import 'seekbar_spec.dart';

const _waveKeys = {'kind', 'density', 'color', 'rest'};
const _squigKeys = {'kind', 'amplitude', 'wavelength', 'motion', 'thumb'};
const _flatKeys = {'kind', 'thickness', 'thumb', 'color'};

const _path = 'seekbar.track';

/// What a track falls back to when lenient loading cannot read it.
const defaultSeekbarTrack = FlatTrack();

/// Reads `seekbar.track`. Strict: `kind` is required and a key of another
/// kind is refused (`seekbar.track.amplitude` on `bars`). Lenient: a track
/// that cannot be read is [defaultSeekbarTrack].
SeekbarTrack readSeekbarTrack(Object? value, SeekbarFields f) {
  final raw = asObject(value);
  if (raw == null) return f.refuse(_path, defaultSeekbarTrack);
  final kind = raw['kind'];
  final wave = WaveKind.values.where((k) => k.name == kind).firstOrNull;
  if (wave != null) {
    f.noUnknownKeys(raw, _waveKeys, _path);
    return WaveTrack(
      kind: wave,
      density: f.pick(
        raw,
        'density',
        _path,
        WaveDensity.values,
        WaveDensity.mid,
      ),
      color: f.pick(raw, 'color', _path, WaveColor.values, WaveColor.solid),
      rest: f.pick(raw, 'rest', _path, WaveRest.values, WaveRest.dim),
    );
  }
  switch (kind) {
    case 'squig':
      f.noUnknownKeys(raw, _squigKeys, _path);
      return SquigTrack(
        amplitude: f.pick(
          raw,
          'amplitude',
          _path,
          SquigAmplitude.values,
          SquigAmplitude.mid,
        ),
        wavelength: f.pick(
          raw,
          'wavelength',
          _path,
          SquigWavelength.values,
          SquigWavelength.mid,
        ),
        motion: f.pick(
          raw,
          'motion',
          _path,
          SquigMotion.values,
          SquigMotion.drift,
        ),
        thumb: f.pick(raw, 'thumb', _path, TrackThumb.values, TrackThumb.bar),
      );
    case 'flat':
      f.noUnknownKeys(raw, _flatKeys, _path);
      return FlatTrack(
        thickness: f.pick(
          raw,
          'thickness',
          _path,
          FlatThickness.values,
          FlatThickness.mid,
        ),
        thumb: f.pick(raw, 'thumb', _path, TrackThumb.values, TrackThumb.bar),
        color: f.pick(raw, 'color', _path, FlatColor.values, FlatColor.solid),
      );
  }
  return f.refuse('$_path.kind', defaultSeekbarTrack);
}
