import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'k_seek_bar.dart';
import 'k_seek_gesture_area.dart';
import 'k_seek_time_bubble.dart';
import 'seek_feedback.dart';
import 'seek_look.dart';
import 'waveform_band.dart';
import 'waveform_bars.dart';
import 'waveform_phase.dart';

export 'wave_style.dart' show waveformPlayedAlpha, waveformRestAlpha;

/// Key of the layer that draws the bars.
const ValueKey<String> waveformBandKey = ValueKey('waveform band');

/// Key of the layer that holds the fallback seek bar.
const ValueKey<String> waveformFallbackKey = ValueKey('waveform fallback');

/// How far above the pointer-down point a drag is cancelled.
const double seekCancelUpDistance = 48;

/// How long a finger rests on the bar before the time bubble shows.
const Duration seekHoldDelay = Duration(milliseconds: 150);

/// Seek bar that draws the loudness of the track as bars, dots, a line or a
/// mirror ([kind], looking as [look] says) in a 56 dp band (the shapes use the
/// 32 dp in the middle), without a thumb: the played part is one colour and the
/// rest another, split at the position.
///
/// The touch feedback of [KWaveLook.feedback] (jelly, lens) draws frames only
/// while a finger is down or a wobble settles, and not at all with reduced
/// motion.
///
/// Same input and API as [KSeekBar] plus [levels] and [status]. The time axis
/// runs over the width minus [seekInset] at each side: a tap at x seeks to
/// `(x - 6) / (width - 12)` of the duration, and the bars use the same map.
///
/// What it shows follows [status] (see [WaveformPhase]): a dotted row while
/// the waveform is unknown or computing, bars growing from the dots when it is
/// ready, the old bars collapsing when [track] changes, and [fallback] when
/// there is no waveform. The first status after mount shows at once.
///
/// With [bubbleLabel] a hold or drag floats the time under the finger above
/// the band ([KSeekTimeBubble]); with [cancelLabel] a drag that goes
/// [seekCancelUpDistance] up is cancelled while it stays there. [onScrub]
/// reports that time to the caller (for its elapsed label and the spoken
/// [semanticValue]), null when it is no longer shown.
class KWaveformSeekBar extends StatefulWidget {
  const KWaveformSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.track,
    this.levels,
    this.levelsDuration,
    this.status = KWaveformStatus.unknown,
    this.fallback,
    this.playing = false,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
    this.bubbleLabel,
    this.cancelLabel,
    this.onScrub,
    this.kind = KSeekKind.bars,
    this.look = const KWaveLook(),
  });

  /// The shape drawn from the levels.
  final KSeekKind kind;

  /// Density, colours, rest and touch feedback of [kind].
  final KWaveLook look;

  final Duration position;
  final Duration? duration;

  /// Identity of the playing item: a drag that outlives it is dropped instead
  /// of seeking the next one, and a change collapses the old bars.
  final Object? track;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final Duration keyStep;

  /// 0..255 loudness, evenly spaced over [levelsDuration].
  final Uint8List? levels;

  /// Length of audio the levels were measured on; the player's [duration]
  /// when null.
  final Duration? levelsDuration;

  /// What is known about the waveform of [track].
  final KWaveformStatus status;

  /// Seek bar shown when there is no waveform. Laid out inside the insets and
  /// given the state of that inner width, so its box width is `state.width`.
  /// Default: [KFlatSeekTrack].
  final Widget Function(BuildContext context, KSeekState state)? fallback;

  /// The player is playing. Not used by the bars; a fallback may animate on it.
  final bool playing;

  /// Time text of the bubble shown while the bar is held or dragged. Null:
  /// no bubble and no hold.
  final String Function(Duration at)? bubbleLabel;

  /// Text of the bubble while a drag is cancelling. Null: no drag-up cancel.
  final String? cancelLabel;

  /// See [KSeekGestureArea.onScrub].
  final ValueChanged<Duration?>? onScrub;

  @override
  State<KWaveformSeekBar> createState() => _KWaveformSeekBarState();
}

