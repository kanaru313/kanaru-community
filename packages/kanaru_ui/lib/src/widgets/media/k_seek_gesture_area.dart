import 'package:material_ui/material_ui.dart';

import 'k_seek_state.dart';
import 'seek_drag_tracker.dart';
import 'seek_focus_tracker.dart';
import 'seek_hold_tracker.dart';
import 'seek_recognizers.dart';

export 'k_seek_state.dart';

/// The input of every seek bar (flat and waveform), without a look of its own.
///
/// - Tap or drag seeks. While dragging the bar follows the finger and ignores
///   [position]; [onSeek] fires once, on release (and on tap), so the engine
///   is not flooded.
/// - Opt-in: a finger resting [holdDelay] marks the bar as held (a time
///   bubble shows), and a drag that goes [cancelUpDistance] above where the
///   pointer went down is cancelled while it stays there.
/// - Left/Right seek by [keyStep] while it has focus.
/// - The slider semantics (value, increase/decrease) are here too.
class KSeekGestureArea extends StatefulWidget {
  const KSeekGestureArea({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.height,
    required this.builder,
    this.track,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
    this.seekOnTap = true,
    this.anyDirection = false,
    this.horizontalInset = 0,
    this.cancelUpDistance,
    this.holdDelay,
  });

  final Duration position;

  /// Null or zero: nothing to seek in; the bar ignores input.
  final Duration? duration;

  /// Identity of the playing item: a drag that outlives it is dropped instead
  /// of seeking the next one, and a hold on it ends.
  final Object? track;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;

  /// Spoken value, for example "1:05 of 3:40".
  final String? semanticValue;
  final Duration keyStep;

  /// A tap seeks to the tapped point. False: a tap is not handled here and
  /// falls to an ancestor (a card that opens on tap).
  final bool seekOnTap;

  /// A drag in any direction seeks by its x (a pan with the touch slop of the
  /// device settings, not twice that). False: only horizontal drags seek.
  final bool anyDirection;

  /// Room kept at each side of the time axis: x = [horizontalInset] is the
  /// start and `width - horizontalInset` the end, taps and drags outside clamp.
  final double horizontalInset;

  /// A drag whose pointer is more than this many dp above where it went down
  /// is cancelling: the real position shows and a release does not seek;
  /// back below, it seeks again. Mobile gives one haptic tick per upward
  /// crossing. Null: off.
  final double? cancelUpDistance;

  /// A pointer resting this long without moving past the touch slop marks the
  /// bar as held ([KSeekState.holding]). It joins no gesture arena: a release
  /// is still a tap, a horizontal move still a drag, and a vertical move still
  /// goes to an ancestor (the hold then ends). Null: off.
  final Duration? holdDelay;

  /// Height of the hit area.
  final double height;
  final Widget Function(BuildContext context, KSeekState state) builder;

  @override
  State<KSeekGestureArea> createState() => _KSeekGestureAreaState();
}

class _KSeekGestureAreaState extends State<KSeekGestureArea> {
  bool _hover = false;
  late final _focus = SeekFocusTracker(_changed);
  late final _hold = SeekHoldTracker(_changed);

  final _drag = SeekDragTracker();

  /// [KSeekGestureArea.track] when the latest pointer went down: a tap seeks
  /// only on that track (a hold may outlive it).
  Object? _downTrack;

  /// The latest touch was cancelled by the system.
  bool _cancelled = false;

