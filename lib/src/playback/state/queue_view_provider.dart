import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/playback_notice.dart';
import '../domain/playback_views.dart';
import 'playback_providers.dart';

/// The queue in play order, from memory.
final queueViewProvider = StreamProvider<QueueView>(
  (ref) => ref.watch(playerControllerProvider).queueView,
);

/// One-off messages (skips, failures, end of queue).
final playbackNoticesProvider = StreamProvider<PlaybackNotice>(
  (ref) => ref.watch(playerControllerProvider).notices,
);
