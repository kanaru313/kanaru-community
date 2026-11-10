import 'package:material_ui/material_ui.dart';

import 'setup_row_frame.dart';

/// A row with a title and a switch. `onChanged: null` locks the switch (for
/// example the last enabled tab): it is dimmed and announced as locked
/// through [lockedLabel]. Tapping the row toggles it.
class KSwitchRow extends StatelessWidget {
  const KSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.lockedLabel,
    this.switchLabel,
  });

  final Widget title;
  final Widget? subtitle;

  /// Icon, or a drag handle in a reorderable list.
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Spoken when the switch is locked.
  final String? lockedLabel;

  /// Spoken name of the switch (for example "Show the Albums tab").
  final String? switchLabel;

  @override
  Widget build(BuildContext context) {
    final locked = onChanged == null;
    final changed = onChanged;
    return Semantics(
      container: true,
      hint: locked ? lockedLabel : null,
      child: SetupRowFrame(
        title: title,
        subtitle: subtitle,
        leading: leading,
        onTap: changed == null ? null : () => changed(!value),
        trailing: Semantics(
          label: switchLabel,
          child: Switch(value: value, onChanged: changed),
        ),
      ),
    );
  }
}
