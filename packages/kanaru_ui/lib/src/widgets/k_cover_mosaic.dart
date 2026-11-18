import 'package:material_ui/material_ui.dart';

import '../tokens/k_shape.dart';

/// Builds one tile of a [KCoverMosaic] at exactly [width] x [height]: draw the
/// cover `BoxFit.cover` into it.
typedef KCoverTileBuilder = Widget Function(
  BuildContext context,
  double width,
  double height,
);

/// A square cover made of two to four covers, no gaps, clipped by [radius]:
/// 2 tiles are two vertical halves; 3 are a vertical half on the left and two
/// squares stacked on the right; 4 are a 2 x 2 grid.
class KCoverMosaic extends StatelessWidget {
  const KCoverMosaic({
    super.key,
    required this.tiles,
    required this.size,
    this.radius,
  }) : assert(
         tiles.length >= 2 && tiles.length <= 4,
         'a mosaic has 2 to 4 tiles, got ${tiles.length}',
       );

  final List<KCoverTileBuilder> tiles;
  final double size;

  /// Corner radius of the whole mosaic; defaults to [KRadius.md].
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final half = size / 2;
    Widget at(int i, double left, double top, double w, double h) => Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: tiles[i](context, w, h),
    );
    final children = switch (tiles.length) {
      2 => [at(0, 0, 0, half, size), at(1, half, 0, half, size)],
      3 => [
        at(0, 0, 0, half, size),
        at(1, half, 0, half, half),
        at(2, half, half, half, half),
      ],
      _ => [
        at(0, 0, 0, half, half),
        at(1, half, 0, half, half),
        at(2, 0, half, half, half),
        at(3, half, half, half, half),
      ],
    };
    return ClipRRect(
      borderRadius: radius ?? KRadius.md,
      child: SizedBox.square(
        dimension: size,
        child: Stack(children: children),
      ),
    );
  }
}
