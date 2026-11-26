import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'k_seek_band.dart';
import 'k_seek_gesture_area.dart';
import 'seek_clock.dart';
import 'seek_look.dart';
import 'squiggle_painter.dart';
import 'waveform_bars.dart';

/// The drawing of the squiggle seek bar (no input): a wavy played line, a
/// straight rest line and a thumb, centred in the height it is given and as
/// wide as `state.width`.
///
/// The wave drifts while [playing], flattens over 300 ms on pause and grows
/// back on play; with [KSquiggleMotion.still] or reduced motion it stands
/// still and full. With [KSquiggleMotion.music] and a [level] its height
/// follows the loudness; without one it drifts. With reduced motion it
/// stands still and ignores the level. No frames are scheduled while
/// paused and settled, and none while `TickerMode` is off.
///
/// [KSquiggleSeekBar] and the waveform bar's fallback both put this track
/// inside their own gesture area: it has no semantics or focus of its own.
class KSquiggleTrack extends StatefulWidget {
  const KSquiggleTrack({
    super.key,
    required this.state,
    this.look = const KSquiggleLook(),
    this.playing = false,
    this.level,
  });

  final KSeekState state;
  final KSquiggleLook look;
  final bool playing;

  /// Loudness 0..1 at the position, for [KSquiggleMotion.music].
  final double? level;

  @override
  State<KSquiggleTrack> createState() => _KSquiggleTrackState();
}

class _KSquiggleTrackState extends State<KSquiggleTrack>
    with SingleTickerProviderStateMixin {
  late final SeekClock _clock = SeekClock(this);
  final _cache = SquigglePaintCache();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(KSquiggleTrack old) {
    super.didUpdateWidget(old);
    _configure();
  }

  void _configure() {
    final still =
        widget.look.motion == KSquiggleMotion.still ||
        MediaQuery.disableAnimationsOf(context);
    _clock.configure(
      target: still || widget.playing ? 1 : 0,
      usesTime: !still,
      instant: still,
    );
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: CustomPaint(
        painter: SquigglePainter(
          progress: widget.state.progress,
          look: widget.look,
          primary: scheme.primary,
          surface: scheme.surface,
          cache: _cache,
          clock: _clock,
          showThumb: widget.state.seekable,
          level: MediaQuery.disableAnimationsOf(context) ? null : widget.level,
        ),
      ),
    );
  }
}

/// Squiggle seek bar: [KSquiggleTrack] in the 56 dp band with the input of
/// every seek bar (tap, drag, keys, hold bubble, drag-up cancel; see
/// [KSeekBand]). The time axis runs over the width minus [seekInset] at each
/// side, as the waveform bar's.
///
/// With [KSquiggleMotion.music] it reads the loudness at [position] from
/// [levels] (0..255, evenly spaced over [levelsDuration], the player's
/// [duration] when null); without levels it drifts.
class KSquiggleSeekBar extends StatefulWidget {
  const KSquiggleSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.track,
    this.look = const KSquiggleLook(),
    this.playing = false,
    this.levels,
    this.levelsDuration,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
    this.bubbleLabel,
    this.cancelLabel,
    this.onScrub,
  });

  final Duration position;
  final Duration? duration;

  /// Identity of the playing item (see [KSeekGestureArea.track]).
  final Object? track;
  final ValueChanged<Duration> onSeek;
  final KSquiggleLook look;
  final bool playing;
  final Uint8List? levels;
  final Duration? levelsDuration;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final Duration keyStep;
  final String Function(Duration at)? bubbleLabel;
  final String? cancelLabel;
  final ValueChanged<Duration?>? onScrub;

  @override
  State<KSquiggleSeekBar> createState() => _KSquiggleSeekBarState();
}

class _KSquiggleSeekBarState extends State<KSquiggleSeekBar> {
  // The contrast-stretched levels of the levels last given.
  Uint8List? _source;
  Uint8List? _contrast;

  double? _level() {
    final levels = widget.levels;
    if (widget.look.motion != KSquiggleMotion.music || levels == null) {
      return null;
    }
    if (!identical(levels, _source)) {
      _source = levels;
      _contrast = waveformContrastLevels(levels);
    }
    final length = widget.levelsDuration ?? widget.duration;
    if (length == null) return null;
    return squiggleLevelAt(
      _contrast,
      position: widget.position,
      length: length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _level();
    return KSeekBand(
      position: widget.position,
      duration: widget.duration,
      trackId: widget.track,
      onSeek: widget.onSeek,
      onSeekStart: widget.onSeekStart,
      onSeekEnd: widget.onSeekEnd,
      semanticLabel: widget.semanticLabel,
      semanticValue: widget.semanticValue,
      keyStep: widget.keyStep,
      bubbleLabel: widget.bubbleLabel,
      cancelLabel: widget.cancelLabel,
      onScrub: widget.onScrub,
      track: (context, inner) => KSquiggleTrack(
        state: inner,
        look: widget.look,
        playing: widget.playing,
        level: level,
      ),
    );
  }
}
