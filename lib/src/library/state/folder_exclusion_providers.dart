import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/folder_exclusion_repository.dart';
import '../domain/folder_exclusions.dart';
import 'scan_providers.dart';

export '../domain/folder_exclusions.dart' show FolderExclusions;

final folderExclusionsProvider = Provider<FolderExclusions>(
  (ref) => FolderExclusionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(libraryScanCommandsProvider),
  ),
);
