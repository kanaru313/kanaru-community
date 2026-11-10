import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_cover.dart';
import '../k_gap.dart';

/// Pastel fill and ink for [seed]: the colours a cover placeholder gets, so a
/// genre tile and its placeholder agree.
({Color fill, Color ink}) _tones(BuildContext context, String seed) {
  final colors = KCoverPlaceholderColors.of(seed, Theme.of(context).brightness);
  return (fill: colors.fill, ink: colors.ink);
}

/// Rounded colour tile of a genre or language grid: bold name, count, a faint
/// icon behind.
class KColorTile extends StatelessWidget {
  const KColorTile({
    super.key,
    required this.seed,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.onLongPress,
  });

  /// Picks the colour (the name, or a key).
  final String seed;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double minHeight = 88;

  @override
  Widget build(BuildContext context) {
    final tones = _tones(context, seed);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      child: Material(
        color: tones.fill,
        shape: KShape.of(KRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Stack(
              children: [
                Positioned(
                  right: -KSpace.x2,
                  bottom: -KSpace.x2,
                  child: ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: 64,
                      color: tones.ink.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(KSpace.x4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: tones.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: tones.ink.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
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

/// Wide colour banner heading a genre or language page: faint icon, large
/// [headline], a [caption] and optional [actions] row.
class KColorBanner extends StatelessWidget {
  const KColorBanner({
    super.key,
    required this.seed,
    required this.icon,
    required this.headline,
    this.caption,
    this.actions,
  });

  final String seed;
  final IconData icon;
  final String headline;
  final String? caption;

  /// Buttons under the text (play, shuffle, more).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final tones = _tones(context, seed);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: tones.fill, borderRadius: KRadius.lg),
      child: ClipRRect(
        borderRadius: KRadius.lg,
        child: Stack(
          children: [
            Positioned(
              right: KSpace.x4,
              top: KSpace.x4,
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 96,
                  color: tones.ink.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: textTheme.headlineMedium?.copyWith(
                      color: tones.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tones.ink.withValues(alpha: 0.85),
                      ),
                    ),
                  if (actions != null) ...[const KGap(KSpace.x4), actions!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
