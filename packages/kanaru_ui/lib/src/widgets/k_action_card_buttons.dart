import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_space.dart';
import 'k_action_card_countdown.dart';

/// A button of a [KActionCard]. [primary] is the main answer (filled), the
/// others are outlined.
class KActionCardAction {
  const KActionCardAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  /// Longer label for screen readers; defaults to [label].
  final String? semanticsLabel;
}

/// The button row of a `KActionCard`: one button at the end, two sharing the
/// row. Buttons are 40 high on the mobile shell, compact on the desktop one.
class KActionCardButtons extends StatelessWidget {
  const KActionCardButtons({
    super.key,
    required this.actions,
    required this.error,
    this.countdown,
  });

  final List<KActionCardAction> actions;

  /// Error tone: buttons take the `onErrorContainer` colour.
  final bool error;

  /// Locks the first action while time is left.
  final KActionCardCountdown? countdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clock = countdown;
    final left = clock == null
        ? null
        : KCountdownLeft.at(clock.until, clock.now());
    final height = FormFactor.of(context) == FormFactor.desktop
        ? KLayout.compactButton
        : KSpace.x8;
    final buttons = [
      for (var i = 0; i < actions.length; i++)
        _button(
          actions[i],
          height: height,
          scheme: scheme,
          error: error,
          // The countdown locks the first action.
          lockedBy: i == 0 ? left : null,
          clock: i == 0 ? clock : null,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x3),
      child: buttons.length == 1
          ? Align(alignment: AlignmentDirectional.centerEnd, child: buttons[0])
          : Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: KSpace.x2),
                Expanded(child: buttons[1]),
              ],
            ),
    );
  }

  Widget _button(
    KActionCardAction action, {
    required double height,
    required ColorScheme scheme,
    required bool error,
    required KCountdownLeft? lockedBy,
    required KActionCardCountdown? clock,
  }) {
    final locked = lockedBy != null;
    final label = locked ? clock!.labelOf(lockedBy) : action.label;
    final onPressed = locked ? null : action.onPressed;
    final size = Size(0, height);
    final Widget button;
    if (action.primary) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: size,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: error ? scheme.onErrorContainer : null,
          side: error
              ? BorderSide(
                  color: scheme.onErrorContainer.withValues(alpha: 0.45),
                )
              : null,
        ),
        child: Text(label),
      );
    }
    // A locked label changes every second: screen readers keep the action's
    // own name (disabled) instead of re-reading it.
    return Semantics(
      container: true,
      button: true,
      enabled: !locked,
      label: action.semanticsLabel ?? action.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: button,
    );
  }
}
