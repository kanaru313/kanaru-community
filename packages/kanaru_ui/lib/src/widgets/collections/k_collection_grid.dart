import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_space.dart';

/// Sliver grid whose column count follows the width: as many columns as fit
/// tiles of at least [mobileMinTileWidth] (mobile shell) or
/// [desktopMinTileWidth] (desktop shell), which then share the room evenly.
///
/// A tile is `tileWidth * tileAspect + footerExtent` tall: a square cover
/// (aspect 1) plus the text below it. The caller adds its text scale to
/// [footerExtent].
class KCollectionGrid extends StatelessWidget {
  const KCollectionGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.mobileMinTileWidth,
    required this.desktopMinTileWidth,
    this.tileAspect = 1,
    this.footerExtent = 0,
    this.spacing = KSpace.x3,
    this.padding = const EdgeInsets.symmetric(horizontal: KSpace.x4),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mobileMinTileWidth;
  final double desktopMinTileWidth;
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

  @override
  Widget build(BuildContext context) {
    final minTile = FormFactor.of(context) == FormFactor.mobile
        ? mobileMinTileWidth
        : desktopMinTileWidth;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.crossAxisExtent - padding.horizontal;
        final columns = columnsFor(inner, minTile, spacing);
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
