import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/folder_tree.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../menus/open_menu.dart';
import 'folder_locations.dart';
import 'folder_place.dart';
import 'folder_tile.dart';

/// Moves the page to another level (a replace that keeps the entry level).
typedef FolderNavigator = void Function(FolderLocation to);

/// Sort of the songs listed inside a folder: by title, whatever the sort of
/// the folders above them.
const folderSongSort = SortSpec(SortCriterion.title);

/// Rows of folders (and music folders) as a fixed-extent sliver with the
/// page gutter.
Widget folderRowsSliver(
  BuildContext context, {
  required int count,
  required IndexedWidgetBuilder builder,
}) => SliverPadding(
  padding: EdgeInsets.symmetric(horizontal: libraryGutter(context)),
  sliver: SliverFixedExtentList(
    itemExtent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
    delegate: SliverChildBuilderDelegate(
      builder,
      childCount: count,
      addAutomaticKeepAlives: false,
    ),
  ),
);

/// The sub-folder rows of a level; a tap opens the folder (the end of a
/// merged chain) in place of this level.
Widget levelFoldersSliver(
  BuildContext context,
  LevelPlace place,
  List<FolderRowItem> rows,
  FolderNavigator open,
) {
  final l10n = AppLocalizations.of(context);
  return folderRowsSliver(
    context,
    count: rows.length,
    builder: (context, i) {
      final row = rows[i];
      final target = row.target;
      return FolderTile(
        title: row.label,
        chain: row.chain.length > 1,
        countLine: folderCounts(l10n, target),
        coverKey: row.chain.first.coverKey,
        seed: target.key,
        onMenu: ({bool viaKeyboard = false}) => openFolderMenu(
          context,
          folder: place.root.folder,
          key: target.key,
          name: row.label,
          subfolders: target.subfolders,
          viaKeyboard: viaKeyboard,
        ),
        onTap: () =>
            open(FolderLocation(sourceUid: place.sourceUid, key: target.key)),
      );
    },
  );
}

/// One row per music folder (the top when there are several).
Widget rootsSliver(
  BuildContext context,
  List<FolderRoot> roots,
  FolderNavigator open,
) {
  final l10n = AppLocalizations.of(context);
  final mobile = FormFactor.of(context) == FormFactor.mobile;
  return folderRowsSliver(
    context,
    count: roots.length,
    builder: (context, i) {
      final root = roots[i];
      return FolderTile(
        title: root.node.name,
        dimLine: folderLocationLabel(l10n, root.folder, mobile: mobile),
        countLine: folderCounts(l10n, root.node),
        leading: RootIcon(volume: root.folder.volume),
        onMenu: ({bool viaKeyboard = false}) => openFolderMenu(
          context,
          folder: root.folder,
          key: '',
          name: root.node.name,
          subfolders: root.node.subfolders,
          viaKeyboard: viaKeyboard,
        ),
        onTap: () => open(FolderLocation(sourceUid: root.folder.sourceUid)),
      );
    },
  );
}

/// One row per folder with songs of its own (the flat view): name, the
/// folders above it, its song count.
Widget flatFoldersSliver(
  BuildContext context,
  List<FlatFolder> folders,
  FolderNavigator open,
) {
  final l10n = AppLocalizations.of(context);
  final mobile = FormFactor.of(context) == FormFactor.mobile;
  return folderRowsSliver(
    context,
    count: folders.length,
    builder: (context, i) {
      final folder = folders[i];
      return FolderTile(
        title: folder.node.key.isEmpty ? folder.root.node.name : folder.name,
        dimLine: _ancestorsLine(folder.ancestors, mobile: mobile),
        countLine: l10n.librarySongCount(folder.songCount),
        coverKey: folder.node.directCoverKey,
        seed: folder.node.key,
        onMenu: ({bool viaKeyboard = false}) => openFolderMenu(
          context,
          folder: folder.root.folder,
          key: folder.node.key,
          name: folder.node.key.isEmpty ? folder.root.node.name : folder.name,
          subfolders: 0,
          flat: true,
          viaKeyboard: viaKeyboard,
        ),
        onTap: () => open(
          FolderLocation(
            sourceUid: folder.root.folder.sourceUid,
            key: folder.node.key,
            flat: true,
          ),
        ),
      );
    },
  );
}

/// `Music › Lossless › A`; the mobile shell keeps the first level and the two
/// nearest (`Music › … › Lossless › A`).
String _ancestorsLine(List<String> ancestors, {required bool mobile}) {
  if (mobile && ancestors.length > 3) {
    return [
      ancestors.first,
      '…',
      ...ancestors.sublist(ancestors.length - 2),
    ].join(' › ');
  }
  return ancestors.join(' › ');
}

/// Heading over the songs of a level, with the number of songs shown.
class FolderSongsHeader extends ConsumerWidget {
  const FolderSongsHeader({
    super.key,
    required this.scope,
    required this.filter,
    required this.direct,
    this.pathLine,
  });

  final SongScope scope;
  final String filter;

  /// A level of the flat view: the title says subfolders are not included.
  final bool direct;

  /// Full path of the folder, shown dim above the title.
  final String? pathLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = ref
        .watch(
          songIdsProvider((scope: scope, sort: folderSongSort, filter: filter)),
        )
        .value
        ?.length;
    final title = count == null
        ? ''
        : direct
        ? l10n.libraryFlatSongsHeader(count)
        : l10n.libraryFolderSongsHeader(count);
    final gutter = libraryGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, KSpace.x3, gutter, KSpace.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pathLine != null)
            Text(
              pathLine!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
