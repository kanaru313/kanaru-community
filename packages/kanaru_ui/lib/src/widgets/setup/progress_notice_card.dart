import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// A card announcing background work (the library scan on Home): icon, title,
/// subtitle and a thin progress bar. Announced to screen readers as a live
/// region.
class ProgressNoticeCard extends StatelessWidget {
  const ProgressNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.progress,
    this.showBar = true,
  });

  final IconData icon;
  final Widget title;
  final Widget? subtitle;

  /// 0..1; null is an indeterminate bar.
  final double? progress;

  /// False for a finished notice: no bar at all.
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: KShape.of(KRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x3,
          ),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const KGap(KSpace.x3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: textTheme.titleSmall,
                      child: title,
                    ),
                    if (subtitle != null)
                      DefaultTextStyle.merge(
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        child: subtitle!,
                      ),
                    if (showBar) ...[
                      const KGap(KSpace.x2),
                      ClipRRect(
                        borderRadius: KRadius.full,
                        child: LinearProgressIndicator(
                          value: progress?.clamp(0.0, 1.0),
                          minHeight: KSpace.x1,
                          backgroundColor: scheme.secondaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
