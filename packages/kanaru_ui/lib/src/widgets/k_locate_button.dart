import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_motion.dart';
import 'k_icon_button.dart';

/// Which side the target (current row / line) is on, seen from the viewport.
enum KLocateSide { none, above, below }

/// Round filled "go to current" button: nothing while [side] is
/// [KLocateSide.none], else a 48 dp button whose arrow points the way. A flip
/// of the arrow turns it (instant when animations are disabled). The owner
/// places it (bottom right, 16 dp inset).
class KLocateButton extends StatelessWidget {
  const KLocateButton({
    super.key,
    required this.side,
    required this.onPressed,
    required this.tooltip,
  });

  static const double size = 48;

  final KLocateSide side;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (side == KLocateSide.none) return const SizedBox.shrink();
    final up = side == KLocateSide.above;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return SizedBox.square(
      dimension: size,
      child: KIconButton.yieldSpace(
        child: IconButton.filled(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: AnimatedSwitcher(
            duration: duration,
            switchInCurve: KMotion.emphasized,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: Tween(begin: 0.25, end: 0.0).animate(animation),
                child: child,
              ),
            ),
            child: Icon(
              up ? KIcons.arrowUp : KIcons.arrowDown,
              key: ValueKey(up),
            ),
          ),
        ),
      ),
    );
  }
}
