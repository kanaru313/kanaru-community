import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../../playback/state/cover_providers.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/custom_cover_index_providers.dart';
import '../../state/browse/detail_providers.dart';
import '../../state/custom_cover_providers.dart';
import '../browse/item_covers.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'detail_header.dart';
import 'detail_songs.dart';

/// Album page: cover, artist link, year and buttons (a left column on a wide
/// page), then the album's songs in track order with their numbers. The page
/// takes a soft tint from the cover.
class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key, required this.albumId});

  /// The encoded `AlbumKey` of the location.
  final String albumId;

  static final String _fallback = LibraryLocations.list(LibraryTab.albums);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AlbumKey.decode(albumId);
    if (key == null) return DetailNotFound(fallback: _fallback);
    final detail = ref.watch(albumDetailProvider(key));
    final album = detail.value;
    if (album == null) {
      return detail.hasValue
          ? DetailNotFound(fallback: _fallback)
          : DetailPending(fallback: _fallback, failed: detail.hasError);
    }
    final coverKey = album.coverKey;
    // A custom cover wins over the tracks' cover and its colours are not
    // extracted yet: no tint rather than the tint of a picture not shown.
    final custom = ref.watch(
      hasCustomCoverProvider((kind: CustomCoverKind.album, itemKey: albumId)),
    );
    final seed = coverKey == null || custom
        ? null
        : ref.watch(coverColorsProvider(coverKey)).value?.seed;
    final playContext = PlayContext(
      PlayContextKind.album,
      ref: albumId,
      label: album.title,
    );
    final scope = SongScope.album(key);
    return DetailFrame(
      title: album.title,
      fallback: _fallback,
      child: DetailSongsHost(
        list: BrowseList.albumTracks,
        item: albumId,
        scope: scope,
        playContext: playContext,
        durationMs: album.durationMs,
        showNumber: true,
        builder: (context, songs) => KDetailLayout(
          tint: seed == null ? null : Color(seed),
          header: KDetailHero(
            coverBuilder: (context, side) => AlbumCover(
              itemKey: albumId,
              coverKey: album.coverKey,
              dimension: side,
              radius: BorderRadius.circular(14),
            ),
            body: [
              _ArtistLink(albumKey: key, album: album),
              if (album.year != null)
                Text(
                  '${album.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
            actions: DetailActions(
              scope: scope,
              list: BrowseList.albumTracks,
              item: albumId,
              playContext: playContext,
              onMenu: (c, {required viaKeyboard}) => openAlbumMenu(
                c,
                key,
                origin: const MenuOrigin.own(),
                viaKeyboard: viaKeyboard,
              ),
            ),
          ),
          slivers: songs,
        ),
      ),
    );
  }
}

/// The album artist, in the primary colour, opening the artist page.
class _ArtistLink extends StatelessWidget {
  const _ArtistLink({required this.albumKey, required this.album});

  final AlbumKey albumKey;
  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    final name = album.artist;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    if (albumKey.artistKey.isEmpty) return Text(name, style: style);
    void open() => openLibraryPage(
      context,
      LibraryLocations.artist(ArtistKey(albumKey.artistKey)),
    );
    return Semantics(
      button: true,
      link: true,
      excludeSemantics: true,
      label: name,
      onTap: open,
      child: InkWell(
        borderRadius: KRadius.sm,
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KLayout.minTarget),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
