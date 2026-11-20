import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_lines.dart';
import '../../domain/history/history_models.dart';
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'history_locations.dart';
import 'history_remove_toast.dart';

/// The group a play's song menu gets on the History page: the song's own
/// history, and removing this one play (the same merged Undo toast as the
/// Delete key).
List<MenuItemSpec> historyRowMenuItems(
  AppLocalizations l10n,
  HistoryPlay play,
) => [
  MenuItemSpec(
    // The id of the "go to" rows: no dedicated id exists for this one.
    MenuItemId.link,
    icon: KIcons.history,
    title: l10n.historyMenuTrackHistory,
    action: MenuAction.go(HistoryLocations.track(play.track.id.value)),
  ),
  MenuItemSpec(
    MenuItemId.delete,
    icon: KIcons.delete,
    title: l10n.historyMenuRemovePlay,
    danger: true,
    action: MenuAction.run((ctx) => removeHistoryPlay(ctx, play)),
  ),
];

/// The menu of a play whose file is gone: its head (title, artist, "can't
/// play") and the two history rows, nothing else (there is no song to act
/// on). Handed to `SongTile.onMenu`.
Future<void> Function({required bool viaKeyboard}) missingPlayMenu(
  BuildContext context,
  HistoryPlay play,
) =>
    ({required bool viaKeyboard}) => openMenu(context, (container, env) async {
      final info = play.track;
      return MenuSpec(
        header: MenuHeader(
          image: MenuImage.track,
          title: info.title,
          subtitle: [
            trackArtistLine(info),
            env.l10n.historyMenuMissing,
          ].where((s) => s.isNotEmpty).join(' · '),
          seed: info.coverSeed,
        ),
        groups: [historyRowMenuItems(env.l10n, play)],
      );
    }, viaKeyboard: viaKeyboard);
