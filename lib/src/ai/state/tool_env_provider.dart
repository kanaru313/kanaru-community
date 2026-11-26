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

/// The ports the assistant's tools use, wired on the live app state.
///
/// `playContextLabel` (a localized string) and `turnUsage` (read from the
/// conversation's transcript) are set by the chat session with
/// `ToolEnv.copyWith`; the defaults here are English text and "nothing used".
final toolEnvProvider = Provider<ToolEnv>((ref) {
  final lookup = ref.watch(trackLookupProvider);
  return ToolEnv(
    library: LibraryPortImpl(
      trackSearch: ref.watch(trackSearchProvider),
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
      store: ref.watch(historyStoreProvider),
      lookup: lookup,
      enabled: () async => ref.read(historyEnabledProvider),
    ),
    playlists: PlaylistsPortImpl(
      store: ref.watch(playlistStoreProvider),
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
      store: ref.watch(playlistStoreProvider),
    ),
  );
});
