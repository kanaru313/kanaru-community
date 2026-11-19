import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';
import 'collections/k_filter_field.dart';
import 'k_gap.dart';
import 'multi_selection_model.dart';
import 'multi_selection_parts.dart';
import 'multi_selection_rows.dart';
import 'picker_footer.dart';
import 'selection_picker.dart';

export 'multi_selection_parts.dart' show MultiSelectionAction;

/// The one multi-select body: header, optional filter, the scrolling rows and
/// a footer with cancel / confirm. [MultiSelectionSheet] and
/// `showMultiSelectionPicker` are thin frames around it.
///
/// Row order: [banner], select-all, [pinned] rows, a divider (only while a
/// pinned row is visible and a row follows), the [leadingAction] row, rows
/// added by that action (newest first), [options], the empty note, [listFooter].
///
/// Picks are never pruned: a pick whose option is filtered out, reloaded away
/// or disabled is kept and comes back with the option, but select-all, the
/// confirm label and the result only count picks that have a currently
/// enabled option. Values that appear in [initial] after the first build are
/// chosen once.
class MultiSelectionBody<T> extends StatefulWidget {
  const MultiSelectionBody({
    super.key,
    required this.options,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.pinned = const [],
    this.subtitle,
    this.emptyNote,
    this.banner,
    this.listFooter,
    this.footerNote,
    this.selectAllLabel,
    this.selectedCountLabel,
    this.initial = const {},
    this.leadingAction,
    this.filterHint,
    this.confirm,
    this.confirmTimeout,
    this.canConfirm,
    this.fillHeight = false,
    this.footerBorder = false,
  });

  final List<SelectionOption<T>> options;
  final List<SelectionOption<T>> pinned;
  final Widget title;
  final Widget? subtitle;
  final Widget? emptyNote;

  /// Above the rows, scrolls with them.
  final Widget? banner;

  /// After the rows (or the empty note), scrolls with them.
  final Widget? listFooter;

  /// Left of the buttons in the fixed footer.
  final Widget Function(BuildContext context, Set<T> selected)? footerNote;
  final String? selectAllLabel;
  final String Function(int n, int total)? selectedCountLabel;
  final String Function(Set<T> selected) confirmLabel;
  final String cancelLabel;
  final Set<T> initial;
  final MultiSelectionAction<T>? leadingAction;
  final String? filterHint;
  final Future<bool> Function(Set<T> selected)? confirm;
  final Duration? confirmTimeout;
  final bool Function(Set<T> selected)? canConfirm;

  /// The rows take all the height they are given (a fixed-height sheet);
  /// otherwise the body is as tall as its content.
  final bool fillHeight;

  /// Draws a line above the footer.
  final bool footerBorder;

  @override
  State<MultiSelectionBody<T>> createState() => _MultiSelectionBodyState<T>();
}

class _MultiSelectionBodyState<T> extends State<MultiSelectionBody<T>> {
  late final Set<T> _chosen = {...widget.initial};
  final List<SelectionOption<T>> _added = [];
  final TextEditingController _filter = TextEditingController();
  final FocusNode _confirmFocus = FocusNode(debugLabel: 'confirm');
  String _query = '';
  bool _busy = false;
  bool _actionRunning = false;

  @override
  void didUpdateWidget(MultiSelectionBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _chosen.addAll(widget.initial.difference(oldWidget.initial));
  }

  @override
  void dispose() {
    _filter.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  MultiSelectionView<T> _view() => MultiSelectionView<T>(
    pinned: widget.pinned,
    added: _added,
    options: widget.options,
    chosen: _chosen,
    query: _query,
    action: widget.leadingAction,
    hasBanner: widget.banner != null,
    hasEmptyNote: widget.emptyNote != null,
    hasListFooter: widget.listFooter != null,
    hasSelectAll: widget.selectAllLabel != null,
  );

  void _toggle(T value) => setState(() {
    if (!_chosen.add(value)) _chosen.remove(value);
  });

  void _toggleAll() => setState(() {
    final enabled = _view().enabledValues;
    if (enabled.every(_chosen.contains)) {
      _chosen.removeAll(enabled);
    } else {
      _chosen.addAll(enabled);
    }
  });

  Future<void> _runAction() async {
    final action = widget.leadingAction;
    if (action == null || _actionRunning || _busy) return;
    setState(() => _actionRunning = true);
    SelectionOption<T>? created;
    try {
      created = await action.onPressed(context);
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
    if (!mounted || created == null) return;
    final option = created;
    setState(() {
      if (!_view().allRows.any((o) => o.value == option.value)) {
        _added.insert(0, option);
      }
      _chosen.add(option.value);
    });
  }

  Future<void> _confirm() async {
    // Two activations can arrive before the next frame disables the button.
    if (_busy) return;
    final picks = _view().picks;
    final confirm = widget.confirm;
    if (confirm == null) {
      Navigator.of(context).pop(picks);
      return;
    }
    final hadFocus = _confirmFocus.hasFocus;
    setState(() => _busy = true);
    final ok = await runBoundedConfirm(
      () => confirm(picks),
      widget.confirmTimeout,
    );
    if (mounted) setState(() => _busy = false);
    if (ok && mounted) {
      Navigator.of(context).pop(picks);
    } else if (hadFocus && mounted) {
      // The disabled button dropped focus; give it back once it is enabled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view();
    final picks = view.picks;
    final canGo = picks.isNotEmpty && (widget.canConfirm?.call(picks) ?? true);
    final label = widget.confirmLabel(picks);
    final scheme = Theme.of(context).colorScheme;
    final rows = ListView.separated(
      shrinkWrap: !widget.fillHeight,
      padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
      itemCount: view.entries.length,
      // A media row carries its own gap below.
      separatorBuilder: (_, i) => view.entries[i].option?.mediaTitle != null
          ? const SizedBox.shrink()
          : const KGap(KSpace.x1),
      itemBuilder: (context, i) => buildMultiEntry<T>(
        context,
        view: view,
        selectAllLabel: widget.selectAllLabel,
        selectedCountLabel: widget.selectedCountLabel,
        banner: widget.banner,
        emptyNote: widget.emptyNote,
        listFooter: widget.listFooter,
        index: i,
        busy: _busy,
        actionBusy: _actionRunning,
        onToggle: _toggle,
        onToggleAll: _toggleAll,
        onAction: _runAction,
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MultiSelectionHeader(title: widget.title, subtitle: widget.subtitle),
          if (widget.filterHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpace.x4,
                KSpace.x1,
                KSpace.x4,
                KSpace.x1,
              ),
              child: KFilterField(
                controller: _filter,
                hint: widget.filterHint!,
                autofocus: false,
                onChanged: (text) => setState(() => _query = text),
                onClose: () {},
              ),
            ),
          widget.fillHeight ? Expanded(child: rows) : Flexible(child: rows),
          PickerFooter(
            border: widget.footerBorder,
            note: widget.footerNote?.call(context, picks),
            buttons: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel),
              ),
              FilledButton(
                focusNode: _confirmFocus,
                // Busy: disabled for the semantics and the keyboard, but it
                // keeps the filled look under the progress ring.
                onPressed: canGo && !_busy ? _confirm : null,
                style: _busy
                    ? FilledButton.styleFrom(
                        disabledBackgroundColor: scheme.primary,
                        disabledForegroundColor: scheme.onPrimary,
                      )
                    : null,
                child: _busy ? BusyButtonLabel(label: label) : Text(label),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
