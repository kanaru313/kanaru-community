import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/menu_targets.dart';
import '../browse/group_play.dart';
import '../browse/library_labels.dart';
import '../library_locations.dart';
import 'link_rows.dart';
import 'menu_items.dart';
import 'menu_model.dart';
import 'menu_origin.dart';

/// Which kind of group a [GroupMenuData] is.
enum GroupMenuKind { genre, language }

/// Everything the menu of a genre or a language shows, loaded before it
/// opens. [key] is the stored `genre_key`, or the language code (null = the
/// group without a language).
class GroupMenuData {
  const GroupMenuData({
    required this.kind,
    required this.key,
    required this.name,
    required this.ids,
    required this.albums,
    required this.folders,
    required this.durationMs,
    this.detected = 0,
  });

  final GroupMenuKind kind;
  final String? key;

  /// Display name (the genre as written, the language's name).
  final String name;
  final List<TrackId> ids;
  final List<AlbumSummary> albums;
  final List<FolderRef> folders;
  final int durationMs;

  /// Languages: how many of [ids] got their language by detection.
  final int detected;
}

/// Menu of a genre or a language: the same rows, apart from the kind's own
/// link and its last row (genre: split or merge; language: how languages are
/// detected).
MenuSpec buildGroupMenu(GroupMenuData data, MenuOrigin origin, MenuEnv env) {
  final l10n = env.l10n;
  final genre = data.kind == GroupMenuKind.genre;
  final own = origin is OwnOrigin;
  final pages = <String, MenuPageSpec>{};

  final albumTargets = [
    for (final a in data.albums)
      if (AlbumKey.decode(a.key) case final key?)
        LinkTarget(
          a.title,
          LibraryLocations.album(key),
          cover: MenuCover(a.key, a.coverKey),
          subtitle: [
            if (a.artist != null && a.artist!.isNotEmpty) a.artist!,
            if (a.year != null) '${a.year}',
          ].join(' · '),
        ),
  ];
  final albumLink = linkRow(
    id: MenuItemId.goAlbum,
    icon: KIcons.album,
    manyIcon: KIcons.albums,
    title: l10n.libraryMenuGoAlbum,
    targets: albumTargets,
    manyText: l10n.libraryAlbumCount(albumTargets.length),
    noneText: l10n.libraryMenuNoAlbum,
    pageKey: 'albums',
    pageTitle: l10n.libraryAlbumsOf(data.name),
    targetIcon: KIcons.album,
  );
  if (albumLink.page != null) pages['albums'] = albumLink.page!;

  final folderLink = folderLinks(
    env,
    data.folders,
    intro: genre
        ? l10n.libraryMenuFoldersIntroGenre(data.folders.length)
        : l10n.libraryMenuFoldersIntroLanguage(data.folders.length),
    pageTitle: l10n.libraryMenuFoldersOf(data.name),
  );
  if (folderLink?.page != null) pages['folders'] = folderLink!.page!;

  final context = genre
      ? genrePlayContext(data.key!, data.name)
      : languagePlayContext(data.key, data.name);
  final goOwn = MenuItemSpec(
    genre ? MenuItemId.goGenre : MenuItemId.goLanguage,
    icon: genre ? KIcons.genres : KIcons.languages,
    title: genre ? l10n.libraryMenuGoGenre : l10n.libraryMenuGoLanguage,
    subtitle: data.name,
    action: MenuAction.go(
      genre
          ? LibraryLocations.genre(data.key!)
          : LibraryLocations.language(data.key),
    ),
  );
  final subtitle = genre
      ? [
          l10n.libraryAlbumCount(albumTargets.length),
          l10n.librarySongCount(data.ids.length),
          formatTotalDuration(l10n, data.durationMs),
        ].join(' · ')
      : data.detected > 0
      ? l10n.libraryLanguageStatsDetected(data.ids.length, data.detected)
      : l10n.librarySongCount(data.ids.length);
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.tile,
      title: data.name,
      subtitle: subtitle,
      seed: data.name,
      tileIcon: genre
          ? KIcons.genres
          : (data.key == null ? KIcons.help : KIcons.languages),
    ),
    groups: [
      [if (!own) goOwn, albumLink.item, ?folderLink?.item],
      [
        ...playRows(l10n, data.ids, context, own: own),
        soonRow(
          MenuItemId.playlist,
          KIcons.playlistAdd,
          l10n.libraryMenuAddToPlaylist,
        ),
        favoriteAllRow(l10n, data.ids),
        if (genre)
          soonRow(
            MenuItemId.split,
            KIcons.genres,
            l10n.libraryMenuSplitGenres,
            subtitle: l10n.libraryMenuSplitGenresNote,
          ),
      ],
      if (!genre)
        [
          soonRow(
            MenuItemId.languageSettings,
            KIcons.settings,
            l10n.libraryMenuLanguageDetection,
            subtitle: l10n.libraryMenuLanguageDetectionNote,
          ),
        ],
    ],
    pages: pages,
    queueIds: data.ids,
  );
}
