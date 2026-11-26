import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';
import '../k_press_surface.dart';

/// The ★ of a [KSeekStyleCard] that stands in when the chosen value cannot be
/// used. Only cards that are eligible carry one (a null mark = not eligible).
class KFallbackMark {
  const KFallbackMark({
    required this.active,
    required this.onActivate,
    required this.tooltip,
  });

  /// True on the one card that currently has the ★ (filled `primary`).
  final bool active;

  /// Moves the ★ to this card. Never changes the chosen card. Not called when
  /// [active] already.
  final VoidCallback onActivate;

  /// Spoken and tooltip text of the toggle ("Dùng X khi …" / "Hiện khi …").
  final String tooltip;
}

/// The one action row button of the chosen card ("Tuỳ chỉnh").
class KCardAction {
  const KCardAction({
    required this.label,
    required this.onPressed,
    this.icon = KIcons.customise,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// Box of the ★ button: icon [KIconSize.sm] plus padding on every side.
const double fallbackStarBox = 32;

/// Toggle button of a [KFallbackMark]: filled `primary` star when active,
/// outline `onSurfaceVariant` otherwise. Tapping the filled one does nothing.
class FallbackStarButton extends StatelessWidget {
  const FallbackStarButton({super.key, required this.mark});

  final KFallbackMark mark;

  @override
  Widget build(BuildContext context) {
    return KIconButton(
      icon: KIcons.fallbackStar,
      selectedIcon: KIcons.fallbackStarFilled,
      selected: mark.active,
      size: KIconSize.sm,
      padding: const EdgeInsets.all((fallbackStarBox - KIconSize.sm) / 2),
      tooltip: mark.tooltip,
      // The filled star is still a live button, only without an effect, so it
      // is not dimmed like a disabled one.
      onPressed: mark.active ? () {} : mark.onActivate,
    );
  }
}

/// Tonal text button, 32 tall, stretching to the room it is given.
class CardActionButton extends StatelessWidget {
  const CardActionButton({super.key, required this.action});

  final KCardAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return KPressSurface(
      onPressed: action.onPressed,
      radius: KRadius.full,
      semanticLabel: action.label,
      builder: (context, overlay, _) => AnimatedContainer(
        duration: duration,
        constraints: const BoxConstraints(minHeight: fallbackStarBox),
        padding: const EdgeInsetsDirectional.only(
          start: KSpace.x2,
          end: KSpace.x3,
          top: KSpace.x1 / 2,
          bottom: KSpace.x1 / 2,
        ),
        decoration: ShapeDecoration(
          color: Color.alphaBlend(
            scheme.onSecondaryContainer.withValues(alpha: overlay),
            scheme.secondaryContainer,
          ),
          shape: KShape.of(KRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: KIconSize.xs,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: KSpace.x2 - 2),
            Flexible(
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
