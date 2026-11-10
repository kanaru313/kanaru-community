import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/state/local_audio_catalog_provider.dart';
import '../data/local_folder_source.dart';

/// Lists music folders through the platform catalog. Tests override the
/// catalog.
final localFolderSourceProvider = Provider<LocalFolderSource>(
  (ref) => LocalFolderSource(ref.watch(localAudioCatalogProvider)),
);
