import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_info.dart';
import '../menus/menu_action_runner.dart';
import '../menus/menu_model.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'song_info_actions.dart';
import 'song_info_hero.dart';
import 'song_info_view.dart';

/// What the info route hands back when it closes: nothing (Back, Esc, ✕) or
/// a library page to open (a link, "go to folder").
sealed class SongInfoResult {
  const SongInfoResult();

  const factory SongInfoResult.open(String location) = SongInfoOpen;
}

class SongInfoOpen extends SongInfoResult {
  const SongInfoOpen(this.location);

  final String location;
}

/// The info route last opened. While it is active a second swipe or tap
/// opens nothing; a route whose navigator is gone is not active, so this
/// cannot stay stuck.
Route<dynamic>? _openRoute;

/// Opens the info of [info] straight (a swipe, Alt+Enter): no menu below, so
/// its header has ⋮, which opens the song menu over it with the page's own
/// rows ([playlistGroup], [favoriteRow]) and [origin]. Back returns to where
/// the user was.
Future<void> openSongInfo(
  BuildContext context,
  TrackInfo info, {
  MenuOrigin origin = const MenuOrigin.list(),
  List<MenuItemSpec> playlistGroup = const [],
  bool favoriteRow = true,
  bool viaKeyboard = false,
}) => showSongInfo(
  context,
  info,
  origin: origin,
  playlistGroup: playlistGroup,
  favoriteRow: favoriteRow,
  viaKeyboard: viaKeyboard,
);

/// Shows the info route of [info] on the root navigator. With [menuBelow] the
/// song menu is the route right under it (the `›` of its header): the header
/// has no ⋮, closing returns to the menu, and a link closes the menu too.
/// [beforeNavigate] (the menu's own) runs before a link opens its page, so
/// whatever sits over the app (Now Playing, the queue sheet) closes first.
Future<void> showSongInfo(
  BuildContext context,
  TrackInfo info, {
  MenuOrigin origin = const MenuOrigin.list(),
  List<MenuItemSpec> playlistGroup = const [],
  bool favoriteRow = true,
  bool menuBelow = false,
  bool viaKeyboard = false,
  VoidCallback? beforeNavigate,
}) async {
  if (_openRoute?.isActive ?? false) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  final root = navigator.context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  Route<SongInfoResult>? infoRoute;
  void closeInfo() {
    final route = infoRoute;
    if (route != null && route.isActive) navigator.removeRoute(route);
  }

  // A link or "go to folder": the menu under the info (if any) goes first,
  // then the info closes with the location.
  void openLocation(String location) {
    final route = infoRoute;
    if (route == null || !route.isActive) return;
    if (menuBelow) navigator.removeRouteBelow(route);
    navigator.pop(SongInfoResult.open(location));
  }

  final closed = showKOverlayPage<SongInfoResult>(
    root,
    title: l10n.libraryMenuSongInfo,
    viaKeyboard: viaKeyboard,
    closeTooltip: l10n.libraryInfoClose,
    backTooltip: l10n.libraryMenuBack,
    onRoute: (route) => infoRoute = _openRoute = route,
    builder: (_) => SongInfoView(info: info, onOpen: openLocation),
    boxHeader: (_) => SongInfoBoxHeader(info: info),
    actions: [
      SongInfoEyeButton(id: info.id),
      if (!menuBelow)
        SongInfoMoreButton(
          onPressed: () => unawaited(
            openSongMenu(
              root,
              info,
              origin: origin,
              playlistGroup: playlistGroup,
              favoriteRow: favoriteRow,
              headerCloses: true,
              beforeNavigate: closeInfo,
            ),
          ),
        ),
    ],
  );
  final result = await closed;
  if (result is! SongInfoOpen || !root.mounted) return;
  await MenuActionRunner(
    container,
    root,
    beforeNavigate: beforeNavigate,
  ).run(MenuAction.go(result.location));
}
