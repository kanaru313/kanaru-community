import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/music_folder.dart';
import '../info/open_song_info.dart' show showSongInfo;
import 'menu_loaders.dart';
import 'menu_model.dart';
import 'menu_origin.dart';
import 'menu_presenter.dart';
import 'song_menu.dart' show SongMenuAroundLyrics, withSongPageRows;

/// Opens a menu built by [build] (data loading and spec building, off the
/// widget tree). Throwing `ItemGoneException` shows the "not found" toast and
/// no menu; any other failure shows the load-failed toast.
Future<void> openMenu(
  BuildContext context,
  Future<MenuSpec> Function(ProviderContainer container, MenuEnv env) build, {
  bool viaKeyboard = false,
}) => presentMenu(context, build, viaKeyboard: viaKeyboard);

/// Opens the menu of a song. [origin] is the page the song is listed on.
/// [playlistGroup] is a group of rows of the page's own (in a playlist: move,
/// remove) placed after the "Go to" group; [favoriteRow] false leaves out the
/// heart row. The header's `›` (and Alt+Enter) opens the song info over the
/// menu; the heart row follows the favorite mark while the menu is open.
///
/// For a caller that knows more than the library (the Now Playing screen):
/// [aroundLyrics] puts its rows before / after the lyrics row, [selectRow] and
/// [queueButtons] false leave out "Select" and the "Play next" / "Add to queue"
/// footer, [openLyrics] replaces what the lyrics row opens (for example "Lyrics
/// for this song" that follows the playing track). The returned future also
/// waits for a `MenuAction.run` chosen in the menu to finish, so a caller can
/// keep something pinned while its dialog is open.
///
/// A menu opened over the song info ([headerCloses]) has a `›` that only
/// closes the menu (the info is right under it), and [beforeNavigate] runs
/// before a "Go to" row opens its page so the info can close first.
Future<void> openSongMenu(
  BuildContext context,
  TrackInfo info, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
  List<MenuItemSpec> playlistGroup = const [],
  bool favoriteRow = true,
  bool headerCloses = false,
  VoidCallback? beforeNavigate,
  SongMenuAroundLyrics? aroundLyrics,
  bool selectRow = true,
  bool queueButtons = true,
  Future<void> Function(BuildContext context)? openLyrics,
}) => presentMenu(
  context,
  (container, env) async => withSongPageRows(
    await songMenuSpec(container, env, info, origin, openLyrics: openLyrics),
    playlistGroup: playlistGroup,
    favoriteRow: favoriteRow,
    aroundLyrics: aroundLyrics,
    selectRow: selectRow,
    queueButtons: queueButtons,
  ),
  viaKeyboard: viaKeyboard,
  beforeNavigate: beforeNavigate,
  favoriteOf: favoriteRow ? info.id : null,
  onHeaderTap: (root, viaKeyboard) {
    if (headerCloses) {
      Navigator.of(root, rootNavigator: true).pop();
    } else {
      unawaited(
        showSongInfo(
          root,
          info,
          origin: origin,
          playlistGroup: playlistGroup,
          favoriteRow: favoriteRow,
          menuBelow: true,
          viaKeyboard: viaKeyboard,
          beforeNavigate: beforeNavigate,
        ),
      );
    }
  },
);

/// Opens the menu of an album. On its own page pass [MenuOrigin.own].
Future<void> openAlbumMenu(
  BuildContext context,
  AlbumKey key, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => presentMenu(
  context,
  (container, env) => albumMenuSpec(container, env, key, origin),
  viaKeyboard: viaKeyboard,
);

Future<void> openArtistMenu(
  BuildContext context,
  ArtistKey key, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => presentMenu(
  context,
  (container, env) => artistMenuSpec(container, env, key, origin),
  viaKeyboard: viaKeyboard,
);

/// [genreKey] is the stored `genre_key`, [name] the genre as written.
Future<void> openGenreMenu(
  BuildContext context, {
  required String genreKey,
  required String name,
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => presentMenu(
  context,
  (container, env) => genreMenuSpec(container, env, genreKey, name, origin),
  viaKeyboard: viaKeyboard,
);

/// A null [code] is the group of songs without a language.
Future<void> openLanguageMenu(
  BuildContext context,
  String? code, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => presentMenu(
  context,
  (container, env) => languageMenuSpec(container, env, code, origin),
  viaKeyboard: viaKeyboard,
);

/// [key] is the folder's path inside [folder] (`''` = the music folder);
/// [subfolders] how many folders it holds; [flat] the flat list's folder.
Future<void> openFolderMenu(
  BuildContext context, {
  required MusicFolder folder,
  required String key,
  required String name,
  required int subfolders,
  bool flat = false,
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => presentMenu(
  context,
  (container, env) => folderMenuSpec(
    container,
    env,
    folder: folder,
    key: key,
    name: name,
    subfolders: subfolders,
    flat: flat,
    origin: origin,
  ),
  viaKeyboard: viaKeyboard,
);

/// Opens the menu of the selection panel.
Future<void> openSelectionMenu(
  BuildContext context, {
  bool viaKeyboard = false,
}) => presentMenu(context, selectionMenuSpec, viaKeyboard: viaKeyboard);
