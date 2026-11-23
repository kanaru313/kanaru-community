import 'package:material_ui/material_ui.dart';

import '../../theme/k_row_colors.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../k_check_mark.dart';
import '../k_icon_button_colors.dart';

/// Frame of a `KMediaCard`: dim fade, hover and focus tracking, background
/// material, gradient, text and icon colours, the focus ring and the tap ink.
/// Package-private: not exported from the library.
///
/// The widget tree is the same in every state (a flat or gradient fill is a
/// property, never a different widget), so a state flip repaints the row and
/// never remounts its content.
///
/// [builder] gets whether the pointer hovers or focus is inside the card
/// (the desktop play button reveals on it).
class KMediaCardFrame extends StatefulWidget {
  const KMediaCardFrame({
    super.key,
    required this.background,
    required this.gradient,
    required this.ink,
    required this.soft,
    required this.radius,
    required this.dimmed,
    required this.onTap,
    required this.onLongPress,
    required this.builder,
    this.missing = false,
    this.focusable = false,
  });

  /// `Material.color`; transparent under a [gradient].
  final Color background;
  final Gradient? gradient;
  final Color ink;
  final Color soft;
  final BorderRadius radius;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext context, bool engaged) builder;

  /// Draws a dashed outline (the item's file is gone); the focus ring
  /// replaces it while the row has keyboard focus.
  final bool missing;

  /// Keeps the row focusable by Tab and click when it has no tap action.
  final bool focusable;

  /// Width of the keyboard focus ring.
  static const double ringWidth = 2;

  /// Dashed outline of a missing row: width, dash and gap lengths.
  static const double dashWidth = 1;
  static const double dashLength = 4;
  static const double dashGap = 3;

  /// Key of the dashed outline, for tests.
  @visibleForTesting
  static const Key dashedKey = ValueKey('kMediaCardDashedOutline');

  @override
  State<KMediaCardFrame> createState() => _KMediaCardFrameState();
}

class _KMediaCardFrameState extends State<KMediaCardFrame> {
  bool _hovered = false;
  bool _focused = false;

  // The row's own focus node (the InkWell's): the ring shows when this node,
  // not a button inside the row, has primary focus.
  final FocusNode _node = FocusNode(debugLabel: 'KMediaCard');

  // Focus of a row that is focusable without any tap action (an editing
  // row): no InkWell action, so no tap semantics, cursor or Enter activation.
  final FocusNode _editNode = FocusNode(debugLabel: 'KMediaCard editing');

  bool get _hasTap => widget.onTap != null || widget.onLongPress != null;
  bool get _editOnly => widget.focusable && !_hasTap;
  bool get _primary => _node.hasPrimaryFocus || _editNode.hasPrimaryFocus;

  bool get _engaged => _hovered || _focused;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _editNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    // A row disposed while focused never gets the blur notification.
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _node.removeListener(_onFocus);
    _editNode.removeListener(_onFocus);
    _editNode.dispose();
    _node.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool _listening = false;

  // Only the row whose own node has primary focus can change its ring, so
  // only that row listens to the highlight mode.
  void _onFocus() {
    final focused = _primary;
    if (focused != _listening) {
      _listening = focused;
      if (focused) {
        FocusManager.instance.addHighlightModeListener(_onHighlightMode);
      } else {
        FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
      }
    }
    _refresh();
  }

  void _onHighlightMode(FocusHighlightMode _) => _refresh();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring =
        _primary &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return AnimatedOpacity(
      opacity: widget.dimmed ? 0.5 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : KMotion.fast,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          focusNode: _editNode,
          canRequestFocus: _editOnly,
          skipTraversal: !_editOnly,
          onFocusChange: (v) => setState(() => _focused = v),
          child: Listener(
            // A click puts a focusable row in focus (an InkWell does not on
            // its own), so an editing row can be driven by keys.
            onPointerDown: widget.focusable
                ? (_) => (_hasTap ? _node : _editNode).requestFocus()
                : null,
            child: Material(
              color: widget.background,
              shape: RoundedRectangleBorder(borderRadius: widget.radius),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: widget.gradient == null
                    ? null
                    : BoxDecoration(gradient: widget.gradient),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: widget.ink),
                  child: IconTheme.merge(
                    data: IconThemeData(color: widget.soft),
                    // Light icon buttons read these: on a tinted row they keep
                    // the row's ink instead of the theme colours.
                    child: KIconButtonColors(
                      rest: widget.soft,
                      hover: widget.ink,
                      child: InkWell(
                        focusNode: _node,
                        onTap: widget.onTap,
                        onLongPress: widget.onLongPress,
                        // Hover and press are a state layer over the fill; the
                        // focus ring below replaces the default focus overlay.
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return scheme.onSurface.withValues(
                              alpha: KRowColors.pressAlpha,
                            );
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return scheme.onSurface.withValues(
                              alpha: KRowColors.hoverAlpha,
                            );
                          }
                          return Colors.transparent;
                        }),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            widget.builder(context, _engaged),
                            // Always present, so the content keeps its slot.
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: widget.radius,
                                    border: ring
                                        ? Border.all(
                                            color: scheme.primary,
                                            width: KMediaCardFrame.ringWidth,
                                          )
                                        : null,
                                  ),
                                  position: DecorationPosition.foreground,
                                  child: widget.missing && !ring
                                      ? CustomPaint(
                                          key: KMediaCardFrame.dashedKey,
                                          painter: _DashedBorderPainter(
                                            color: scheme.outline,
                                            radius: widget.radius,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

/// Keeps its room when hidden so the card does not shift; hidden children
/// stay focusable (Tab reveals them) but ignore the pointer.
class KMediaCardRevealed extends StatelessWidget {
  const KMediaCardRevealed({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: KMotion.fast,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

/// Selection overlay of a cover: a 35 % black scrim and an "on" [KCheckMark]
/// when selected, the bare ring while a selection is active. Stays mounted
/// across toggles so the mark animates.
class KMediaCardCoverCheck extends StatelessWidget {
  const KMediaCardCoverCheck({
    super.key,
    required this.circle,
    required this.selected,
    required this.selecting,
    this.radius = KRadius.sm,
  });

  final bool circle;

  /// Corners of a square cover (ignored for [circle]).
  final BorderRadius radius;
  final bool selected;

  /// A selection is active. Without it and without [selected] the overlay
  /// stays mounted (so the off animation plays) but its ring fades out.
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: instant ? Duration.zero : KMotion.fast,
      decoration: BoxDecoration(
        color: selected
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.transparent,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : radius,
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: selecting || selected ? 1 : 0,
          duration: instant ? Duration.zero : KMotion.fast,
          child: KCheckMark(
            size: 28,
            style: KCheckMarkStyle.cover,
            state: selected ? KCheckState.on : KCheckState.off,
          ),
        ),
      ),
    );
  }
}

/// Dashed 1 dp outline along a rounded rect (flat rows: a plain rect).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = KMediaCardFrame.dashWidth / 2;
    final path = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(inset));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = KMediaCardFrame.dashWidth;
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = at + KMediaCardFrame.dashLength;
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + KMediaCardFrame.dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      color != old.color || radius != old.radius;
}
