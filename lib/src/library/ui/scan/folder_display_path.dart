import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/domain/storage_volumes.dart';

/// The words used for volumes in a displayed path.
class VolumeLabels {
  const VolumeLabels({
    required this.internal,
    required this.sdCard,
    required this.usb,
  });

  VolumeLabels.of(AppLocalizations l10n)
    : internal = l10n.scanVolumeInternal,
      sdCard = l10n.scanVolumeSdCard,
      usb = l10n.scanVolumeUsb;

  final String internal, sdCard, usb;
}

/// How a folder path is shown: `Internal storage › Music › Rock` on
/// Android, `~/Music/Rock` below the home folder on Linux, the plain path
/// elsewhere. [volume] is the volume that holds [path].
String folderDisplayPath(
  String path,
  StorageVolume volume,
  VolumeLabels labels,
) {
  final root = volume.root.endsWith('/') && volume.root.length > 1
      ? volume.root.substring(0, volume.root.length - 1)
      : volume.root;
  final inside = path == root || (root != '/' && path.startsWith('$root/'));
  if (!inside || volume.kind == StorageVolumeKind.other) return path;
  final rest = path == root ? '' : path.substring(root.length + 1);
  if (volume.kind == StorageVolumeKind.home) {
    return rest.isEmpty ? '~' : '~/$rest';
  }
  final label = switch (volume.kind) {
    StorageVolumeKind.internal => labels.internal,
    StorageVolumeKind.sdCard => labels.sdCard,
    StorageVolumeKind.usb => labels.usb,
    _ => '',
  };
  final segments = rest.isEmpty ? const <String>[] : rest.split('/');
  return [label, ...segments].join(' › ');
}

/// [folderDisplayPath] for the volume [volumes] reports for [path].
String folderDisplayPathOf(
  AppLocalizations l10n,
  StorageVolumes volumes,
  String path,
) => folderDisplayPath(path, volumes.volumeOf(path), VolumeLabels.of(l10n));
