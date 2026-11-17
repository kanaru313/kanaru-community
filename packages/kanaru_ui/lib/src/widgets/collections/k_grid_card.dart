import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// Tile of an album or artist grid: a square cover (or a round photo) as wide
/// as the tile, a title and a subtitle under it. Both texts take one line, so
/// every tile of a grid is [footerExtent] taller than it is wide (give that to
/// `KCollectionGrid.footerExtent`).
///
/// The cover is drawn by [coverBuilder] with the side it may use, so the
/// caller keeps the music types (cover files, seeds) and this widget the
/// layout.
class KGridCard extends StatelessWidget {
  const KGridCard({
    super.key,
    required this.coverBuilder,
    required this.title,
    this.subtitle,
    this.circle = false,
    this.onTap,
    this.onLongPress,
    this.onMenu,
    this.menuLabel,
  }) : assert(onMenu == null || menuLabel != null, 'onMenu needs menuLabel');

  /// Draws the cover in a square of the given side.
  final Widget Function(BuildContext context, double side) coverBuilder;
  final String title;
  final String? subtitle;

  /// Round photo: the title and subtitle are centred.
  final bool circle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Opens the item's menu. The card has no ⋮ button: the caller wraps it in
  /// a context region (long press, right click); this gives screen readers
  /// the same menu as a custom action named [menuLabel].
  final VoidCallback? onMenu;

  /// Name of the screen-reader menu action (needed with [onMenu]).
  final String? menuLabel;

  static const double _titleSize = 14;
  static const double _subtitleSize = 12;
  static const double _lineHeight = 1.35;
  static const double _gap = KSpace.x2;

  /// Height under the cover for [scaler]: gap, title line, subtitle line.
  static double footerExtent(TextScaler scaler) =>
      _gap +
      scaler.scale(_titleSize) * _lineHeight +
      scaler.scale(_subtitleSize) * _lineHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final align = circle ? TextAlign.center : TextAlign.start;
    final menuLabel = this.menuLabel;
    return Semantics(
      button: onTap != null,
      customSemanticsActions: onMenu == null || menuLabel == null
          ? null
          : {CustomSemanticsAction(label: menuLabel): onMenu!},
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: KRadius.md,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth;
            return Column(
              crossAxisAlignment: circle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: side,
                  child: coverBuilder(context, side),
                ),
                const SizedBox(height: _gap),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: align,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: _titleSize,
                      height: _lineHeight,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: align,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: _subtitleSize,
                      height: _lineHeight,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
