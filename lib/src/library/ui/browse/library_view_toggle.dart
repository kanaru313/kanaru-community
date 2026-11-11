import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// One choice of a [LibraryViewToggle].
class ViewOption<T> {
  const ViewOption(this.value, this.icon, this.label);

  final T value;
  final IconData icon;
  final String label;
}

/// Switch between two layouts (grid / list, tree / flat). Mobile: one icon
/// button showing the layout it switches to. Desktop: a double button with
/// both layouts, the current one filled.
class LibraryViewToggle<T> extends StatelessWidget {
  const LibraryViewToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : assert(options.length == 2);

  final T value;
  final List<ViewOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (FormFactor.of(context) == FormFactor.mobile) {
      final target = options.firstWhere((o) => o.value != value);
      return IconButton(
        tooltip: target.label,
        onPressed: () => onChanged(target.value),
        icon: Icon(target.icon),
      );
    }
    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final o in options)
          ButtonSegment(value: o.value, icon: Icon(o.icon), tooltip: o.label),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
