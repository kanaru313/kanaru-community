import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/library_view_toggle.dart';
import '../browse/play_actions.dart';
import '../collections/collection_parts.dart';
import 'folder_breadcrumb.dart';
import 'folder_locations.dart';
import 'folder_place.dart';
import 'folder_slivers.dart';

/// Play context of a level of the tree view.
PlayContext levelPlayContext(LevelPlace place) => PlayContext(
  PlayContextKind.folder,
  ref: '${place.sourceUid}:${place.node.key}',
  label: place.node.name,
);

/// Play context of a folder opened from the flat list.
PlayContext flatPlayContext(FlatOpenPlace place) => PlayContext(
  PlayContextKind.folder,
  ref: '${place.root.folder.sourceUid}:${place.node.key}',
  label: place.node.key.isEmpty ? place.root.node.name : place.node.name,
);

/// What the play buttons of a folder page play: the songs below a tree level,
/// the direct songs of a folder opened from the flat list. Null elsewhere.
({SongScope scope, PlayContext context})? folderPlayTarget(FolderPlace place) =>
    switch (place) {
      LevelPlace() => (
        scope: SongScope.folder(place.root.folder.sourceId, place.node.key),
        context: levelPlayContext(place),
      ),
      FlatOpenPlace() => (
        scope: SongScope.folder(
          place.root.folder.sourceId,
          place.node.key,
          direct: true,
        ),
        context: flatPlayContext(place),
      ),
      _ => null,
    };

/// Shuffle and play of a folder page: icon buttons in the list bar (desktop),
/// labelled buttons in [FolderPlayRow] (mobile).
class FolderPlayButtons extends ConsumerWidget {
  const FolderPlayButtons({
    super.key,
    required this.target,
    this.labelled = false,
  });

  final ({SongScope scope, PlayContext context}) target;
  final bool labelled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void shuffle() => shuffleScope(
      ref,
      context,
      target.scope,
      BrowseList.songs,
      target.context,
    );
    void play() =>
        playScope(ref, context, target.scope, BrowseList.songs, target.context);
    if (labelled) {
      return Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: play,
            icon: const Icon(KIcons.play),
            label: Text(l10n.libraryPlayAll),
          ),
          const KGap(KSpace.x2),
          OutlinedButton.icon(
            onPressed: shuffle,
            icon: const Icon(KIcons.shuffle),
            label: Text(l10n.libraryShuffle),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.libraryShuffle,
          onPressed: shuffle,
          icon: const Icon(KIcons.shuffle),
        ),
        IconButton.filledTonal(
          tooltip: l10n.libraryPlayAll,
          onPressed: play,
          icon: const Icon(KIcons.play),
        ),
      ],
    );
  }
}

/// Play and shuffle under the bar on the mobile shell, where the bar has no
/// room for them next to the breadcrumb.
class FolderPlayRow extends StatelessWidget {
  const FolderPlayRow({super.key, required this.target});

  final ({SongScope scope, PlayContext context}) target;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      libraryGutter(context),
      0,
      libraryGutter(context),
      KSpace.x2,
    ),
    child: FolderPlayButtons(target: target, labelled: true),
  );
}

/// Left group of the Folders bar: the breadcrumb (the count in the flat list),
/// the tree / flat switch, and for a level (desktop) shuffle and play.
class FoldersBarLeading extends ConsumerWidget {
  const FoldersBarLeading({
    super.key,
    required this.placeKey,
    required this.input,
    required this.open,
  });

  final FolderPlaceKey placeKey;
  final LibraryListInput input;
  final FolderNavigator open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final place = ref.watch(folderPlaceProvider(placeKey)).value;
    if (place == null || place is NoFoldersPlace) {
      return const SizedBox.shrink();
    }

    final Widget first;
    if (place is FlatListPlace) {
      final shown = flatRows(
        place.folders,
        sort: input.sort,
        filter: input.filter,
      ).length;
      first = Text(
        collectionCountText(
          shown: shown,
          total: place.folders.length,
          filtering: input.filter.isNotEmpty,
          plain: l10n.libraryFolderCount,
          unit: l10n.libraryUnitFolders,
          l10n: l10n,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    } else {
      first = FolderBreadcrumb(
        segments: folderSegments(l10n, place, mobile: mobile, jump: open),
      );
    }

    // The mobile shell has no room for them here: see FolderPlayRow.
    final target = mobile ? null : folderPlayTarget(place);

    return Row(
      children: [
        Flexible(child: first),
        const KGap(KSpace.x1),
        LibraryViewToggle<FolderView>(
          value: place is FlatListPlace || place is FlatOpenPlace
              ? FolderView.flat
              : FolderView.tree,
          options: [
            ViewOption(FolderView.tree, KIcons.tree, l10n.libraryViewTree),
            ViewOption(FolderView.flat, KIcons.flatList, l10n.libraryViewFlat),
          ],
          onChanged: (view) async {
            await ref
                .read(libraryListViewsProvider.notifier)
                .setFolderView(view);
            if (context.mounted) open(FolderLocation.top);
          },
        ),
        if (target != null) FolderPlayButtons(target: target),
      ],
    );
  }
}
