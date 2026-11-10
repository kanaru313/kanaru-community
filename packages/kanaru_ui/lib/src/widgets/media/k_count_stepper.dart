import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';

/// A minus and a plus button that move a whole number between [min] and
/// [max]. Each button is dimmed at its bound, and both while [enabled] is
/// false. The number itself is shown by the caller (in a row label), so this
/// takes no space for it.
class KCountStepper extends StatelessWidget {
  const KCountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    this.min = 1,
    this.max = 99,
    this.enabled = true,
    this.color,
  });

  /// Keys of the two buttons, for tests.
  static const decreaseKey = ValueKey('k-count-stepper-decrease');
  static const increaseKey = ValueKey('k-count-stepper-increase');

  // The icon set has no minus yet; the same Material glyph as its others.
  static const IconData _minus = Icons.remove;

  final int value;
  final ValueChanged<int> onChanged;
  final String decreaseTooltip;
  final String increaseTooltip;
  final int min;
  final int max;
  final bool enabled;

  /// Icon colour of the buttons; the surrounding icon colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget button(
      Key key,
      IconData icon,
      String tooltip,
      int target,
      bool atBound,
    ) => IconButton(
      key: key,
      icon: Icon(icon),
      iconSize: 18,
      color: color,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
      tooltip: tooltip,
      onPressed: enabled && !atBound ? () => onChanged(target) : null,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          decreaseKey,
          _minus,
          decreaseTooltip,
          (value - 1).clamp(min, max),
          value <= min,
        ),
        button(
          increaseKey,
          KIcons.add,
          increaseTooltip,
          (value + 1).clamp(min, max),
          value >= max,
        ),
      ],
    );
  }
}
