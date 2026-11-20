import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_draft.dart';

/// Set by a tap: the next edit replaces the whole number. Selection alone is
/// not trusted for this, because some IMEs push their own value and caret after
/// the select-all, so the typed digit would land beside the old number.
class SleepReplaceFlag {
  bool armed = false;
}

/// Keeps what is typed or pasted a clean number: other scripts' digits become
/// ASCII, every other character goes, and the whole number is clamped before
/// it is shown ("1000" → "720"). Empty and zero show as typed (they are not a
/// value; the field puts the last valid number back when it is left).
/// Text under an IME composition is left alone, except when [replace] is armed.
///
/// Armed ([SleepReplaceFlag.armed], touch shells only): the first edit that
/// changes the text replaces the number, by the shape of the change
/// ([_replacement]), wherever the IME put its caret, and disarms.
/// Composing digits that are inserted become the whole new text (no append).
class SleepNumberFormatter extends TextInputFormatter {
  SleepNumberFormatter(this.range, {this.replace});

  final SleepTimerRange range;
  final SleepReplaceFlag? replace;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final flag = replace;
    if (flag != null && flag.armed && newValue.text != oldValue.text) {
      flag.armed = false;
      final inserted = _replacement(oldValue, newValue);
      // Still composing: keep the inserted text raw and composing (it is
      // cleaned and reported when the composition ends, blur or submit).
      if (_composing(newValue) && inserted.isNotEmpty) {
        return TextEditingValue(
          text: inserted,
          selection: TextSelection.collapsed(offset: inserted.length),
          composing: TextRange(start: 0, end: inserted.length),
        );
      }
      return _clean(inserted);
    }
    if (_composing(newValue)) return newValue;
    final result = _clean(newValue.text);
    return result.text == newValue.text ? newValue : result;
  }

  /// What the user meant to type when the field was armed to be replaced.
  /// 1. The old text was fully selected (the IME honoured it): the new text.
  /// 2. The new text still holds the whole old number (the IME appended or
  ///    inserted at its own caret): only the inserted part.
  /// 3. Only a piece was deleted: empty (the user is replacing).
  /// 4. Anything else: the new text.
  static String _replacement(TextEditingValue old, TextEditingValue next) {
    final o = old.text;
    final n = next.text;
    final sel = old.selection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start == 0 &&
        sel.end == o.length) {
      return n;
    }
    if (o.isNotEmpty && n.length > o.length) {
      final starts = <int>[
        for (var i = 0; i + o.length <= n.length; i++)
          if (n.startsWith(o, i)) i,
      ];
      if (starts.isNotEmpty) {
        final extra = n.length - o.length;
        // The run position implied by where the old caret was (end: the IME
        // appended, start: it prepended), else by the new caret (it sits at
        // the end of the inserted part), else the first run.
        final caret = sel.isValid ? sel.extentOffset : -1;
        final wanted = caret >= o.length ? 0 : (caret == 0 ? extra : -1);
        var at = starts.contains(wanted) ? wanted : -1;
        if (at < 0) {
          final end = next.selection.isValid ? next.selection.extentOffset : -1;
          for (final i in starts) {
            if ((i == 0 ? n.length : extra) == end) {
              at = i;
              break;
            }
          }
        }
        if (at < 0) at = starts.first;
        return n.substring(0, at) + n.substring(at + o.length);
      }
    }
    if (n.length < o.length) {
      final limit = n.length;
      var prefix = 0;
      while (prefix < limit && o[prefix] == n[prefix]) {
        prefix++;
      }
      var suffix = 0;
      while (suffix < limit - prefix &&
          o[o.length - 1 - suffix] == n[n.length - 1 - suffix]) {
        suffix++;
      }
      if (prefix + suffix >= n.length) return '';
    }
    return n;
  }

  TextEditingValue _clean(String raw) {
    final typed = parseTypedNumber(raw, range);
    final text = typed != null
        ? '$typed'
        : (asciiDigitsOf(raw).isEmpty ? '' : '0');
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
/// number; on touch shells focusing (a tap) selects it too, so typing replaces
/// it. The field never takes focus by itself (the modal decides, and
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
  final SleepReplaceFlag _replace = SleepReplaceFlag();

  /// Last number reported to the parent that its rebuild has not delivered
  /// back through [SleepTimerNumberField.value] yet (submit and blur can
  /// arrive before that frame).
  int? _reported;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SleepTimerNumberField old) {
    super.didUpdateWidget(old);
    _reported = null;
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
    if (old.range != widget.range || changed) {
      _settle();
      _outsideChange();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _ownFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Touch shells: a number replaced from outside while the field has focus is
  /// selected whole again.
  void _outsideChange() {
    if (!_focus.hasFocus || FormFactor.of(context) == FormFactor.desktop) {
      return;
    }
    _selectAllAfterFrame();
  }

  /// Every tap on a touch shell selects the whole number (also on a field that
  /// already has focus), so typing always replaces; the tap places the caret
  /// after this callback, so select after that.
  void _onTap() {
    if (FormFactor.of(context) == FormFactor.desktop) return;
    _replace.armed = true;
    // A tap is explicit: select even when the keyboard left the typed digit
    // under a composing region (many Android keyboards do), which would
    // otherwise keep the caret collapsed and make the next digit append.
    _selectAllAfterFrame(overrideComposing: true);
  }

  void _selectAllAfterFrame({bool overrideComposing = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      if (!overrideComposing && _composing(_controller.value)) return;
      _selectAll();
    });
    // A callback alone does not make a frame: ask for one so it runs now.
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Shows [SleepTimerNumberField.value] again.
  void _settle() {
    final text = '${_reported ?? widget.value}';
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      if (FormFactor.of(context) == FormFactor.desktop) {
        _selectAll();
      } else {
        _selectAllAfterFrame();
      }
    } else {
      _replace.armed = false;
      _commitThenSettle();
    }
  }

  /// Digits still under an IME composing region were not reported while
  /// typing: when the field is left or submitted they count. A valid number
  /// the parent does not know yet is reported and shown; otherwise the last
  /// valid number comes back.
  void _commitThenSettle() {
    final typed = parseTypedNumber(_controller.text, widget.range);
    if (typed != null && typed != (_reported ?? widget.value)) {
      _reported = typed;
      widget.onChanged(typed);
      final text = '$typed';
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }
    _settle();
  }

  void _selectAll() {
    // Only touch shells replace on the next edit; desktop types where the
    // caret is (End then a digit appends).
    _replace.armed = FormFactor.of(context) != FormFactor.desktop;
    _controller.value = _controller.value.copyWith(
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _onEdited(String text) {
    if (_composing(_controller.value)) return;
    final typed = parseTypedNumber(text, widget.range);
    if (typed == null) return;
    _reported = typed;
    widget.onChanged(typed);
  }

  void _onSubmitted(String _) {
    _commitThenSettle();
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
        inputFormatters: [
          SleepNumberFormatter(widget.range, replace: _replace),
        ],
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
        onTap: _onTap,
        onChanged: _onEdited,
        onSubmitted: _onSubmitted,
      ),
    );
  }
}
