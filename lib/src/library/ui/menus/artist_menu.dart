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

/// Everything the menu of one artist shows, loaded before it opens.
class ArtistMenuData {
  const ArtistMenuData({
    required this.artist,
    required this.key,
    required this.albums,
    required this.ids,
    required this.folders,
  });

  final ArtistSummary artist;
  final ArtistKey key;

  /// Own albums and the ones the artist appears on.
  final ArtistAlbums albums;

  /// The tracks Play and the queue buttons take.
  final List<TrackId> ids;
  final List<FolderRef> folders;
}

/// Menu of an artist. The albums row lists the artist's own albums first,
/// then the ones they appear on, as chips or (from four) a page with a
/// heading for each part.
MenuSpec buildArtistMenu(ArtistMenuData data, MenuOrigin origin, MenuEnv env) {
  final l10n = env.l10n;
  final artist = data.artist;
  final own = origin is OwnOrigin;
  final pages = <String, MenuPageSpec>{};

  LinkTarget target(AlbumSummary a) => LinkTarget(
    a.title,
    _albumLocation(a),
    cover: MenuCover(a.key, a.coverKey),
    subtitle: [
      if (a.year != null) '${a.year}',
      l10n.librarySongCount(a.trackCount),
    ].join(' · '),
  );
  final ownTargets = [
    for (final a in data.albums.own)
      if (AlbumKey.decode(a.key) != null) target(a),
  ];
  final appearsTargets = [
    for (final a in data.albums.appears)
      if (AlbumKey.decode(a.key) != null) target(a),
  ];
  final albumLink = linkRow(
    id: MenuItemId.goAlbum,
    icon: KIcons.album,
    manyIcon: KIcons.albums,
    title: l10n.libraryMenuGoAlbum,
    targets: [...ownTargets, ...appearsTargets],
    manyText: [
      if (ownTargets.isNotEmpty) l10n.libraryAlbumCount(ownTargets.length),
      if (appearsTargets.isNotEmpty)
        l10n.libraryMenuAppearsCount(appearsTargets.length),
    ].join(' · '),
    noneText: l10n.libraryMenuNoAlbum,
    pageKey: 'albums',
    pageTitle: l10n.libraryAlbumsOf(artist.name),
    targetIcon: KIcons.album,
    sections: [
      if (ownTargets.isNotEmpty)
        LinkSection(ownTargets, title: l10n.libraryTabAlbums),
      if (appearsTargets.isNotEmpty)
        LinkSection(appearsTargets, title: l10n.libraryAppearsIn),
    ],
  );
  if (albumLink.page != null) pages['albums'] = albumLink.page!;

  final folderLink = folderLinks(
    env,
    data.folders,
    intro: l10n.libraryMenuFoldersIntroArtist(data.folders.length),
    pageTitle: l10n.libraryMenuFoldersOf(artist.name),
  );
  if (folderLink?.page != null) pages['folders'] = folderLink!.page!;

  final context = PlayContext(
    PlayContextKind.artist,
    ref: artist.key,
    label: artist.name,
  );
  final advanced = [
    [
      soonRow(
        MenuItemId.split,
        KIcons.artistsMany,
        l10n.libraryMenuSplitArtists,
        subtitle: l10n.libraryMenuSplitArtistsNote,
      ),
    ],
    removeRows(env, data.ids.length),
  ];
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.artist,
      title: artist.name,
      subtitle: [
        l10n.libraryAlbumCount(artist.albumCount),
        l10n.librarySongCount(artist.trackCount),
        formatTotalDuration(l10n, artist.durationMs),
      ].join(' · '),
      itemKey: artist.key,
      coverKey: artist.coverKey,
      seed: artist.name,
    ),
    groups: withAdvanced(
      [
        [
          if (!own)
            MenuItemSpec(
              MenuItemId.goArtist,
              icon: KIcons.artists,
              title: l10n.libraryMenuGoArtist,
              subtitle: artist.name,
              action: MenuAction.go(LibraryLocations.artist(data.key)),
            ),
          albumLink.item,
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
          proRow(l10n, l10n.libraryMenuAskAiArtist),
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

String _albumLocation(AlbumSummary a) {
  final key = AlbumKey.decode(a.key);
  return key == null ? '' : LibraryLocations.album(key);
}
