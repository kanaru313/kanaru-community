import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/music_folder.dart';
import '../folders/folder_locations.dart';
import 'link_rows.dart';
import 'menu_items.dart';
import 'menu_model.dart';
import 'menu_origin.dart';

/// Everything the menu of one folder shows. [key] is the folder's relative
/// path inside [folder] (`''` = the music folder itself).
class FolderMenuData {
  const FolderMenuData({
    required this.folder,
    required this.key,
    required this.name,
    required this.ids,
    required this.directIds,
    required this.subfolders,
    this.flat = false,
  });

  final MusicFolder folder;
  final String key;
  final String name;

  /// What Play takes: the folder with its subfolders (tree view), or only
  /// its own songs ([flat], the flat list).
  final List<TrackId> ids;

  /// The songs that sit directly in the folder.
  final List<TrackId> directIds;
  final int subfolders;

  /// The flat view: every operation counts the folder's own songs only.
  final bool flat;

  /// Absolute path of the folder.
  String get path {
    final root = folder.root.endsWith('/')
        ? folder.root.substring(0, folder.root.length - 1)
        : folder.root;
    return key.isEmpty ? root : '$root/$key';
  }

  bool get isRoot => key.isEmpty;
}

/// Menu of a folder. On the folder's own page ([OwnOrigin]) "Show in file
/// manager" replaces "Go to folder" and Play / Shuffle are left out.
MenuSpec buildFolderMenu(FolderMenuData data, MenuOrigin origin, MenuEnv env) {
  final l10n = env.l10n;
  final own = origin is OwnOrigin;
  final withSub = !data.flat && data.subfolders > 0;
  final context = PlayContext(
    PlayContextKind.folder,
    ref: '${data.folder.sourceUid}:${data.key}',
    label: data.name,
  );
  final advanced = [
    [
      MenuItemSpec(
        MenuItemId.copyPath,
        icon: KIcons.copy,
        title: l10n.libraryMenuCopyPath,
        subtitle: data.path,
        action: MenuAction.copy(data.path),
      ),
    ],
    [
      if (!data.isRoot)
        MenuItemSpec(
          MenuItemId.exclude,
          icon: KIcons.folderOff,
          title: l10n.libraryMenuExclude,
          subtitle: l10n.libraryMenuExcludeNote,
          action: MenuAction.exclude(
            data.folder,
            data.key,
            displayPath: '${data.folder.name}/${data.key}',
          ),
        ),
    ],
  ];
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.folder,
      title: data.name,
      subtitle: data.flat
          ? l10n.librarySongCount(data.directIds.length)
          : l10n.libraryFolderCounts(data.ids.length, data.subfolders),
      seed: data.key,
    ),
    groups: withAdvanced(
      [
        [
          if (own)
            revealRow(env, data.path)
          else
            MenuItemSpec(
              MenuItemId.goFolder,
              icon: KIcons.folders,
              title: l10n.libraryMenuGoFolder,
              subtitle: data.path,
              action: MenuAction.go(
                FolderLocation(
                  sourceUid: data.folder.sourceUid,
                  key: data.key,
                  flat: data.flat,
                ).path,
              ),
              trailing: env.canReveal
                  ? MenuTrailingSpec(
                      icon: KIcons.openInNew,
                      tooltip: l10n.libraryMenuReveal,
                      action: MenuAction.reveal(data.path),
                    )
                  : null,
            ),
        ],
        [
          ...playRows(
            l10n,
            data.ids,
            context,
            own: own,
            playSubtitle: withSub ? l10n.libraryMenuIncludesSubfolders : null,
          ),
          if (withSub && data.directIds.isNotEmpty)
            MenuItemSpec(
              MenuItemId.playDirect,
              icon: KIcons.playlistPlay,
              title: l10n.libraryMenuPlayDirect,
              subtitle: l10n.libraryMenuPlayDirectNote(data.directIds.length),
              action: MenuAction.play(
                data.directIds,
                shuffle: false,
                context: context,
              ),
            ),
          soonRow(
            MenuItemId.playlist,
            KIcons.playlistAdd,
            l10n.libraryMenuAddToPlaylist,
          ),
        ],
      ],
      advanced,
      l10n.libraryMenuAdvanced,
    ),
    advanced: advanced,
    queueIds: data.ids,
  );
}
