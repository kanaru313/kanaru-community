import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// The sort chip of `KListSortFilterBar`: no fill, only the criterion name
/// (`"Nghệ sĩ +2"` when several are chosen), [minHeight] tall, padding 12.
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
  });

  final GlobalKey chipKey;
  final String label;
  final String semanticLabel;
  final String tooltip;
  final double maxWidth;
  final double minHeight;
  final VoidCallback onTap;

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
