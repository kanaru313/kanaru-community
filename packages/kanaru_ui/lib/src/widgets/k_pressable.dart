import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';

/// Tappable surface: slight scale and tonal overlay while pressed, haptic on
/// long press, focusable (Enter and Space activate it).
class KPressable extends StatefulWidget {
  const KPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? radius;

  @override
  State<KPressable> createState() => _KPressableState();
}

class _KPressableState extends State<KPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? KRadius.md;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final longPress = widget.onLongPress;
    return AnimatedScale(
      scale: _pressed && animate ? 0.97 : 1,
      duration: KMotion.fast,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onLongPress: longPress == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  longPress();
                },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: widget.child,
        ),
      ),
    );
  }
}
