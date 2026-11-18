import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../browse/play_shuffle_buttons.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../../state/browse/shelf_block_providers.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/play_actions.dart';
import '../collections/album_tile.dart';
import '../collections/artist_tile.dart';
import '../menus/menu_origin.dart';
import '../menus/more_button.dart';
import 'detail_tint.dart';

/// Frame of a detail page: a header with a back button (no root slots, no ⋮)
/// and the page below it. Back pops one page; a page opened as the first one
/// (a link from outside) goes to [fallback] instead.
///
/// With [titleInContent] (the default) the page [title] is shown in the page
/// content; the header shows it again only while it is scrolled out of sight.
/// Without it the header always shows the [title].
///
/// The frame has its own solid ground: the detail layouts paint over a
/// translucent tint, and the page under would show through while this one
/// slides in.
///
/// A non-null [tint] washes the whole page, header band included, with the
/// colours of the cover the page shows (see [watchDetailTint]); null leaves
/// the page untinted.
class DetailFrame extends StatelessWidget {
  const DetailFrame({
    super.key,
    required this.title,
    required this.fallback,
    required this.child,
    this.tint,
    this.titleInContent = true,
    this.actions = const [],
    this.showBack = true,
  });

  final String title;
  final String fallback;
  final Widget child;
  final DetailTint? tint;
  final bool titleInContent;

  /// Header buttons before the scope's trailing ones (an edit toggle, a
  /// search).
  final List<Widget> actions;

  /// False drops the `[←]`: a page that is also a sidebar item (Favorites on
  /// desktop). The header becomes a root header, so the enclosing
  /// `PageHeaderScope`'s `leading` and `rootTrailing` show: none on the
  /// desktop shell, but ☰ and ⚙ on the mobile shell. Pass it on desktop only.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final page = Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
          child: PageHeader(
            title: title,
            titleInContent: titleInContent,
            actions: actions,
            onBack: showBack ? () => _back(context) : null,
          ),
        ),
        Expanded(child: KScrollInkSurface(child: child)),
      ],
    );
    final hosted = KDetailTitleHost(child: page);
    final t = tint;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: t == null
          ? hosted
          : CoverTintBackground(
              palette: t.palette,
              loading: t.loading,
              strength: _tintStrength,
              fadeIn: true,
              child: hosted,
            ),
    );
  }

  /// Half the tint of the player surfaces: a page is read for a long time.
  static const double _tintStrength = 0.5;

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
      titleInContent: false,
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
class DetailActions extends ConsumerWidget {
  const DetailActions({
    super.key,
    required this.scope,
    required this.list,
    required this.item,
    required this.playContext,
    required this.onMenu,
  });

  /// The songs Play and shuffle take.
  final SongScope scope;
  final BrowseList list;

  /// Id of the page's item, which keys its sort.
  final String item;
  final PlayContext playContext;

  /// Opens the page's own menu (a centred dialog on desktop, a sheet on the
  /// mobile shell).
  final void Function(BuildContext context, {required bool viaKeyboard}) onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(detailSortProvider((list: list, item: item)));
    final ids = ref
        .watch(songIdsProvider((scope: scope, sort: sort, filter: '')))
        .value;
    final enabled = ids != null && ids.isNotEmpty;
    return PlayShuffleButtons(
      compact: false,
      labelled: true,
      playLabel: l10n.libraryPlay,
      onPlay: enabled ? () => playAll(ref, context, ids, playContext) : null,
      onShuffle: enabled
          ? () => shuffleAll(ref, context, ids, playContext)
          : null,
      trailing: [
        LibraryMoreButton(
          large: true,
          onPressed: ({required viaKeyboard}) =>
              onMenu(context, viaKeyboard: viaKeyboard),
        ),
      ],
    );
  }
}

/// Number of cards a genre or language shelf shows on this shell.
int shelfCap(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? 8 : 10;

/// Collapsible block of album cards; the grid button opens [onSeeAll].
/// [kind] (a [ShelfBlockKind]) keys the remembered collapsed state; [total]
/// is the number shown on the head when [albums] is only the first cards.
class AlbumShelf extends StatelessWidget {
  const AlbumShelf({
    super.key,
    required this.title,
    required this.kind,
    required this.albums,
    required this.onSeeAll,
    this.icon = KIcons.album,
    this.total,
    this.origin = const MenuOrigin.list(),
  });

  final String title;
  final String kind;
  final IconData icon;
  final List<AlbumSummary> albums;
  final int? total;
  final VoidCallback onSeeAll;

  /// The page the shelf is on, so a card's menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context) => _Shelf(
    title: title,
    kind: kind,
    icon: icon,
    total: total ?? albums.length,
    count: albums.length,
    onSeeAll: onSeeAll,
    card: (i) => AlbumCard(album: albums[i], origin: origin),
  );
}

/// Collapsible block of artist cards; the grid button opens [onSeeAll].
class ArtistShelf extends StatelessWidget {
  const ArtistShelf({
    super.key,
    required this.title,
    required this.artists,
    required this.onSeeAll,
    this.kind = ShelfBlockKind.artists,
    this.icon = KIcons.artists,
    this.total,
  });

  final String title;
  final String kind;
  final IconData icon;
  final List<ArtistSummary> artists;
  final int? total;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => _Shelf(
    title: title,
    kind: kind,
    icon: icon,
    total: total ?? artists.length,
    count: artists.length,
    onSeeAll: onSeeAll,
    card: (i) => ArtistCard(artist: artists[i]),
  );
}

class _Shelf extends ConsumerWidget {
  const _Shelf({
    required this.title,
    required this.kind,
    required this.icon,
    required this.total,
    required this.count,
    required this.onSeeAll,
    required this.card,
  });

  final String title;
  final String kind;
  final IconData icon;

  /// Number on the head; [count] is how many cards the row builds.
  final int total;
  final int count;
  final VoidCallback onSeeAll;
  final Widget Function(int index) card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final width = desktop ? 150.0 : 128.0;
    final scaler = MediaQuery.textScalerOf(context);
    final collapsed = ref.watch(
      shelfBlockCollapsedProvider.select((kinds) => kinds.contains(kind)),
    );
    return KShelfBlock(
      title: title,
      icon: icon,
      count: total,
      collapsed: collapsed,
      onToggle: () =>
          ref.read(shelfBlockCollapsedProvider.notifier).set(kind, !collapsed),
      onSeeAll: onSeeAll,
      seeAllLabel: AppLocalizations.of(context).libraryShelfSeeAll,
      itemCount: count,
      itemWidth: width,
      height: width + KGridCard.footerExtent(scaler),
      // Desktop: same side inset as the song rows below (card edges line up
      // with the row cards). Mobile rows are flat full-width; the block keeps
      // the page gutter there, as the mockup shows.
      margin: EdgeInsets.only(
        left: desktop ? libraryRowGutter(context) : libraryGutter(context),
        right: desktop ? libraryRowGutter(context) : libraryGutter(context),
        bottom: KSpace.x3,
      ),
      itemBuilder: (context, i) => card(i),
    );
  }
}
