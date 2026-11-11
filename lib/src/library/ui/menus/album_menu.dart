import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/menu_targets.dart';
import '../browse/library_labels.dart';
import '../library_locations.dart';
import 'link_rows.dart';
import 'menu_items.dart';
import 'menu_model.dart';
import 'menu_origin.dart';

/// Everything the menu of one album shows, loaded before it opens.
class AlbumMenuData {
  const AlbumMenuData({
    required this.album,
    required this.key,
    required this.ids,
    required this.folders,
  });

  final AlbumSummary album;
  final AlbumKey key;

  /// The album's tracks in track order.
  final List<TrackId> ids;
  final List<FolderRef> folders;
}

/// Menu of an album. On the album's own page ([OwnOrigin]) there is no
/// "Go to album" and no Play / Shuffle (the page has the buttons).
MenuSpec buildAlbumMenu(AlbumMenuData data, MenuOrigin origin, MenuEnv env) {
  final l10n = env.l10n;
  final album = data.album;
  final own = origin is OwnOrigin;
  final pages = <String, MenuPageSpec>{};

  // An album has one album-artist key (`tracks.album_artist_key`), so the
  // artist row has no target or one. It stays on that artist's page too (old
  // app: "always show all artists").
  final artistName = album.artist;
  final artistKey = data.key.artistKey;
  final MenuItemSpec artistRow = artistKey.isEmpty
      ? MenuItemSpec(
          MenuItemId.goArtist,
          icon: KIcons.artists,
          title: l10n.libraryMenuGoArtist,
          subtitle: l10n.libraryMenuNoArtist,
          enabled: false,
        )
      : MenuItemSpec(
          MenuItemId.goArtist,
          icon: KIcons.artists,
          title: l10n.libraryMenuGoArtist,
          subtitle: artistName == null || artistName.isEmpty
              ? artistKey
              : artistName,
          action: MenuAction.go(LibraryLocations.artist(ArtistKey(artistKey))),
        );

  final folderLink = folderLinks(
    env,
    data.folders,
    intro: l10n.libraryMenuFoldersIntroAlbum(data.folders.length),
    pageTitle: l10n.libraryMenuFoldersOf(album.title),
  );
  if (folderLink?.page != null) pages['folders'] = folderLink!.page!;

  final context = PlayContext(
    PlayContextKind.album,
    ref: album.key,
    label: album.title,
  );
  final advanced = [removeRows(env, data.ids.length)];
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.album,
      title: album.title,
      subtitle: [
        if (artistName != null && artistName.isNotEmpty) artistName,
        if (album.year != null) '${album.year}',
        l10n.librarySongCount(album.trackCount),
        formatTotalDuration(l10n, album.durationMs),
      ].join(' · '),
      itemKey: album.key,
      coverKey: album.coverKey,
      seed: album.key,
    ),
    groups: withAdvanced(
      [
        [
          if (!own)
            MenuItemSpec(
              MenuItemId.goAlbum,
              icon: KIcons.album,
              title: l10n.libraryMenuGoAlbum,
              subtitle: album.title,
              action: MenuAction.go(LibraryLocations.album(data.key)),
            ),
          artistRow,
          ?folderLink?.item,
        ],
        [
          ...playRows(l10n, data.ids, context, own: own),
          soonRow(
            MenuItemId.playlist,
            KIcons.playlistAdd,
            l10n.libraryMenuAddToPlaylist,
          ),
          favoriteAllRow(l10n, data.ids),
          soonRow(
            MenuItemId.edit,
            KIcons.edit,
            l10n.libraryMenuEditAlbum,
            subtitle: l10n.librarySongCount(album.trackCount),
          ),
          proRow(l10n, l10n.libraryMenuAskAiAlbum),
        ],
      ],
      advanced,
      l10n.libraryMenuAdvanced,
    ),
    advanced: advanced,
    pages: pages,
    queueIds: data.ids,
  );
}
