import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';

/// Outlined field under the sort bar. Filters only the list in view; the
/// caller listens to [controller]. The caller owns [controller]; the ✕ button
/// and Esc clear it, report the empty text through [onChanged] (so an applied
/// filter clears with the text) and then call [onClose].
class KFilterField extends StatelessWidget {
  const KFilterField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onClose,
    this.closeTooltip,
    this.onChanged,
    this.autofocus,
    this.persistent = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClose;
  final String? closeTooltip;
  final ValueChanged<String>? onChanged;

  /// Takes the keyboard when it appears. Null means yes for a field that is
  /// opened on demand and no for a [persistent] one (a field that is always on
  /// the page must not pop the keyboard on every visit). Off too for a field
  /// above a list in a picker, where the list is what the user acts on first.
  final bool? autofocus;

  /// A field that is always on the page (a store's search): pill on
  /// `surfaceContainerHighest`, search icon, ✕ only while there is text. The
  /// ✕ and Esc clear the text but never close it, so [onClose] is not called;
  /// Esc on an empty field is left to whatever is above (a dialog, the page).
  final bool persistent;

  static const double height = 48;

  void _close() {
    controller.clear();
    onChanged?.call('');
    if (!persistent) onClose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        (persistent && controller.text.isEmpty)) {
      return KeyEventResult.ignored;
    }
    _close();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = persistent ? KRadius.full : KRadius.md;
    OutlineInputBorder border(BorderSide side) =>
        OutlineInputBorder(borderRadius: radius, borderSide: side);
    final rest = persistent
        ? BorderSide.none
        : BorderSide(color: scheme.outlineVariant);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: SizedBox(
        height: height,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TextField(
            controller: controller,
            autofocus: autofocus ?? !persistent,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              filled: persistent,
              fillColor: persistent ? scheme.surfaceContainerHighest : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KSpace.x3,
                vertical: KSpace.x3,
              ),
              prefixIcon: Icon(persistent ? KIcons.search : KIcons.filter),
              suffixIcon: persistent && controller.text.isEmpty
                  ? null
                  : KIconButton(
                      tooltip:
                          closeTooltip ??
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _close,
                      icon: KIcons.close,
                    ),
              border: border(rest),
              enabledBorder: border(rest),
              focusedBorder: border(
                BorderSide(color: scheme.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
