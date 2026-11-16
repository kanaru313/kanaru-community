import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// The sort chip of `KListSortFilterBar`: no fill, only the criterion name
/// (`"Nghệ sĩ +2"` when several are chosen), 32 dp tall, padding 12. With
/// [arrowAscending] set (the layout still used while callers move to the new
/// bar) it is the older chip: [minHeight] tall with a direction arrow after
/// the name.
class ListSortChip extends StatelessWidget {
  const ListSortChip({
    super.key,
    required this.chipKey,
    required this.label,
    required this.semanticLabel,
    required this.tooltip,
    required this.maxWidth,
    required this.minHeight,
    required this.onTap,
    this.arrowAscending,
  });

  final GlobalKey chipKey;
  final String label;
  final String semanticLabel;
  final String tooltip;
  final double maxWidth;
  final double minHeight;
  final VoidCallback onTap;
  final bool? arrowAscending;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: InkWell(
            key: chipKey,
            borderRadius: KRadius.full,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    if (arrowAscending != null) ...[
                      const KGap(KSpace.x1),
                      Icon(
                        arrowAscending! ? KIcons.sortAsc : KIcons.sortDesc,
                        size: KIconSize.xs,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
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