  bool get _seekable => (widget.duration?.inMilliseconds ?? 0) > 0;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.dispose();
    _hold.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KSeekGestureArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged = widget.track != oldWidget.track;
    if (trackChanged || !_seekable) {
      _hold.stop(notify: false);
      _drag.drop();
    }
  }

  double _fractionOf(double dx, double width) {
    final inner = width - 2 * widget.horizontalInset;
    return inner <= 0
        ? 0
        : ((dx - widget.horizontalInset) / inner).clamp(0.0, 1.0);
  }

  Duration _at(double fraction) => Duration(
    milliseconds: (widget.duration!.inMilliseconds * fraction).round(),
  );

  void _seekBy(Duration delta) {
    if (!_seekable) return;
    final total = widget.duration!;
    var target = widget.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    widget.onSeek(target);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final direction = _focus.arrowKey(event);
    if (direction == null || !_seekable) return KeyEventResult.ignored;
    _seekBy(widget.keyStep * direction);
    return KeyEventResult.handled;
  }

  void _endDrag({required bool commit}) {
    _hold.stop();
    final wasDragging = _drag.dragging;
    final (:seekTo, :ended) = _drag.end(
      commit: commit && _seekable,
      track: widget.track,
    );
    if (wasDragging) setState(() {});
    if (seekTo != null) widget.onSeek(_at(seekTo));
    if (ended) widget.onSeekEnd?.call();
  }

  void _dragStart(DragStartDetails d, double width) {
    if (!_seekable) return;
    _hold.stop(notify: false);
    _drag.start(
      fraction: _fractionOf(d.localPosition.dx, width),
      track: widget.track,
      originY: _hold.downGlobal?.dy ?? d.globalPosition.dy,
      globalY: d.globalPosition.dy,
      cancelUp: widget.cancelUpDistance,
    );
    widget.onSeekStart?.call();
    setState(() {});
  }

  void _dragUpdate(DragUpdateDetails d, double width) {
    if (!_drag.dragging) return;
    _drag.update(
      fraction: _fractionOf(d.localPosition.dx, width),
      globalY: d.globalPosition.dy,
    );
    setState(() {});
  }

  Map<Type, GestureRecognizerFactory> _gestures(
    BuildContext context,
    double width,
  ) {
    return seekRecognizers(
      settings: MediaQuery.maybeGestureSettingsOf(context),
      onTapUp: widget.seekOnTap && _seekable
          ? (d) {
              _focus.pointerFocuses();
              Focus.of(context).requestFocus();
              // The track changed under a held finger: not this one's time.
              if (widget.track != _downTrack) return;
              widget.onSeekStart?.call();
              widget.onSeek(_at(_fractionOf(d.localPosition.dx, width)));
              widget.onSeekEnd?.call();
            }
          : null,
      anyDirection: widget.anyDirection,
      // The handlers check [_seekable] themselves: a recognizer dropped
      // mid-drag (the track changed and the duration went to zero) would
      // never report the end of the drag. A pan claims any drag, so without
      // a duration it is left out (the drag then belongs to an ancestor),
      // unless one is running.
      pan: _seekable || _drag.dragging,
      drag: SeekDragHandlers(
        onStart: (d) => _dragStart(d, width),
        onUpdate: (d) => _dragUpdate(d, width),
        // A cancelled touch after the drag started still ends it in Flutter;
        // [_cancelled] tells the two apart so a cancel never seeks.
        onEnd: (_) => _endDrag(commit: !_cancelled),
        // Also when another recognizer won the pointer: that ends a hold.
        onCancel: () => _endDrag(commit: false),
      ),
    );
  }

  KSeekState _state(double width) {
    final total = widget.duration?.inMilliseconds ?? 0;
    final real = total > 0
        ? (widget.position.inMilliseconds / total).clamp(0.0, 1.0)
        : 0.0;
    final drag = _drag.fraction;
    final heldX = drag == null ? _hold.heldX : null;
    final holding = heldX != null && _seekable;
    return KSeekState(
      progress: drag != null && !_drag.cancelling ? drag : real,
      width: width,
      active: _hover || _focus.focused || drag != null || holding,
      seekable: _seekable,
      dragging: drag != null,
      focused: _focus.focused,
      keyboardFocus: _focus.keyboardFocus(dragging: drag != null),
      holding: holding,
      cancelling: drag != null && _drag.cancelling,
      pointerFraction: drag ?? (holding ? _fractionOf(heldX, width) : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      enabled: _seekable,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      // Flutter wants the adjusted values whenever an adjust action exists;
      // the screen reader re-reads the live value after the seek.
      increasedValue: widget.semanticValue,
      decreasedValue: widget.semanticValue,
      onIncrease: _seekable && widget.semanticValue != null
          ? () => _seekBy(widget.keyStep)
          : null,
      onDecrease: _seekable && widget.semanticValue != null
          ? () => _seekBy(-widget.keyStep)
          : null,
      child: Focus(
        onKeyEvent: _onKey,
        onFocusChange: _focus.focusChanged,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: _seekable ? SystemMouseCursors.click : MouseCursor.defer,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              return Listener(
                onPointerDown: (e) {
                  _cancelled = false;
                  _downTrack = widget.track;
                  _focus.pointerDown();
                  _hold.down(
                    e,
                    delay: _seekable ? widget.holdDelay : null,
                    settings: MediaQuery.maybeGestureSettingsOf(context),
                  );
                },
                onPointerMove: _hold.move,
                onPointerUp: _hold.end,
                onPointerCancel: (e) {
                  _cancelled = true;
                  _hold.end(e);
                },
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: _gestures(context, width),
                  child: SizedBox(
                    height: widget.height,
                    child: widget.builder(context, _state(width)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
