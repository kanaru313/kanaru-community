import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_draft.dart';

/// Keeps what is typed or pasted a clean number: other scripts' digits become
/// ASCII, every other character goes, and the whole number is clamped before
/// it is shown ("1000" → "720"). Empty and zero show as typed (they are not a
/// value; the field puts the last valid number back when it is left).
/// Text under an IME composition is left alone.
class SleepNumberFormatter extends TextInputFormatter {
  const SleepNumberFormatter(this.range);

  final SleepTimerRange range;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_composing(newValue)) return newValue;
    final typed = parseTypedNumber(newValue.text, range);
    final text = typed != null
        ? '$typed'
        : (asciiDigitsOf(newValue.text).isEmpty ? '' : '0');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

bool _composing(TextEditingValue v) =>
    v.composing.isValid && !v.composing.isCollapsed;

/// The big number of the custom screen, which can be typed over.
///
/// [value] is the last valid number: a typed number reaches [onChanged] as
/// soon as it means a value; empty and zero do not. Leaving the field shows
/// [value] again. Enter / Done does the same and calls [onSubmit], so an empty
/// field submits the last valid number. On desktop focusing selects the whole
/// number; the field never takes focus by itself (the modal decides, and
/// never on mobile, where the keyboard would cover the sheet).
class SleepTimerNumberField extends StatefulWidget {
  const SleepTimerNumberField({
    super.key,
    required this.value,
    required this.range,
    required this.semanticsLabel,
    required this.onChanged,
    required this.onSubmit,
    this.focusNode,
  });

  final int value;
  final SleepTimerRange range;

  /// Screen reader name ("Số phút" / "Số bài").
  final String semanticsLabel;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;

  /// Lets the modal move focus here; the field makes its own when null.
  final FocusNode? focusNode;

  @override
  State<SleepTimerNumberField> createState() => _SleepTimerNumberFieldState();
}

class _SleepTimerNumberFieldState extends State<SleepTimerNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SleepTimerNumberField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocusChanged);
      _focus.addListener(_onFocusChanged);
    }
    // The number came from a button, the ruler, a chip or another kind: show
    // it unless the text already means it (typing keeps the caret) or the
    // user is composing.
    final value = _controller.value;
    if (_composing(value)) return;
    final shown = parseTypedNumber(value.text, widget.range);
    final changed = old.value != widget.value && shown != widget.value;
    if (old.range != widget.range || changed) _settle();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _ownFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Shows [SleepTimerNumberField.value] again.
  void _settle() {
    final text = '${widget.value}';
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      if (FormFactor.of(context) == FormFactor.desktop) _selectAll();
    } else {
      _settle();
    }
  }

  void _selectAll() => _controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: _controller.text.length,
  );

  void _onEdited(String text) {
    if (_composing(_controller.value)) return;
    final typed = parseTypedNumber(text, widget.range);
    if (typed != null) widget.onChanged(typed);
  }

  void _onSubmitted(String _) {
    _settle();
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final base = desktop
        ? theme.textTheme.displayMedium
        : theme.textTheme.displayLarge;
    return Semantics(
      label: widget.semanticsLabel,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [SleepNumberFormatter(widget.range)],
        style: base?.copyWith(
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        cursorColor: scheme.primary,
        // Touch shells: the caret is as tall as the (scaled) digits, not the
        // whole line box, and the field keeps a little air above and below
        // it. Desktop keeps the default caret and the compact field.
        cursorHeight: desktop || base?.fontSize == null
            ? null
            : MediaQuery.textScalerOf(context).scale(base!.fontSize!),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: desktop
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: KSpace.x1),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary),
          ),
        ),
        onChanged: _onEdited,
        onSubmitted: _onSubmitted,
      ),
    );
  }
}
