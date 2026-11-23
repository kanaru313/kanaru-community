import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';

/// Icon button that is an on / off switch: the "show empty fields" eye of the
/// song info page and the "show timestamps" clock of the lyrics modal.
///
/// On shows [onIcon] in `primary`; off shows [icon] quiet. [onChanged] null
/// dims the button and says [disabledTooltip]. A [badgeCount] above 0 draws a
/// `secondaryContainer` pill at the corner, only while off (it counts what
/// turning on would reveal). Semantics: a button, toggled when [on].
class KInfoToggleButton extends StatelessWidget {
  const KInfoToggleButton({
    super.key,
    required this.on,
    required this.onChanged,
    required this.icon,
    required this.onIcon,
    required this.tooltip,
    this.onTooltip,
    this.disabledTooltip,
    this.badgeCount,
    this.badgeLabel,
  });

  final bool on;

  /// Called with the new state; null = disabled.
  final ValueChanged<bool>? onChanged;
  final IconData icon;
  final IconData onIcon;

  /// Said while off (and while on or disabled when those have no text).
  final String tooltip;
  final String? onTooltip;
  final String? disabledTooltip;
  final int? badgeCount;

  /// Spoken with the count while the pill shows ("3 trường trống"; the
  /// caller localises). The pill itself is hidden from screen readers.
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final change = onChanged;
    final text = change == null
        ? disabledTooltip ?? tooltip
        : on
        ? onTooltip ?? tooltip
        : tooltip;
    final count = on ? 0 : (badgeCount ?? 0);
    final button = KIconButton(
      tooltip: text,
      icon: icon,
      selectedIcon: onIcon,
      selected: on,
      semanticLabel: count > 0 && badgeLabel != null
          ? '$text, $badgeLabel'
          : null,
      selectedColor: scheme.primary,
      onPressed: change == null ? null : () => change(!on),
    );
    if (count <= 0) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(
          top: -KSpace.x1,
          end: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: KRadius.xs,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
