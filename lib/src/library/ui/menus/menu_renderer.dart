import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show BorderRadius;

import '../../../../l10n/gen/app_localizations.dart';
import '../browse/item_covers.dart';
import 'menu_action_runner.dart';
import 'menu_header.dart';
import 'menu_model.dart';

/// Turns a [MenuSpec] into the pages `showKLayeredMenu` shows: one renderer
/// for every kind of item and both shells. Rows run through [runner] once the
/// menu has closed.
KMenuPage renderMenu(
  MenuSpec spec,
  AppLocalizations l10n,
  MenuActionRunner runner,
) {
  final pages = <String, KMenuPage>{};
  KMenuPage? pageOf(String? key) {
    if (key == null) return null;
    return pages.putIfAbsent(key, () {
      if (key == advancedPageKey) {
        return _page(
          MenuPageSpec(title: l10n.libraryMenuAdvanced, groups: spec.advanced),
          pageOf,
          l10n,
          runner,
        );
      }
      final page = spec.pages[key];
      if (page == null) throw StateError('menu has no page "$key"');
      return _page(page, pageOf, l10n, runner);
    });
  }

  final header = spec.header;
  return KMenuPage(
    header: MenuHeaderView(header: header),
    headerOpens: pageOf(header.infoPage),
    groups: _groups(spec.groups, pageOf, l10n, runner),
    footer: spec.queueIds.isEmpty
        ? const []
        : [
            KMenuButton(
              label: l10n.libraryMenuPlayNext,
              icon: KIcons.playlistPlay,
              onPressed: () => runner.playNext(spec.queueIds),
            ),
            KMenuButton(
              label: l10n.libraryMenuAddToQueue,
              icon: KIcons.queueMusic,
              onPressed: () => runner.enqueue(spec.queueIds),
            ),
          ],
  );
}

KMenuPage _page(
  MenuPageSpec page,
  KMenuPage? Function(String? key) pageOf,
  AppLocalizations l10n,
  MenuActionRunner runner,
) => KMenuPage(
  title: page.title,
  note: page.note,
  groups: _groups(page.groups, pageOf, l10n, runner),
  groupTitles: page.groupTitles,
);

List<List<KMenuRow>> _groups(
  List<List<MenuItemSpec>> groups,
  KMenuPage? Function(String? key) pageOf,
  AppLocalizations l10n,
  MenuActionRunner runner,
) => [
  for (final group in groups)
    [for (final item in group) _row(item, pageOf, l10n, runner)],
];

KMenuRow _row(
  MenuItemSpec item,
  KMenuPage? Function(String? key) pageOf,
  AppLocalizations l10n,
  MenuActionRunner runner,
) {
  final action = item.action;
  final trailing = item.trailing;
  final cover = item.cover;
  return KMenuRow(
    title: item.title,
    subtitle: item.subtitle,
    icon: item.icon,
    leading: cover == null
        ? null
        : AlbumCover(
            itemKey: cover.itemKey,
            coverKey: cover.coverKey,
            dimension: 40,
            radius: BorderRadius.circular(8),
          ),
    onTap: action == null ? null : () => runner.run(action),
    opens: pageOf(item.page),
    chips: [
      for (final chip in item.chips)
        KMenuChip(label: chip.label, onTap: () => runner.run(chip.action)),
    ],
    chipsExpanded: item.chipsOpen,
    trailing: trailing == null
        ? null
        : KMenuTrailing(
            icon: trailing.icon,
            tooltip: trailing.tooltip,
            onPressed: () => runner.run(trailing.action),
          ),
    enabled: item.enabled,
    soonLabel: item.soon ? l10n.appComingSoon : null,
    danger: item.danger,
    proLabel: item.pro ? l10n.proBadge : null,
  );
}
