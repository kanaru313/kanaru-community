import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../tokens/k_motion.dart';
import 'k_seek_gesture_area.dart';
import 'seek_look.dart';
import 'wave_style.dart';
import 'waveform_bars.dart';
import 'waveform_painter.dart';
import 'waveform_phase.dart';

/// The drawing of one frame of the waveform band: which heights the bars have
/// for the current [WaveformPhase], and the painter that draws them.
///
/// Keeps what must survive between frames: the recorded steady pictures, the
/// bar heights of the current levels, and the dotted row.
class WaveformBandFrames {
  final _pictures = WaveformPictures();
  final _extentsCache = WaveformExtentsCache();

  /// Heights last drawn from live levels: what a collapse starts from, and
  /// what fades out when the levels go before the fade ends.
  List<double>? _liveExtents;
  List<double> _dots = const [];

  /// Heights the band draws now from [phase] and [live] extents, or null when
  /// there are none (a dotted row).
  List<double>? drawnHeights(WaveformPhase phase, List<double>? live) {
    final base = switch (phase.kind) {
      WaveformPhaseKind.growing || WaveformPhaseKind.shown => live,
      _ => phase.snapshot ?? (phase.growT > 0 ? live : null),
    };
    if (base == null) return null;
    final t = KMotion.waveformGrowCurve.transform(phase.growT);
    return t >= 1 ? base : waveformGrownExtents(base, t);
  }

  /// The heights a collapse starts from when the track changes now; forgets
  /// the old track's levels.
  List<double>? takeSnapshot(WaveformPhase phase) {
    final snapshot = drawnHeights(phase, _liveExtents);
    _liveExtents = null;
    return snapshot;
  }

  /// Bar heights for [levels] at [width]; the last ones drawn when the levels
  /// or durations are missing (null when there never were any).
  List<double>? _extents({
    required Uint8List? levels,
    required Duration? levelsDuration,
    required Duration? duration,
    required double width,
    required KWaveDensity density,
  }) {
    final length = levelsDuration ?? duration;
    final axis = (duration ?? Duration.zero) > Duration.zero
        ? duration!
        : levelsDuration;
    if (levels == null ||
        levels.isEmpty ||
        length == null ||
        axis == null ||
        length <= Duration.zero ||
        axis <= Duration.zero) {
      return _liveExtents;
    }
    return _liveExtents = _extentsCache.of(
      levels: levels,
      length: length,
      duration: axis,
      width: width,
      inset: seekInset,
      barWidth: density.barWidth,
      barGap: density.barGap,
    );
  }

  List<double> _dotsFor(double width, KWaveDensity density) {
    final n = waveformBarCount(
      width - 2 * seekInset,
      barWidth: density.barWidth,
      barGap: density.barGap,
    );
    if (_dots.length != n) {
      _dots = List.filled(n, waveformMinExtent, growable: false);
    }
    return _dots;
  }

  /// The painter of the bars for this frame. Steady bars (fully grown, no
  /// fade) draw from recorded pictures; everything else draws its heights.
  /// [factors] (touch feedback in progress) make steady bars draw directly
  /// too, scaled per bar; [factorsRevision] says they changed in place.
  WaveformBandPainter painter({
    required BuildContext context,
    required KSeekState state,
    required WaveformPhase phase,
    required Uint8List? levels,
    required Duration? levelsDuration,
    required Duration? duration,
    KSeekKind kind = KSeekKind.bars,
    KWaveLook look = const KWaveLook(),
    Float32List? factors,
    int factorsRevision = 0,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final live = _extents(
      levels: levels,
      levelsDuration: levelsDuration,
      duration: duration,
      width: state.width,
      density: look.density,
    );
    final fade = phase.fallbackT;
    final grown = phase.kind == WaveformPhaseKind.shown && phase.growT >= 1;
    final steady = grown && fade <= 0 && live != null && live.isNotEmpty;
    final style = WaveStyle(
      kind: kind,
      look: look,
      palette: WavePalette(
        primary: scheme.primary,
        tertiary: scheme.tertiary,
        outline: scheme.outlineVariant,
      ),
    );
    // Feedback frames draw the bars directly; the pictures stay for after.
    final direct = steady && factors != null;

    final painter = WaveformBandPainter(
      progress: state.progress,
      inset: seekInset,
      devicePixelRatio: dpr,
      style: style,
      focusColor: scheme.onSurface.withValues(alpha: 0.7),
      focusLine: state.keyboardFocus && !state.dragging,
      opacity: 1 - fade,
      pictures: steady && !direct
          ? _pictures.pair((
              extents: live,
              size: Size(state.width, seekBandHeight),
              inset: seekInset,
              devicePixelRatio: dpr,
              style: style.recorded,
            ))
          : null,
      heights: steady && !direct
          ? null
          : direct
          ? live
          : (drawnHeights(phase, live) ?? _dotsFor(state.width, look.density)),
      factors: direct ? factors : null,
      factorsRevision: factorsRevision,
    );
    if (!steady) _pictures.dispose();
    return painter;
  }

  void dispose() => _pictures.dispose();
}
