import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../browse/library_labels.dart';
import '../../browse/library_navigation.dart';
import '../../library_locations.dart';
import '../../playlist_common/playlist_cover.dart';
import '../menu/playlist_menu.dart';

/// `N songs • M min`, or "No songs" for an empty playlist.
String playlistStatsLine(AppLocalizations l10n, PlaylistSummary p) =>
    p.trackCount == 0
    ? l10n.playlistTrackCount(0)
    : l10n.libraryAlbumStats(p.trackCount, minutesOf(p.durationMs));

void openPlaylistPage(BuildContext context, PlaylistSummary p) =>
    openLibraryPage<void>(context, LibraryLocations.playlist(p.uid));

/// Opens the menu of [p] from the list (never "on its own page").
void openPlaylistListMenu(
  BuildContext context,
  PlaylistSummary p, {
  required bool viaKeyboard,
}) => openPlaylistMenu(
  context,
  p.uid,
  onOwnPage: false,
  viaKeyboard: viaKeyboard,
);

/// Playlist tile of the grid: cover, name, count. No ⋮ button: the menu opens
/// by long press, right click, the Menu key or Shift+F10 (from
/// `KContextRegion`) and, for screen readers, the card's custom action.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.playlist});

  final PlaylistSummary playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return KContextRegion(
      onOpen: (at) =>
          openPlaylistListMenu(context, playlist, viaKeyboard: at == null),
      child: KGridCard(
        title: playlist.name,
        subtitle: desktop
            ? playlistStatsLine(l10n, playlist)
            : l10n.playlistTrackCount(playlist.trackCount),
        onTap: () => openPlaylistPage(context, playlist),
        menuLabel: l10n.libraryMenuMore,
        onMenu: () =>
            openPlaylistListMenu(context, playlist, viaKeyboard: true),
        coverBuilder: (context, side) => PlaylistCover(
          uid: playlist.uid,
          autoCoverKeys: playlist.autoCoverKeys,
          dimension: side,
          radius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
