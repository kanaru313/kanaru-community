import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_view_models.dart';
import 'store_actions.dart';
import 'store_empty.dart';
import 'store_rows.dart';

/// The three blocks of the list, in order Cập nhật → Đã cài → Chưa cài (an
/// empty one is left out), then the footer. A store with no repository shows
/// its guide card in place of Chưa cài.
List<Widget> storeSectionWidgets(
  BuildContext context,
  StoreView view,
  StoreActions actions,
) {
  final l10n = AppLocalizations.of(context);
  final sections = <Widget>[
    if (view.updates.isNotEmpty)
      SetupSection(
        title: Text(l10n.pluginsSectionUpdates(view.updates.length)),
        hint: l10n.pluginsUpdatesHint,
        hintTooltip: l10n.pluginsUpdatesHintTooltip,
        hintTitle: l10n.pluginsSectionUpdates(view.updates.length),
        action: view.updateAllCount == 0
            ? null
            : TextButton(
                onPressed: actions.onUpdateAll == null
                    ? null
                    : () => actions.onUpdateAll!(context),
                child: Text(l10n.pluginsUpdateAll(view.updateAllCount)),
              ),
        children: [
          for (final row in view.updates)
            UpdateRow(key: ValueKey(row.installId), row: row, actions: actions),
        ],
      ),
    if (view.installed.isNotEmpty)
      SetupSection(
        title: Text(l10n.pluginsSectionInstalled(view.installed.length)),
        children: [
          for (final row in view.installed)
            InstalledRow(
              key: ValueKey(row.installId),
              row: row,
              actions: actions,
            ),
        ],
      ),
    if (view.notInstalled.isNotEmpty)
      SetupSection(
        title: Text(l10n.pluginsSectionAvailable(view.notInstalled.length)),
        children: [
          for (final row in view.notInstalled)
            AvailableRow(
              key: ValueKey(row.installId),
              row: row,
              actions: actions,
            ),
        ],
      )
    else if (view.repoCount == 0)
      NoRepositoryCard(actions: actions),
    StoreFooter(newerAppCount: view.needsNewerAppCount),
  ];
  return sections;
}
