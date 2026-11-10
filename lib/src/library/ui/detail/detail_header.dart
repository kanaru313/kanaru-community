import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/play_actions.dart';
import '../collections/album_tile.dart';
import '../collections/artist_tile.dart';

/// Frame of a detail page: the page [title] in a header with a back button
/// (no root slots, no ⋮), and the page below it. Back pops one page; a page
/// opened as the first one (a link from outside) goes to [fallback] instead.
class DetailFrame extends StatelessWidget {
  const DetailFrame({
    super.key,
    required this.title,
    required this.fallback,
    required this.child,
  });

  final String title;
  final String fallback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
          child: PageHeader(title: title, onBack: () => _back(context)),
        ),
        Expanded(child: child),
      ],
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallback);
    }
  }
}

/// A detail page whose item is not in the library (a stale link, a key that
/// does not decode).
class DetailNotFound extends StatelessWidget {
  const DetailNotFound({super.key, required this.fallback});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DetailFrame(
      title: l10n.libraryNotFoundTitle,
      fallback: fallback,
      child: KEmpty(icon: KIcons.help, message: l10n.libraryNotFoundMessage),
    );
  }
}

/// A detail page waiting for its first answer, or one whose query failed.
class DetailPending extends StatelessWidget {
  const DetailPending({super.key, required this.fallback, this.failed = false});

  final String fallback;
  final bool failed;

  @override
  Widget build(BuildContext context) => DetailFrame(
    title: '',
    fallback: fallback,
    child: failed
        ? Center(
            child: Text(
              AppLocalizations.of(context).libraryLoadFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        : const SizedBox.shrink(),
  );
}

/// [▶ Play] · [shuffle] · [⋮] of a detail page. Play and shuffle take every
/// song of [DetailActions.scope] in the sort the page is in (the page filter
/// is ignored).
/// The page menu is not built yet: its button is dimmed.
class DetailActions extends ConsumerWidget {
  const DetailActions({
    super.key,
    required this.scope,
    required this.list,
    required this.item,
    required this.playContext,
  });

  /// The songs Play and shuffle take.
  final SongScope scope;
  final BrowseList list;

  /// Id of the page's item, which keys its sort.
  final String item;
  final PlayContext playContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(detailSortProvider((list: list, item: item)));
    final ids = ref
        .watch(songIdsProvider((scope: scope, sort: sort, filter: '')))
        .value;
    final enabled = ids != null && ids.isNotEmpty;
    return Wrap(
      spacing: KSpace.x2,
      runSpacing: KSpace.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: enabled
              ? () => playAll(ref, context, ids, playContext)
              : null,
          icon: const Icon(KIcons.play),
          label: Text(l10n.libraryPlay),
        ),
        IconButton.filledTonal(
          tooltip: l10n.libraryShuffle,
          onPressed: enabled
              ? () => shuffleAll(ref, context, ids, playContext)
              : null,
          icon: const Icon(KIcons.shuffle),
        ),
        IconButton(
          tooltip: l10n.appComingSoon,
          onPressed: null,
          icon: const Icon(KIcons.moreVert),
        ),
      ],
    );
  }
}

/// Number of cards a genre or language shelf shows on this shell.
int shelfCap(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? 8 : 10;

/// Horizontal shelf of album cards; `›` opens [onSeeAll].
class AlbumShelf extends StatelessWidget {
  const AlbumShelf({
    super.key,
    required this.title,
    required this.albums,
    required this.onSeeAll,
  });

  final String title;
  final List<AlbumSummary> albums;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => _Shelf(
    title: title,
    count: albums.length,
    onSeeAll: onSeeAll,
    card: (i) => AlbumCard(album: albums[i]),
  );
}

/// Horizontal shelf of artist cards; `›` opens [onSeeAll].
class ArtistShelf extends StatelessWidget {
  const ArtistShelf({
    super.key,
    required this.title,
    required this.artists,
    required this.onSeeAll,
  });

  final String title;
  final List<ArtistSummary> artists;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => _Shelf(
    title: title,
    count: artists.length,
    onSeeAll: onSeeAll,
    card: (i) => ArtistCard(artist: artists[i]),
  );
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.count,
    required this.onSeeAll,
    required this.card,
  });

  final String title;
  final int count;
  final VoidCallback onSeeAll;
  final Widget Function(int index) card;

  @override
  Widget build(BuildContext context) {
    final width = FormFactor.of(context) == FormFactor.desktop ? 160.0 : 140.0;
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x3),
      child: KShelf(
        title: title,
        itemCount: count,
        itemWidth: width,
        height: width + KGridCard.footerExtent(scaler),
        padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
        onSeeAll: onSeeAll,
        itemBuilder: (context, i) => card(i),
      ),
    );
  }
}
