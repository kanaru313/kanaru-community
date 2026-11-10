import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../foundation/text/text_fold.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import '../collections/collection_parts.dart';
import '../songs/song_list.dart';
import 'folder_back.dart';
import 'folder_bar.dart';
import 'folder_locations.dart';
import 'folder_place.dart';
import 'folder_slivers.dart';
import 'folder_tile.dart';

/// The Folders list: levels of the music folders one at a time, or every
/// folder that holds songs in a flat list.
///
/// [location] is read from the URL. Moving between levels replaces the page,
/// so a Folders page pushed from elsewhere keeps the page below it, and Back
/// climbs one level at a time. [entry] is the level the page was opened at; it
/// rides through every replace as the route's `extra`.
class FoldersPage extends ConsumerWidget {
  const FoldersPage({super.key, required this.location, required this.entry});

  final FolderLocation location;
  final FolderLocation entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(
      libraryListViewsProvider.select((v) => v.folderView),
    );
    final compact = ref.watch(compactFoldersProvider);
    final key = (location: location, view: view, compact: compact);
    void open(FolderLocation to) => moveToFolder(context, to, entry: entry);
    return LibraryListScaffold(
      tab: LibraryTab.folders,
      child: LibraryListFrame(
        list: BrowseList.folders,
        filterHint: l10n.libraryFilterFoldersHint,
        builder: (context, input) => (
          leading: FoldersBarLeading(placeKey: key, input: input, open: open),
          body: _FoldersBody(
            placeKey: key,
            input: input,
            entry: entry,
            open: open,
          ),
        ),
      ),
    );
  }
}

class _FoldersBody extends ConsumerWidget {
  const _FoldersBody({
    required this.placeKey,
    required this.input,
    required this.entry,
    required this.open,
  });

  final FolderPlaceKey placeKey;
  final LibraryListInput input;
  final FolderLocation entry;
  final FolderNavigator open;

  static const Widget _bottom = SliverToBoxAdapter(child: KGap(KSpace.x4));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return collectionBody<FolderPlace>(
      context,
      ref.watch(folderPlaceProvider(placeKey)).whenData((p) => [p]),
      (places) {
        final place = places.single;
        return FolderBackGuard(
          parent: place.parent,
          entry: entry,
          current: placeKey.location,
          filterOpen: input.filterOpen,
          child: _content(context, place),
        );
      },
    );
  }

  /// Play and shuffle as a row under the bar, on the mobile shell only.
  Widget? _playRow(BuildContext context, FolderPlace place) {
    final target = folderPlayTarget(place);
    if (target == null || FormFactor.of(context) != FormFactor.mobile) {
      return null;
    }
    return SliverToBoxAdapter(child: FolderPlayRow(target: target));
  }

  Widget _content(BuildContext context, FolderPlace place) {
    final l10n = AppLocalizations.of(context);
    switch (place) {
      case NoFoldersPlace():
        return const SizedBox.shrink();
      case RootsPlace(:final roots):
        final shown = [
          for (final r in roots)
            if (foldedContains(r.node.name, input.filter)) r,
        ];
        return CustomScrollView(
          slivers: [rootsSliver(context, shown, open), _bottom],
        );
      case FlatListPlace(:final folders):
        return CustomScrollView(
          slivers: [
            flatFoldersSliver(
              context,
              flatRows(folders, sort: input.sort, filter: input.filter),
              open,
            ),
            _bottom,
          ],
        );
      case LevelPlace():
        final rows = levelRows(
          place.node,
          compact: placeKey.compact,
          sort: input.sort,
          filter: input.filter,
        );
        final scope = SongScope.folder(
          place.root.folder.sourceId,
          place.node.key,
          direct: true,
        );
        return SongList(
          // A new level starts at the top, with its own rows.
          key: ValueKey('level ${place.sourceUid}:${place.node.key}'),
          scope: scope,
          sort: folderSongSort,
          filter: input.filter,
          playContext: levelPlayContext(place),
          leadingSlivers: [
            ?_playRow(context, place),
            levelFoldersSliver(context, place, rows, open),
            if (place.node.directSongs > 0)
              SliverToBoxAdapter(
                child: FolderSongsHeader(
                  scope: scope,
                  filter: input.filter,
                  direct: false,
                ),
              ),
          ],
        );
      case FlatOpenPlace(:final root, :final node):
        final scope = SongScope.folder(
          root.folder.sourceId,
          node.key,
          direct: true,
        );
        final path = folderLocationLabel(l10n, root.folder, mobile: false);
        return SongList(
          key: ValueKey('flat ${root.folder.sourceUid}:${node.key}'),
          scope: scope,
          sort: folderSongSort,
          filter: input.filter,
          playContext: flatPlayContext(place),
          leadingSlivers: [
            ?_playRow(context, place),
            SliverToBoxAdapter(
              child: FolderSongsHeader(
                scope: scope,
                filter: input.filter,
                direct: true,
                pathLine: node.key.isEmpty ? path : '$path/${node.key}',
              ),
            ),
          ],
        );
    }
  }
}
