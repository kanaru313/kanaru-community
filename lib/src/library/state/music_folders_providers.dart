import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../platform/state/storage_volumes_provider.dart';
import '../data/music_folders_repository.dart';
import '../domain/music_folder.dart';

/// Folders the user added, live, by root. Writing them is the scanner's.
final musicFoldersProvider = StreamProvider<List<MusicFolder>>(
  (ref) => watchMusicFolders(
    ref.watch(appDatabaseProvider),
    ref.watch(storageVolumesProvider),
  ),
);
