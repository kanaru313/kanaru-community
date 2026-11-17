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
/// [emptyNote] replaces the list when [options] is empty. [banner] sits above
/// the list and [footerNote] after the list (or the empty note), both inside
/// the scrolling area. See [MultiSelectionSheet] for what happens when the
/// options change while the sheet is open.
Future<Set<T>?> showMultiSelectionSheet<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required Widget title,
  required String Function(int n) confirmLabel,
  required String cancelLabel,
  Set<T> initial = const {},
  Widget? subtitle,
  Widget? emptyNote,
  Widget? banner,
  Widget? footerNote,
  String? selectAllLabel,
  String Function(int n, int total)? selectedCountLabel,
  bool useRootNavigator = false,
}) => showKSheet<Set<T>>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => MultiSelectionSheet<T>(
    options: options,
    title: title,
    subtitle: subtitle,
    emptyNote: emptyNote,
    banner: banner,
    footerNote: footerNote,
    selectAllLabel: selectAllLabel,
    selectedCountLabel: selectedCountLabel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    initial: initial,
  ),
);

/// The body of [showMultiSelectionSheet]. Use it directly when the options
/// change while the sheet is open (a list that loads, reloads or is rescanned):
/// rebuild it with the new [options] and it keeps its state.
///
/// Picks are never pruned: a pick whose option disappears (a reload frame) is
/// kept and comes back with the option, but the select-all row, the confirm
/// label and the result only count picks that have a currently enabled option.
/// Values that appear in [initial] after the first build are chosen once (the
/// user can untick them).
class MultiSelectionSheet<T> extends StatefulWidget {
  const MultiSelectionSheet({
    super.key,
    required this.options,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.subtitle,
    this.emptyNote,
    this.banner,
    this.footerNote,
    this.selectAllLabel,
    this.selectedCountLabel,
    this.initial = const {},
  });

  final List<SelectionOption<T>> options;
  final Widget title;
  final Widget? subtitle;
  final Widget? emptyNote;

  /// Above the list, scrolls with it.
  final Widget? banner;

  /// After the list (or [emptyNote]), scrolls with it.
  final Widget? footerNote;
  final String? selectAllLabel;
  final String Function(int n, int total)? selectedCountLabel;
  final String Function(int n) confirmLabel;
  final String cancelLabel;
  final Set<T> initial;

  @override
  State<MultiSelectionSheet<T>> createState() => _MultiSelectionSheetState<T>();
}

class _MultiSelectionSheetState<T> extends State<MultiSelectionSheet<T>> {
  late final Set<T> _chosen = {...widget.initial};

  @override
  void didUpdateWidget(MultiSelectionSheet<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Newly suggested values are chosen once; later rebuilds with the same
    // `initial` never re-tick what the user cleared.
    _chosen.addAll(widget.initial.difference(oldWidget.initial));
  }

  void _toggle(T value) => setState(() {
    if (!_chosen.add(value)) _chosen.remove(value);
  });

  List<T> get _enabledValues =>
      widget.options.where((o) => o.enabled).map((o) => o.value).toList();

  void _toggleAll() => setState(() {
    final enabled = _enabledValues;
    if (enabled.every(_chosen.contains)) {
      _chosen.removeAll(enabled);
    } else {
      _chosen.addAll(enabled);
    }
  });

  @override
  Widget build(BuildContext context) {
    final enabled = _enabledValues;
    final iconRows =
        enabled.isNotEmpty &&
        widget.options.where((o) => o.enabled).every((o) => o.leading != null);
    final showAll = widget.selectAllLabel != null && enabled.length >= 2;
    final chosenEnabled = enabled.where(_chosen.contains).toList();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final empty = widget.options.isEmpty;
    // Scrolling items: banner, select-all, the rows (or the empty note), then
    // the footer note.
    final lead = (widget.banner != null ? 1 : 0) + (showAll ? 1 : 0);
    final body = empty ? 1 : widget.options.length;
    final count = lead + body + (widget.footerNote != null ? 1 : 0);
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
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(KSpace.x2),
            itemCount: count,
            separatorBuilder: (_, _) => const KGap(KSpace.x1),
            itemBuilder: (context, i) {
              var at = i;
              if (widget.banner != null) {
                if (at == 0) return widget.banner!;
                at--;
              }
              if (showAll) {
                if (at == 0) {
                  final label = widget.selectedCountLabel;
                  return SelectionRow(
                    multi: true,
                    // Icon options: plain tick on the right (no leading
                    // slot); text options: mark at the start.
                    plainMark: iconRows,
                    title: Text(widget.selectAllLabel!),
                    subtitle: label == null
                        ? null
                        : Text(label(chosenEnabled.length, enabled.length)),
                    selected: chosenEnabled.isNotEmpty,
                    partial:
                        chosenEnabled.isNotEmpty &&
                        chosenEnabled.length < enabled.length,
                    onTap: _toggleAll,
                  );
                }
                at--;
              }
              if (empty) {
                if (at == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(KSpace.x6),
                    child: widget.emptyNote ?? const SizedBox.shrink(),
                  );
                }
                return widget.footerNote!;
              }
              if (at >= widget.options.length) return widget.footerNote!;
              final o = widget.options[at];
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
                onPressed: chosenEnabled.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(<T>{...chosenEnabled}),
                child: Text(widget.confirmLabel(chosenEnabled.length)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
