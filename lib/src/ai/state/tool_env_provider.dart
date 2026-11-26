import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/state/history/history_providers.dart';
import '../../library/state/playlists/playlist_providers.dart';
import '../../library/state/track_search_provider.dart';
import '../../lyrics/state/stored_track_lyrics_provider.dart';
import '../../lyrics/state/track_lyrics_providers.dart';
import '../../playback/state/playback_position_provider.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/playback_settings_providers.dart';
import '../../playback/state/queue_view_provider.dart';
import '../../playback/state/track_info_providers.dart';
import '../data/tool_env_impl.dart';
import '../data/tool_env_player.dart';
import '../data/tool_env_write.dart';
import '../domain/tools/tool_env.dart';

/// How the session builds its tool env; tests override it with fakes.
final toolEnvFactoryProvider = Provider<ToolEnv Function(Ref ref)>(
  (ref) => buildToolEnv,
);

/// The ports the assistant's tools use, wired on the live app state.
///
/// A plain function, not a provider: a provider value would keep its `ref`
/// in the port closures and fail after the provider rebuilt. The chat session
/// calls this each time it needs the env, with its own long-lived `ref`, and
/// every dependency is read at that moment (`read`, never `watch`).
///
/// `playContextLabel` (a localized string) and `turnUsage` (read from the
/// conversation's transcript) are set by the caller with `ToolEnv.copyWith`;
/// the defaults here are English text and "nothing used".
ToolEnv buildToolEnv(Ref ref) {
  final lookup = ref.read(trackLookupProvider);
  return ToolEnv(
    library: LibraryPortImpl(
      trackSearch: ref.read(trackSearchProvider),
      trackLookup: lookup,
      trackInfo: (id) => ref.read(trackInfoProvider(id).future),
    ),
    playback: PlaybackPortImpl(
      readNowPlaying: () => ref.read(nowPlayingProvider.future),
      readPosition: () => ref.read(playbackPositionProvider.future),
      readQueue: () => ref.read(queueViewProvider.future),
    ),
    lyrics: LyricsPortImpl((id) async {
      // Read the local lyrics first so the stored state is not still loading.
      await ref.read(localLyricsReadProvider(id).future);
      return ref.read(storedTrackLyricsProvider(id));
    }),
    history: HistoryPortImpl(
      store: ref.read(historyStoreProvider),
      lookup: lookup,
      enabled: () async => ref.read(historyEnabledProvider),
    ),
    playlists: PlaylistsPortImpl(
      store: ref.read(playlistStoreProvider),
      lookup: lookup,
    ),
    playbackWrite: PlaybackWritePortImpl(
      playTracks: (visible, {required contextLabel, startIndex = 0}) => ref
          .read(playerControllerProvider)
          .playTracksForTool(
            visible,
            contextLabel: contextLabel,
            startIndex: startIndex,
          ),
      playNext: (tracks) => ref.read(playbackCommandsProvider).playNext(tracks),
      enqueue: (tracks) => ref.read(playbackCommandsProvider).enqueue(tracks),
      removeQueueEntries: (ids) =>
          ref.read(playerControllerProvider).removeEntriesForTool(ids),
      queueIsEmpty: () =>
          ref.read(playerControllerProvider).queueState.items.isEmpty,
    ),
    playlistsWrite: PlaylistsWritePortImpl(
      store: ref.read(playlistStoreProvider),
    ),
  );
}
