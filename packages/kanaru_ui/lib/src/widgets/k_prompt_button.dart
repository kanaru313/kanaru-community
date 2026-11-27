import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';

/// Full-width outlined button with a left-aligned [label] and, when the action
/// cannot run now, a [reason] line inside it (the saved prompts under the
/// greeting of an empty chat). A column of them is spaced by the caller.
///
/// [enabled] false dims the whole button and makes it inert; the [reason] is
/// still shown and spoken. [onTap] is not called while disabled.
class KPromptButton extends StatelessWidget {
  const KPromptButton({
    super.key,
    required this.label,
    required this.onTap,
    this.reason,
    this.enabled = true,
  });

  final String label;
  final String? reason;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    final why = reason;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: KPressSurface(
        onPressed: enabled ? onTap : null,
        radius: KRadius.md,
        semanticLabel: why == null ? label : '$label. $why',
        builder: (context, overlay, _) => AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(minHeight: KLayout.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x3,
          ),
          alignment: Alignment.centerLeft,
          decoration: ShapeDecoration(
            color: scheme.onSurface.withValues(alpha: overlay),
            shape: RoundedRectangleBorder(
              borderRadius: KRadius.md,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              if (why != null)
                Text(
                  why,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
