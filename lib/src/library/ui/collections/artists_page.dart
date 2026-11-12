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
import 'artist_tile.dart';
import '../selection/selection_inset.dart';
import 'collection_parts.dart';

/// The Artists list: a grid of round photos or rows, sorted and filtered.
class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LibraryListScaffold(
      tab: LibraryTab.artists,
      child: LibraryListFrame(
        list: BrowseList.artists,
        filterHint: l10n.libraryFilterArtistsHint,
        builder: (context, input) => (
          leading: _ArtistsLeading(input: input),
          body: _ArtistsBody(input: input),
        ),
      ),
    );
  }
}

CollectionViewKey _key(LibraryListInput input) =>
    (sort: input.sort, filter: input.filter);

class _ArtistsLeading extends ConsumerWidget {
  const _ArtistsLeading({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(artistListProvider(_key(input))).value?.length;
    final total = ref.watch(artistSummariesProvider).value?.length;
    return CollectionBarLeading(
      text: collectionCountText(
        shown: shown,
        total: total,
        filtering: input.filter.isNotEmpty,
        plain: l10n.libraryArtistCount,
        unit: l10n.libraryUnitArtists,
        l10n: l10n,
      ),
      switchFor: BrowseList.artists,
      view: input.view,
    );
  }
}

class _ArtistsBody extends ConsumerWidget {
  const _ArtistsBody({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = libraryGutter(context);
    final scaler = MediaQuery.textScalerOf(context);
    return collectionBody(
      context,
      ref.watch(artistListProvider(_key(input))),
      (artists) {
        final grid = input.view == CollectionView.grid;
        return CustomScrollView(
          slivers: [
            if (grid)
              KCollectionGrid(
                itemCount: artists.length,
                mobileMinTileWidth: 100,
                desktopMinTileWidth: 160,
                footerExtent: KGridCard.footerExtent(scaler),
                padding: EdgeInsets.symmetric(horizontal: gutter),
                itemBuilder: (context, i) => ArtistCard(artist: artists[i]),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: libraryRowGutter(context),
                ),
                sliver: SliverFixedExtentList(
                  itemExtent: KMediaCard.extentOf(scaler),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ArtistTile(artist: artists[i]),
                    childCount: artists.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            const SelectionInsetSliver(),
          ],
        );
      },
      skeletonRows: input.view == CollectionView.list,
      roundCover: true,
    );
  }
}
