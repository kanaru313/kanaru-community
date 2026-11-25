import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'k_seek_bar.dart';
import 'k_seek_gesture_area.dart';
import 'waveform_band.dart';
import 'waveform_bars.dart';
import 'waveform_phase.dart';

export 'waveform_band.dart' show waveformPlayedAlpha, waveformRestAlpha;

/// Key of the layer that draws the bars.
const ValueKey<String> waveformBandKey = ValueKey('waveform band');

/// Key of the layer that holds the fallback seek bar.
const ValueKey<String> waveformFallbackKey = ValueKey('waveform fallback');

/// Seek bar that draws the loudness of the track as bars in a 56 dp band (the
/// bars use the 32 dp in the middle), without a thumb: the played bars are one
/// colour and the rest another, split at the position.
///
/// Same input and API as [KSeekBar] plus [levels] and [status]. The time axis
/// runs over the width minus [seekInset] at each side: a tap at x seeks to
/// `(x - 6) / (width - 12)` of the duration, and the bars use the same map.
///
/// What it shows follows [status] (see [WaveformPhase]): a dotted row while
/// the waveform is unknown or computing, bars growing from the dots when it is
/// ready, the old bars collapsing when [track] changes, and [fallback] when
/// there is no waveform. The first status after mount shows at once.
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
  });

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

  @override
  State<KWaveformSeekBar> createState() => _KWaveformSeekBarState();
}

class _KWaveformSeekBarState extends State<KWaveformSeekBar>
    with SingleTickerProviderStateMixin {
  final _phase = WaveformPhase();
  final _frames = WaveformBandFrames();
  late final Ticker _ticker;

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
    _phase.onReduceMotion(MediaQuery.disableAnimationsOf(context), _phase.now);
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
    final revision = _phase.revision;
    _phase.onTick(_clockBase + elapsed);
    if (_phase.revision != revision && mounted) setState(() {});
    _syncTicker();
  }

  /// Runs the ticker only while the machine has something pending.
  void _syncTicker() {
    if (_phase.needsTicks) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
      _clockBase = _phase.now;
    }
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
    );
    final build = widget.fallback;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: seekInset),
      child: build != null
          ? build(context, inner)
          : KFlatSeekTrack(state: inner),
    );
  }

  Widget _band(BuildContext context, KSeekState state) {
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
      onSeek: widget.onSeek,
      onSeekStart: widget.onSeekStart,
      onSeekEnd: widget.onSeekEnd,
      semanticLabel: widget.semanticLabel,
      semanticValue: widget.semanticValue,
      keyStep: widget.keyStep,
      height: seekBandHeight,
      horizontalInset: seekInset,
      builder: _band,
    );
  }
}
