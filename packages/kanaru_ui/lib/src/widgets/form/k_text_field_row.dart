import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';
import 'k_number_spec.dart';
import 'k_text_field_footer.dart';

/// Outlined text field, 56 dp (48 when [dense]): the label floats inside the
/// box, the [hint] shows while focused (always, without a label), [helper]
/// sits under the field (line breaks kept) and [error] replaces it (never
/// both). Enter calls [onSubmitted] (the screen's primary action), except in a
/// [rows] field where it inserts a line break. A long value is clipped at the
/// box edge, not ellipsised: the framework's text field has no overflow
/// option.
///
/// Variants by intent:
/// - [rows]: a multi-line field of that many lines; on desktop it grows with
///   its text up to three times as many.
/// - [number]: number / integer field with in-field − / + buttons, see
///   [KNumberSpec].
/// - [keyboard]: e.g. [TextInputType.url].
/// - [isRequired]: a `*` after the label.
/// - [maxLength]: a limit with a counter, see there. [warning] is a soft note line.
/// - [invalid]: the red outline without an error line (an item of a list
///   whose one shared error sits under the whole list).
/// - [enabled] false: dimmed, not focusable, ignores input.
///
/// The label float is the framework's own 167 ms transition (the field has no
/// hook for another duration). The caller owns [controller].
class KTextFieldRow extends StatelessWidget {
  const KTextFieldRow({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.keyboard,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.isRequired = false,
    this.invalid = false,
    this.dense = false,
    this.rows,
    this.number,
    this.maxLength,
    this.warning,
  }) : assert(label != null || hint != null, 'needs a label or a hint'),
       assert(rows == null || rows >= 1, 'rows is at least 1'),
       assert(rows == null || number == null, 'a number field is one line'),
       assert(maxLength == null || maxLength > 0, 'maxLength is positive');

  final String? label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;

  /// Replaces [helper] while set, in the error colour.
  final String? error;
  final bool enabled;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;

  /// Typing only. A [number] step does not call it: it reports through
  /// [KNumberSpec.onStepped] (the save path) and updates the controller.
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isRequired;

  /// Red outline without an error line.
  final bool invalid;

  /// 48 dp high (items of a list or table) instead of 56.
  final bool dense;

  /// Number of lines of a multi-line field; null = one line.
  final int? rows;

  /// Makes it a number field (filter, keyboard, − / + buttons, ↑ / ↓).
  final KNumberSpec? number;

  /// Hard limit in characters: typing and paste stop there. Shows "n / max"
  /// at the right of the supporting line (digits grouped by locale), in the
  /// normal colour also when full. An [error] replaces the line, counter
  /// included.
  final int? maxLength;

  /// Soft note on its own tinted line under the helper / counter line; the
  /// outline turns tertiary. Not an error: an [error] replaces it.
  final String? warning;

  static const double height = 56;
  static const double denseHeight = 48;

  @override
  Widget build(BuildContext context) {
    final spec = number;
    if (spec == null) return _field(context, null);
    // The − / + dimming follows the text, whoever changes it.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _onKey(event, spec),
        child: _field(context, spec),
      ),
    );
  }

  /// ↑ / ↓ step the value; the arrow keys do nothing else in a one-line field.
  KeyEventResult _onKey(KeyEvent event, KNumberSpec spec) {
    if (!enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final dir = event.logicalKey == LogicalKeyboardKey.arrowUp
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowDown
        ? -1
        : 0;
    if (dir == 0) return KeyEventResult.ignored;
    _step(spec, dir);
    return KeyEventResult.handled;
  }

  void _step(KNumberSpec spec, int dir) {
    final text = spec.stepped(controller.text, dir);
    if (text == null) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    spec.onStepped(text);
  }

  Widget _field(BuildContext context, KNumberSpec? spec) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = error != null && error!.isNotEmpty;
    final bad = hasError || invalid;
    final soft = !hasError && warning != null && warning!.isNotEmpty;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: KRadius.xs,
          borderSide: BorderSide(color: color, width: width),
        );
    final lines = rows;
    final grow = lines != null && FormFactor.of(context) == FormFactor.desktop;
    final text = label;
    final footer =
        maxLength != null || (warning != null && warning!.isNotEmpty);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: lines != null
          ? TextInputType.multiline
          : spec?.keyboard ?? keyboard,
      inputFormatters: spec?.formatters,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      minLines: lines,
      maxLines: lines == null ? 1 : (grow ? lines * 3 : lines),
      textInputAction: lines != null
          ? TextInputAction.newline
          : TextInputAction.done,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: text != null && !isRequired ? text : null,
        label: text != null && isRequired
            ? Text.rich(
                TextSpan(
                  text: text,
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ),
              )
            : null,
        alignLabelWithHint: lines != null,
        hintText: hint,
        // Hint only while focused: the floating label owns the empty box.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Replaces the helper line; an empty error would still reserve it.
        helperText: hasError || footer ? null : helper,
        helper: hasError || !footer
            ? null
            : KTextFieldFooter(
                controller: controller,
                maxLength: maxLength,
                helper: helper,
                warning: warning,
              ),
        helperMaxLines: 6,
        // Our own counter lives in the footer; hide the framework's.
        counterText: '',
        errorText: hasError ? error : null,
        errorMaxLines: 3,
        isDense: false,
        filled: false,
        constraints: BoxConstraints(minHeight: dense ? denseHeight : height),
        contentPadding: dense
            ? const EdgeInsets.symmetric(
                horizontal: KSpace.x4,
                vertical: KSpace.x3,
              )
            : null,
        suffixIcon: spec == null ? null : _stepButtons(spec),
        suffixIconConstraints: const BoxConstraints(),
        border: border(scheme.outline),
        enabledBorder: border(
          bad
              ? scheme.error
              : soft
              ? scheme.tertiary
              : scheme.outline,
        ),
        disabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(
          bad
              ? scheme.error
              : soft
              ? scheme.tertiary
              : scheme.primary,
          2,
        ),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
      ),
      mouseCursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
    );
  }

  Widget _stepButtons(KNumberSpec spec) {
    Widget button(int dir) {
      final on = enabled && spec.canStep(controller.text, dir);
      return KIconButton(
        icon: dir < 0 ? KIcons.remove : KIcons.add,
        size: KIconSize.sm,
        tooltip: dir < 0 ? spec.decreaseTooltip : spec.increaseTooltip,
        onPressed: on ? () => _step(spec, dir) : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: KSpace.x1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [button(-1), button(1)],
      ),
    );
  }
}
