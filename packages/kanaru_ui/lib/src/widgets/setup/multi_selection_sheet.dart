import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_sheet.dart';
import '../selection_picker.dart';
import '../selection_row.dart';

/// Multi-choice sheet (a dialog from 600 dp up, like [showKSheet]): one
/// [SelectionRow] per option, the check on the right and a tinted fill for
/// the chosen ones, and a footer with [cancelLabel] and a confirm button
/// labelled by [confirmLabel] (called with the number chosen, 0 included).
/// Confirm is off while nothing is chosen.
///
/// With [selectAllLabel] and at least two enabled options, a first row
/// chooses or clears every enabled option (clears when all are chosen); its
/// subtitle is [selectedCountLabel] (chosen, enabled total) and its mark is
/// off / partial / on.
///
/// Resolves to the chosen values, or null on cancel, Back or a tap outside.
/// [emptyNote] replaces the list when [options] is empty.
Future<Set<T>?> showMultiSelectionSheet<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required Widget title,
  required String Function(int n) confirmLabel,
  required String cancelLabel,
  Set<T> initial = const {},
  Widget? subtitle,
  Widget? emptyNote,
  String? selectAllLabel,
  String Function(int n, int total)? selectedCountLabel,
  bool useRootNavigator = false,
}) => showKSheet<Set<T>>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => _MultiSelectionBody<T>(
    options: options,
    title: title,
    subtitle: subtitle,
    emptyNote: emptyNote,
    selectAllLabel: selectAllLabel,
    selectedCountLabel: selectedCountLabel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    initial: initial,
  ),
);

class _MultiSelectionBody<T> extends StatefulWidget {
  const _MultiSelectionBody({
    required this.options,
    required this.title,
    required this.subtitle,
    required this.emptyNote,
    required this.selectAllLabel,
    required this.selectedCountLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.initial,
  });

  final List<SelectionOption<T>> options;
  final Widget title;
  final Widget? subtitle;
  final Widget? emptyNote;
  final String? selectAllLabel;
  final String Function(int n, int total)? selectedCountLabel;
  final String Function(int n) confirmLabel;
  final String cancelLabel;
  final Set<T> initial;

  @override
  State<_MultiSelectionBody<T>> createState() => _MultiSelectionBodyState<T>();
}

class _MultiSelectionBodyState<T> extends State<_MultiSelectionBody<T>> {
  late final Set<T> _chosen = {...widget.initial};

  void _toggle(T value) => setState(() {
    if (!_chosen.add(value)) _chosen.remove(value);
  });

  Iterable<T> get _enabledValues =>
      widget.options.where((o) => o.enabled).map((o) => o.value);

  void _toggleAll() => setState(() {
    final enabled = _enabledValues.toList();
    if (enabled.every(_chosen.contains)) {
      _chosen.removeAll(enabled);
    } else {
      _chosen.addAll(enabled);
    }
  });

  @override
  Widget build(BuildContext context) {
    final enabled = _enabledValues.toList();
    final iconRows =
        enabled.isNotEmpty &&
        widget.options.where((o) => o.enabled).every((o) => o.leading != null);
    final showAll = widget.selectAllLabel != null && enabled.length >= 2;
    final chosenEnabled = enabled.where(_chosen.contains).length;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x4,
            KSpace.x6,
            KSpace.x1,
          ),
          child: DefaultTextStyle.merge(
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            child: widget.title,
          ),
        ),
        if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              0,
              KSpace.x6,
              KSpace.x2,
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              child: widget.subtitle!,
            ),
          ),
        Flexible(
          child: widget.options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(KSpace.x6),
                  child: widget.emptyNote ?? const SizedBox.shrink(),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(KSpace.x2),
                  itemCount: widget.options.length + (showAll ? 1 : 0),
                  separatorBuilder: (_, _) => const KGap(KSpace.x1),
                  itemBuilder: (context, i) {
                    if (showAll && i == 0) {
                      final count = widget.selectedCountLabel;
                      return SelectionRow(
                        multi: true,
                        // Icon options: plain tick on the right (no leading
                        // slot); text options: mark at the start.
                        plainMark: iconRows,
                        title: Text(widget.selectAllLabel!),
                        subtitle: count == null
                            ? null
                            : Text(count(chosenEnabled, enabled.length)),
                        selected: chosenEnabled > 0,
                        partial:
                            chosenEnabled > 0 && chosenEnabled < enabled.length,
                        onTap: _toggleAll,
                      );
                    }
                    final o = widget.options[showAll ? i - 1 : i];
                    return SelectionRow(
                      multi: true,
                      title: o.title,
                      subtitle: o.subtitle,
                      leading: o.leading,
                      enabled: o.enabled,
                      selected: _chosen.contains(o.value),
                      onTap: () => _toggle(o.value),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x4,
            KSpace.x2,
            KSpace.x4,
            KSpace.x1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel),
              ),
              const KGap(KSpace.x2),
              FilledButton(
                onPressed: _chosen.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(<T>{..._chosen}),
                child: Text(widget.confirmLabel(_chosen.length)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
