import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// Outlined field under the sort bar. Filters only the list in view; the
/// caller listens to [controller]. The caller owns [controller]; the ✕ button
/// and Esc clear it and call [onClose].
class KFilterField extends StatelessWidget {
  const KFilterField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onClose,
    this.closeTooltip,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClose;
  final String? closeTooltip;
  final ValueChanged<String>? onChanged;

  static const double height = 48;

  void _close() {
    controller.clear();
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: SizedBox(
        height: height,
        child: TextField(
          controller: controller,
          autofocus: true,
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
            suffixIcon: IconButton(
              tooltip: closeTooltip,
              onPressed: _close,
              icon: const Icon(KIcons.close),
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
}
