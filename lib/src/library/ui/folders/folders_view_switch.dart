import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../browse/library_view_toggle.dart';
import 'folder_locations.dart';
import 'folder_place.dart';
import 'folder_slivers.dart';

/// The tree / flat switch of the Folders bar.
class FoldersViewSwitch extends ConsumerWidget {
  const FoldersViewSwitch({
    super.key,
    required this.placeKey,
    required this.open,
  });

  final FolderPlaceKey placeKey;
  final FolderNavigator open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final place = ref.watch(folderPlaceProvider(placeKey)).value;
    if (place == null || place is NoFoldersPlace) {
      return const SizedBox.shrink();
    }
    return LibraryViewToggle<FolderView>(
      value: place is FlatListPlace || place is FlatOpenPlace
          ? FolderView.flat
          : FolderView.tree,
      options: [
        ViewOption(FolderView.tree, KIcons.tree, l10n.libraryViewTree),
        ViewOption(FolderView.flat, KIcons.flatList, l10n.libraryViewFlat),
      ],
      onChanged: (view) async {
        await ref.read(libraryListViewsProvider.notifier).setFolderView(view);
        if (context.mounted) open(FolderLocation.top);
      },
    );
  }
}
