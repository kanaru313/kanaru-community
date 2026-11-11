import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';

/// Gives a popup-menu body a fixed width: [maxWidth], or the screen width
/// less a 16 dp margin on each side when that is narrower (a small phone).
/// Rows with an expanding title need a bounded width, and a menu measures
/// its children by intrinsic width, so this cannot use a layout builder.
class KMenuWidth extends StatelessWidget {
  const KMenuWidth({super.key, this.maxWidth = 340, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: math.min(maxWidth, MediaQuery.sizeOf(context).width - KSpace.x4 * 2),
    child: child,
  );
}
