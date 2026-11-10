import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/folder_tree.dart';
import '../../domain/music_folder.dart';
import '../../../platform/domain/storage_volumes.dart';
import 'folder_art.dart';

/// Row of a folder: [FolderArt], name (two lines for a chain), a dim line
/// and the counts. Mobile ends the row with a chevron.
class FolderTile extends StatelessWidget {
  const FolderTile({
    super.key,
    required this.title,
    required this.onTap,
    this.dimLine,
    this.countLine,
    this.coverKey,
    this.seed = '',
    this.chain = false,
    this.leading,
  });

  /// Folder name, or a chain's names joined with ` › `.
  final String title;

  /// Folders above (flat view) or the full path (roots with the same name).
  final String? dimLine;
  final String? countLine;
  final String? coverKey;
  final String seed;

  /// A merged chain: the name may take two lines and [dimLine] is dropped.
  final bool chain;

  /// Replaces the folder picture (the root list shows a volume icon).
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return KMediaCard(
      title: title,
      titleLines: chain ? 2 : 1,
      line2: dimLine,
      line3: countLine,
      leading: leading ?? FolderArt(coverKey: coverKey, seed: seed),
      trailing: mobile ? const Icon(KIcons.chevronRight) : null,
      onTap: onTap,
    );
  }
}

/// Icon of a music folder in the root list.
class RootIcon extends StatelessWidget {
  const RootIcon({super.key, required this.volume});

  final StorageVolume volume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox.square(
        dimension: FolderArt.size,
        child: Icon(
          volume.kind == StorageVolumeKind.sdCard
              ? KIcons.sdCard
              : KIcons.folders,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Where a music folder lives, for the second line of the root list and the
/// breadcrumb. The mobile shell names the volume ("Internal storage", "SD
/// card"); the desktop shell shows the path with the home folder as `~`.
String folderLocationLabel(
  AppLocalizations l10n,
  MusicFolder folder, {
  required bool mobile,
}) {
  final volume = folder.volume;
  if (mobile) {
    switch (volume.kind) {
      case StorageVolumeKind.internal:
        return l10n.libraryVolumeInternal;
      case StorageVolumeKind.sdCard:
        return l10n.libraryVolumeSdCard;
      case StorageVolumeKind.usb:
        return l10n.libraryVolumeUsb;
      case StorageVolumeKind.home:
      case StorageVolumeKind.other:
        break;
    }
  }
  return _pathLabel(folder.root, volume);
}

/// The path of [root] with the home folder shortened to `~`.
String _pathLabel(String root, StorageVolume volume) {
  if (volume.kind != StorageVolumeKind.home) return root;
  final rest = root.substring(volume.root.length);
  return '~$rest';
}

/// `N songs · M folders` of a folder node.
String folderCounts(AppLocalizations l10n, FolderNode node) =>
    l10n.libraryFolderCounts(node.deepSongs, node.subfolders);
