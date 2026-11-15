import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// One choice of a [LibraryViewToggle].
class ViewOption<T> {
  const ViewOption(this.value, this.icon, this.label);

  final T value;
  final IconData icon;
  final String label;
}

/// Switch between two layouts (grid / list, tree / flat): one small icon
/// button showing the layout it switches to, on every shell. It sits in the
/// list bar between the sort chip and the filter toggle.
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
    final target = options.firstWhere((o) => o.value != value);
    return KIconButton(
      tooltip: target.label,
      size: KIconSize.sm,
      padding: const EdgeInsets.all(KSpace.x2),
      onPressed: () => onChanged(target.value),
      icon: target.icon,
    );
  }
}
