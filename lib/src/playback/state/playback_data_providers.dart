import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../database/state/database_providers.dart';
import '../../media/domain/cover_files.dart';
import '../../platform/state/media_controls_provider.dart';
import '../../platform/state/platform_providers.dart';
import '../data/track_info_rows.dart';
import '../data/db_track_title_lookup.dart';
import '../data/play_log_writer.dart';
import '../data/playable_resolver.dart';
import '../data/queue_repository.dart';
import '../domain/playable.dart';
import '../domain/playback_focus.dart';
import '../domain/track_title_lookup.dart';
import 'media_session_bridge.dart';

/// Data-layer pieces of the player. They read the database provider, which a
/// bare container does not have: reading them there throws inside Riverpod.
final queueRepositoryProvider = Provider<QueueRepository>(
  (ref) => QueueRepository(ref.watch(appDatabaseProvider)),
);

final playableResolverProvider = Provider<PlayableResolver>(
  (ref) => LocalPlayableResolver(ref.watch(appDatabaseProvider)),
);

final playLogWriterProvider = Provider<PlayLogWriter>(
  (ref) => PlayLogWriter(ref.watch(appDatabaseProvider)),
);

final trackTitleLookupProvider = Provider<TrackTitleLookup>(
  (ref) => DbTrackTitleLookup(ref.watch(appDatabaseProvider)),
);

/// The link between the player and the system media controls. It reads the
/// database and the cache folder only when it builds an item, so a container
/// without them (a bare test) can still create it.
final mediaSessionBridgeProvider = Provider<MediaSessionBridge>((ref) {
  final bridge = MediaSessionBridge(
    controls: ref.read(mediaControlsProvider),
    infoOf: (id) async =>
        (await loadTrackInfos(ref.read(appDatabaseProvider), [id])).firstOrNull,
    artPathOf: (key) {
      final path = p.join(
        ref.read(appPathsProvider).cacheDir.path,
        coverRelativePath(key, CoverSize.full),
      );
      return File(path).existsSync() ? path : null;
    },
    startOnRestore: Platform.isLinux,
  );
  ref.onDispose(bridge.dispose);
  return bridge;
});

/// Audio focus: the media-controls bridge asks the system (Android) or
/// grants (Linux). A test overrides it.
final playbackFocusProvider = Provider<PlaybackFocus>(
  (ref) => ref.watch(mediaSessionBridgeProvider),
);
