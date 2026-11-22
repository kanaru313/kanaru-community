import 'package:flutter/foundation.dart'
    show ErrorDescription, FlutterError, FlutterErrorDetails, ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'anchored_panel_layout.dart';
import 'k_anchored_panel.dart';
import 'k_gap.dart';
import 'k_sheet.dart';
import 'picker_footer.dart';
import 'k_row_edges.dart';
import 'selection_picker_action.dart';
import 'selection_row.dart';

export 'selection_picker_action.dart';

/// One option of [showSelectionPicker].
class SelectionOption<T> {
  const SelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.filterText,
    this.hint,
    this.removeTooltip,
    this.onRemove,
  }) : assert(
         (removeTooltip == null) == (onRemove == null),
         'removeTooltip and onRemove go together',
       ),
       mediaTitle = null,
       mediaLine2 = null,
       mediaTag = null,
       circleCover = false;

  /// An option with a cover: shown as the library's media row (see
  /// [SelectionRow.media]). [title] and [leading] are derived from the strings
  /// and [cover].
  SelectionOption.media({
    required this.value,
    required String this.mediaTitle,
    required Widget cover,
    this.mediaLine2,
    this.mediaTag,
    this.circleCover = false,
    this.enabled = true,
    this.filterText,
    this.hint,
  }) : title = Text(mediaTitle),
       subtitle = null,
       removeTooltip = null,
       onRemove = null,
       leading = cover;

  final String? mediaTitle;
  final String? mediaLine2;
  final String? mediaTag;
  final bool circleCover;

  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;

  /// Plain text a multi picker filters on (the [title] widget is never
  /// searched). Without it the option always shows.
  final String? filterText;

  /// Accessible description of the option ([SelectionRow.hint]).
  final String? hint;

  /// Makes the row removable: a ✕ after it (tooltip [removeTooltip]) runs
  /// [onRemove] and the picker stays open. [onRemove] resolves to an error
  /// line to show in the picker, or null when it went through (follow the
  /// change through `live`). Text options only.
  final String? removeTooltip;
  final Future<String?> Function()? onRemove;
}

/// Options and choice of an open picker that changes under it
/// ([showSelectionPicker]'s `live`).
class SelectionPickerState<T> {
  const SelectionPickerState({required this.options, required this.selected});

  final List<SelectionOption<T>> options;
  final T? selected;
}

/// Where [showSelectionPicker] shows itself.
enum SelectionPickerPresentation {
  /// Mobile: a sheet. Desktop: a panel under the anchor, or a centred dialog
  /// without one.
  auto,

  /// A centred dialog ([KLayout.dialog] wide) on both shells; the anchor is
  /// ignored.
  dialog,

  /// A dropdown panel under the anchor on both shells (dense 40 dp rows, as
  /// the sort dropdown). Without a laid-out anchor it falls back to [auto].
  anchored,
}

