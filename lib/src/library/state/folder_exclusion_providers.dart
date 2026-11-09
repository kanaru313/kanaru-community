import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/folder_exclusion_repository.dart';
import 'scan_providers.dart';

export '../data/folder_exclusion_repository.dart' show FolderExclusions;

final folderExclusionsProvider = Provider<FolderExclusions>(
  (ref) => FolderExclusionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(libraryScanCommandsProvider),
  ),
);
