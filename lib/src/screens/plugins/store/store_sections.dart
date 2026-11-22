import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_view_models.dart';
import '../updates/update_all_button.dart';
import 'store_actions.dart';
import 'store_card_slice.dart';
import 'store_empty.dart';
import 'store_rows.dart';

/// The three blocks of the list, in order Cập nhật → Đã cài → Chưa cài (an
/// empty one is left out), then the footer. A store with no repository shows
/// its guide card in place of Chưa cài.
///
/// Returns a flat list of list items (a heading, then one slice per row) with
/// the gaps between blocks included, so the page builds only the rows in view
/// and starts only their icon fetches.
List<Widget> storeSectionWidgets(
  BuildContext context,
  StoreView view,
  StoreActions actions,
) {
  final l10n = AppLocalizations.of(context);
  const gap = KGap(KSpace.x5);
  final blocks = <List<Widget>>[
    if (view.updates.isNotEmpty)
      _block(
        heading: SetupSection(
          card: false,
          title: Text(l10n.pluginsSectionUpdates(view.updates.length)),
          hint: l10n.pluginsUpdatesHint,
          hintTooltip: l10n.pluginsUpdatesHintTooltip,
          hintTitle: l10n.pluginsSectionUpdates(view.updates.length),
          action: UpdateAllButton(count: view.updateAllCount, actions: actions),
          children: const [],
        ),
        rows: [
          for (final row in view.updates)
            (row.installId, UpdateRow(row: row, actions: actions)),
        ],
      ),
    if (view.installed.isNotEmpty)
      _block(
        heading: SetupSection(
          card: false,
          title: Text(l10n.pluginsSectionInstalled(view.installed.length)),
          children: const [],
        ),
        rows: [
          for (final row in view.installed)
            (row.installId, InstalledRow(row: row, actions: actions)),
        ],
      ),
    if (view.notInstalled.isNotEmpty)
      _block(
        heading: SetupSection(
          card: false,
          title: Text(l10n.pluginsSectionAvailable(view.notInstalled.length)),
          children: const [],
        ),
        rows: [
          for (final row in view.notInstalled)
            (row.installId, AvailableRow(row: row, actions: actions)),
        ],
      )
    else if (view.repoCount == 0)
      [NoRepositoryCard(actions: actions)],
    [StoreFooter(newerAppCount: view.needsNewerAppCount)],
  ];
  return [
    for (var i = 0; i < blocks.length; i++) ...[if (i > 0) gap, ...blocks[i]],
  ];
}

List<Widget> _block({
  required Widget heading,
  required List<(String, Widget)> rows,
}) => [
  heading,
  for (var i = 0; i < rows.length; i++)
    CardSlice(
      key: ValueKey(rows[i].$1),
      first: i == 0,
      last: i == rows.length - 1,
      child: rows[i].$2,
    ),
];