/// Single-choice picker. Mobile: sheet ([showKSheet]), unless [presentation]
/// is `anchored` (the dropdown panel on both shells). Desktop: a panel
/// anchored under [anchor] when given, otherwise a centred dialog
/// ([presentation] `dialog` forces the dialog on both shells). [anchorAlign]
/// picks which edge of the panel lines up with the anchor (`end` for panels
/// opened from a Settings or first-run row).
///
/// [header] sits above the options and stays put while they scroll.
/// With [confirmLabel] and [cancelLabel] a tap only selects the row and the
/// footer [cancelLabel] / [confirmLabel] closes it; without them a tap chooses
/// and closes. Give both or neither: with only one, release builds stay in
/// tap-to-close mode (debug asserts). [confirm] runs before the picker closes;
/// returning false keeps it open (the choice is never popped first and asked
/// about afterwards).
///
/// [live] replaces [options] and [selected] while open (a removal redraws the
/// list and its choice).
/// [footerAction] is a button under the options (not with [confirmLabel]).
/// The error line under the options shows what a removal or the action
/// reported. A throw from an option's `onRemove` or the footer action never
/// escapes: it is reported through [FlutterError.reportError] and the line
/// shows [errorText] (null: no line), the picker stays usable. Resolves to the
/// chosen value, or null when dismissed.
Future<T?> showSelectionPicker<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required T? selected,
  Widget? title,
  Widget? header,
  Future<bool> Function(T value)? confirm,
  ValueListenable<SelectionPickerState<T>>? live,
  SelectionPickerAction? footerAction,
  String? errorText,
  GlobalKey? anchor,
  String? confirmLabel,
  String? cancelLabel,
  SelectionPickerPresentation presentation = SelectionPickerPresentation.auto,
  KAnchorAlign anchorAlign = KAnchorAlign.start,
}) {
  assert(
    (confirmLabel == null) == (cancelLabel == null),
    'confirmLabel and cancelLabel go together',
  );
  assert(
    footerAction == null || confirmLabel == null,
    'a footer action and confirm / cancel are two footers',
  );
  Widget body(BuildContext _, {bool compact = false}) => _PickerBody<T>(
    options: options,
    selected: selected,
    title: title,
    header: header,
    confirm: confirm,
    live: live,
    footerAction: footerAction,
    errorText: errorText,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    compact: compact,
  );

  final centred = presentation == SelectionPickerPresentation.dialog;
  final box = centred ? null : anchor?.currentContext?.findRenderObject();
  final rect = box is RenderBox && box.attached
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final dropdown =
      presentation == SelectionPickerPresentation.anchored && rect != null;
  if (!centred && !dropdown && FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<T>(context, builder: body);
  }
  if (rect == null) {
    return showDialog<T>(
      context: context,
      animationStyle: KMotion.routeAnimationStyle(context),
      builder: (context) => KRowEdgesScope(
        edges: KRowEdges.inset,
        child: Dialog(
          shape: KShape.of(KRadius.xl, continuous: true),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KLayout.dialog),
            child: body(context),
          ),
        ),
      ),
    );
  }
  return showKAnchoredPanel<T>(
    context,
    anchor: rect,
    align: anchorAlign,
    // Same size as the sort dropdown: width follows the content between the
    // dropdown limits, rows are dense.
    builder: (context) => ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: KLayout.anchoredPickerMinWidth,
        maxWidth: KLayout.anchoredPickerMaxWidth,
      ),
      child: IntrinsicWidth(child: body(context, compact: true)),
    ),
  );
}

class _PickerBody<T> extends StatefulWidget {
  const _PickerBody({
    required this.options,
    required this.selected,
    required this.title,
    required this.header,
    required this.confirm,
    required this.live,
    required this.footerAction,
    required this.errorText,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.compact,
  });

  final List<SelectionOption<T>> options;
  final T? selected;
  final Widget? title;
  final Widget? header;
  final Future<bool> Function(T value)? confirm;
  final ValueListenable<SelectionPickerState<T>>? live;
  final SelectionPickerAction? footerAction;

  /// The line shown when a removal or the footer action throws.
  final String? errorText;
  final String? confirmLabel;
  final String? cancelLabel;

  /// Anchored desktop panel: dense rows, `titleSmall`, no gaps (the sort
  /// dropdown's size). Sheets and dialogs keep the 48 dp rows.
  final bool compact;

  bool get footer => confirmLabel != null && cancelLabel != null;

  @override
  State<_PickerBody<T>> createState() => _PickerBodyState<T>();
}

class _PickerBodyState<T> extends State<_PickerBody<T>> {
  /// Blocks a second tap while [_PickerBody.confirm] is pending.
  bool _busy = false;

  /// The row chosen so far in footer mode (starts as [_PickerBody.selected]).
  late T? _pending = _selected;

  /// What a removal or the footer action reported.
  String? _error;

  List<SelectionOption<T>> get _options =>
      widget.live?.value.options ?? widget.options;

  T? get _selected {
    final live = widget.live;
    return live == null ? widget.selected : live.value.selected;
  }

  @override
  void initState() {
    super.initState();
    widget.live?.addListener(_changed);
  }

  @override
  void didUpdateWidget(_PickerBody<T> old) {
    super.didUpdateWidget(old);
    if (old.live == widget.live) return;
    old.live?.removeListener(_changed);
    widget.live?.addListener(_changed);
  }

