import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/detail_providers.dart';
import '../../state/custom_cover_providers.dart';
import '../browse/item_covers.dart';
import '../browse/library_labels.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'detail_header.dart';
import 'detail_tint.dart';
import 'detail_songs.dart';

/// Album page: cover, name, artist link with the year, counts and buttons (a
/// left column on a wide page), then the album's songs in track order with
/// their numbers. The page takes a soft tint from the cover it shows.
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
    final tint = watchDetailTint(ref, (
      kind: CustomCoverKind.album,
      itemKey: albumId,
    ), coverKey);
    final playContext = PlayContext(
      PlayContextKind.album,
      ref: albumId,
      label: album.title,
    );
    final scope = SongScope.album(key);
    final l10n = AppLocalizations.of(context);
    return DetailFrame(
      title: album.title,
      fallback: _fallback,
      tint: tint,
      child: DetailSongsHost(
        list: BrowseList.albumTracks,
        item: albumId,
        scope: scope,
        playContext: playContext,
        durationMs: album.durationMs,
        showNumber: true,
        builder: (context, songs) => KDetailLayout(
          header: KDetailHero(
            coverBuilder: (context, side) => AlbumCover(
              itemKey: albumId,
              coverKey: album.coverKey,
              dimension: side,
              // The wide (desktop) cover is square; the narrow one stays round.
              radius: KDetailLayout.isWide(context)
                  ? BorderRadius.zero
                  : BorderRadius.circular(14),
            ),
            title: album.title,
            line2: _artistLine(context, key, album),
            line3: [
              l10n.librarySongCount(album.trackCount),
              formatTotalDuration(l10n, album.durationMs),
            ].join(' · '),
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

  /// Second line: the album artist (a link when the album has an artist key)
  /// and the year; null when the album has neither.
  KDetailLine? _artistLine(
    BuildContext context,
    AlbumKey key,
    AlbumSummary album,
  ) {
    final name = album.artist;
    final year = album.year;
    if (name == null || name.isEmpty) {
      return year == null ? null : KDetailLine(text: '$year');
    }
    return KDetailLine(
      text: name,
      onTap: key.artistKey.isEmpty
          ? null
          : () => openLibraryPage(
              context,
              LibraryLocations.artist(ArtistKey(key.artistKey)),
            ),
      trailing: year?.toString(),
    );
  }
}
