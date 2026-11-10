import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/track_info.dart';
import '../../domain/browse/menu_targets.dart';
import '../library_locations.dart';
import 'link_rows.dart';
import 'menu_items.dart';
import 'menu_model.dart';
import 'menu_origin.dart';

/// Everything the menu of one song shows, loaded before it opens.
class SongMenuData {
  const SongMenuData({
    required this.info,
    required this.links,
    required this.file,
    required this.favorite,
    required this.selected,
  });

  final TrackInfo info;
  final TrackLinks links;

  /// File facts; null when the track vanished from the table meanwhile.
  final SongInfo? file;
  final bool favorite;
  final bool selected;
}

/// Menu of a song. [origin] is the page the song is listed on: a song on its
/// album page has no "Go to album", on its folder's page "Show in file
/// manager" replaces "Go to folder", on an artist's page that artist is left
/// out of the artist chips. [infoPage] is the song info sub-page.
MenuSpec buildSongMenu(
  SongMenuData data,
  MenuOrigin origin,
  MenuEnv env, {
  MenuPageSpec? infoPage,
}) {
  final l10n = env.l10n;
  final info = data.info;
  final links = data.links;
  final id = info.id;
  final pages = <String, MenuPageSpec>{};

  final hideArtist = origin is ArtistOrigin ? origin.key : null;
  List<LinkTarget> artistTargets(List<ArtistRef> refs) => [
    for (final a in refs)
      if (a.key != hideArtist)
        LinkTarget(a.name, LibraryLocations.artist(a.key)),
  ];

  final goAlbum = _goAlbum(data, origin, env);
  final artists = artistTargets(links.artists);
  // The page's own artist is not a link; when it was the only one the row
  // goes (a song with no artist at all keeps its dimmed row).
  final artistRow = links.artists.isNotEmpty && artists.isEmpty
      ? null
      : linkRow(
          id: MenuItemId.goArtist,
          icon: KIcons.artists,
          manyIcon: KIcons.artistsMany,
          title: l10n.libraryMenuGoArtist,
          targets: artists,
          manyText: l10n.libraryArtistCount(artists.length),
          noneText: l10n.libraryMenuNoArtist,
          pageKey: 'artists',
          chipsOnly: true,
        ).item;
  final albumArtists = artistTargets(links.albumArtists);
  final albumArtistRow = albumArtists.isEmpty
      ? null
      : linkRow(
          id: MenuItemId.goAlbumArtist,
          icon: KIcons.albumArtist,
          manyIcon: KIcons.artistsMany,
          title: l10n.libraryMenuGoAlbumArtist,
          targets: albumArtists,
          manyText: l10n.libraryArtistCount(albumArtists.length),
          noneText: l10n.libraryMenuNoArtist,
          pageKey: 'albumArtists',
          chipsOnly: true,
        ).item;

  final ownFolder =
      origin is FolderOrigin &&
      origin.sourceId == links.folder.sourceId &&
      origin.folderKey == links.folder.folderKey;
  final folderPath = env.pathOf(links.folder);
  final MenuItemSpec folderRow;
  if (ownFolder) {
    // Show the file itself when its path is known, else its folder.
    folderRow = revealRow(env, data.file?.path ?? folderPath);
  } else {
    folderRow = folderLinks(
      env,
      [links.folder],
      intro: '',
      pageTitle: '',
    )!.item;
  }

  final advanced = <List<MenuItemSpec>>[
    [soonRow(MenuItemId.lyrics, KIcons.lyrics, l10n.libraryMenuFindLyrics)],
    removeRows(env, 1),
  ];

  if (infoPage != null) pages[infoPageKey] = infoPage;
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.track,
      title: info.title,
      subtitle: [
        links.artists.isEmpty
            ? info.artist
            : links.artists.map((a) => a.name).join(', '),
        info.album,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      coverKey: info.coverKey,
      seed: info.albumKey?.encode() ?? info.title,
      infoPage: infoPage == null ? null : infoPageKey,
    ),
    groups: withAdvanced(
      [
        [?goAlbum, ?artistRow, ?albumArtistRow, folderRow],
        [
          soonRow(
            MenuItemId.playlist,
            KIcons.playlistAdd,
            l10n.libraryMenuAddToPlaylist,
          ),
          MenuItemSpec(
            MenuItemId.favorite,
            icon: data.favorite ? KIcons.heartFilled : KIcons.heart,
            title: data.favorite
                ? l10n.libraryFavoriteRemove
                : l10n.libraryFavoriteAdd,
            action: MenuAction.favorite([id], on: !data.favorite),
          ),
          soonRow(MenuItemId.edit, KIcons.edit, l10n.libraryMenuEditSong),
          MenuItemSpec(
            MenuItemId.select,
            icon: data.selected ? KIcons.deselect : KIcons.select,
            title: data.selected
                ? l10n.libraryMenuDeselect
                : l10n.libraryMenuSelect,
            action: MenuAction.select(id, on: !data.selected),
          ),
          proRow(l10n, l10n.libraryMenuAskAiSong),
        ],
      ],
      advanced,
      l10n.libraryMenuAdvanced,
    ),
    advanced: advanced,
    pages: pages,
    queueIds: [id],
  );
}

MenuItemSpec? _goAlbum(SongMenuData data, MenuOrigin origin, MenuEnv env) {
  final key = data.links.albumKey;
  final l10n = env.l10n;
  if (key == null) {
    return MenuItemSpec(
      MenuItemId.goAlbum,
      icon: KIcons.album,
      title: l10n.libraryMenuGoAlbum,
      subtitle: l10n.libraryMenuNoAlbum,
      enabled: false,
    );
  }
  if (origin is AlbumOrigin && origin.key == key) return null;
  return MenuItemSpec(
    MenuItemId.goAlbum,
    icon: KIcons.album,
    title: l10n.libraryMenuGoAlbum,
    subtitle: data.links.albumTitle,
    action: MenuAction.go(LibraryLocations.album(key)),
  );
}
