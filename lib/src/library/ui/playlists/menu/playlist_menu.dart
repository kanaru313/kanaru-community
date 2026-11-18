import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../menus/menu_loaders.dart' show ItemGoneException;
import '../../menus/menu_model.dart';
import '../../menus/open_menu.dart';
import 'favorites_menu_spec.dart';
import 'playlist_menu_spec.dart';

/// Opens the menu of playlist [uid] (Favorites included).
///
/// Everything is read inside the menu's builder, under its single-load guard
/// and time limit. On the playlist's own page ([onOwnPage]) it first waits for
/// the page's queued writes, so the counts and the rows it offers match what
/// the page shows. A playlist that no longer exists shows "no longer in your
/// library" and no menu.
///
/// [pageRoute]: the route of the playlist's own page (`ModalRoute.of` of the
/// page), passed to "Delete playlist" so the page leaves before the playlist
/// goes. Only used with [onOwnPage].
Future<void> openPlaylistMenu(
  BuildContext context,
  String uid, {
  required bool onOwnPage,
  ModalRoute<Object?>? pageRoute,
  bool viaKeyboard = false,
}) {
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  return openMenu(context, (container, env) async {
    if (onOwnPage) {
      await container.read(playlistPageProvider(uid).notifier).afterWrites();
    }
    final detail = await container
        .read(playlistStoreProvider)
        .loadPlaylist(uid);
    if (detail == null) throw ItemGoneException('playlist $uid');
    return _buildSpec(
      detail,
      env,
      onOwnPage: onOwnPage,
      desktop: desktop,
      pageRoute: pageRoute,
    );
  }, viaKeyboard: viaKeyboard);
}

MenuSpec _buildSpec(
  PlaylistDetail detail,
  MenuEnv env, {
  required bool onOwnPage,
  required bool desktop,
  required ModalRoute<Object?>? pageRoute,
}) => detail.summary.isFavorites
    ? buildFavoritesMenu(
        detail,
        env,
        onOwnPage: onOwnPage,
        desktop: desktop,
        today: DateTime.now(),
      )
    : buildPlaylistMenu(
        detail,
        env,
        onOwnPage: onOwnPage,
        desktop: desktop,
        pageRoute: pageRoute,
      );
