import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../database/state/database_providers.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_info.dart';
import '../../../platform/state/file_manager_provider.dart';
import '../../data/browse/detail_queries.dart';
import '../../data/browse/album_artist_queries.dart';
import '../../data/browse/menu_queries.dart';
import '../../data/browse/song_ids_query.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/music_folder.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/favorites_providers.dart';
import '../../state/music_folders_providers.dart';
import '../browse/library_labels.dart';
import '../folders/folder_play.dart';
import 'album_menu.dart';
import 'artist_menu.dart';
import 'folder_menu.dart';
import 'group_menu.dart';
import 'menu_model.dart';
import 'menu_origin.dart';
import 'selection_menu.dart';
import 'song_info_page.dart';
import 'song_menu.dart';

/// Loads what a menu shows, once, before it opens: no half-filled rows and no
/// rows that change under the user's finger. Each function reads the database
/// directly (one-shot reads, no provider that could dispose mid-load) and
/// hands plain data to the pure builder of its kind.

/// The first value of [provider]. A provider nobody listens to is paused, so
/// the read holds a listener until the value is there.
Future<T> _first<T>(
  ProviderContainer container,
  StreamProvider<T> provider,
) async {
  final hold = container.listen(provider, (_, _) {});
  try {
    return await container.read(provider.future);
  } finally {
    hold.close();
  }
}

/// How long a menu waits for the list of music folders before it opens
/// without paths (rows that need one are then inert).
const _foldersWait = Duration(seconds: 2);

/// The platform facts and folder paths every builder needs.
Future<MenuEnv> loadMenuEnv(
  ProviderContainer container,
  AppLocalizations l10n, {
  required bool trash,
}) async {
  List<MusicFolder> folders;
  try {
    folders = await _first(
      container,
      musicFoldersProvider,
    ).timeout(_foldersWait, onTimeout: () => const []);
  } on Object {
    folders = const [];
  }
  return MenuEnv(
    l10n: l10n,
    canReveal: container.read(fileManagerProvider).canReveal,
    trash: trash,
    pathOf: (folder) {
      for (final f in folders) {
        if (f.sourceId != folder.sourceId) continue;
        final root = f.root.endsWith('/')
            ? f.root.substring(0, f.root.length - 1)
            : f.root;
        return folder.folderKey.isEmpty ? root : '$root/${folder.folderKey}';
      }
      return null;
    },
  );
}

Future<MenuSpec> songMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  TrackInfo info,
  MenuOrigin origin,
) async {
  final db = container.read(appDatabaseProvider);
  final links = await trackLinks(db, info.id);
  if (links == null) throw StateError('track ${info.id} is gone');
  final file = await songInfo(db, info.id);
  final favorites = await _first(container, favoriteTrackIdsProvider);
  return buildSongMenu(
    SongMenuData(
      info: info,
      links: links,
      file: file,
      favorite: favorites.contains(info.id),
      selected: container.read(librarySelectionProvider).set.contains(info.id),
    ),
    origin,
    env,
    infoPage: songInfoPage(file, env),
  );
}

Future<MenuSpec> albumMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  AlbumKey key,
  MenuOrigin origin,
) async {
  final db = container.read(appDatabaseProvider);
  final scope = SongScope.album(key);
  final encoded = key.encode();
  final album = (await albumSummaries(
    db,
    scope: scope,
  )).where((a) => a.key == encoded).firstOrNull;
  if (album == null) throw StateError('album $encoded is gone');
  return buildAlbumMenu(
    AlbumMenuData(
      album: album,
      key: key,
      ids: await songIds(db, scope, defaultSortOf(BrowseList.albumTracks), ''),
      folders: await foldersOf(db, scope),
    ),
    origin,
    env,
  );
}

