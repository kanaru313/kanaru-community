import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../browse/library_labels.dart';
import 'menu_items.dart';
import 'menu_model.dart';

/// The menu of the selection panel's ⋮: [ids] in selection order.
class SelectionMenuData {
  const SelectionMenuData({
    required this.ids,
    required this.durationMs,
    required this.allFavorite,
  });

  final List<TrackId> ids;
  final int durationMs;

  /// Every selected track is a favourite: the row removes them.
  final bool allFavorite;
}

/// Menu of the selected songs. Play all, edit and add-to-playlist are on the
/// panel itself.
MenuSpec buildSelectionMenu(SelectionMenuData data, MenuEnv env) {
  final l10n = env.l10n;
  final count = data.ids.length;
  final advanced = [removeRows(env, count)];
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.tile,
      title: l10n.libraryMenuSelectionTitle(count),
      subtitle: formatTotalDuration(l10n, data.durationMs),
      seed: 'selection',
      tileIcon: KIcons.multiSelect,
    ),
    groups: withAdvanced(
      [
        [
          MenuItemSpec(
            MenuItemId.shuffle,
            icon: KIcons.shuffle,
            title: l10n.libraryShuffle,
            action: MenuAction.play(
              data.ids,
              shuffle: true,
              context: PlayContext(
                PlayContextKind.selection,
                label: l10n.librarySongCount(count),
              ),
            ),
            enabled: count > 0,
          ),
          MenuItemSpec(
            MenuItemId.favorite,
            icon: data.allFavorite ? KIcons.heartFilled : KIcons.heart,
            title: data.allFavorite
                ? l10n.libraryFavoriteRemove
                : l10n.libraryFavoriteAdd,
            action: MenuAction.favorite(data.ids, on: !data.allFavorite),
            enabled: count > 0,
          ),
          proRow(l10n, l10n.libraryMenuAskAiSongs),
        ],
      ],
      advanced,
      l10n.libraryMenuAdvanced,
    ),
    advanced: advanced,
    queueIds: data.ids,
  );
}