  @override
  void dispose() {
    widget.live?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _remove(SelectionOption<T> o) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await o.onRemove!();
    } catch (e, stack) {
      _report(e, stack, 'removing a picker option');
      error = widget.errorText;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  void _report(Object error, StackTrace stack, String doing) =>
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'kanaru_ui',
          context: ErrorDescription(doing),
        ),
      );

  Future<void> _runAction() async {
    final action = widget.footerAction!;
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    SelectionActionResult result;
    try {
      result = await action.onPressed(context);
    } catch (e, stack) {
      _report(e, stack, 'running the picker footer action');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = widget.errorText;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.error;
    });
    if (result.close) Navigator.of(context).pop();
  }

  Future<void> _pick(T value) async {
    if (_busy) return;
    final confirm = widget.confirm;
    if (confirm != null) {
      setState(() => _busy = true);
      setState(() => _error = null);
      bool ok;
      try {
        ok = await confirm(value);
      } catch (e, stack) {
        // A throwing confirm keeps the picker open with the error line.
        _report(e, stack, 'confirming a picker choice');
        if (mounted) {
          setState(() {
            _busy = false;
            _error = widget.errorText;
          });
        }
        return;
      }
      if (mounted) setState(() => _busy = false);
      if (!ok || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x4,
              KSpace.x6,
              KSpace.x2,
            ),
            child: DefaultTextStyle.merge(
              style:
                  (widget.compact
                          ? textTheme.titleSmall
                          : textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w700),
              child: widget.title!,
            ),
          ),
        if (widget.header != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
            // Caption of the compact panel: bodySmall, as the mockup draws it.
            child: widget.compact
                ? DefaultTextStyle.merge(
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: widget.header!,
                  )
                : widget.header,
          ),
        Flexible(
          child: widget.compact
              // A plain scroll view (a viewport has no intrinsic width) so the
              // panel can size to its content, as the sort dropdown does.
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final o in _options) _row(o)],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
                  itemCount: _options.length,
                  separatorBuilder: (_, i) => _options[i].mediaTitle != null
                      ? const SizedBox.shrink()
                      : const KGap(KSpace.x1),
                  itemBuilder: (context, i) => _row(_options[i]),
                ),
        ),
        if (_error != null) _errorLine(context, _error!),
        if (widget.footer) _footer(context),
        if (widget.footerAction != null) _actionFooter(),
      ],
    );
  }

  Widget _row(SelectionOption<T> o) => o.mediaTitle != null
      ? SelectionRow.media(
          mediaTitle: o.mediaTitle!,
          mediaLine2: o.mediaLine2,
          mediaTag: o.mediaTag,
          circleCover: o.circleCover,
          cover: o.leading!,
          alikeOptions: true,
          hint: o.hint,
          enabled: o.enabled && !_busy,
          selected: o.value == (widget.footer ? _pending : _selected),
          onTap: widget.footer
              ? () => setState(() => _pending = o.value)
              : () => _pick(o.value),
        )
      : _textRow(o);

  Widget _textRow(SelectionOption<T> o) {
    return SelectionRow(
      dense: widget.compact,
      trailingAction: o.onRemove == null
          ? null
          : SelectionRowAction(
              icon: KIcons.close,
              tooltip: o.removeTooltip!,
              onPressed: _busy ? null : () => _remove(o),
            ),
      title: o.title,
      subtitle: o.subtitle,
      leading: o.leading,
      enabled: o.enabled && !_busy,
      selected: o.value == (widget.footer ? _pending : _selected),
      onTap: widget.footer
          ? () => setState(() => _pending = o.value)
          : () => _pick(o.value),
    );
  }

  Widget _errorLine(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x1,
        KSpace.x6,
        KSpace.x2,
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _actionFooter() {
    final action = widget.footerAction!;
    return PickerFooter(
      buttons: [
        TextButton.icon(
          onPressed: _busy ? null : _runAction,
          icon: Icon(action.icon),
          label: Text(action.label),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final pending = _pending;
    return PickerFooter(
      buttons: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel!),
        ),
        FilledButton(
          onPressed: _busy || pending == null
              ? null
              : () {
                  // Read at tap time: the row may have just changed.
                  final chosen = _pending;
                  if (chosen != null) _pick(chosen);
                },
          child: Text(widget.confirmLabel!),
        ),
      ],
    );
  }
}
