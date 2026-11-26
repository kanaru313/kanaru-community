import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'k_switch_row.dart';

/// One row of a [ReorderableToggleList].
class ReorderableToggleItem<T> {
  const ReorderableToggleItem({
    required this.value,
    required this.title,
    required this.enabled,
    this.switchLabel,
    this.leading,
    this.subtitle,
    this.problem,
    this.onProblemTap,
    this.onTap,
    this.tapLabel,
  });

  /// Identifies the row (and keys it while it moves).
  final T value;
  final Widget title;
  final bool enabled;

  /// Spoken name of this row's switch.
  final String? switchLabel;

  /// A picture after the drag handle (for example a plugin icon, 24 dp).
  final Widget? leading;

  /// A line under the title.
  final String? subtitle;

  /// Why the row cannot work right now: a line in the error colour, shown
  /// under [subtitle] when both are given. A caller that wants the problem to
  /// replace the subtitle passes no [subtitle] while a problem exists. With
  /// [onProblemTap] it is a button that leads to the fix.
  final String? problem;
  final VoidCallback? onProblemTap;

  /// Tapping the row runs this (open, edit) and does not toggle; only the
  /// switch toggles. Null: a row tap toggles.
  final VoidCallback? onTap;

  /// Spoken name of the [onTap] action, for example "Name, open to edit".
  final String? tapLabel;
}

/// Rows with a drag handle on the left and a switch on the right. By default
/// the last enabled row cannot be switched off: its switch is locked. For use inside a
/// page that scrolls; it does not scroll itself.
class ReorderableToggleList<T> extends StatelessWidget {
  const ReorderableToggleList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onToggle,
    required this.dragLabel,
    this.lockedLabel,
    this.keepOneOn = true,
  });

  final List<ReorderableToggleItem<T>> items;

  /// `to` is the index the row ends at in the new order (already corrected
  /// for the removal, as `LibraryTabsConfig.reorder` expects).
  final void Function(int from, int to) onReorder;
  final void Function(T value, bool enabled) onToggle;

  /// Tooltip and spoken label of the drag handle.
  final String dragLabel;
  final String? lockedLabel;

  /// True (a list of tabs) locks the last enabled row's switch; false lets
  /// every row go off.
  final bool keepOneOn;

  @override
  Widget build(BuildContext context) {
    final enabledCount = items.where((i) => i.enabled).length;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: (from, to) => onReorder(from, to),
      itemBuilder: (context, index) {
        final item = items[index];
        final locked = keepOneOn && item.enabled && enabledCount == 1;
        return KSwitchRow(
          key: ValueKey(item.value),
          title: item.title,
          value: item.enabled,
          lockedLabel: locked ? lockedLabel : null,
          switchLabel: item.switchLabel,
          onTap: item.onTap,
          tapSemanticsLabel: item.tapLabel,
          subtitle: _subtitle(context, item),
          onChanged: locked ? null : (on) => onToggle(item.value, on),
          leading: _leading(index, item),
        );
      },
    );
  }

  /// The drag handle, then the item's own [ReorderableToggleItem.leading].
  Widget _leading(int index, ReorderableToggleItem<T> item) {
    // A tap on the handle must not reach the row, which would flip the
    // switch; only a drag does something here.
    final handle = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ReorderableDragStartListener(
        index: index,
        child: Tooltip(
          message: dragLabel,
          child: Semantics(
            container: true,
            label: dragLabel,
            child: const SizedBox(
              width: KSpace.x7,
              height: KLayout.minTarget,
              child: Icon(KIcons.dragIndicator),
            ),
          ),
        ),
      ),
    );
    final extra = item.leading;
    if (extra == null) return handle;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [handle, const KGap(KSpace.x2), extra],
    );
  }

  Widget? _subtitle(BuildContext context, ReorderableToggleItem<T> item) {
    final line = item.subtitle;
    final problem = item.problem;
    if (line == null && problem == null) return null;
    final scheme = Theme.of(context).colorScheme;
    final tap = item.onProblemTap;
    Widget? problemLine;
    if (problem != null) {
      final text = Text(problem, style: TextStyle(color: scheme.error));
      problemLine = tap == null
          ? text
          : Semantics(
              button: true,
              excludeSemantics: true,
              label: problem,
              onTap: tap,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: tap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
                  child: text,
                ),
              ),
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [if (line != null) Text(line), ?problemLine],
    );
  }
}
