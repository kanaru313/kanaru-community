import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../theme/k_row_colors.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../k_row_icon_action.dart';

/// Frame of a `KMediaCard`: dim, hover and focus tracking, background
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

  /// Width of the keyboard focus ring.
  static const double ringWidth = 2;

  @override
  State<KMediaCardFrame> createState() => _KMediaCardFrameState();
}

class _KMediaCardFrameState extends State<KMediaCardFrame> {
  bool _hovered = false;
  bool _focused = false;
  // The row's own focus node (the InkWell's): the ring shows when this node,
  // not a button inside the row, has primary focus.
  final FocusNode _node = FocusNode(debugLabel: 'KMediaCard');

  bool get _engaged => _hovered || _focused;

  @override
  void initState() {
    super.initState();
    _node.addListener(_refresh);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _node.removeListener(_refresh);
    _node.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  // Only the row whose own node has primary focus can change its ring.
  void _onHighlightMode(FocusHighlightMode _) {
    if (_node.hasPrimaryFocus) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring =
        _node.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Opacity(
      opacity: widget.dimmed ? 0.5 : 1,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (v) => setState(() => _focused = v),
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
                  // Row actions (KRowIconAction) take their colour from this
                  // marker, not from the IconTheme, so one outside a row keeps
                  // its own.
                  child: KRowIconColor(
                    color: widget.soft,
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

/// Primary tint with a white check over a cover.
class KMediaCardSelectedMark extends StatelessWidget {
  const KMediaCardSelectedMark({super.key, required this.circle});

  final bool circle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.55),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : KRadius.sm,
      ),
      child: Icon(KIcons.check, color: scheme.onPrimary),
    );
  }
}
