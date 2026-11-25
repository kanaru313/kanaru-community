import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import 'k_seek_state.dart';

/// Gap between the bottom of the time bubble and the top of its bar.
const double seekBubbleGap = 6;

/// Wraps a seek bar and floats the time under the finger above it while the
/// bar is held or dragged ([KSeekState.pointerFraction]); while the drag is
/// cancelling it shows [cancelLabel] on `errorContainer` instead.
///
/// The bubble lives in the overlay: no clip of the bar cuts it and it takes
/// no room in the layout. It is centred on the finger and kept off the bar's
/// ends (at least half its width, and 32 dp, from them).
class KSeekTimeBubble extends StatefulWidget {
  const KSeekTimeBubble({
    super.key,
    required this.state,
    required this.duration,
    required this.label,
    required this.child,
    this.cancelLabel,
    this.horizontalInset = 0,
  });

  /// The bar's state; the bubble shows while it is holding or dragging.
  final KSeekState state;

  /// Length the pointer fraction is a part of.
  final Duration? duration;

  /// Text for the time under the finger, for example "1:05".
  final String Function(Duration at) label;

  /// Text while the drag is cancelling, for example "Release to cancel".
  /// Null: the time stays.
  final String? cancelLabel;

  /// Room at each side of the bar's time axis, as on its gesture area.
  final double horizontalInset;

  /// The bar.
  final Widget child;

  @override
  State<KSeekTimeBubble> createState() => _KSeekTimeBubbleState();
}

class _KSeekTimeBubbleState extends State<KSeekTimeBubble> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  static const double _fontSize = 12;
  static const double _lineHeight = 20;
  static const double _padV = 2;
  static const double _padH = 8;

  bool get _visible {
    final s = widget.state;
    return s.seekable &&
        s.pointerFraction != null &&
        (s.holding || s.dragging) &&
        (widget.duration?.inMilliseconds ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    // Shown for the life of the widget, before the portal attaches (the
    // controller may not be toggled during a build); the overlay child is
    // empty while the bar is neither held nor dragged.
    _portal.show();
  }

  Widget _bubble(BuildContext context) {
    final state = widget.state;
    final fraction = state.pointerFraction;
    if (!_visible || fraction == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final cancel = state.cancelling && widget.cancelLabel != null;
    final background = cancel ? scheme.errorContainer : scheme.inverseSurface;
    final foreground = cancel
        ? scheme.onErrorContainer
        : scheme.onInverseSurface;
    final text = cancel
        ? widget.cancelLabel!
        : widget.label(
            Duration(
              milliseconds: (widget.duration!.inMilliseconds * fraction)
                  .round(),
            ),
          );
    final scaler = MediaQuery.textScalerOf(context);
    final inset = widget.horizontalInset;
    final x = inset + fraction * (state.width - 2 * inset);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: foreground,
      fontSize: _fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: _lineHeight / _fontSize,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // The overlay gives its child tight constraints: Align frees the follower
    // to take the size of the bubble box.
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: const Offset(0, -seekBubbleGap),
        child: IgnorePointer(
          child: SizedBox(
            width: state.width,
            // The same maths as the text line (scaled font size x height):
            // a nonlinear scaler grows small text more than large text, so
            // scaling the line height itself would leave the box too short.
            height:
                scaler.scale(_fontSize) * (_lineHeight / _fontSize) + 2 * _padV,
            child: CustomSingleChildLayout(
              delegate: _BubbleLayout(x),
              child: Semantics(
                // The slider already speaks the position.
                excludeSemantics: true,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: KRadius.xs,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _padH,
                      vertical: _padV,
                    ),
                    child: Text(
                      text,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _bubble,
        child: widget.child,
      ),
    );
  }
}

/// Centres the bubble on [x], keeping its centre at least half its width and
/// [edge] from both ends.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout(this.x);

  final double x;

  /// About half the width of "h:mm:ss" in the bubble font.
  static const double edge = 32;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final half = childSize.width / 2 > edge ? childSize.width / 2 : edge;
    final low = half;
    final high = size.width - half;
    final centre = high < low ? size.width / 2 : x.clamp(low, high);
    return Offset(centre - childSize.width / 2, 0);
  }

  @override
  bool shouldRelayout(_BubbleLayout old) => old.x != x;
}