Future<MenuSpec> artistMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  ArtistKey key,
  MenuOrigin origin,
) async {
  final db = container.read(appDatabaseProvider);
  final encoded = key.encode();
  final found = (await artistSummaries(
    db,
    scope: SongScope.artist(key),
  )).where((a) => a.key == encoded).firstOrNull;
  final albums = await artistAlbums(db, key);
  var artist = found;
  if (artist == null) {
    // Only an album artist: no track of its own, the albums name it.
    if (albums.own.isEmpty && albums.appears.isEmpty) {
      throw StateError('artist $encoded is gone');
    }
    final named = albums.own.firstOrNull?.artist;
    artist = ArtistSummary(
      key: encoded,
      name: named != null && named.isNotEmpty ? named : key.key,
      trackCount: 0,
      albumCount: albums.own.length,
      durationMs: 0,
      coverKey: albums.own.map((a) => a.coverKey).nonNulls.firstOrNull,
    );
  }
  // An artist with no song of its own plays what its albums hold.
  final scope = artist.trackCount > 0
      ? SongScope.artist(key)
      : SongScope.albumArtist(key);
  return buildArtistMenu(
    ArtistMenuData(
      artist: artist,
      key: key,
      albums: albums,
      ids: await songIds(db, scope, defaultSortOf(BrowseList.detailSongs), ''),
      folders: await foldersOf(db, scope),
    ),
    origin,
    env,
  );
}

Future<MenuSpec> _groupMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  GroupMenuKind kind,
  String? key,
  String name,
  SongScope scope,
  MenuOrigin origin,
) async {
  final db = container.read(appDatabaseProvider);
  final totals = await groupTotals(db, scope);
  return buildGroupMenu(
    GroupMenuData(
      kind: kind,
      key: key,
      name: name,
      ids: await songIds(db, scope, defaultSortOf(BrowseList.detailSongs), ''),
      albums: await albumSummaries(db, scope: scope, newestFirst: true),
      folders: await foldersOf(db, scope),
      durationMs: totals.durationMs,
      detected: totals.detected,
    ),
    origin,
    env,
  );
}

Future<MenuSpec> genreMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  String genreKey,
  String name,
  MenuOrigin origin,
) => _groupMenuSpec(
  container,
  env,
  GroupMenuKind.genre,
  genreKey,
  name,
  SongScope.genre(genreKey),
  origin,
);

Future<MenuSpec> languageMenuSpec(
  ProviderContainer container,
  MenuEnv env,
  String? code,
  MenuOrigin origin,
) => _groupMenuSpec(
  container,
  env,
  GroupMenuKind.language,
  code,
  languageDisplayName(env.l10n, code),
  SongScope.language(code),
  origin,
);

Future<MenuSpec> folderMenuSpec(
  ProviderContainer container,
  MenuEnv env, {
  required MusicFolder folder,
  required String key,
  required String name,
  required int subfolders,
  required bool flat,
  required MenuOrigin origin,
}) async {
  final db = container.read(appDatabaseProvider);
  const sort = SortSpec(SortCriterion.title);
  final direct = await songIds(
    db,
    folderPlayScope(folder.sourceId, key, flat: true),
    sort,
    '',
  );
  final all = flat
      ? direct
      : await songIds(db, folderPlayScope(folder.sourceId, key), sort, '');
  return buildFolderMenu(
    FolderMenuData(
      folder: folder,
      key: key,
      name: name,
      ids: all,
      directIds: direct,
      subfolders: subfolders,
      flat: flat,
    ),
    origin,
    env,
  );
}

Future<MenuSpec> selectionMenuSpec(
  ProviderContainer container,
  MenuEnv env,
) async {
  final db = container.read(appDatabaseProvider);
  final selection = container.read(librarySelectionProvider);
  final measured = await selectionDuration(db, selection.ids);
  final gone = measured.absent.toSet();
  // Tracks that vanished since they were picked drop out of the selection
  // and the menu.
  if (gone.isNotEmpty) {
    container.read(librarySelectionProvider.notifier).removeAll(gone);
  }
  final ids = [
    for (final id in selection.ids)
      if (!gone.contains(id)) id,
  ];
  final favorites = await _first(container, favoriteTrackIdsProvider);
  return buildSelectionMenu(
    SelectionMenuData(
      ids: ids,
      durationMs: measured.durationMs,
      allFavorite: ids.isNotEmpty && ids.every(favorites.contains),
    ),
    env,
  );
}
