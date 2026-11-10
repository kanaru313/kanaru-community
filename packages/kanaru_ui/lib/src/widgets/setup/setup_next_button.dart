import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// The floating arrow that ends setup: 64 x 64, rounded 20, primary fill.
///
/// When [visible] turns true it scales in (no scale with reduced motion);
/// while not visible it takes no taps and is not in the semantics tree.
/// `onPressed: null` while visible dims it and shows [disabledTooltip].
class SetupNextButton extends StatelessWidget {
  const SetupNextButton({
    super.key,
    required this.onPressed,
    required this.visible,
    required this.semanticLabel,
    this.disabledTooltip,
  });

  final VoidCallback? onPressed;
  final bool visible;
  final String semanticLabel;
  final String? disabledTooltip;

  static const double _size = KSpace.x10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final enabled = onPressed != null;
    Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        elevation: enabled ? 3 : 0,
        shape: KShape.of(KRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: _size,
            child: Icon(KIcons.arrowForward, size: 30, color: scheme.onPrimary),
          ),
        ),
      ),
    );
    if (!enabled) {
      button = Opacity(opacity: 0.38, child: button);
      final tip = disabledTooltip;
      if (tip != null) button = Tooltip(message: tip, child: button);
    }
    return ExcludeSemantics(
      excluding: !visible,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          scale: visible ? 1 : 0,
          duration: reduce ? Duration.zero : KMotion.normal,
          curve: Curves.easeOutBack,
          child: button,
        ),
      ),
    );
  }
}
