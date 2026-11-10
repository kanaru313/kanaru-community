import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// One option of a choice list: value on the left, a primary-colour check on
/// the right of the selected row, tonal rounded fill when selected. The check
/// slot keeps its width when unselected so titles line up. No radio buttons.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;

  /// Icon or logo; omit it and the text starts at the edge.
  final Widget? leading;
  final bool selected;

  /// A disabled row is dimmed and ignores taps.
  final bool enabled;
  final VoidCallback? onTap;

  static const double _checkSlot = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final minHeight = FormFactor.of(context) == FormFactor.mobile
        ? KLayout.minTarget + KSpace.x2
        : KLayout.minTarget;
    final active = enabled && onTap != null;
    return Semantics(
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: KMotion.fast,
          decoration: ShapeDecoration(
            shape: KShape.of(KRadius.md),
            color: selected ? scheme.secondaryContainer : const Color(0x00000000),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: KShape.of(KRadius.md),
              onTap: active ? onTap : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpace.x4,
                    vertical: KSpace.x2,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(color: scheme.onSurfaceVariant),
                          child: leading!,
                        ),
                        const KGap(KSpace.x4),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle.merge(
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: selected ? FontWeight.w700 : null,
                              ),
                              child: title,
                            ),
                            if (subtitle != null)
                              DefaultTextStyle.merge(
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                      const KGap(KSpace.x3),
                      Icon(
                        KIcons.check,
                        size: _checkSlot,
                        color: selected ? scheme.primary : const Color(0x00000000),
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
