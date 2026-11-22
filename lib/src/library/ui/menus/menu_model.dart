import 'package:flutter/widgets.dart' show IconData;

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/menu_targets.dart';
import 'menu_actions.dart';
import 'menu_origin.dart';

export 'menu_actions.dart';

/// Key of the "Nâng cao" sub-page in [MenuSpec.pages].
const String advancedPageKey = 'advanced';

/// Key of the song info sub-page in [MenuSpec.pages].
const String infoPageKey = 'info';

/// Stable name of a menu row, so tests and callers do not match on text.
enum MenuItemId {
  goAlbum,
  goArtist,
  goAlbumArtist,
  goGenre,
  goLanguage,
  goFolder,
  reveal,
  play,
  shuffle,
  playDirect,
  playlist,
  favorite,
  edit,
  select,
  ai,
  advanced,
  lyrics,
  hide,
  delete,
  split,
  languageSettings,
  copyPath,
  exclude,
  link,
  info,
  playlistMoveUp,
  playlistMoveDown,
  playlistRemove,
  playlistEdit,
  playlistDelete,
  playlistDuplicate,
  playlistRemoveDuplicates,
  playlistRemoveMissing,
  playlistFavoriteAll,
  playlistSaveAs,
  playlistClearFavorites,
  playlistExportM3u,
  playlistExportM3uRelative,
  playlistAskAi,
  queueAppend,
}

/// A chip under a row: one of several targets.
class MenuChipSpec {
  const MenuChipSpec(this.label, this.action);
  final String label;
  final MenuAction action;
}

/// The icon button at the end of a row.
class MenuTrailingSpec {
  const MenuTrailingSpec({
    required this.icon,
    required this.tooltip,
    required this.action,
  });
  final IconData icon;
  final String tooltip;
  final MenuAction action;
}

/// The cover of an album, shown in place of a row's icon.
class MenuCover {
  const MenuCover(this.itemKey, this.coverKey);

  /// Encoded `AlbumKey` (where a custom cover is stored).
  final String itemKey;
  final String? coverKey;

  @override
  bool operator ==(Object other) =>
      other is MenuCover &&
      other.itemKey == itemKey &&
      other.coverKey == coverKey;

  @override
  int get hashCode => Object.hash(itemKey, coverKey);
}

/// One row of a menu page.
///
/// At most one of [action], [page] and [chips] drives it. [soon] dims the row
/// with the "coming soon" label; `enabled: false` dims it without one (a
/// "no album" row). [pro] marks the Pro surface.
class MenuItemSpec {
  const MenuItemSpec(
    this.id, {
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.page,
    this.chips = const [],
    this.chipsOpen = false,
    this.trailing,
    this.enabled = true,
    this.soon = false,
    this.danger = false,
    this.pro = false,
    this.cover,
    this.hint,
  });

  final MenuItemId id;
  final IconData icon;
  final String title;
  final String? subtitle;
  final MenuAction? action;

  /// Key of the sub-page in [MenuSpec.pages] this row opens.
  final String? page;
  final List<MenuChipSpec> chips;
  final bool chipsOpen;
  final MenuTrailingSpec? trailing;
  final bool enabled;
  final bool soon;
  final bool danger;
  final bool pro;

  /// Album cover drawn in place of [icon].
  final MenuCover? cover;

  /// Explanation of the row (ui-hints): the row's accessible description,
  /// never shown as the subtitle.
  final String? hint;

  /// Whether the row does anything when chosen.
  bool get active => enabled && !soon;
}

/// A sub-page of a menu: a title, an optional note, groups of rows (a group
/// may carry a heading).
class MenuPageSpec {
  const MenuPageSpec({
    required this.title,
    required this.groups,
    this.note,
    this.groupTitles = const [],
  });

  final String title;
  final String? note;
  final List<List<MenuItemSpec>> groups;

  /// Heading of each group by index; missing or null = none.
  final List<String?> groupTitles;
}

/// The picture at the top of a menu.
enum MenuImage { track, album, artist, tile, folder, playlist }

class MenuHeader {
  const MenuHeader({
    required this.image,
    required this.title,
    this.subtitle,
    this.itemKey = '',
    this.coverKey,
    this.seed = '',
    this.tileIcon,
    this.infoPage,
    this.autoCoverKeys = const [],
    this.note,
    this.action,
  });

  final MenuImage image;
  final String title;
  final String? subtitle;

  /// Encoded key of the album or artist (where its custom cover is stored).
  final String itemKey;
  final String? coverKey;

  /// Seeds the placeholder colours.
  final String seed;

  /// Icon of a [MenuImage.tile].
  final IconData? tileIcon;

  /// Key of the page the header opens (`›`), the song info of a song.
  final String? infoPage;

  /// Cover keys of the first tracks of a playlist ([MenuImage.playlist]):
  /// the automatic cover when it has no custom one.
  final List<String> autoCoverKeys;

  /// Third line under the subtitle, one line with an ellipsis (a playlist's
  /// description); null = none.
  final String? note;

  /// Icon button at the header's end, centred on the image; null = none.
  final MenuTrailingSpec? action;
}

/// A whole menu, built before it is shown.
class MenuSpec {
  const MenuSpec({
    required this.header,
    required this.groups,
    this.advanced = const [],
    this.pages = const {},
    this.queueIds = const [],
    this.origin,
  });

  final MenuHeader header;
  final List<List<MenuItemSpec>> groups;

  /// Groups of the "Nâng cao" sub-page; the builder adds the row that opens
  /// it to [groups] when this is not empty.
  final List<List<MenuItemSpec>> advanced;
  final Map<String, MenuPageSpec> pages;

  /// The tracks "Play next" and "Add to queue" take, captured when the menu
  /// was built (the list may change before a button is pressed). Empty = the
  /// two buttons are left out.
  final List<TrackId> queueIds;

  /// The page the menu was opened from, kept for rows that depend on it
  /// (a song's "Add to playlist" leaves out the playlist it is listed in).
  final MenuOrigin? origin;

  /// A copy with [groups] replaced; every other field is kept.
  MenuSpec copyWith({List<List<MenuItemSpec>>? groups}) => MenuSpec(
    header: header,
    groups: groups ?? this.groups,
    advanced: advanced,
    pages: pages,
    queueIds: queueIds,
    origin: origin,
  );
}

/// What a builder needs besides its data.
class MenuEnv {
  const MenuEnv({
    required this.l10n,
    required this.canReveal,
    required this.pathOf,
    this.trash = false,
  });

  final AppLocalizations l10n;

  /// The file manager can show a file (Linux); false dims the rows.
  final bool canReveal;

  /// Absolute path of a folder of the library; null when unknown.
  final String? Function(FolderRef folder) pathOf;

  /// Desktop: deleting moves the files to the Trash.
  final bool trash;
}
