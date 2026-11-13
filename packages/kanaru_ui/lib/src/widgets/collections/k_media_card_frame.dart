import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../k_row_icon_action.dart';

/// Frame of a `KMediaCard`: dim, hover and focus tracking, background
/// material, text and icon colours, and the tap ink. Package-private: not
/// exported from the library.
///
/// [builder] gets whether the pointer hovers or focus is inside the card
/// (the desktop play button reveals on it).
class KMediaCardFrame extends StatefulWidget {
  const KMediaCardFrame({
    super.key,
    required this.background,
    required this.ink,
    required this.soft,
    required this.radius,
    required this.dimmed,
    required this.onTap,
    required this.onLongPress,
    required this.builder,
  });

  final Color background;
  final Color ink;
  final Color soft;
  final BorderRadius radius;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext context, bool engaged) builder;

  @override
  State<KMediaCardFrame> createState() => _KMediaCardFrameState();
}

class _KMediaCardFrameState extends State<KMediaCardFrame> {
  bool _hovered = false;
  bool _focused = false;

  bool get _engaged => _hovered || _focused;

  @override
  Widget build(BuildContext context) {
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
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    child: widget.builder(context, _engaged),
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
