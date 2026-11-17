import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_icon_size.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_cover.dart';
import '../k_detail_title.dart';
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
    this.onMenu,
    this.menuLabel,
  }) : assert(onMenu == null || menuLabel != null, 'onMenu needs menuLabel');

  /// Picks the colour (the name, or a key).
  final String seed;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Opens the item's menu. The tile has no ⋮ button: the caller wraps it in
  /// a context region (long press, right click); this gives screen readers
  /// the same menu as a custom action named [menuLabel].
  final VoidCallback? onMenu;

  /// Name of the screen-reader menu action (needed with [onMenu]).
  final String? menuLabel;

  static const double minHeight = 88;

  /// Faint icon behind the text: a fixed 64 dp watermark, outside the icon
  /// scale.
  static const double _watermark = minHeight - KSpace.x6;

  static const double _padding = KSpace.x4;

  /// Sizes and line heights used when the theme style leaves them out, so the
  /// drawn text and [extentOf] always use the same font size x height.
  static const double _titleSize = 16;
  static const double _titleHeight = 1.5;
  static const double _subtitleSize = 12;
  static const double _subtitleHeight = 1.35;

  static TextStyle _titleStyle(TextTheme theme) {
    final base = theme.titleMedium ?? const TextStyle();
    return base.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: base.fontSize ?? _titleSize,
      height: base.height ?? _titleHeight,
    );
  }

  static TextStyle _subtitleStyle(TextTheme theme) {
    final base = theme.bodySmall ?? const TextStyle();
    return base.copyWith(
      fontSize: base.fontSize ?? _subtitleSize,
      height: base.height ?? _subtitleHeight,
    );
  }

  /// Height a tile needs under [scaler] for a two-line name and a one-line
  /// count: padding plus those lines, never under [minHeight]. Give it to
  /// `KCollectionGrid.footerExtent`; the tile draws its text from the same
  /// styles, so the two cannot drift.
  static double extentOf(TextScaler scaler, TextTheme theme) {
    final title = _titleStyle(theme);
    final sub = _subtitleStyle(theme);
    // The text engine rounds a line up to whole pixels, so do the same.
    double line(TextStyle style) =>
        (scaler.scale(style.fontSize!) * style.height!).ceilToDouble();
    final lines = 2 * line(title) + line(sub);
    return math.max(minHeight, 2 * _padding + lines);
  }

  @override
  Widget build(BuildContext context) {
    final menuLabel = this.menuLabel;
    final tones = _tones(context, seed);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      customSemanticsActions: onMenu == null || menuLabel == null
          ? null
          : {CustomSemanticsAction(label: menuLabel): onMenu!},
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
                      size: _watermark,
                      color: tones.ink.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpace.x4,
                    vertical: _padding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle(textTheme)
                            .copyWith(color: tones.ink),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _subtitleStyle(
                            textTheme,
                          ).copyWith(color: tones.ink.withValues(alpha: 0.8)),
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
/// [headline] (the page's name, up to two lines), the [lines] under it and
/// an optional [actions] row.
class KColorBanner extends StatelessWidget {
  const KColorBanner({
    super.key,
    required this.seed,
    required this.icon,
    required this.headline,
    this.lines = const [],
    this.actions,
  });

  final String seed;
  final IconData icon;
  final String headline;

  /// One line each, in order, under the headline (counts, notes).
  final List<String> lines;

  /// Buttons under the text (play, shuffle, more).
  final Widget? actions;

  /// Faint icon behind the headline: a fixed 96 dp watermark, outside the
  /// icon scale.
  static const double _watermark = KIconSize.hero * 2;

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
                  size: _watermark,
                  color: tones.ink.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KDetailTitle(
                    headline,
                    maxLines: 2,
                    style: textTheme.headlineMedium!.copyWith(
                      color: tones.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  for (final line in lines)
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
