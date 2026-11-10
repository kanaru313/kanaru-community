import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/collection_providers.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import 'album_tile.dart';
import '../selection/selection_inset.dart';
import 'collection_parts.dart';

/// The Albums list: a grid of covers or rows, sorted and filtered.
class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LibraryListScaffold(
      tab: LibraryTab.albums,
      child: LibraryListFrame(
        list: BrowseList.albums,
        filterHint: l10n.libraryFilterAlbumsHint,
        builder: (context, input) => (
          leading: _AlbumsLeading(input: input),
          body: _AlbumsBody(input: input),
        ),
      ),
    );
  }
}

CollectionViewKey _key(LibraryListInput input) =>
    (sort: input.sort, filter: input.filter);

class _AlbumsLeading extends ConsumerWidget {
  const _AlbumsLeading({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(albumListProvider(_key(input))).value?.length;
    final total = ref.watch(albumSummariesProvider).value?.length;
    return CollectionBarLeading(
      text: collectionCountText(
        shown: shown,
        total: total,
        filtering: input.filter.isNotEmpty,
        plain: l10n.libraryAlbumCount,
        unit: l10n.libraryUnitAlbums,
        l10n: l10n,
      ),
      switchFor: BrowseList.albums,
      view: input.view,
    );
  }
}

class _AlbumsBody extends ConsumerWidget {
  const _AlbumsBody({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = libraryGutter(context);
    final scaler = MediaQuery.textScalerOf(context);
    return collectionBody(context, ref.watch(albumListProvider(_key(input))), (
      albums,
    ) {
      final grid = input.view == CollectionView.grid;
      return CustomScrollView(
        slivers: [
          if (grid)
            KCollectionGrid(
              itemCount: albums.length,
              mobileMinTileWidth: 150,
              desktopMinTileWidth: 160,
              footerExtent: KGridCard.footerExtent(scaler),
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemBuilder: (context, i) => AlbumCard(album: albums[i]),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: SliverFixedExtentList(
                itemExtent: KMediaCard.extentOf(scaler),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => AlbumTile(album: albums[i]),
                  childCount: albums.length,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),
          const SelectionInsetSliver(),
        ],
      );
    });
  }
}
