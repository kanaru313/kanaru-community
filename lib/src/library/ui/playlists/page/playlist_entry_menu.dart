import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_lines.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../menus/menu_model.dart';
import '../../menus/open_menu.dart';

/// The group a song's menu gets inside a playlist (normal mode): Move up /
/// Move down (only when the rows are in playlist order with no filter,
/// [canStep]; each disabled at its end) and the removal. In Favorites the
/// removal is "Remove from Favorites" and the page drops the heart row.
///
/// [onStep] and [onRemove] run when the row is chosen and look the entry up
/// again by its uid, so a menu opened before another change acts on the right
/// row, or on nothing when it is gone.
List<MenuItemSpec> playlistEntryMenuGroup(
  AppLocalizations l10n, {
  required bool isFavorites,
  required bool canStep,
  required bool isFirst,
  required bool isLast,
  required void Function(int delta) onStep,
  required Future<void> Function(BuildContext context) onRemove,
}) => [
  if (canStep) ...[
    MenuItemSpec(
      MenuItemId.playlistMoveUp,
      icon: KIcons.arrowUp,
      title: l10n.playlistMenuMoveUp,
      enabled: !isFirst,
      action: MenuAction.run((_) async => onStep(-1)),
    ),
    MenuItemSpec(
      MenuItemId.playlistMoveDown,
      icon: KIcons.arrowDown,
      title: l10n.playlistMenuMoveDown,
      enabled: !isLast,
      action: MenuAction.run((_) async => onStep(1)),
    ),
  ],
  MenuItemSpec(
    MenuItemId.playlistRemove,
    icon: isFavorites ? KIcons.heartOff : KIcons.playlistRemove,
    title: isFavorites
        ? l10n.playlistMenuRemoveFavorite
        : l10n.playlistMenuRemoveEntry,
    action: MenuAction.run(onRemove),
  ),
];

/// The menu of a missing row: its head (title, artist, "Not in library") and
/// the removal, nothing else (there is no song to act on).
Future<void> openMissingEntryMenu(
  BuildContext context, {
  required PlaylistEntryView entry,
  required bool isFavorites,
  required Future<void> Function(BuildContext context) onRemove,
  bool viaKeyboard = false,
}) => openMenu(context, (container, env) async {
  final l10n = env.l10n;
  final info = entry.info;
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.track,
      title: info.title,
      subtitle: [
        trackArtistLine(info),
        l10n.playlistNotInLibrary,
      ].where((s) => s.isNotEmpty).join(' · '),
      seed: info.coverSeed,
    ),
    groups: [
      playlistEntryMenuGroup(
        l10n,
        isFavorites: isFavorites,
        canStep: false,
        isFirst: true,
        isLast: true,
        onStep: (_) {},
        onRemove: onRemove,
      ),
    ],
  );
}, viaKeyboard: viaKeyboard);
