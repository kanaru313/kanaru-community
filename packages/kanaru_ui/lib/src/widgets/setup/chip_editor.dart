import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_font.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_chip.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';
import 'dashed_outline.dart';

/// An editable list of short text values shown as chips: [values] with a
/// remove button each, dashed [suggestions] that add themselves when tapped,
/// and an input with an add button.
///
/// The widget keeps no list: [onAdd] gets the typed text (or a suggestion) and
/// returns null when it was taken (the field clears) or a message to show
/// under the field. [onRemove] removes one value at once.
///
/// [display] turns a stored value into its label (a space shown as `␣`);
/// labels are monospaced. With no [values] the [emptyNote] shows instead.
class KChipEditor extends StatefulWidget {
  const KChipEditor({
    super.key,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    required this.inputHint,
    required this.addLabel,
    required this.removeTooltip,
    this.suggestions = const [],
    this.display = _same,
    this.emptyNote,
  });

  final List<String> values;

  /// Values offered as dashed chips; one already in [values] is hidden.
  final List<String> suggestions;

  /// Called with the text to add; returns an error message or null.
  final String? Function(String raw) onAdd;
  final ValueChanged<String> onRemove;
  final String inputHint;
  final String addLabel;

  /// Tooltip and accessible name of the remove button of a value.
  final String Function(String value) removeTooltip;
  final String Function(String value) display;

  /// Shown instead of the chips while [values] is empty.
  final String? emptyNote;

  static String _same(String value) => value;

  @override
  State<KChipEditor> createState() => _KChipEditorState();
}

class _KChipEditorState extends State<KChipEditor> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Adds [raw]; a refusal shows under the field whether the text was typed
  /// or came from a suggestion.
  void _add(String raw, {required bool fromField}) {
    final error = widget.onAdd(raw);
    setState(() => _error = error);
    if (error == null && fromField) {
      _controller.clear();
      _focus.requestFocus();
    }
  }

  TextStyle _mono(BuildContext context) =>
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
        fontFamily: KFont.mono,
        fontFamilyFallback: KFont.monoFallback,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mono = _mono(context);
    // Same comparison as the host's duplicate check: any case.
    final have = {for (final v in widget.values) v.toLowerCase()};
    final open = [
      for (final s in widget.suggestions)
        if (!have.contains(s.toLowerCase())) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.values.isEmpty && widget.emptyNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpace.x2),
            child: Text(
              widget.emptyNote!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        Wrap(
          spacing: KSpace.x2,
          runSpacing: KSpace.x2,
          children: [
            for (final v in widget.values)
              KChip.static(
                label: Text(
                  widget.display(v),
                  style: mono.copyWith(color: scheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: KIconButton(
                  icon: KIcons.close,
                  size: KIconSize.sm,
                  tooltip: widget.removeTooltip(v),
                  onPressed: () => widget.onRemove(v),
                ),
              ),
            for (final s in open)
              DashedOutline(
                color: scheme.outline,
                child: KChip(
                  label: Text(
                    '+ ${widget.display(s)}',
                    style: mono.copyWith(color: scheme.primary),
                  ),
                  onTap: () => _add(s, fromField: false),
                ),
              ),
          ],
        ),
        const KGap(KSpace.x3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                style: mono,
                maxLines: 1,
                // Control characters never reach the list (the entry check
                // would strip them anyway).
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F]')),
                ],
                decoration: InputDecoration(
                  hintText: widget.inputHint,
                  errorText: _error,
                  isDense: true,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (v) => _add(v, fromField: true),
              ),
            ),
            const KGap(KSpace.x2),
            FilledButton.tonal(
              onPressed: () => _add(_controller.text, fromField: true),
              child: Text(widget.addLabel),
            ),
          ],
        ),
      ],
    );
  }
}
