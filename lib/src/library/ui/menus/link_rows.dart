import 'package:flutter/widgets.dart' show IconData;
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../domain/browse/menu_targets.dart';
import '../folders/folder_locations.dart';
import 'menu_model.dart';

/// From this many targets a link row opens a sub-page instead of unfolding
/// its chips.
const int linkPageFrom = 4;

/// One place a "Go to" row can lead to.
class LinkTarget {
  const LinkTarget(this.label, this.location, {this.subtitle, this.cover});

  final String label;

  /// Library location opened by a push.
  final String location;

  /// Second line on the sub-page.
  final String? subtitle;

  /// Album cover for the page row.
  final MenuCover? cover;
}

/// A heading and its targets on a link sub-page.
class LinkSection {
  const LinkSection(this.targets, {this.title});

  final List<LinkTarget> targets;
  final String? title;
}

/// A "Go to ..." row and the sub-page it may open.
class LinkRow {
  const LinkRow(this.item, [this.page]);

  final MenuItemSpec item;

  /// Set when [item] opens it (under [MenuItemSpec.page]).
  final MenuPageSpec? page;
}

/// One "Go to ..." row for a list of targets, by how many there are:
/// none -> a dimmed row saying [noneText]; one -> a plain row with its name;
/// several -> a count line with the names as chips, open while fewer than
/// [linkPageFrom]; [linkPageFrom] or more -> a sub-page, unless [chipsOnly]
/// (a song's artists are always chips, folded from [linkPageFrom]).
///
/// [sections] lets the sub-page group the targets under headings; the row's
/// chips are the targets of every section in order.
LinkRow linkRow({
  required MenuItemId id,
  required IconData icon,
  IconData? manyIcon,
  required String title,
  required List<LinkTarget> targets,
  required String manyText,
  required String noneText,
  required String pageKey,
  String? pageTitle,
  IconData? targetIcon,
  List<LinkSection>? sections,
  bool chipsOnly = false,
}) {
  final count = targets.length;
  if (count == 0) {
    return LinkRow(
      MenuItemSpec(
        id,
        icon: icon,
        title: title,
        subtitle: noneText,
        enabled: false,
      ),
    );
  }
  if (count == 1) {
    final only = targets.single;
    return LinkRow(
      MenuItemSpec(
        id,
        icon: icon,
        title: title,
        subtitle: only.label,
        action: MenuAction.go(only.location),
      ),
    );
  }
  if (!chipsOnly && count >= linkPageFrom) {
    return LinkRow(
      MenuItemSpec(
        id,
        icon: manyIcon ?? icon,
        title: title,
        subtitle: manyText,
        page: pageKey,
      ),
      MenuPageSpec(
        title: pageTitle ?? title,
        groups: [
          for (final s in sections ?? [LinkSection(targets)])
            [
              for (final t in s.targets)
                MenuItemSpec(
                  MenuItemId.link,
                  icon: targetIcon ?? icon,
                  title: t.label,
                  subtitle: t.subtitle,
                  action: MenuAction.go(t.location),
                  cover: t.cover,
                ),
            ],
        ],
        groupTitles: [
          for (final s in sections ?? [LinkSection(targets)]) s.title,
        ],
      ),
    );
  }
  return LinkRow(
    MenuItemSpec(
      id,
      icon: manyIcon ?? icon,
      title: title,
      subtitle: manyText,
      chips: [
        for (final t in targets)
          MenuChipSpec(t.label, MenuAction.go(t.location)),
      ],
      chipsOpen: count < linkPageFrom,
    ),
  );
}

/// The folder a [FolderRef] opens in the Folders tab.
String folderLocation(FolderRef folder) =>
    FolderLocation(sourceUid: folder.sourceUid, key: folder.folderKey).path;

/// `Music › Lossless`: the path of a folder as one line, the music folder's
/// own name for the root.
String folderLine(FolderRef folder) => folder.folderKey.isEmpty
    ? folder.name
    : folder.folderKey.replaceAll('/', ' › ');

/// "Show in file manager" as a row of its own. Dimmed with "coming soon"
/// where the platform has no file manager integration, inert without a path.
MenuItemSpec revealRow(MenuEnv env, String? path) => MenuItemSpec(
  MenuItemId.reveal,
  icon: KIcons.folderOpen,
  title: env.l10n.libraryMenuReveal,
  action: path == null ? null : MenuAction.reveal(path),
  enabled: path != null,
  soon: !env.canReveal,
);

/// The "Go to folder" row of the folders that hold a menu's songs, and its
/// sub-page. None -> no row (null); one -> its name and a button that shows
/// it in the file manager; several -> `N songs in M folders` opening a page
/// whose rows go to the folder level. [intro] is the note of that page.
LinkRow? folderLinks(
  MenuEnv env,
  List<FolderRef> folders, {
  required String intro,
  required String pageTitle,
  String pageKey = 'folders',
}) {
  final l10n = env.l10n;
  if (folders.isEmpty) return null;
  if (folders.length == 1) {
    final only = folders.single;
    final path = env.pathOf(only);
    return LinkRow(
      MenuItemSpec(
        MenuItemId.goFolder,
        icon: KIcons.folders,
        title: l10n.libraryMenuGoFolder,
        subtitle: folderLine(only),
        action: MenuAction.go(folderLocation(only)),
        trailing: env.canReveal && path != null
            ? MenuTrailingSpec(
                icon: KIcons.openInNew,
                tooltip: l10n.libraryMenuReveal,
                action: MenuAction.reveal(path),
              )
            : null,
      ),
    );
  }
  final songs = folders.fold<int>(0, (sum, f) => sum + f.songCount);
  return LinkRow(
    MenuItemSpec(
      MenuItemId.goFolder,
      icon: KIcons.folders,
      title: l10n.libraryMenuGoFolder,
      subtitle: l10n.libraryMenuSongsInFolders(songs, folders.length),
      page: pageKey,
    ),
    MenuPageSpec(
      title: pageTitle,
      note: intro,
      groups: [
        [
          for (final f in folders)
            MenuItemSpec(
              MenuItemId.link,
              icon: KIcons.folders,
              title: f.name,
              subtitle: l10n.librarySongCount(f.songCount),
              action: MenuAction.go(folderLocation(f)),
            ),
        ],
      ],
    ),
  );
}
