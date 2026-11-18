import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/browse/list_view_prefs.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../browse/library_list_scaffold.dart';
import '../../collections/collection_parts.dart';
import 'playlist_card.dart';
import 'playlist_tile.dart';

/// Shortest an empty or no-match state is drawn, so it never collapses under
/// the hub on a short phone (it scrolls with the page).
const double _minStateHeight = 320;

/// The part of the playlists page under the bar: loading / error, the empty
/// state, "no match", or the grid / rows. One sliver.
class PlaylistsListSlivers extends StatelessWidget {
  const PlaylistsListSlivers({
    super.key,
    required this.async,
    required this.shown,
    required this.view,
    required this.onCreate,
    required this.onImport,
  });

  /// The stored playlists (sorted), for loading and error.
  final AsyncValue<List<PlaylistSummary>> async;

  /// [async] after the filter; null while there is no value.
  final List<PlaylistSummary>? shown;

  final CollectionView view;
  final VoidCallback onCreate;

  /// Null while M3U import is not available.
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final items = shown;
    if (items == null || async.hasError) {
      return SliverToBoxAdapter(
        child: collectionBody<PlaylistSummary>(
          context,
          async,
          (_) => const SizedBox.shrink(),
          skeletonRows: view == CollectionView.list,
        ),
      );
    }
    if (async.requireValue.isEmpty) return _state(_empty(context));
    if (items.isEmpty) {
      return _state(
        KEmpty(
          icon: KIcons.search,
          message: AppLocalizations.of(context).playlistFilterNoMatch,
        ),
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    if (view == CollectionView.grid) {
      return KCollectionGrid(
        itemCount: items.length,
        mobileMinTileWidth: 150,
        desktopMinTileWidth: 160,
        footerExtent: KGridCard.footerExtent(scaler),
        padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
        itemBuilder: (context, i) =>
            PlaylistCard(key: ValueKey(items[i].uid), playlist: items[i]),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: libraryRowGutter(context)),
      sliver: SliverFixedExtentList(
        itemExtent: KMediaCard.extentOf(scaler),
        delegate: SliverChildBuilderDelegate(
          (context, i) =>
              PlaylistTile(key: ValueKey(items[i].uid), playlist: items[i]),
          childCount: items.length,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }

  Widget _state(Widget child) => SliverLayoutBuilder(
    builder: (context, sliver) => SliverToBoxAdapter(
      child: SizedBox(
        height: math.max(sliver.remainingPaintExtent, _minStateHeight),
        child: child,
      ),
    ),
  );

  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmpty(
      icon: KIcons.playlists,
      title: l10n.playlistsEmptyTitle,
      message: l10n.playlistsEmptyMessage,
      actions: [
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(KIcons.add, size: KIconSize.sm),
          label: Text(l10n.playlistCreateAction),
        ),
        Tooltip(
          message: onImport == null ? l10n.appComingSoon : '',
          child: OutlinedButton(
            onPressed: onImport,
            child: Text(l10n.playlistImportM3uAction),
          ),
        ),
      ],
    );
  }
}
