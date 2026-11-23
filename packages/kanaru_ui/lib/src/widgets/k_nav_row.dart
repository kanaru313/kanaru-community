import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';

/// One row of a sidebar (desktop sidebar / rail, mobile push sidebar).
///
/// Selected: `primary` 14 % tint (20 % on hover), a 3 dp `primary` bar on the
/// left edge clipped by the corner radius, `primary` [selectedIcon], label
/// `onSurface` w600. [onTap] null = disabled (dimmed, does nothing).
/// [expanded] false = rail: icon only. Keyboard focus draws the shared ring.
class KNavRow extends StatefulWidget {
  const KNavRow({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expanded = true,
    this.leadingInset = KSpace.x3,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool expanded;

  /// Space before the icon; the mobile sidebar uses a smaller one.
  final double leadingInset;

  /// Optional end content (e.g. the "coming soon" text), shown when expanded.
  final Widget? trailing;

  /// Accessible name when it differs from [label] (e.g. "Albums, coming
  /// soon"). Defaults to [label].
  final String? semanticLabel;

  /// Width of the selection bar.
  static const double barWidth = 3;

  @override
  State<KNavRow> createState() => _KNavRowState();
}

class _KNavRowState extends State<KNavRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final selected = widget.selected && enabled;
    final iconColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final labelColor = !enabled
        ? iconColor
        : selected
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final tint = selected
        ? scheme.primary.withValues(alpha: _hovered ? 0.20 : 0.14)
        : Colors.transparent;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: widget.semanticLabel ?? widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: KFocusRing(
          focused: _focused,
          radius: KRadius.xs,
          child: ClipRRect(
            borderRadius: KRadius.xs,
            // The tint sits below the Material, so the pressed splash is
            // painted over it and stays visible.
            child: AnimatedContainer(
              duration: duration,
              height: KLayout.minTarget,
              color: tint,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap,
                  onHover: (v) => setState(() => _hovered = v),
                  onFocusChange: (v) => setState(() => _focused = v),
                  // No hover / focus overlay: the spec tint (and KFocusRing)
                  // are the only hover and focus signals. Pressed keeps ink.
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                        ? null
                        : Colors.transparent,
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: widget.leadingInset),
                          Icon(
                            selected ? widget.selectedIcon : widget.icon,
                            color: iconColor,
                          ),
                          if (widget.expanded) ...[
                            const SizedBox(width: KSpace.x3),
                            Expanded(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: labelColor,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : null,
                                    ),
                              ),
                            ),
                            ?widget.trailing,
                          ],
                        ],
                      ),
                      if (selected)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: KNavRow.barWidth,
                          child: ColoredBox(
                            key: const ValueKey('nav-row-bar'),
                            color: scheme.primary,
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
    );
  }
}
