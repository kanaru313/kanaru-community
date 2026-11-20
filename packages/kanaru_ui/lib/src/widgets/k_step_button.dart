import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import 'k_press_surface.dart';

/// Tonal round − / + button beside a big number (48 dp on touch shells, 40 on
/// desktop). [onPressed] null = at its bound: dimmed, not focusable.
/// [semanticLabel] is its spoken name ("Thêm 5 phút"). [KStepButton.text]
/// shows a short text ("−5", "+1") instead of an icon.
class KStepButton extends StatelessWidget {
  const KStepButton({
    super.key,
    required IconData this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
  }) : label = null;

  const KStepButton.text({
    super.key,
    required String this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
  }) : icon = null;

  final IconData? icon;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final size = desktop ? 40.0 : KLayout.minTarget;
    final enabled = onPressed != null;
    final fg = enabled
        ? scheme.onSecondaryContainer
        : scheme.onSurface.withValues(alpha: 0.38);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return KPressSurface(
      onPressed: onPressed,
      radius: KRadius.full,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, overlay, _) => AnimatedContainer(
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
        child: icon != null
            ? Icon(icon, size: desktop ? KIconSize.sm : KIconSize.md, color: fg)
            : Text(
                label!,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}
