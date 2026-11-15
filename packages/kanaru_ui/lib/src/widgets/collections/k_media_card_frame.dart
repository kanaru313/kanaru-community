import 'package:material_ui/material_ui.dart';

import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../k_check_mark.dart';
import '../k_icon_button_colors.dart';

/// Frame of a `KMediaCard`: dim fade, hover and focus tracking, background
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
    return AnimatedOpacity(
      opacity: widget.dimmed ? 0.5 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : KMotion.fast,
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
                // Light icon buttons read these: on a tinted row they keep
                // the row's ink instead of the theme colours.
                child: KIconButtonColors(
                  rest: widget.soft,
                  hover: widget.ink,
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

/// Selection overlay of a cover: a 35 % black scrim and an "on" [KCheckMark]
/// when selected, the bare ring while a selection is active. Stays mounted
/// across toggles so the mark animates.
class KMediaCardCoverCheck extends StatelessWidget {
  const KMediaCardCoverCheck({
    super.key,
    required this.circle,
    required this.selected,
    required this.selecting,
  });

  final bool circle;
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
        borderRadius: circle ? null : KRadius.sm,
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
