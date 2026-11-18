import 'dart:math' as math;

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_ids.dart';
import '../../library_locations.dart';
import '../../detail/detail_header.dart';

/// Shortest an empty or no-match state is drawn, so it never collapses under
/// the hero on a short phone (it scrolls with the page).
const double _minStateHeight = 320;

/// The playlist page waiting for its first answer, or one whose query failed.
/// An ordinary playlist is a child page: [DetailPending]. Favorites is also a
/// sidebar item, so on desktop ([showBack] false) it keeps a root header
/// while it waits, as it does once loaded.
class PlaylistPending extends StatelessWidget {
  const PlaylistPending({
    super.key,
    required this.showBack,
    this.failed = false,
  });

  final bool showBack;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (showBack) {
      return DetailPending(
        fallback: LibraryLocations.playlists,
        failed: failed,
      );
    }
    return DetailFrame(
      title: '',
      fallback: LibraryLocations.playlists,
      showBack: false,
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
}

/// A playlist that no longer exists (a stale link, a deleted one).
class PlaylistNotFound extends StatelessWidget {
  const PlaylistNotFound({super.key, required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DetailFrame(
      title: l10n.libraryNotFoundTitle,
      titleInContent: false,
      fallback: LibraryLocations.playlists,
      showBack: showBack,
      child: KEmpty(
        icon: KIcons.help,
        title: l10n.playlistNotFoundTitle,
        message: l10n.playlistNotFoundMessage,
      ),
    );
  }
}

/// A state drawn in the room the list leaves (at least [_minStateHeight]).
class PlaylistStateSliver extends StatelessWidget {
  const PlaylistStateSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, sliver) => SliverToBoxAdapter(
      child: SizedBox(
        height: math.max(sliver.remainingPaintExtent, _minStateHeight),
        child: child,
      ),
    ),
  );
}

/// The playlist has no entry: no list bar, no edit toggle.
class PlaylistEmptyState extends StatelessWidget {
  const PlaylistEmptyState({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = uid == PlaylistUids.favorites;
    return PlaylistStateSliver(
      child: KEmpty(
        icon: favorites ? KIcons.heart : KIcons.playlists,
        title: favorites
            ? l10n.playlistFavoritesEmptyTitle
            : l10n.playlistEmptyTitle,
        message: favorites
            ? l10n.playlistFavoritesEmptyMessage
            : l10n.playlistEmptyMessage,
      ),
    );
  }
}

/// The filter matches no entry.
class PlaylistNoMatchState extends StatelessWidget {
  const PlaylistNoMatchState({super.key});

  @override
  Widget build(BuildContext context) => PlaylistStateSliver(
    child: KEmpty(
      icon: KIcons.search,
      message: AppLocalizations.of(context).playlistFilterSongsNoMatch,
    ),
  );
}
