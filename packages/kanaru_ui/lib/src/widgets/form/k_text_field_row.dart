import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';

/// One-line outlined text field, 56 dp: the label floats inside the box, the
/// [hint] shows while focused, [helper] sits under the field and [error]
/// replaces it (never both). Enter calls [onSubmitted] (the screen's primary
/// action). Not focused, a long value ends with an ellipsis.
///
/// The label float is the framework's own 167 ms transition (the field has no
/// hook for another duration). The caller owns [controller]. [enabled] false dims it and ignores input.
class KTextFieldRow extends StatelessWidget {
  const KTextFieldRow({
    super.key,
    required this.label,
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
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;

  /// Replaces [helper] while set, in the error colour.
  final String? error;
  final bool enabled;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = error != null && error!.isNotEmpty;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: KRadius.xs,
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: keyboard,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Hint only while focused: the floating label owns the empty box.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Replaces the helper line; an empty error would still reserve it.
        helperText: hasError ? null : helper,
        helperMaxLines: 3,
        errorText: hasError ? error : null,
        errorMaxLines: 3,
        isDense: false,
        filled: false,
        constraints: const BoxConstraints(minHeight: height),
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        disabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
      ),
      mouseCursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
    );
  }
}
