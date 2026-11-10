import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/collection_providers.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import 'collection_parts.dart';

/// The Genres list: coloured tiles with the genre name and its song count.
class GenresPage extends StatelessWidget {
  const GenresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LibraryListScaffold(
      tab: LibraryTab.genres,
      child: LibraryListFrame(
        list: BrowseList.genres,
        filterHint: l10n.libraryFilterGenresHint,
        builder: (context, input) => (
          leading: _GenresLeading(input: input),
          body: _GenresBody(input: input),
        ),
      ),
    );
  }
}

CollectionViewKey _key(LibraryListInput input) =>
    (sort: input.sort, filter: input.filter);

class _GenresLeading extends ConsumerWidget {
  const _GenresLeading({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(genreListProvider(_key(input))).value?.length;
    final total = ref.watch(genreSummariesProvider).value?.length;
    return CollectionBarLeading(
      text: collectionCountText(
        shown: shown,
        total: total,
        filtering: input.filter.isNotEmpty,
        plain: l10n.libraryGenreCount,
        unit: l10n.libraryUnitGenres,
        l10n: l10n,
      ),
    );
  }
}

class _GenresBody extends ConsumerWidget {
  const _GenresBody({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gutter = libraryGutter(context);
    final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
    return collectionBody(context, ref.watch(genreListProvider(_key(input))), (
      genres,
    ) {
      return CustomScrollView(
        slivers: [
          KCollectionGrid(
            itemCount: genres.length,
            mobileMinTileWidth: 150,
            desktopMinTileWidth: 200,
            tileAspect: 0,
            footerExtent: KColorTile.minHeight * scale,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemBuilder: (context, i) {
              final genre = genres[i];
              return KColorTile(
                seed: genre.name,
                title: genre.name,
                subtitle: l10n.librarySongCount(genre.trackCount),
                icon: KIcons.genres,
                onTap: () =>
                    openLibraryPage(context, LibraryLocations.genre(genre.key)),
              );
            },
          ),
          const SliverToBoxAdapter(child: KGap(KSpace.x4)),
        ],
      );
    });
  }
}
