import 'dart:async';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import 'config_checks.dart';
import 'config_env.dart';
import 'config_texts.dart';

/// One text, multiline, number, integer or url field: an outlined box whose
/// value is the stored one, else the manifest's default. Saves when the user
/// leaves the box or presses Enter (a number's − / + save at each tap) and
/// once more when the page closes with the box still focused. A box cleared
/// goes back to the default. An error shows only after the first leave and
/// goes as soon as the text is right; text that does not fit is never sent.
class TextFieldEditor extends StatefulWidget {
  const TextFieldEditor({
    super.key,
    required this.field,
    required this.stored,
    required this.env,
  });

  final InputField field;

  /// What the user saved, or null (the default applies).
  final Object? stored;
  final ConfigEnv env;

  @override
  State<TextFieldEditor> createState() => _TextFieldEditorState();
}

class _TextFieldEditorState extends State<TextFieldEditor>
    with ConfigCommitHost<TextFieldEditor> {
  late final _controller = TextEditingController(text: _shown(widget.stored));
  final _focus = FocusNode();
  bool _touched = false;
  ConfigIssue? _issue;

  /// The last value handed to the store: the same one is not sent twice.
  Object? _sent;
  bool _hasSent = false;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  /// What the box shows for [value]: the saved value, else the default.
  String _shown(Object? value) {
    final v = value ?? widget.field.defaultValue;
    return switch (v) {
      null => '',
      int() => '$v',
      num() => configNumberText(v),
      _ => '$v',
    };
  }

  @override
  void didUpdateWidget(TextFieldEditor old) {
    super.didUpdateWidget(old);
    // A change made elsewhere shows up, but never over a box being typed in
    // or one whose own save is still going.
    if (old.stored == widget.stored || _focus.hasFocus || commit.busy) return;
    final text = _shown(widget.stored);
    // What this box saved comes back the same: nothing to change then.
    if (_controller.text == text) return;
    _controller.text = text;
    _touched = false;
    _issue = null;
  }

  @override
  void dispose() {
    // Leaving the page with the box focused does not blur it: save here.
    _leave();
    detachCommit();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) return;
    // A page that closes unfocuses its box with nothing left to draw into:
    // dispose saves that edit.
    scheduleMicrotask(() {
      if (mounted) _commit();
    });
  }

  /// What the box says now, as the store wants it, and what it needs: the
  /// issue to show and the value to send (`send` false: nothing to do).
  ({ConfigIssue? issue, bool send, Object? value}) _decide() {
    final field = widget.field;
    final check = checkInputText(field, _controller.text);
    if (check.cleared) {
      final backToDefault = field.defaultValue != null;
      return (
        issue: !backToDefault && field.required
            ? const ConfigIssue(ConfigIssueKind.required)
            : null,
        send: widget.stored != null,
        value: null,
      );
    }
    if (!check.ok) return (issue: check.issue, send: false, value: null);
    final effective = widget.stored ?? field.defaultValue;
    return (issue: null, send: check.value != effective, value: check.value);
  }

  /// The user left the box, pressed Enter or stepped a number.
  void _commit() {
    final decision = _decide();
    if (_controller.text.trim().isEmpty && widget.field.defaultValue != null) {
      _controller.text = _shown(null);
    }
    setState(() {
      _touched = true;
      _issue = decision.issue;
    });
    _send(decision);
  }

  void _send(({ConfigIssue? issue, bool send, Object? value}) decision) {
    if ((decision.issue?.blocks ?? false) || !decision.send) return;
    if (_hasSent && _sent == decision.value && commit.busy) return;
    _hasSent = true;
    _sent = decision.value;
    commit.submit(decision.value);
  }

  /// The page closes: send the last edit when it is valid, without drawing.
  void _leave() {
    if (!_touched && _controller.text == _shown(widget.stored)) return;
    _send(_decide());
  }

  void _onChanged(String _) {
    commit.dismiss();
    if (!_touched) return;
    setState(() => _issue = _decide().issue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    final issue = _touched ? _issue : null;
    final refusal = commit.refusal;
    final error = issue != null
        ? configIssueText(l10n, issue)
        : refusal == null
        ? null
        : configRefusalText(l10n, refusal);
    final multiline = field.format == InputFormat.multiline;
    final numeric =
        field.format == InputFormat.number ||
        field.format == InputFormat.integer;
    final step = (field.step ?? 1).toDouble();
    final stepText = configNumberText(step);
    return KTextFieldRow(
      label: field.title.isEmpty ? field.key : field.title,
      controller: _controller,
      focusNode: _focus,
      hint: field.placeholder,
      helper: field.subtitle,
      error: error,
      enabled: !widget.env.locked,
      isRequired: field.required,
      keyboard: field.format == InputFormat.url ? TextInputType.url : null,
      rows: multiline ? (field.rows ?? 3) : null,
      number: numeric
          ? KNumberSpec(
              integer: field.format == InputFormat.integer,
              min: field.min?.toDouble(),
              max: field.max?.toDouble(),
              step: step,
              decreaseTooltip: l10n.pluginsCfgStepDown(stepText),
              increaseTooltip: l10n.pluginsCfgStepUp(stepText),
              onStepped: (_) => _commit(),
            )
          : null,
      onChanged: _onChanged,
      onSubmitted: (_) => _commit(),
    );
  }
}
