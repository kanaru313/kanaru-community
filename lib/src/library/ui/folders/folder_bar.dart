import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../browse/library_list_frame.dart';
import '../collections/collection_parts.dart';
import 'folder_breadcrumb.dart';
import 'folder_place.dart';
import 'folder_play.dart';
import 'folder_slivers.dart';

/// Play context of a level of the tree view.
PlayContext levelPlayContext(LevelPlace place) =>
    folderPlayContext(place.sourceUid, place.node.key, place.node.name);

/// Play context of a folder opened from the flat list.
PlayContext flatPlayContext(FlatOpenPlace place) => folderPlayContext(
  place.root.folder.sourceUid,
  place.node.key,
  place.node.key.isEmpty ? place.root.node.name : place.node.name,
);

/// Left group of the Folders bar: the breadcrumb (the count in the flat list).

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
      final shown =
          ref
              .watch(
                flatRowsProvider((
                  place: placeKey,
                  sort: input.sort,
                  filter: input.filter,
                )),
              )
              ?.length ??
          0;
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

    return first;
  }
}
