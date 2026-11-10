import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../../platform/state/media_permissions_provider.dart';
import '../../../platform/state/storage_volumes_provider.dart';
import '../../data/scan/directory_check.dart';
import '../../data/scan/exclusion_entries.dart';
import '../folder_exclusion_providers.dart';
import 'music_folder_editor.dart';
import 'scan_settings.dart';

/// Counts edits to music folders and exclusions, so lists derived from the
/// platform (candidates, the estimate) refresh after each one.
class FolderEdits extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final folderEditsProvider = NotifierProvider<FolderEdits, int>(FolderEdits.new);

/// The editor behind the first-run screen and, later, Settings. It lives for
/// the app; it reads its ports when built and holds no widget reference.
final musicFolderEditorProvider = Provider<MusicFolderEditor>((ref) {
  return MusicFolderEditor(
    db: ref.watch(appDatabaseProvider),
    catalog: ref.watch(localAudioCatalogProvider),
    permissions: ref.watch(mediaPermissionsProvider),
    volumes: ref.watch(storageVolumesProvider),
    exclusions: ref.watch(folderExclusionsProvider),
    defaultsApplied: () => ref.read(setupDefaultsAppliedProvider),
    markDefaultsApplied: () =>
        ref.read(setupDefaultsAppliedProvider.notifier).set(true),
    onChanged: () => ref.read(folderEditsProvider.notifier).bump(),
    isDirectory: directoryExists,
  );
});

/// Live exclusions of all chosen music folders.
final exclusionEntriesProvider = StreamProvider<List<ExclusionEntry>>(
  (ref) => watchExclusionEntries(ref.watch(appDatabaseProvider)),
);
