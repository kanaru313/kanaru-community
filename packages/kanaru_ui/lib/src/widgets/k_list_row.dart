import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// Floating tonal row (settings items, menu entries). At least 48 dp tall;
/// dimmed and inert when [enabled] is false (items marked "coming soon").
class KListRow extends StatelessWidget {
  const KListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.autofocus = false,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  /// Takes focus as soon as its scope does (a menu opened with the keyboard).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerLow,
          shape: KShape.of(KRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            autofocus: autofocus && enabled,
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KLayout.minTarget),
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
                            style: textTheme.bodyLarge,
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
                    if (trailing != null) ...[const KGap(KSpace.x3), trailing!],
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
