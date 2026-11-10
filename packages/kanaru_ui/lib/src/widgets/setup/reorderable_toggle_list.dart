import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_space.dart';
import 'k_switch_row.dart';

/// One row of a [ReorderableToggleList].
class ReorderableToggleItem<T> {
  const ReorderableToggleItem({
    required this.value,
    required this.title,
    required this.enabled,
    this.switchLabel,
  });

  /// Identifies the row (and keys it while it moves).
  final T value;
  final Widget title;
  final bool enabled;

  /// Spoken name of this row's switch.
  final String? switchLabel;
}

/// Rows with a drag handle on the left and a switch on the right. The last
/// enabled row cannot be switched off: its switch is locked. For use inside a
/// page that scrolls; it does not scroll itself.
class ReorderableToggleList<T> extends StatelessWidget {
  const ReorderableToggleList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onToggle,
    required this.dragLabel,
    this.lockedLabel,
  });

  final List<ReorderableToggleItem<T>> items;

  /// `to` is the index the row ends at in the new order (already corrected
  /// for the removal, as `LibraryTabsConfig.reorder` expects).
  final void Function(int from, int to) onReorder;
  final void Function(T value, bool enabled) onToggle;

  /// Tooltip and spoken label of the drag handle.
  final String dragLabel;
  final String? lockedLabel;

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
        final locked = item.enabled && enabledCount == 1;
        return KSwitchRow(
          key: ValueKey(item.value),
          title: item.title,
          value: item.enabled,
          lockedLabel: locked ? lockedLabel : null,
          switchLabel: item.switchLabel,
          onChanged: locked ? null : (on) => onToggle(item.value, on),
          // A tap on the handle must not reach the row, which would flip the
          // switch; only a drag does something here.
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: dragLabel,
                child: Semantics(
                  label: dragLabel,
                  child: const SizedBox(
                    width: KSpace.x7,
                    height: KLayout.minTarget,
                    child: Icon(KIcons.dragIndicator),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
