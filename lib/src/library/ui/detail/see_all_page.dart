import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/detail_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../collections/album_tile.dart';
import '../collections/artist_tile.dart';
import '../menus/menu_origin.dart';
import '../library_locations.dart';
import '../selection/selection_inset.dart';
import 'detail_header.dart';
import 'group_page.dart';

/// Locations of the "see all" grids behind the `›` of a shelf.
abstract final class SeeAllLocations {
  static String artistAlbums(ArtistKey key) =>
      '${LibraryLocations.artist(key)}/albums';

  static String artistAppears(ArtistKey key) =>
      '${LibraryLocations.artist(key)}/appears';

  static String groupArtists(GroupTarget target) => '${_base(target)}/artists';

  static String groupAlbums(GroupTarget target) => '${_base(target)}/albums';

  static String _base(GroupTarget target) => target.kind == GroupKind.genre
      ? LibraryLocations.genre(target.genreKey!)
      : LibraryLocations.language(target.code);
}

/// Grid of every album an artist owns, or appears on.
class ArtistAlbumsPage extends ConsumerWidget {
  const ArtistAlbumsPage({
    super.key,
    required this.artistId,
    required this.appears,
  });

  final String artistId;

  /// Albums of other artists the artist appears on, not its own.
  final bool appears;

  static final String _fallback = LibraryLocations.list(LibraryTab.artists);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ArtistKey.decode(artistId);
    if (key == null) return DetailNotFound(fallback: _fallback);
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(artistNameProvider(key));
    final albums = ref.watch(artistAlbumsProvider(key));
    final title = name.value;
    final data = albums.value;
    if (title == null || data == null) {
      return name.hasValue && title == null
          ? DetailNotFound(fallback: _fallback)
          : DetailPending(fallback: _fallback, failed: albums.hasError);
    }
    final heading = appears
        ? l10n.libraryAppearsInOf(title)
        : l10n.libraryAlbumsOf(title);
    final shown = appears ? data.appears : data.own;
    return DetailFrame(
      title: heading,
      fallback: LibraryLocations.artist(key),
      child: _AlbumGrid(
        title: heading,
        caption: l10n.libraryAlbumCount(shown.length),
        albums: shown,
        origin: MenuOrigin.artist(key),
      ),
    );
  }
}

/// Grid of the artists or albums of a genre or language.
class GroupSeeAllPage extends ConsumerWidget {
  const GroupSeeAllPage({
    super.key,
    required this.kind,
    required this.id,
    required this.artists,
  });

  final GroupKind kind;
  final String id;

  /// Artists when true, albums when false.
  final bool artists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = GroupTarget.parse(kind, id);
    final fallback = LibraryLocations.list(
      kind == GroupKind.genre ? LibraryTab.genres : LibraryTab.languages,
    );
    if (target == null) return DetailNotFound(fallback: fallback);
    final l10n = AppLocalizations.of(context);
    final named = groupName(ref, l10n, target);
    final name = named.value;
    final shelves = ref.watch(groupShelvesProvider(target.scope));
    final data = shelves.value;
    if (named.hasValue && name == null) {
      return DetailNotFound(fallback: fallback);
    }
    if (name == null || data == null) {
      return DetailPending(fallback: fallback, failed: shelves.hasError);
    }
    // A language with no track (a stale link) is not a page either.
    if (data.artists.isEmpty && data.albums.isEmpty) {
      return DetailNotFound(fallback: fallback);
    }
    final back = kind == GroupKind.genre
        ? LibraryLocations.genre(target.genreKey!)
        : LibraryLocations.language(target.code);
    final heading = artists
        ? l10n.libraryArtistsOf(name)
        : l10n.libraryAlbumsOf(name);
    return DetailFrame(
      title: heading,
      fallback: back,
      child: artists
          ? _ArtistGrid(
              title: heading,
              caption: l10n.libraryArtistCount(data.artists.length),
              artists: data.artists,
            )
          : _AlbumGrid(
              title: heading,
              caption: l10n.libraryAlbumCount(data.albums.length),
              albums: data.albums,
            ),
    );
  }
}

/// Name block at the head of a see-all grid.
Widget _gridHeading(BuildContext context, String title, String caption) =>
    SliverPadding(
      padding: EdgeInsets.fromLTRB(
        libraryGutter(context),
        KSpace.x2,
        libraryGutter(context),
        KSpace.x3,
      ),
      sliver: SliverToBoxAdapter(
        child: KGridHeading(title: title, caption: caption),
      ),
    );

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({
    required this.title,
    required this.caption,
    required this.albums,
    this.origin = const MenuOrigin.list(),
  });

  final String title;
  final String caption;
  final List<AlbumSummary> albums;
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      _gridHeading(context, title, caption),
      AlbumGrid(
        albums: albums,
        origin: origin,
        padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
      ),
      const SelectionInsetSliver(),
    ],
  );
}

class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({
    required this.title,
    required this.caption,
    required this.artists,
  });

  final String title;
  final String caption;
  final List<ArtistSummary> artists;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      _gridHeading(context, title, caption),
      KCollectionGrid(
        itemCount: artists.length,
        mobileMinTileWidth: 100,
        desktopMinTileWidth: 160,
        footerExtent: KGridCard.footerExtent(MediaQuery.textScalerOf(context)),
        padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
        itemBuilder: (context, i) => ArtistCard(artist: artists[i]),
      ),
      const SelectionInsetSliver(),
    ],
  );
}
