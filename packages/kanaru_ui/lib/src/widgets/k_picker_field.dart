import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';

/// A field that shows the chosen value of a select and opens it on tap: a
/// rounded tonal card (`secondaryContainer`, radius md) with the value's
/// [title], an optional [subtitle] (2 lines at most, 80 % opacity) and a
/// round ▾ at the end. It is a field, not a list row: it carries no
/// selected state of its own. Inset 8 dp from both edges.
class KPickerField extends StatelessWidget {
  const KPickerField({
    super.key,
    required this.title,
    required this.semanticLabel,
    required this.onTap,
    this.subtitle,
  });

  /// The chosen value (may carry a badge); bold `titleMedium`.
  final Widget title;
  final String? subtitle;

  /// Spoken name of the field, including its value.
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final fg = scheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x2, 0, KSpace.x2, KSpace.x1),
      child: KPressSurface(
        onPressed: onTap,
        radius: KRadius.md,
        semanticLabel: semanticLabel,
        builder: (context, overlay, _) => DecoratedBox(
          decoration: ShapeDecoration(
            color: Color.alphaBlend(
              fg.withValues(alpha: overlay),
              scheme.secondaryContainer,
            ),
            shape: KShape.of(KRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x2,
              KSpace.x2,
              KSpace.x2,
            ),
            child: Row(
              spacing: KSpace.x2,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: theme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                        child: title,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fg.withValues(alpha: 0.12),
                  ),
                  child: SizedBox.square(
                    dimension: 32,
                    child: Icon(KIcons.collapse, size: KIconSize.md, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
