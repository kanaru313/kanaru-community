import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';

/// Full-width filled action at the top of a list ("Cuộc trò chuyện mới" in the
/// chat history): a [KLayout.minTarget] tall `primaryContainer` button, [icon]
/// then bold [label], and an optional [shortcutHint] pushed to the end
/// (desktop only: the caller decides when to pass it).
///
/// Sits inset by [KSpace.x2] on both sides so the rounded fill never touches
/// the container's edges. [onPressed] null = disabled.
class KListActionButton extends StatelessWidget {
  const KListActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcutHint,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Keyboard shortcut shown at the end, e.g. `Ctrl+Shift+O`.
  final String? shortcutHint;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final fg = enabled
        ? scheme.onPrimaryContainer
        : scheme.onSurface.withValues(alpha: 0.38);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x2, 0, KSpace.x2, KSpace.x1),
      child: KPressSurface(
        onPressed: onPressed,
        radius: KRadius.md,
        semanticLabel: label,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, overlay, _) => AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(minHeight: KLayout.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
          decoration: ShapeDecoration(
            color: enabled
                ? Color.alphaBlend(
                    fg.withValues(alpha: overlay),
                    scheme.primaryContainer,
                  )
                : scheme.onSurface.withValues(alpha: 0.12),
            shape: const RoundedRectangleBorder(borderRadius: KRadius.md),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: KIconSize.md, color: fg),
                const SizedBox(width: KSpace.x3),
              ],
              Expanded(
                child: Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (shortcutHint != null)
                Text(
                  shortcutHint!,
                  style: text.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
