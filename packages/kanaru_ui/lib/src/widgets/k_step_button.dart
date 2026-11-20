import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import 'k_press_surface.dart';

/// Tonal round − / + button beside a big number (56 dp on touch shells, 40 on
/// desktop). [onPressed] null = at its bound: dimmed, not focusable.
/// [semanticLabel] is its spoken name ("Thêm 5 phút").
class KStepButton extends StatelessWidget {
  const KStepButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final size = desktop ? 40.0 : 56.0;
    final enabled = onPressed != null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: KPressSurface(
          onPressed: onPressed,
          radius: KRadius.full,
          focusNode: focusNode,
          autofocus: autofocus,
          builder: (context, overlay) => AnimatedContainer(
            duration: duration,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: KShape.of(KRadius.full),
              color: enabled
                  ? Color.alphaBlend(
                      scheme.onSecondaryContainer.withValues(alpha: overlay),
                      scheme.secondaryContainer,
                    )
                  : scheme.onSurface.withValues(alpha: 0.10),
            ),
            child: Icon(
              icon,
              size: desktop ? KIconSize.sm : KIconSize.md,
              color: enabled
                  ? scheme.onSecondaryContainer
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
