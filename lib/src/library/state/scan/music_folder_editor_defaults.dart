import 'package:logging/logging.dart';

import '../../../platform/domain/media_permissions.dart';
import '../../data/scan/scan_folders.dart';
import '../../domain/music_folder.dart';
import '../../domain/scan/folder_paths.dart';
import '../../domain/scan/root_rules.dart';
import 'music_folder_editor.dart';

final _log = Logger('library.folders');

/// Subfolders of a default music folder that are excluded at first run.
const Set<String> _defaultExclusions = {'ringtones', 'notifications', 'alarms'};

extension MusicFolderDefaults on MusicFolderEditor {
  /// First-run defaults, once: the system music folder, and on Android the
  /// ringtone, notification and alarm folders inside it as exclusions. Only
  /// when audio may be read and no folder is chosen yet; the "applied" flag
  /// is set before anything is written, so removing the folder later does
  /// not bring it back.
  Future<void> applyFirstRunDefaults() async {
    try {
      if (defaultsApplied()) return;
      final state = await permissions.status();
      if (state.applies && state.audio != MediaPermissionStatus.granted) {
        return;
      }
      await markDefaultsApplied();
      if ((await liveScanFolders(db)).isNotEmpty) return;
      final suggestion = await catalog.suggestedMusicFolder();
      if (suggestion == null) return;
      final added = await addFolder(suggestion, fromCatalog: isAndroid);
      if (added is! FolderAdded || !isAndroid) return;
      final folders = await liveScanFolders(db);
      final base = normalizeRootPath(suggestion);
      final target = folders.where((f) => f.root == base).firstOrNull;
      if (target == null) return;
      final folder = MusicFolder(
        sourceId: target.sourceId,
        sourceUid: target.sourceUid,
        root: target.root,
        volume: volumes.volumeOf(target.root),
        name: folderBaseName(target.root),
      );
      for (final candidate in await catalog.audioFolders()) {
        final path = normalizeRootPath(candidate.path);
        if (folderParentPath(path) == base &&
            _defaultExclusions.contains(folderBaseName(path).toLowerCase())) {
          await excludeFolder(folder, path, fromCatalog: true);
        }
      }
    } on Object catch (e, st) {
      _log.warning('first-run defaults failed', e, st);
    }
  }
}
