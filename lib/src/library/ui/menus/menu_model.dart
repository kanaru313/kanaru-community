import 'package:flutter/widgets.dart' show IconData;

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/music_folder.dart';

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
}

/// What a row does once chosen. Executed by the action runner, never by the
/// builder, so a model is plain data.
sealed class MenuAction {
  const MenuAction();

  /// Opens a library page.
  const factory MenuAction.go(String location) = GoAction;

  /// Favourites or unfavourites [ids].
  const factory MenuAction.favorite(List<TrackId> ids, {required bool on}) =
      FavoriteAction;

  /// Excludes [folderKey] of [folder] from the library.
  const factory MenuAction.exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  }) = ExcludeAction;

  /// Puts [text] on the clipboard.
  const factory MenuAction.copy(String text) = CopyAction;

  /// Shows the file or folder at [path] in the file manager.
  const factory MenuAction.reveal(String path) = RevealAction;

  /// Adds [id] to the selection, or removes it.
  const factory MenuAction.select(TrackId id, {required bool on}) =
      SelectTrackAction;

  /// Replaces the queue with [ids].
  const factory MenuAction.play(
    List<TrackId> ids, {
    required bool shuffle,
    required PlayContext context,
  }) = PlayAction;
}

class GoAction extends MenuAction {
  const GoAction(this.location);
  final String location;

  @override
  bool operator ==(Object other) =>
      other is GoAction && other.location == location;

  @override
  int get hashCode => location.hashCode;
}

class FavoriteAction extends MenuAction {
  const FavoriteAction(this.ids, {required this.on});
  final List<TrackId> ids;
  final bool on;

  @override
  bool operator ==(Object other) =>
      other is FavoriteAction && other.on == on && _same(other.ids, ids);

  @override
  int get hashCode => Object.hash(on, Object.hashAll(ids));
}

class ExcludeAction extends MenuAction {
  const ExcludeAction(this.folder, this.folderKey, {required this.displayPath});
  final MusicFolder folder;
  final String folderKey;
  final String displayPath;

  @override
  bool operator ==(Object other) =>
      other is ExcludeAction &&
      other.folder == folder &&
      other.folderKey == folderKey &&
      other.displayPath == displayPath;

  @override
  int get hashCode => Object.hash(folder, folderKey, displayPath);
}

class CopyAction extends MenuAction {
  const CopyAction(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is CopyAction && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class RevealAction extends MenuAction {
  const RevealAction(this.path);
  final String path;

  @override
  bool operator ==(Object other) => other is RevealAction && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

class SelectTrackAction extends MenuAction {
  const SelectTrackAction(this.id, {required this.on});
  final TrackId id;
  final bool on;

  @override
  bool operator ==(Object other) =>
      other is SelectTrackAction && other.id == id && other.on == on;

  @override
  int get hashCode => Object.hash(id, on);
}

class PlayAction extends MenuAction {
  const PlayAction(this.ids, {required this.shuffle, required this.context});
  final List<TrackId> ids;
  final bool shuffle;
  final PlayContext context;

  @override
  bool operator ==(Object other) =>
      other is PlayAction &&
      other.shuffle == shuffle &&
      other.context == context &&
      _same(other.ids, ids);

  @override
  int get hashCode => Object.hash(shuffle, context, Object.hashAll(ids));
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
enum MenuImage { track, album, artist, tile, folder }

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
}

/// A whole menu, built before it is shown.
class MenuSpec {
  const MenuSpec({
    required this.header,
    required this.groups,
    this.advanced = const [],
    this.pages = const {},
    this.queueIds = const [],
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

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
