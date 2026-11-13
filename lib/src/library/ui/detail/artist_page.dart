import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/detail_providers.dart';
import '../../state/custom_cover_providers.dart';
import '../browse/item_covers.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'detail_header.dart';
import 'detail_tint.dart';
import 'detail_songs.dart';
import 'see_all_page.dart';

/// Artist page: round photo and `N albums` with the buttons (a left column on
/// a wide page), then the shelves of own albums and of albums the artist
/// appears on, then every song of the artist. A section with nothing in it is
/// left out; an artist that is only an album artist has no songs section.
class ArtistPage extends ConsumerWidget {
  const ArtistPage({super.key, required this.artistId});

  /// The encoded `ArtistKey` of the location.
  final String artistId;

  static final String _fallback = LibraryLocations.list(LibraryTab.artists);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ArtistKey.decode(artistId);
    if (key == null) return DetailNotFound(fallback: _fallback);
    final name = ref.watch(artistNameProvider(key));
    final title = name.value;
    if (title == null) {
      return name.hasValue
          ? DetailNotFound(fallback: _fallback)
          : DetailPending(fallback: _fallback, failed: name.hasError);
    }
    final detail = ref.watch(artistDetailProvider(key)).value;
    final albums =
        ref.watch(artistAlbumsProvider(key)).value ??
        const ArtistAlbums(own: [], appears: []);
    final photo =
        detail?.coverKey ??
        albums.own.map((a) => a.coverKey).whereType<String>().firstOrNull;
    final tint = watchDetailTint(ref, (
      kind: CustomCoverKind.artist,
      itemKey: artistId,
    ), photo);
    final scope = SongScope.artist(key);
    final playContext = PlayContext(
      PlayContextKind.artist,
      ref: artistId,
      label: title,
    );
    final hasSongs = detail != null && detail.trackCount > 0;
    // An artist that is only an album artist has no songs part; Play still
    // plays what its albums hold.
    final playScope = hasSongs ? scope : SongScope.albumArtist(key);

    Widget layout(List<Widget> songs) {
      final l10n = AppLocalizations.of(context);
      return KDetailLayout(
        header: KDetailHero(
          circle: true,
          coverBuilder: (context, side) => ArtistCover(
            itemKey: artistId,
            name: title,
            coverKey: photo,
            dimension: side,
          ),
          body: [
            if (albums.own.isNotEmpty)
              Text(
                l10n.libraryAlbumCount(albums.own.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
          ],
          actions: DetailActions(
            scope: playScope,
            list: BrowseList.detailSongs,
            item: artistId,
            playContext: playContext,
            onMenu: (c, {required viaKeyboard}) => openArtistMenu(
              c,
              key,
              origin: const MenuOrigin.own(),
              viaKeyboard: viaKeyboard,
            ),
          ),
        ),
        slivers: [
          if (albums.own.isNotEmpty)
            SliverToBoxAdapter(
              child: AlbumShelf(
                title: l10n.libraryTabAlbums,
                albums: albums.own,
                origin: MenuOrigin.artist(key),
                onSeeAll: () =>
                    openLibraryPage(context, SeeAllLocations.artistAlbums(key)),
              ),
            ),
          if (albums.appears.isNotEmpty)
            SliverToBoxAdapter(
              child: AlbumShelf(
                title: l10n.libraryAppearsIn,
                albums: albums.appears,
                origin: MenuOrigin.artist(key),
                onSeeAll: () => openLibraryPage(
                  context,
                  SeeAllLocations.artistAppears(key),
                ),
              ),
            ),
          ...songs,
        ],
      );
    }

    return DetailFrame(
      title: title,
      fallback: _fallback,
      tint: tint,
      child: DetailSongsHost(
        list: BrowseList.detailSongs,
        item: artistId,
        scope: scope,
        playContext: playContext,
        hasSongs: hasSongs,
        durationMs: detail?.durationMs,
        builder: (context, songs) => layout(songs),
      ),
    );
  }
}
