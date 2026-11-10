import 'package:flutter/widgets.dart' show IconData;
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import 'menu_model.dart';

/// A row that is not built yet: dimmed, labelled "coming soon", inert.
MenuItemSpec soonRow(
  MenuItemId id,
  IconData icon,
  String title, {
  String? subtitle,
  bool danger = false,
}) => MenuItemSpec(
  id,
  icon: icon,
  title: title,
  subtitle: subtitle,
  soon: true,
  danger: danger,
);

/// "Ask AI ...": a Pro surface, dimmed with the Pro badge until the Pro
/// intro exists.
MenuItemSpec proRow(AppLocalizations l10n, String title) => MenuItemSpec(
  MenuItemId.ai,
  icon: KIcons.ai,
  title: title,
  soon: true,
  pro: true,
);

/// Adds the "Advanced" row (a group of its own, last) to [groups] when the
/// sub-page has anything in it.
List<List<MenuItemSpec>> withAdvanced(
  List<List<MenuItemSpec>> groups,
  List<List<MenuItemSpec>> advanced,
  String title,
) => [
  for (final g in groups)
    if (g.isNotEmpty) g,
  if (advanced.any((g) => g.isNotEmpty))
    [
      MenuItemSpec(
        MenuItemId.advanced,
        icon: KIcons.advanced,
        title: title,
        page: advancedPageKey,
      ),
    ],
];

/// "Play" and "Shuffle" of a set of tracks; none on the item's own page,
/// where the page has the buttons.
List<MenuItemSpec> playRows(
  AppLocalizations l10n,
  List<TrackId> ids,
  PlayContext context, {
  required bool own,
  String? playSubtitle,
}) => [
  if (!own) ...[
    MenuItemSpec(
      MenuItemId.play,
      icon: KIcons.play,
      title: l10n.libraryPlay,
      subtitle: playSubtitle,
      action: MenuAction.play(ids, shuffle: false, context: context),
      enabled: ids.isNotEmpty,
    ),
    MenuItemSpec(
      MenuItemId.shuffle,
      icon: KIcons.shuffle,
      title: l10n.libraryShuffle,
      action: MenuAction.play(ids, shuffle: true, context: context),
      enabled: ids.isNotEmpty,
    ),
  ],
];

/// "Add all to favourites" of an album, artist, genre or language.
MenuItemSpec favoriteAllRow(AppLocalizations l10n, List<TrackId> ids) =>
    MenuItemSpec(
      MenuItemId.favorite,
      icon: KIcons.heart,
      title: l10n.libraryMenuFavoriteAll,
      action: MenuAction.favorite(ids, on: true),
      enabled: ids.isNotEmpty,
    );

/// The two "Advanced" rows that are not built yet: remove from the library,
/// delete the files ([count] of them; the Trash on desktop).
List<MenuItemSpec> removeRows(MenuEnv env, int count) {
  final l10n = env.l10n;
  return [
    soonRow(
      MenuItemId.hide,
      KIcons.hideFromLibrary,
      l10n.libraryMenuHide,
      subtitle: l10n.libraryMenuHideNote,
    ),
    soonRow(
      MenuItemId.delete,
      KIcons.delete,
      env.trash ? l10n.libraryMenuMoveToTrash : l10n.libraryMenuDeleteFiles,
      subtitle: l10n.libraryMenuFileCount(count),
      danger: true,
    ),
  ];
}
