import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../menus/more_button.dart';
import '../../playlist_common/playlist_cover.dart';
import '../menu/playlist_menu_rows.dart';
import 'playlist_card.dart';
import 'playlist_play.dart';

/// Playlist row: cover, name, counts, description (desktop: the edit date
/// when there is none). ▶ plays the playlist in its saved order and is off
/// for an empty one; ⋮ and long press open the menu.
class PlaylistTile extends ConsumerWidget {
  const PlaylistTile({super.key, required this.playlist});

  final PlaylistSummary playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final line3 = playlist.description.isNotEmpty
        ? playlist.description
        : desktop
        ? l10n.playlistEditedOn(
            playlistMenuDate(
              l10n,
              DateTime.fromMillisecondsSinceEpoch(playlist.updatedAt),
            ),
          )
        : null;
    return KContextRegion(
      onOpen: (at) =>
          openPlaylistListMenu(context, playlist, viaKeyboard: at == null),
      child: KMediaCard(
        title: playlist.name,
        line2: playlistStatsLine(l10n, playlist),
        line3: line3,
        leading: PlaylistCover(
          uid: playlist.uid,
          autoCoverKeys: playlist.autoCoverKeys,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
        onAction: () => playPlaylist(ref, context, playlist),
        actionEnabled: playlist.trackCount > 0,
        actionLabel: l10n.plScreensPlay,
        trailing: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              openPlaylistListMenu(context, playlist, viaKeyboard: viaKeyboard),
        ),
        onTap: () => openPlaylistPage(context, playlist),
      ),
    );
  }
}
