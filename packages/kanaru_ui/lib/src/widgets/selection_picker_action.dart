import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';

/// What a picker action (the footer's or an option's ✕) decided.
class SelectionActionResult {
  /// Nothing to report: the picker stays open (the caller gave up, or the
  /// action only changed the options).
  const SelectionActionResult.stay() : close = false, error = null;

  /// The picker closes without a choice.
  const SelectionActionResult.close() : close = true, error = null;

  /// The picker stays open and shows [message] in its error line.
  const SelectionActionResult.error(String message)
    : close = false,
      error = message;

  final bool close;
  final String? error;
}

/// The footer action of [showSelectionPicker] (the mockup's "+ Thêm model…"):
/// a text button with [icon] and [label] under the options. [onPressed] gets
/// the picker's context (to open a dialog over it); the options are blocked
/// while it runs.
class SelectionPickerAction {
  const SelectionPickerAction({
    required this.label,
    required this.onPressed,
    this.icon = KIcons.add,
  });

  final String label;
  final IconData icon;
  final Future<SelectionActionResult> Function(BuildContext context) onPressed;
}
