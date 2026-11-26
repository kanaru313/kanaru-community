import 'package:material_ui/material_ui.dart';

import 'k_switch.dart';
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
    this.onTap,
    this.tapSemanticsLabel,
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

  /// Row action that replaces "tap the row toggles" (open, edit). The switch
  /// alone toggles then. Null keeps the default: a row tap toggles.
  final VoidCallback? onTap;

  /// Spoken name of the [onTap] action (the caller localises it). The row is
  /// announced as a button with this label; the title is not read twice.
  final String? tapSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final locked = onChanged == null;
    final changed = onChanged;
    final tap = onTap;
    final tapLabel = tap == null ? null : tapSemanticsLabel;
    return Semantics(
      container: true,
      hint: locked ? lockedLabel : null,
      label: tapLabel,
      button: tap != null ? true : null,
      child: SetupRowFrame(
        title: tapLabel == null ? title : ExcludeSemantics(child: title),
        subtitle: subtitle,
        leading: leading,
        onTap: tap ?? (changed == null ? null : () => changed(!value)),
        trailing: Semantics(
          container: tap != null,
          label: switchLabel,
          child: KSwitch(value: value, onChanged: changed),
        ),
      ),
    );
  }
}
