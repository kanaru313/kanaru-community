import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/playback_views.dart';
import 'playback_providers.dart';

/// Position and duration of the loaded entry; ticks here, never through
/// `nowPlayingProvider`.
final playbackPositionProvider = StreamProvider<PlaybackPosition>(
  (ref) => ref.watch(playerControllerProvider).position,
);
