import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The quick choices of the custom screen on one centred line that never
/// wraps ([KChipLine]): it scrolls, with faded edges, only when the chips do
/// not fit, and then opens scrolled to the chosen chip, which is tinted (no
/// tick).
class SleepTimerPresetChips extends StatelessWidget {
  const SleepTimerPresetChips({
    super.key,
    required this.presets,
    required this.selected,
    required this.label,
    required this.tooltip,
    required this.onSelected,
  });

  final List<int> presets;

  /// The preset equal to the draft's value, if any.
  final int? selected;

  /// Text of a chip ("15 ph") and its tooltip ("15 phút").
  final String Function(int preset) label;
  final String Function(int preset) tooltip;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final index = selected == null ? -1 : presets.indexOf(selected!);
    return KChipLine(
      revealIndex: index < 0 ? null : index,
      children: [
        for (final p in presets)
          Tooltip(
            message: tooltip(p),
            excludeFromSemantics: true,
            child: KChip(
              semanticLabel: tooltip(p),
              dense: true,
              selected: p == selected,
              label: Text(label(p)),
              onTap: () => onSelected(p),
            ),
          ),
      ],
    );
  }
}