class _KWaveformSeekBarState extends State<KWaveformSeekBar>
    with SingleTickerProviderStateMixin {
  final _phase = WaveformPhase();
  final _frames = WaveformBandFrames();
  late final Ticker _ticker;
  final _feedback = SeekFeedback();
  bool _reduceMotion = false;

  /// Ticker time of the last frame, for the feedback's step.
  Duration _lastElapsed = Duration.zero;

  /// A tap or drag is in progress (between the start and end it reports), so
  /// the seek it makes is the pointer's and not a key's.
  bool _pointerSeeking = false;

  /// Width of the band at the last build, for the bar index of a seek.
  double _width = 0;

  /// The clock of [_phase] when the ticker was last stopped; the ticker's own
  /// elapsed time restarts at zero each time it starts.
  Duration _clockBase = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _phase.onStatus(widget.status, _phase.now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _phase.onReduceMotion(_reduceMotion, _phase.now);
    _syncTicker();
  }

  @override
  void didUpdateWidget(KWaveformSeekBar old) {
    super.didUpdateWidget(old);
    // The first track after none (the app still loading its player) has no
    // old bars to collapse and nothing to wait for: it is not a change.
    final trackChanged = widget.track != old.track && old.track != null;
    if (trackChanged) {
      _phase.onTrackChange(_phase.now, snapshot: _frames.takeSnapshot(_phase));
    }
    if (trackChanged || widget.status != old.status) {
      _phase.onStatus(widget.status, _phase.now);
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frames.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final revision = _phase.revision;
    _phase.onTick(_clockBase + elapsed);
    final moved = _feedback.active;
    if (moved) _feedback.advance(dt);
    if ((moved || _phase.revision != revision) && mounted) setState(() {});
    _syncTicker();
  }

  /// Runs the ticker only while the machine has something pending or a touch
  /// feedback moves.
  void _syncTicker() {
    if (_phase.needsTicks || _feedback.active) {
      if (!_ticker.isActive) {
        _lastElapsed = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
      _clockBase = _phase.now;
    }
  }

  /// The feedback that applies now: only while the bars stand fully grown
  /// (not on the dotted row, a transition or the fallback), and none with
  /// reduced motion.
  KSeekFeedback get _feedbackKind {
    final steady =
        _phase.kind == WaveformPhaseKind.shown &&
        _phase.growT >= 1 &&
        _phase.fallbackT <= 0 &&
        widget.levels != null;
    return _reduceMotion || !steady ? KSeekFeedback.off : widget.look.feedback;
  }

  /// Bar index (fractional) at [fraction] of the time axis, in the bars
  /// of the current density and width.
  double _barIndexAt(double fraction) {
    final density = widget.look.density;
    final inner = _width - 2 * seekInset;
    final count = waveformBarCount(
      inner,
      barWidth: density.barWidth,
      barGap: density.barGap,
    );
    final offset = waveformBarsOffset(
      count: count,
      width: _width,
      inset: seekInset,
      barWidth: density.barWidth,
      barGap: density.barGap,
    );
    return (seekInset + inner * fraction - offset) /
        (density.barWidth + density.barGap);
  }

  /// A seek reached the owner: ripples from the bar it landed on.
  void _seeked(Duration to) {
    final total = widget.duration?.inMilliseconds ?? 0;
    if (total > 0) {
      final fraction = (to.inMilliseconds / total).clamp(0.0, 1.0);
      _feedback.poke(_barIndexAt(fraction), _pointerSeeking ? 1 : 0.5);
      _syncTicker();
    }
    widget.onSeek(to);
  }

  /// Every fallback sits inside the insets, so its box is as wide as the
  /// state it gets and `state.progress * state.width` lands on the time axis.
  Widget _fallback(BuildContext context, KSeekState state) {
    final inner = KSeekState(
      progress: state.progress,
      width: (state.width - 2 * seekInset).clamp(0.0, double.infinity),
      active: state.active,
      seekable: state.seekable,
      dragging: state.dragging,
      focused: state.focused,
      keyboardFocus: state.keyboardFocus,
      holding: state.holding,
      cancelling: state.cancelling,
      pointerFraction: state.pointerFraction,
    );
    final build = widget.fallback;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: seekInset),
      child: build != null
          ? build(context, inner)
          : KFlatSeekTrack(state: inner),
    );
  }

  Widget _withBubble(BuildContext context, KSeekState state) {
    final band = _band(context, state);
    final label = widget.bubbleLabel;
    if (label == null) return band;
    return KSeekTimeBubble(
      state: state,
      duration: widget.duration,
      label: label,
      cancelLabel: widget.cancelLabel,
      horizontalInset: seekInset,
      child: band,
    );
  }

  /// Feeds the feedback with what the finger does now and starts its frames.
  void _syncFeedback(KSeekState state) {
    _width = state.width;
    final density = widget.look.density;
    _feedback.configure(
      kind: _feedbackKind,
      count: waveformBarCount(
        state.width - 2 * seekInset,
        barWidth: density.barWidth,
        barGap: density.barGap,
      ),
    );
    final fraction = state.pointerFraction;
    _feedback.press(
      fraction != null && !state.cancelling && state.seekable
          ? _barIndexAt(fraction)
          : null,
    );
    _syncTicker();
  }

  Widget _band(BuildContext context, KSeekState state) {
    _syncFeedback(state);
    final fade = _phase.fallbackT;
    // Built on every frame, also under a full fallback: it keeps the last
    // levels for a collapse and drops the steady pictures when not steady.
    final painter = _frames.painter(
      context: context,
      state: state,
      phase: _phase,
      levels: widget.levels,
      levelsDuration: widget.levelsDuration,
      duration: widget.duration,
      kind: widget.kind,
      look: widget.look,
      factors: _feedback.showing ? _feedback.factors : null,
      factorsRevision: _feedback.revision,
    );
    return ClipRect(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (fade > 0)
              Opacity(
                key: waveformFallbackKey,
                opacity: fade,
                child: _fallback(context, state),
              ),
            if (fade < 1) CustomPaint(key: waveformBandKey, painter: painter),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KSeekGestureArea(
      position: widget.position,
      duration: widget.duration,
      track: widget.track,
      onSeek: _seeked,
      onSeekStart: () {
        _pointerSeeking = true;
        widget.onSeekStart?.call();
      },
      onSeekEnd: () {
        _pointerSeeking = false;
        widget.onSeekEnd?.call();
      },
      semanticLabel: widget.semanticLabel,
      semanticValue: widget.semanticValue,
      keyStep: widget.keyStep,
      height: seekBandHeight,
      horizontalInset: seekInset,
      cancelUpDistance: widget.cancelLabel != null
          ? seekCancelUpDistance
          : null,
      holdDelay: widget.bubbleLabel != null ? seekHoldDelay : null,
      onScrub: widget.onScrub,
      builder: _withBubble,
    );
  }
}
