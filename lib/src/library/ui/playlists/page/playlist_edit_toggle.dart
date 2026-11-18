import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// The header button of edit mode: `[✏]` "Edit list" while off, `[✓]`
/// "Done" on the tonal disc while on. [onPressed] null (a drag is running)
/// disables it.
class PlaylistEditToggle extends StatelessWidget {
  const PlaylistEditToggle({
    super.key,
    required this.editing,
    required this.onPressed,
  });

  final bool editing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = editing ? l10n.plScreensEditDone : l10n.plScreensEditList;
    // One node for a screen reader: the button and its on / off. The off
    // button names itself; the on one has only its tooltip, so it is named
    // here (never both: the name would be read twice).
    return MergeSemantics(
      child: Semantics(
        toggled: editing,
        label: editing ? label : null,
        child: KTonalToggleButton(
          icon: KIcons.editList,
          selectedIcon: KIcons.check,
          selected: editing,
          tooltip: label,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
