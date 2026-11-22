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
    this.autofocus = true,
    this.persistent = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClose;
  final String? closeTooltip;
  final ValueChanged<String>? onChanged;

  /// Takes the keyboard when it appears; off for a field that sits above a
  /// list in a picker, where the list is what the user acts on first.
  final bool autofocus;

  /// A field that is always on the page (a store's search): pill on
  /// `surfaceContainerHighest`, search icon, ✕ only while there is text. The
  /// ✕ and Esc clear the text but never close it, so [onClose] is not called.
  final bool persistent;

  static const double height = 48;

  void _close() {
    controller.clear();
    onChanged?.call('');
    if (!persistent) onClose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (persistent) return _buildPersistent(context, scheme);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: SizedBox(
        height: height,
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KSpace.x3,
              vertical: KSpace.x3,
            ),
            prefixIcon: const Icon(KIcons.filter),
            suffixIcon: KIconButton(
              tooltip:
                  closeTooltip ??
                  MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: _close,
              icon: KIcons.close,
            ),
            border: OutlineInputBorder(
              borderRadius: KRadius.md,
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KRadius.md,
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KRadius.md,
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersistent(BuildContext context, ColorScheme scheme) {
    const none = BorderSide.none;
    final pill = OutlineInputBorder(
      borderRadius: KRadius.full,
      borderSide: none,
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: SizedBox(
        height: height,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KSpace.x3,
                vertical: KSpace.x3,
              ),
              prefixIcon: const Icon(KIcons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : KIconButton(
                      tooltip:
                          closeTooltip ??
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _close,
                      icon: KIcons.close,
                    ),
              border: pill,
              enabledBorder: pill,
              focusedBorder: OutlineInputBorder(
                borderRadius: KRadius.full,
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
