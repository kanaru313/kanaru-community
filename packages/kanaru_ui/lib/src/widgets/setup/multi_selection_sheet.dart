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
  bool useRootNavigator = false,
}) => showKSheet<Set<T>>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => _MultiSelectionBody<T>(
    options: options,
    title: title,
    subtitle: subtitle,
    emptyNote: emptyNote,
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
    required this.confirmLabel,
    required this.cancelLabel,
    required this.initial,
  });

  final List<SelectionOption<T>> options;
  final Widget title;
  final Widget? subtitle;
  final Widget? emptyNote;
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

  @override
  Widget build(BuildContext context) {
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
                  itemCount: widget.options.length,
                  separatorBuilder: (_, _) => const KGap(KSpace.x1),
                  itemBuilder: (context, i) {
                    final o = widget.options[i];
                    return SelectionRow(
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
