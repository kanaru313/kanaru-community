import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Flat seek bar: 4 dp track, 4 x 16 dp thumb, in a 24 dp tall hit area.
///
/// - Tap or drag seeks. While dragging the bar follows the finger and ignores
///   [position]; [onSeek] fires once, on release (and on tap), so the engine
///   is not flooded.
/// - Left/Right seek by [keyStep] while it has focus.
/// - The track grows a little under the mouse or while dragging.
class KSeekBar extends StatefulWidget {
  const KSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
  });

  static const double hitHeight = 24;
  static const double trackHeight = 4;
  static const double trackHeightActive = 6;
  static const double thumbWidth = 4;
  static const double thumbHeight = 16;

  final Duration position;

  /// Null or zero: nothing to seek in; the bar shows empty and ignores input.
  final Duration? duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;

  /// Spoken value, for example "1:05 of 3:40".
  final String? semanticValue;
  final Duration keyStep;

  @override
  State<KSeekBar> createState() => _KSeekBarState();
}

class _KSeekBarState extends State<KSeekBar> {
  bool _hover = false;
  bool _focus = false;

  /// 0..1 while dragging; null otherwise.
  double? _drag;

  bool get _seekable => (widget.duration?.inMilliseconds ?? 0) > 0;

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

  void _finishDrag() {
    final fraction = _drag;
    if (fraction == null) return;
    setState(() => _drag = null);
    widget.onSeek(_at(fraction));
    widget.onSeekEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.duration?.inMilliseconds ?? 0;
    final shown =
        _drag ??
        (total > 0
            ? (widget.position.inMilliseconds / total).clamp(0.0, 1.0)
            : 0.0);
    final grown = _hover || _focus || _drag != null;
    final trackHeight = grown
        ? KSeekBar.trackHeightActive
        : KSeekBar.trackHeight;
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
                onHorizontalDragStart: _seekable
                    ? (d) {
                        widget.onSeekStart?.call();
                        setState(
                          () => _drag = _fractionOf(d.localPosition.dx, width),
                        );
                      }
                    : null,
                onHorizontalDragUpdate: _seekable
                    ? (d) => setState(
                        () => _drag = _fractionOf(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragEnd: _seekable ? (_) => _finishDrag() : null,
                onHorizontalDragCancel: _seekable ? _finishDrag : null,
                child: SizedBox(
                  height: KSeekBar.hitHeight,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: trackHeight,
                          width: width * shown,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(
                              trackHeight / 2,
                            ),
                          ),
                        ),
                      ),
                      if (_seekable)
                        Positioned(
                          left: (width * shown - KSeekBar.thumbWidth / 2).clamp(
                            0.0,
                            (width - KSeekBar.thumbWidth).clamp(0.0, width),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const SizedBox(
                              width: KSeekBar.thumbWidth,
                              height: KSeekBar.thumbHeight,
                            ),
                          ),
                        ),
                    ],
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
