import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_space.dart';

/// Sliver grid whose column count follows the width: as many columns as fit
/// tiles of at least [mobileMinTileWidth] (mobile shell) or
/// [desktopMinTileWidth] (desktop shell), which then share the room evenly.
///
/// With [maxTileWidth] the rule is the other way round: the fewest columns
/// whose tiles are at most that wide (album grid), and the minimums are not
/// needed.
///
/// A tile is `tileWidth * tileAspect + footerExtent` tall: a square cover
/// (aspect 1) plus the text below it. The caller adds its text scale to
/// [footerExtent].
class KCollectionGrid extends StatelessWidget {
  const KCollectionGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileMinTileWidth,
    this.desktopMinTileWidth,
    this.maxTileWidth,
    this.tileAspect = 1,
    this.footerExtent = 0,
    this.spacing = KSpace.x3,
    this.padding = const EdgeInsets.symmetric(horizontal: KSpace.x4),
  }) : assert(
         maxTileWidth != null ||
             (mobileMinTileWidth != null && desktopMinTileWidth != null),
         'give maxTileWidth or both minimum widths',
       );

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double? mobileMinTileWidth;
  final double? desktopMinTileWidth;

  /// Widest a tile may be; wins over the minimums when set.
  final double? maxTileWidth;
  final double tileAspect;
  final double footerExtent;
  final double spacing;
  final EdgeInsets padding;

  /// Columns that fit [width] for tiles of at least [minTileWidth].
  @visibleForTesting
  static int columnsFor(double width, double minTileWidth, double spacing) {
    if (width <= 0) return 1;
    return math.max(1, ((width + spacing) / (minTileWidth + spacing)).floor());
  }

  /// Fewest columns that keep tiles of [width] at most [maxTileWidth] wide.
  @visibleForTesting
  static int columnsForMax(double width, double maxTileWidth, double spacing) {
    if (width <= 0) return 1;
    return math.max(1, ((width + spacing) / (maxTileWidth + spacing)).ceil());
  }

  @override
  Widget build(BuildContext context) {
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.crossAxisExtent - padding.horizontal;
        final max = maxTileWidth;
        final columns = max != null
            ? columnsForMax(inner, max, spacing)
            : columnsFor(
                inner,
                (mobile ? mobileMinTileWidth : desktopMinTileWidth)!,
                spacing,
              );
        final tileWidth = (inner - spacing * (columns - 1)) / columns;
        return SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: tileWidth * tileAspect + footerExtent,
            ),
          ),
        );
      },
    );
  }
}
