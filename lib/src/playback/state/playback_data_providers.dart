import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/db_track_title_lookup.dart';
import '../data/play_log_writer.dart';
import '../data/playable_resolver.dart';
import '../data/queue_repository.dart';
import '../domain/playable.dart';
import '../domain/playback_focus.dart';
import '../domain/track_title_lookup.dart';

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

/// Audio focus. The media-controls bridge overrides this; until then every
/// request is granted.
final playbackFocusProvider = Provider<PlaybackFocus>(
  (ref) => const AlwaysFocus(),
);
