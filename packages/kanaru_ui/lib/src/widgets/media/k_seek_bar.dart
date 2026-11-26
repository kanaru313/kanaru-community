import 'package:material_ui/material_ui.dart';

import 'flat_effects_painter.dart';
import 'flat_geometry.dart';
import 'k_seek_gesture_area.dart';
import 'seek_clock.dart';
import 'seek_look.dart';
import 'seek_thumb_painter.dart';

/// Flat seek bar: 4 dp track, 4 x 16 dp thumb, in a 24 dp tall hit area.
///
/// Input (tap, drag, Left/Right) is [KSeekGestureArea]'s. The track grows a
/// little under the mouse, with focus or while dragging.
class KSeekBar extends StatelessWidget {
  const KSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.track,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
  });

  static const double hitHeight = 24;
  static const double trackHeight = 4;
  static const double trackHeightActive =
      trackHeight + KFlatSeekTrack.activeGrowth;
  static const double thumbWidth = seekThumbBarWidth;
  static const double thumbHeight = flatThumbBarHeight;

  final Duration position;

  /// Null or zero: nothing to seek in; the bar shows empty and ignores input.
  final Duration? duration;

  /// Identity of the playing item: a drag that outlives it is dropped instead
  /// of seeking the next one.
  final Object? track;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;

  /// Spoken value, for example "1:05 of 3:40".
  final String? semanticValue;
  final Duration keyStep;

  @override
  Widget build(BuildContext context) {
    return KSeekGestureArea(
      position: position,
      duration: duration,
      track: track,
      onSeek: onSeek,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      keyStep: keyStep,
      height: hitHeight,
      builder: (context, state) => KFlatSeekTrack(state: state),
    );
  }
}

/// The straight track and thumb of the flat seek bars, centred in the height
/// it is given. The one renderer of the plain bar (mini player, player bar:
/// the default [look]) and of the Now Playing flat style ([KFlatLook]); the
/// waveform bar shows it while it has no bars.
///
/// The track is [KFlatLook.thickness] thick (the default look: 4 dp) and
/// grows by 2 dp while [KSeekState.active], over 120 ms; the played part slides
/// to a new position over the same 120 ms. An effect of the look
/// runs only while [playing], fades out over 300 ms on pause and is off with
/// reduced motion; with no effect the track never schedules a frame itself.
class KFlatSeekTrack extends StatefulWidget {
  const KFlatSeekTrack({
    super.key,
    required this.state,
    this.look = const KFlatLook(),
    this.playing = false,
  });

  /// Growth of the track while the bar is active, in dp.
  static const double activeGrowth = 2;

  /// How long the track takes to grow or shrink.
  static const Duration growDuration = Duration(milliseconds: 120);

  final KSeekState state;
  final KFlatLook look;

  /// The player is playing: effects of [look] run.
  final bool playing;

  @override
  State<KFlatSeekTrack> createState() => _KFlatSeekTrackState();
}

class _KFlatSeekTrackState extends State<KFlatSeekTrack>
    with SingleTickerProviderStateMixin {
  late final SeekClock _clock = SeekClock(this);
  final _cache = FlatPaintCache();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(KFlatSeekTrack old) {
    super.didUpdateWidget(old);
    _configure();
  }

  void _configure() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final effect = widget.look.effect != KFlatEffect.off;
    _clock.configure(
      target: effect && widget.playing && !reduce ? 1 : 0,
      usesTime: effect,
      instant: reduce,
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
    final look = widget.look;
    final state = widget.state;
    final thickness =
        look.thickness.dp + (state.active ? KFlatSeekTrack.activeGrowth : 0);
    // The played part slides to its target over the same 120 ms as the track
    // grows (the plain bar always did); the thumb jumps.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: state.progress),
      duration: KFlatSeekTrack.growDuration,
      builder: (context, played, _) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: thickness),
        duration: KFlatSeekTrack.growDuration,
        builder: (context, animated, _) => SizedBox.expand(
          child: CustomPaint(
            painter: FlatSeekPainter(
              progress: state.progress,
              playedProgress: played,
              thickness: animated,
              look: look,
              primary: scheme.primary,
              tertiary: scheme.tertiary,
              surface: scheme.surface,
              showThumb: state.seekable,
              cache: _cache,
              clock: look.effect == KFlatEffect.off ? null : _clock,
            ),
          ),
        ),
      ),
    );
  }
}
