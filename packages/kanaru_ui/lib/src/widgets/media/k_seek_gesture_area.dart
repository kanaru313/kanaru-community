import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// What a seek bar draws from: where the thumb is and whether the pointer or
/// keyboard is on the bar.
class KSeekState {
  const KSeekState({
    required this.progress,
    required this.width,
    required this.active,
    required this.seekable,
    this.dragging = false,
    this.focused = false,
    this.keyboardFocus = false,
  });

  /// 0..1; follows the finger while dragging, [KSeekGestureArea.position]
  /// otherwise.
  final double progress;
  final double width;

  /// Hovered, focused or being dragged.
  final bool active;

  /// There is a duration to seek in.
  final bool seekable;

  /// A drag is in progress (a subset of [active]).
  final bool dragging;

  /// Has focus (a subset of [active]), from a click or tap too.
  final bool focused;

  /// Has focus the user is driving with the keyboard: focused, the keyboard
  /// highlight mode is on, no drag runs, and no pointer touched the bar since
  /// focus came or since the last key. A focus ring is drawn only for this
  /// (a mouse click on desktop leaves the highlight mode on keyboard).
  final bool keyboardFocus;
}

/// The input of every seek bar (flat and waveform), without a look of its own.
///
/// - Tap or drag seeks. While dragging the bar follows the finger and ignores
///   [position]; [onSeek] fires once, on release (and on tap), so the engine
///   is not flooded.
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
  });

  final Duration position;

  /// Null or zero: nothing to seek in; the bar ignores input.
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

  /// A tap seeks to the tapped point. False: a tap is not handled here and
  /// falls to an ancestor (a card that opens on tap).
  final bool seekOnTap;

  /// A drag in any direction seeks by its x (a pan with the touch slop of the
  /// device settings, not twice that). False: only horizontal drags seek.
  final bool anyDirection;

  /// Room kept at each side of the time axis: x = [horizontalInset] is the
  /// start and `width - horizontalInset` the end, taps and drags outside clamp.
  final double horizontalInset;

  /// Height of the hit area.
  final double height;
  final Widget Function(BuildContext context, KSeekState state) builder;

  @override
  State<KSeekGestureArea> createState() => _KSeekGestureAreaState();
}

class _KSeekGestureAreaState extends State<KSeekGestureArea> {
  bool _hover = false;
  bool _focus = false;

  /// A pointer focused the bar or touched it while focused; cleared by a key
  /// and when focus goes.
  bool _pointerFocus = false;

  /// 0..1 while dragging; null otherwise.
  double? _drag;

  /// [KSeekGestureArea.track] when the drag began.
  Object? _draggedTrack;
  bool _seeking = false;

  /// The latest touch was cancelled by the system.
  bool _cancelled = false;

  bool get _seekable => (widget.duration?.inMilliseconds ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (mounted && _focus) setState(() {});
  }

  void _onFocusChange(bool focused) {
    setState(() {
      _focus = focused;
      if (!focused) _pointerFocus = false;
    });
  }

  @override
  void didUpdateWidget(KSeekGestureArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag != null && (widget.track != _draggedTrack || !_seekable)) {
      _drag = null;
      _draggedTrack = null;
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
    // Any key means the keyboard drives the bar now: show its focus ring.
    if (_pointerFocus) setState(() => _pointerFocus = false);
    if (event is KeyUpEvent || !_seekable) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _seekBy(-widget.keyStep);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seekBy(widget.keyStep);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _endDrag({required bool commit}) {
    final fraction = _drag;
    final valid =
        commit &&
        fraction != null &&
        _seekable &&
        widget.track == _draggedTrack;
    if (_drag != null || _draggedTrack != null) {
      setState(() {
        _drag = null;
        _draggedTrack = null;
      });
    }
    if (valid) widget.onSeek(_at(fraction));
    if (_seeking) {
      _seeking = false;
      widget.onSeekEnd?.call();
    }
  }

  void _dragStart(Offset local, double width) {
    if (!_seekable) return;
    _draggedTrack = widget.track;
    _seeking = true;
    widget.onSeekStart?.call();
    setState(() => _drag = _fractionOf(local.dx, width));
  }

  void _dragUpdate(Offset local, double width) {
    if (_drag != null) setState(() => _drag = _fractionOf(local.dx, width));
  }

  void _wireDrag(
    DragGestureRecognizer r,
    double width,
    DeviceGestureSettings? settings,
  ) {
    r
      ..gestureSettings = settings
      ..onStart = (d) {
        _dragStart(d.localPosition, width);
      }
      ..onUpdate = (d) {
        _dragUpdate(d.localPosition, width);
      }
      // A cancelled touch after the drag started still ends it in Flutter;
      // [_cancelled] tells the two apart so a cancel never seeks.
      ..onEnd = (_) {
        _endDrag(commit: !_cancelled);
      }
      ..onCancel = () {
        _endDrag(commit: false);
      };
  }

  Map<Type, GestureRecognizerFactory> _gestures(
    BuildContext context,
    double width,
  ) {
    final settings = MediaQuery.maybeGestureSettingsOf(context);
    return {
      if (widget.seekOnTap && _seekable)
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              TapGestureRecognizer.new,
              (r) => r
                ..gestureSettings = settings
                ..onTapUp = (d) {
                  _pointerFocus = true;
                  Focus.of(context).requestFocus();
                  widget.onSeekStart?.call();
                  widget.onSeek(_at(_fractionOf(d.localPosition.dx, width)));
                  widget.onSeekEnd?.call();
                },
            ),
      // The handlers check [_seekable] themselves: a recognizer dropped
      // mid-drag (the track changed and the duration went to zero) would
      // never report the end of the drag, so the horizontal one is always
      // attached. A pan claims any drag, so without a duration it is left
      // out (the drag then belongs to an ancestor), unless one is running.
      if (widget.anyDirection)
        if (_seekable || _drag != null)
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                PanGestureRecognizer.new,
                (r) => _wireDrag(
                  r,
                  width,
                  // Pan slop is twice the touch slop: halve it so a drag
                  // locks after the same distance as a horizontal one.
                  DeviceGestureSettings(
                    touchSlop: (settings?.touchSlop ?? kTouchSlop) / 2,
                  ),
                ),
              ),
      if (!widget.anyDirection)
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(
              HorizontalDragGestureRecognizer.new,
              (r) => _wireDrag(r, width, settings),
            ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration?.inMilliseconds ?? 0;
    final shown =
        _drag ??
        (total > 0
            ? (widget.position.inMilliseconds / total).clamp(0.0, 1.0)
            : 0.0);
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
        onFocusChange: _onFocusChange,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: _seekable ? SystemMouseCursors.click : MouseCursor.defer,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              return Listener(
                onPointerDown: (_) {
                  _cancelled = false;
                  // A pointer on a focused bar hides its keyboard focus ring;
                  // a tap that brings focus sets this itself.
                  if (_focus && !_pointerFocus) {
                    setState(() => _pointerFocus = true);
                  }
                },
                onPointerCancel: (_) => _cancelled = true,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: _gestures(context, width),
                  child: SizedBox(
                    height: widget.height,
                    child: widget.builder(
                      context,
                      KSeekState(
                        progress: shown,
                        width: width,
                        active: _hover || _focus || _drag != null,
                        seekable: _seekable,
                        dragging: _drag != null,
                        focused: _focus,
                        keyboardFocus:
                            _focus &&
                            !_pointerFocus &&
                            _drag == null &&
                            FocusManager.instance.highlightMode ==
                                FocusHighlightMode.traditional,
                      ),
                    ),
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
