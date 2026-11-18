import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';
import 'k_pressable.dart';

/// The 56 x 56 button of `KFabMenu`: rounded square with [icon] while closed,
/// a `primary` circle with a rotating-in close glyph while open.
const double _disabledOpacity = 0.5;
const double _shadowBlur = 8;
const Offset _shadowOffset = Offset(0, 2);

class FabMenuButton extends StatelessWidget {
  const FabMenuButton({
    super.key,
    required this.icon,
    required this.open,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool open;
  final String tooltip;
  final VoidCallback onPressed;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.normal;
    final radius = open ? KRadius.full : KRadius.md;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        expanded: open,
        child: AnimatedContainer(
          duration: duration,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: open ? scheme.primary : scheme.primaryContainer,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.2),
                blurRadius: _shadowBlur,
                offset: _shadowOffset,
              ),
            ],
          ),
          child: KPressable(
            radius: radius,
            onTap: onPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: RotationTransition(
                    turns: Tween<double>(
                      begin: -0.25,
                      end: 0,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  open ? KIcons.close : icon,
                  key: ValueKey(open),
                  size: KIconSize.md,
                  color: open ? scheme.onPrimary : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tonal pill of `KFabMenu`: icon, label and an optional trailing widget.
class FabMenuPill extends StatelessWidget {
  const FabMenuPill({
    super.key,
    required this.icon,
    required this.label,
    required this.height,
    required this.enabled,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final double height;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSecondaryContainer;
    return Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: scheme.secondaryContainer,
          elevation: 1,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: KIconSize.md, color: foreground),
                    const KGap(KSpace.x3),
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: foreground),
                      ),
                    ),
                    if (trailing != null) ...[const KGap(KSpace.x2), trailing!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
