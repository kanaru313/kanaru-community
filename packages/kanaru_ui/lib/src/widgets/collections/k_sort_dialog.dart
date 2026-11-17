import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import 'k_sort_chosen_row.dart';
import 'k_sort_dialog_rows.dart';
import 'k_sort_dialog_types.dart';

export 'k_sort_dialog_types.dart';

/// The "Sắp xếp theo" box: the ordered criteria of a list's sort, each with
/// its own direction, plus the criteria not used yet.
///
/// A dumb view. It draws [chosen] (rebuilt whenever it changes) and reports
/// what the user asked for; the caller applies the rule and updates [chosen].
/// It never reorders by itself. [options] are in menu order and every entry of
/// [chosen] must name one of them. [onMove] gets the row's index before and
/// after the move (`to` is where the row ends up). Changes apply at once;
/// nothing needs confirming, so Esc, Back, a tap outside and "Xong" all just
/// close it.
///
/// [onRoute] gets the pushed route (before the dialog shows), so a caller can
/// remove exactly this route later.
///
/// Centred on both shells (root navigator), at most [KLayout.sortDialog] wide.
/// Drag a row by its handle, or use Alt + Up / Alt + Down on the keyboard;
/// screen readers get the list's own move actions. Flutter's slide of the other
/// rows during a drag has a fixed duration and ignores reduced motion; the
/// lift of the dragged row follows it.
Future<void> showKSortDialog<T>(
  BuildContext context, {
  required List<KSortOption<T>> options,
  required ValueListenable<List<KSortEntry<T>>> chosen,
  required ValueChanged<T> onAdd,
  required ValueChanged<T> onRemove,
  required ValueChanged<T> onFlip,
  required void Function(int from, int to) onMove,
  required VoidCallback onReset,
  required KSortDialogStrings strings,
  ValueChanged<Route<dynamic>>? onRoute,
}) {
  // The route is built here (what `showDialog` does) so the caller can be
  // handed the exact route that was pushed.
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (context) => Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: KShape.of(KRadius.xl, continuous: true),
      insetPadding: const EdgeInsets.all(KSpace.x4),
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxWidth: KLayout.sortDialog),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: _SortDialogBody<T>(
            options: options,
            chosen: chosen,
            onAdd: onAdd,
            onRemove: onRemove,
            onFlip: onFlip,
            onMove: onMove,
            onReset: onReset,
            strings: strings,
          ),
        ),
      ),
    ),
  );
  onRoute?.call(route);
  return navigator.push(route);
}

class _SortDialogBody<T> extends StatelessWidget {
  const _SortDialogBody({
    required this.options,
    required this.chosen,
    required this.onAdd,
    required this.onRemove,
    required this.onFlip,
    required this.onMove,
    required this.onReset,
    required this.strings,
  });

  final List<KSortOption<T>> options;
  final ValueListenable<List<KSortEntry<T>>> chosen;
  final ValueChanged<T> onAdd;
  final ValueChanged<T> onRemove;
  final ValueChanged<T> onFlip;
  final void Function(int from, int to) onMove;
  final VoidCallback onReset;
  final KSortDialogStrings strings;

  bool _hasOption(T value) => options.any((o) => o.value == value);

  /// The option of [value], or null when [options] lacks it (a chosen entry
  /// the caller did not offer: skipped rather than throwing in a release build).
  KSortOption<T>? _option(T value) {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x6,
              KSpace.x6,
              KSpace.x2,
            ),
            child: Text(
              strings.title,
              style: text.headlineSmall?.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        // The title and the actions stay out of the scroll view; one scroll
        // view holds both sections so a dragged row auto-scrolls it.
        Flexible(
          child: ValueListenableBuilder<List<KSortEntry<T>>>(
            valueListenable: chosen,
            builder: (context, entries, _) => _scroll(context, entries),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x4,
            KSpace.x2,
            KSpace.x4,
            KSpace.x4,
          ),
          // OverflowBar: Reset at the start, Done at the end; when they do
          // not fit (large text) they stack, Reset above Done, both at the end.
          child: OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            overflowSpacing: KSpace.x1,
            children: [
              TextButton(onPressed: onReset, child: Text(strings.reset)),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(strings.done),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scroll(BuildContext context, List<KSortEntry<T>> all) {
    final entries = [
      for (final e in all)
        if (_hasOption(e.value)) e,
    ];
    final rest = [
      for (final o in options)
        if (!entries.any((e) => e.value == o.value)) o,
    ];
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: SortSectionHeader(
                  title: strings.chosen,
                  count: entries.length,
                ),
              ),
              SliverReorderableList(
                itemCount: entries.length,
                onReorderItem: onMove,
                proxyDecorator: (child, index, animation) =>
                    sortRowLift(context, child),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final option = _option(entry.value)!;
                  final word = entry.descending
                      ? option.descendingLabel
                      : option.ascendingLabel;
                  final other = entry.descending
                      ? option.ascendingLabel
                      : option.descendingLabel;
                  return SortChosenRow(
                    key: ValueKey(entry.value),
                    index: i,
                    name: option.label,
                    descending: entry.descending,
                    canReorder: entries.length > 1,
                    dragLabel: strings.dragHint(option.label),
                    flipTooltip: strings.flipTooltip(other),
                    flipSemantics: strings.flipSemantics(option.label, word),
                    removeLabel: strings.remove(option.label),
                    onFlip: () => onFlip(entry.value),
                    onRemove: entries.length > 1
                        ? () => onRemove(entry.value)
                        : null,
                    onMoveBy: (delta) {
                      final to = i + delta;
                      if (to >= 0 && to < entries.length) onMove(i, to);
                    },
                  );
                },
              ),
              if (rest.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SortSectionHeader(title: strings.notChosen),
                ),
                SliverList.builder(
                  itemCount: rest.length,
                  itemBuilder: (context, i) => SortOffRow(
                    key: ValueKey(rest[i].value),
                    name: rest[i].label,
                    icon: rest[i].icon,
                    addLabel: strings.add(rest[i].label),
                    onAdd: () => onAdd(rest[i].value),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KSpace.x2)),
      ],
    );
  }
}
