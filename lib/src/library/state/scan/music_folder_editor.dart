import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../platform/domain/storage_volumes.dart';
import '../../data/scan/music_folder_writer.dart';
import '../../data/scan/scan_folders.dart';
import '../../domain/folder_exclusions.dart';
import '../../domain/music_folder.dart';
import '../../domain/scan/folder_edit_results.dart';
import '../../domain/scan/folder_paths.dart';
import '../../domain/scan/root_rules.dart';

export '../../domain/scan/folder_edit_results.dart';

final _log = Logger('library.folders');

/// Adds and removes music folders and their exclusions. Every outcome is a
/// value; nothing here throws to the caller.
class MusicFolderEditor {
  MusicFolderEditor({
    required this.db,
    required this.catalog,
    required this.permissions,
    required this.volumes,
    required this.exclusions,
    required this.defaultsApplied,
    required this.markDefaultsApplied,
    required this.onChanged,
    required this.isDirectory,
    int Function()? now,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase db;
  final LocalAudioCatalog catalog;
  final MediaPermissions permissions;
  final StorageVolumes volumes;
  final FolderExclusions exclusions;

  /// Whether the first-run defaults were applied already.
  final bool Function() defaultsApplied;
  final Future<void> Function() markDefaultsApplied;

  /// Called after every edit that reached the database.
  final void Function() onChanged;
  final int Function() _now;

  /// Whether a path is an existing folder (checked for picked paths only).
  final Future<bool> Function(String path) isDirectory;

  /// The platform picks folders from a MediaStore list (Android).
  bool get isAndroid => catalog.folderChoice == FolderChoice.mediaStoreSheet;

  /// Adds [path] as a music folder. [fromCatalog] is true for a path the
  /// catalog itself listed (Android MediaStore folders): it is only
  /// normalised, because it is already in the form MediaStore stores.
  Future<AddFolderResult> addFolder(
    String path, {
    bool fromCatalog = false,
  }) async {
    try {
      final normal = normalizeRootPath(path.trim());
      final root = fromCatalog ? normal : await catalog.canonicalize(normal);
      final live = [for (final f in await liveScanFolders(db)) f.root];
      switch (checkNewRoot(root, live)) {
        case RootTooBroad():
          return const FolderTooBroad();
        case RootInsideExisting(root: final existing):
          return normalizeRootPath(existing) == normalizeRootPath(root)
              ? const FolderAlreadyChosen()
              : FolderInsideExisting(existing);
        case RootContainsExisting(root: final existing):
          return FolderContainsExisting(existing);
        case RootOk():
          break;
      }
      if (!fromCatalog && !await isDirectory(root)) {
        return const FolderNotADirectory();
      }
      final written = await addLocalSource(
        db,
        root: normalizeRootPath(root),
        name: folderBaseName(normalizeRootPath(root)),
        now: _now(),
      );
      onChanged();
      return switch (written) {
        SourceWrite.alreadyLive => const FolderAlreadyChosen(),
        SourceWrite.added => const FolderAdded(revived: false),
        SourceWrite.revived => const FolderAdded(revived: true),
      };
    } on Object catch (e, st) {
      _log.warning('adding $path failed', e, st);
      return const FolderWriteFailed();
    }
  }

  /// Removes [folder] and, with it, the exclusions inside it. False when the
  /// write failed.
  Future<bool> removeFolder(MusicFolder folder) async {
    try {
      await removeLocalSource(db, folder.sourceId, _now());
      onChanged();
      return true;
    } on Object catch (e, st) {
      _log.warning('removing ${folder.root} failed', e, st);
      return false;
    }
  }

  /// Excludes [absolutePath], a sub-folder of [folder]. The parent of the
  /// path is canonicalised and the last part joined back (the leaf itself is
  /// not followed), unless [fromCatalog].
  Future<ExcludeFolderResult> excludeFolder(
    MusicFolder folder,
    String absolutePath, {
    bool fromCatalog = false,
  }) async {
    try {
      var path = normalizeRootPath(absolutePath.trim());
      if (!fromCatalog && path.length > 1) {
        final parent = await catalog.canonicalize(folderParentPath(path));
        path = normalizeRootPath('$parent/${folderBaseName(path)}');
      }
      final root = normalizeRootPath(folder.root);
      if (path == root || !isSameOrInside(path, root)) {
        return ExcludeFolderResult.outsideFolder;
      }
      final key = path.substring(root.length + 1);
      final current = await excludedPaths();
      if (current.any((p) => isSameOrInside(path, p))) {
        return ExcludeFolderResult.alreadyExcluded;
      }
      await exclusions.exclude(folder, key, displayPath: path);
      onChanged();
      return ExcludeFolderResult.excluded;
    } on Object catch (e, st) {
      _log.warning('excluding $absolutePath failed', e, st);
      return ExcludeFolderResult.writeFailed;
    }
  }

  /// Excludes [absolutePath] in whichever of [folders] holds it (the deepest
  /// one). [ExcludeFolderResult.outsideFolder] when none does.
  Future<ExcludeFolderResult> excludeInAnyFolder(
    Iterable<MusicFolder> folders,
    String absolutePath, {
    bool fromCatalog = false,
  }) async {
    try {
      var path = normalizeRootPath(absolutePath.trim());
      if (!fromCatalog && path.length > 1) {
        final parent = await catalog.canonicalize(folderParentPath(path));
        path = normalizeRootPath('$parent/${folderBaseName(path)}');
      }
      MusicFolder? best;
      for (final f in folders) {
        final root = normalizeRootPath(f.root);
        if (path != root &&
            isSameOrInside(path, root) &&
            (best == null || root.length > best.root.length)) {
          best = f;
        }
      }
      if (best == null) return ExcludeFolderResult.outsideFolder;
      return await excludeFolder(best, path, fromCatalog: true);
    } on Object catch (e, st) {
      _log.warning('excluding $absolutePath failed', e, st);
      return ExcludeFolderResult.writeFailed;
    }
  }

  /// Undoes an exclusion. False when the write failed.
  Future<bool> includeFolder(MusicFolder folder, String folderKey) async {
    try {
      await exclusions.include(folder, folderKey);
      onChanged();
      return true;
    } on Object catch (e, st) {
      _log.warning('including $folderKey failed', e, st);
      return false;
    }
  }

  /// Absolute paths of every live exclusion.
  Future<List<String>> excludedPaths() async {
    final out = <String>[];
    for (final f in await liveScanFolders(db)) {
      for (final key in await excludedFolderKeys(db, f.sourceId)) {
        out.add(normalizeRootPath('${normalizeRootPath(f.root)}/$key'));
      }
    }
    return out;
  }
}
