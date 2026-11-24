import 'package:flutter/widgets.dart' show BuildContext;
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
    required this.favorite,
    required this.selected,
    this.lyricsLabel,
    this.openLyrics,
  });

  final TrackInfo info;
  final TrackLinks links;

  final bool favorite;
  final bool selected;

  /// Subtitle of the "Lyrics source" row; null when not known.
  final String? lyricsLabel;

  /// Opens the lyrics modal of the song; null without a lyrics module (the
  /// row is then a soon row).
  final Future<void> Function(BuildContext context)? openLyrics;
}

/// Menu of a song. [origin] is the page the song is listed on: a song on its
/// album page has no "Go to album", on its folder's page "Show in file
/// manager" replaces "Go to folder", on an artist's page that artist is left
/// out of the artist chips. The header opens the song info (the caller wires
/// it when it renders the menu).
MenuSpec buildSongMenu(SongMenuData data, MenuOrigin origin, MenuEnv env) {
  final l10n = env.l10n;
  final info = data.info;
  final links = data.links;
  final id = info.id;

  // Every artist is a link, the page's own artist included (old app: "always
  // show all artists in Go to artist"); only the album and the folder have a
  // self-link rule.
  List<LinkTarget> artistTargets(List<ArtistRef> refs) => [
    for (final a in refs) LinkTarget(a.name, LibraryLocations.artist(a.key)),
  ];

  final goAlbum = _goAlbum(data, origin, env);
  final artists = artistTargets(links.artists);
  final artistRow = linkRow(
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
    folderRow = revealRow(env, links.filePath ?? folderPath);
  } else {
    folderRow = folderLinks(
      env,
      [links.folder],
      intro: '',
      pageTitle: '',
    )!.item;
  }

  final advanced = <List<MenuItemSpec>>[removeRows(env, 1)];

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
      seed: info.coverSeed,
    ),
    groups: withAdvanced(
      [
        [?goAlbum, artistRow, ?albumArtistRow, folderRow],
        [lyricsSourceRow(l10n, data.lyricsLabel, data.openLyrics)],
        [
          addToPlaylistRow(
            l10n,
            [id],
            info.title,
            excludePlaylistUid: origin is PlaylistOrigin ? origin.uid : null,
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
    queueIds: [id],
    origin: origin,
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

/// Rows a caller adds around the song menu's lyrics row, in the same group:
/// [before] above it, [after] below it.
typedef SongMenuAroundLyrics = ({
  List<MenuItemSpec> before,
  List<MenuItemSpec> after,
});

/// Adds the page's own rows to a song menu: [playlistGroup] as a group of its
/// own right after the "Go to" group (the first), [aroundLyrics] in the group
/// of the lyrics row (a group of its own right after "Go to" when the menu has
/// no lyrics row), drops the heart row when [favoriteRow] is false, the "Select"
/// row when [selectRow] is false and the "Play next" / "Add to queue" footer
/// when [queueButtons] is false. [leadingGroup] becomes the first group (before
/// "Go to"), [selectReplacement] takes the place of the "Select" row (same
/// position; ignored when [selectRow] is false), [beforeAdvanced] becomes a
/// group right before the "Advanced" group (the last group when the menu has
/// none). Defaults return [spec] as it is.
MenuSpec withSongPageRows(
  MenuSpec spec, {
  List<MenuItemSpec> playlistGroup = const [],
  bool favoriteRow = true,
  SongMenuAroundLyrics? aroundLyrics,
  bool selectRow = true,
  bool queueButtons = true,
  List<MenuItemSpec> leadingGroup = const [],
  MenuItemSpec? selectReplacement,
  List<MenuItemSpec> beforeAdvanced = const [],
}) {
  final around =
      aroundLyrics != null &&
          (aroundLyrics.before.isNotEmpty || aroundLyrics.after.isNotEmpty)
      ? aroundLyrics
      : null;
  if (playlistGroup.isEmpty &&
      favoriteRow &&
      around == null &&
      selectRow &&
      queueButtons &&
      leadingGroup.isEmpty &&
      selectReplacement == null &&
      beforeAdvanced.isEmpty) {
    return spec;
  }
  var placed = false;
  final groups = <List<MenuItemSpec>>[];
  for (final g in spec.groups) {
    final hasLyrics = around != null && g.any((i) => i.id == MenuItemId.lyrics);
    placed |= hasLyrics;
    groups.add([
      for (final item in g) ...[
        if (hasLyrics && item.id == MenuItemId.lyrics) ...around.before,
        if ((favoriteRow || item.id != MenuItemId.favorite) &&
            (selectRow || item.id != MenuItemId.select))
          if (selectRow &&
              selectReplacement != null &&
              item.id == MenuItemId.select)
            selectReplacement
          else
            item,
        if (hasLyrics && item.id == MenuItemId.lyrics) ...around.after,
      ],
    ]);
  }
  if (playlistGroup.isNotEmpty) {
    groups.insert(groups.isEmpty ? 0 : 1, playlistGroup);
  }
  if (around != null && !placed) {
    groups.insert(groups.isEmpty ? 0 : 1, [...around.before, ...around.after]);
  }
  if (beforeAdvanced.isNotEmpty) {
    final at = groups.indexWhere(
      (g) => g.any((i) => i.id == MenuItemId.advanced),
    );
    groups.insert(at < 0 ? groups.length : at, beforeAdvanced);
  }
  if (leadingGroup.isNotEmpty) groups.insert(0, leadingGroup);
  return spec.copyWith(
    groups: [
      for (final g in groups)
        if (g.isNotEmpty) g,
    ],
    queueIds: queueButtons ? null : const [],
  );
}
