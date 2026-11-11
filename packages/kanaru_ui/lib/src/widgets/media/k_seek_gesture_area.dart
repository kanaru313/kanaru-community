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
  });

  /// 0..1; follows the finger while dragging, [KSeekGestureArea.position]
  /// otherwise.
  final double progress;
  final double width;

  /// Hovered, focused or being dragged.
  final bool active;

  /// There is a duration to seek in.
  final bool seekable;
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

  /// Height of the hit area.
  final double height;
  final Widget Function(BuildContext context, KSeekState state) builder;

  @override
  State<KSeekGestureArea> createState() => _KSeekGestureAreaState();
}

class _KSeekGestureAreaState extends State<KSeekGestureArea> {
  bool _hover = false;
  bool _focus = false;

  /// 0..1 while dragging; null otherwise.
  double? _drag;

  /// [KSeekGestureArea.track] when the drag began.
  Object? _draggedTrack;
  bool _seeking = false;

  bool get _seekable => (widget.duration?.inMilliseconds ?? 0) > 0;

  @override
  void didUpdateWidget(KSeekGestureArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag != null && (widget.track != _draggedTrack || !_seekable)) {
      _drag = null;
      _draggedTrack = null;
    }
  }

  double _fractionOf(double dx, double width) =>
      width <= 0 ? 0 : (dx / width).clamp(0.0, 1.0);

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
        onFocusChange: (v) => setState(() => _focus = v),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: _seekable ? SystemMouseCursors.click : MouseCursor.defer,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _seekable
                    ? (d) {
                        Focus.of(context).requestFocus();
                        widget.onSeekStart?.call();
                        widget.onSeek(
                          _at(_fractionOf(d.localPosition.dx, width)),
                        );
                        widget.onSeekEnd?.call();
                      }
                    : null,
                // Always attached, checking [_seekable] inside: a recognizer
                // dropped mid-drag (the track changed and the duration went
                // to zero) would never report the end of the drag.
                onHorizontalDragStart: (d) {
                  if (!_seekable) return;
                  _draggedTrack = widget.track;
                  _seeking = true;
                  widget.onSeekStart?.call();
                  setState(
                    () => _drag = _fractionOf(d.localPosition.dx, width),
                  );
                },
                onHorizontalDragUpdate: (d) {
                  if (_drag != null) {
                    setState(
                      () => _drag = _fractionOf(d.localPosition.dx, width),
                    );
                  }
                },
                onHorizontalDragEnd: (_) => _endDrag(commit: true),
                onHorizontalDragCancel: () => _endDrag(commit: false),
                child: SizedBox(
                  height: widget.height,
                  child: widget.builder(
                    context,
                    KSeekState(
                      progress: shown,
                      width: width,
                      active: _hover || _focus || _drag != null,
                      seekable: _seekable,
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
