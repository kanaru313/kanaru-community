import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// The big square cover of the mobile Now Playing page: `min(420, width - 64)`
/// wide, radius 20, soft shadow. Its geometry lives here because reading the
/// width to size a layout is allowed only in this package and in `shell/`.
class NowPlayingCoverBox extends StatelessWidget {
  const NowPlayingCoverBox({super.key, required this.builder});

  /// Widest cover.
  static const double maxSide = 420;

  /// Space kept on both sides together.
  static const double sideMargin = 64;

  /// Side of the cover in a column [width] dp wide.
  static double sideFor(double width) =>
      math.max(0, math.min(maxSide, width - sideMargin));

  /// Builds the cover itself at [side] dp (the box adds clipping and shadow).
  final Widget Function(BuildContext context, double side) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = sideFor(box.maxWidth);
        final scheme = Theme.of(context).colorScheme;
        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: KRadius.lg,
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.35),
                  blurRadius: KSpace.x6,
                  offset: const Offset(0, KSpace.x2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: KRadius.lg,
              child: SizedBox.square(
                dimension: side,
                child: builder(context, side),
              ),
            ),
          ),
        );
      },
    );
  }
}
