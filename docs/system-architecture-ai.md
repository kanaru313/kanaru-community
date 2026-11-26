# AI chat architecture

The `ai` module (`lib/src/ai/`) is the chat engine: conversation data model,
settings, the tools the assistant may call, and the loop that talks to an
`ai-chat` plugin. It sits above `lyrics`, `library`, `playback` and `plugins`
and below `screens` (`architecture.yaml`). Chat screens live in `screens/`;
nothing in `ai/` imports them. `ai/` never reads library tables: every read
and write goes through the public APIs listed in "Tool read sources".

This file grows with each engine part; it describes what has landed.

## Data model (`ai/domain/`)

- `conversation/ai_conversation.dart`, `ai_message.dart`: the conversation and
  message types. Their value sets (`AiPermission`, `AiMessageRole`,
  `AiMessageState`) use the names stored in `ai_conversations.permission` and
  `ai_messages.role` / `state` (`database/tables/ai_tables.dart`); a test keeps
  the two lists equal. `ToolExecState` (running, done, failed, skipped,
  unknown) maps to the stored message states (`failed` is stored as `error`).
- `conversation/parts.dart`, `parts_codec.dart`: a message is a list of parts,
  stored as `{"v":1,"parts":[{"t":"<type>",…}]}` in `parts_json`.
  Types: `text`, `data` (source from the chat contract), `tool_call`
  (parsed `args` or the model's `rawArgs`), `tool_result` (`content` is a
  parts list), `confirm` (pending, allowed, denied, deniedByNewMessage,
  expired), `done` (added, removed, absent ids, replaced queue), `error`
  (contract code and kind only, never provider text), `event` (plugin
  switch), `chip` (nowPlaying, song, songs, album, artist, genre, language,
  playlist).
- A part type this build does not know, or a known type with a damaged
  shape, is an `UnknownPart` and is written back unchanged. A `v` other than
  1 throws `UnsupportedPartsVersion`; text that is not the parts shape throws
  `MalformedParts` (both `AiPartsException`).
- `conversation/track_ref_snapshot.dart`: `{trackId, title, artist, album?}`.
  Tracks are never referenced by foreign key; parts carry snapshots.
- `permission.dart`: `AiPermission { readOnly, ask, auto }`.

## Settings (`ai/domain/settings/`, `ai/data/ai_settings_store.dart`, `ai/state/ai_settings_providers.dart`)

One `Setting<T>` per key (declared in `ai_settings_store.dart`) and one
provider per key (`ai_settings_providers.dart`). `decode` throws
`FormatException` on a value it does not know (the default is used);
`encode` throws `ArgumentError` on a value over its limit.

| Key | Type | Default | Provider |
|---|---|---|---|
| `ai.default_permission` | `AiPermission` | `ask` | `aiDefaultPermissionProvider` |
| `ai.instructions` | string, at most 2000 characters | empty | `aiInstructionsProvider` |
| `ai.tools.<group>` | bool, 11 keys | true | `aiToolGroupProvider(group)` |
| `ai.var_bypass` | bool | false | `aiVarBypassProvider` |
| `ai.auto_ask` | bool (ask before switching to Auto) | true | `aiAutoAskProvider` |
| `ai.last_plugin` | install id or null | null | `aiLastPluginProvider` |
| `ai.prompts` | list of `PromptTemplate` | the 6 builtins | `aiPromptsProvider` |

- Tool groups (`tool_groups.dart`, key suffix in brackets). Reads:
  `nowPlaying` [now_playing], `queue`, `librarySearch` [library_search],
  `lyrics`, `trackInfo` [track_info], `listeningStats` [listening_stats],
  `playlists`. Writes: `playControl` [play_control], `queueEdit`
  [queue_edit], `playlistCreate` [playlist_create], `playlistEdit`
  [playlist_edit].
- `ai.last_plugin` holds the last plugin used. `aiChatPluginProvider` is what
  a new conversation uses: that plugin while it is an installed `ai-chat`
  plugin, else the first installed one (`resolveChatPlugin`), else null;
  loading while the installed list loads.
- `PromptTemplate{key?, label?, body?, enabled, edited}`: a builtin has a
  `key` and no text until edited (labels and texts are l10n strings of the AI
  settings part, looked up by key); a custom template has label (at most 40
  characters) and body (at most 2000). An item of the stored list that cannot
  be read stays in the list as an unknown template and is written back
  unchanged. Builtin keys (`BuiltinTemplateKeys`, never renamed):
  `explain_lyrics`, `similar_songs`, `mood_playlist`, `song_story`,
  `translate_lyrics`, `taste_summary`.
- `PromptTemplateOps` (`prompt_template_ops.dart`, `promptTemplateOpsProvider`):
  add, edit (a builtin becomes edited), delete, reorder (as
  `ReorderableListView.onReorder` reports it), toggle, restoreDefaults (adds
  back only the missing builtins, at the end).

## Tool read sources

Every tool, the public API it calls and where it is declared
(`file:line` in `lib/src/`). Every track id first goes through
`TrackLookup.visibleOf`. Tool code lives in `ai/domain/tools` (ports, no
Flutter) with the adapters in `ai/data/tool_env_impl.dart`.

| Tool | Public API | Declared at |
|---|---|---|
| `get_now_playing` | `nowPlayingProvider` (`NowPlaying`: `trackId`, `playing`, `index`, `length`, `context`), `playbackPositionProvider` (`PlaybackPosition`), title and artist from `TrackLookup.visibleOf` | `playback/state/playback_providers.dart:72`, `playback/domain/now_playing.dart:7`, `playback/state/playback_position_provider.dart:8`, `library/domain/search/track_lookup.dart:12` |
| `get_queue` | `queueViewProvider` (`QueueView.items`: `QueueItem.entryId`, `trackId`; `current`), titles from `visibleOf` | `playback/state/queue_view_provider.dart:7`, `playback/domain/playback_views.dart:34`, `playback/domain/queue_state.dart:8` |
| `search_library` | `TrackSearch.searchTracks(query, offset:, limit:)` via `trackSearchProvider`; returns `({rows, total})` of `TrackHit` | `library/domain/search/track_search.dart:25`, `library/state/track_search_provider.dart:14` |
| `get_lyrics` | `localLyricsReadProvider(id).future`, then `storedTrackLyricsProvider(id)` (never starts a lookup); `LyricsShown.lyrics.lines` (`LyricLine`), `synced` | `lyrics/state/track_lyrics_providers.dart:43`, `lyrics/state/stored_track_lyrics_provider.dart:15`, `lyrics/domain/lyrics_status.dart:34`, `lyrics/domain/lyrics.dart:36,73` |
| `get_track_info` | `TrackLookup.visibleOf` (visible ids), then `trackInfoProvider(id).future` for genre, language, duration, year (`TrackInfo`) | `library/domain/search/track_lookup.dart:12`, `playback/state/track_info_providers.dart:11`, `media/domain/track_info.dart:22` |
| `get_listening_stats` | `HistoryStore.top(window:, limit:)` and `overview()` via `historyStoreProvider`; window from `MostPlayedRange.days(now)`; unavailable when `historyEnabledProvider` is false | `library/domain/history/history_store.dart:22,29`, `library/state/history/history_providers.dart:23`, `library/domain/history/history_ranges.dart:20,40`, `library/domain/history/history_models.dart:106,122`, `playback/state/playback_settings_providers.dart:17` |
| `list_playlists` | `PlaylistStore.listWritable()` (Favorites id 0, then user playlists by creation; saved queues and mood playlists excluded), counts from `watchSummaries().first` by uid | `library/domain/playlists/playlist_store.dart:109,14`, `library/data/playlists/playlist_id_lookups.dart:43`, `library/domain/playlists/playlist_models.dart:123,180` |
| `get_playlist_tracks` | `resolvePlaylistIds([id])` then `loadPlaylist(uid)`; `PlaylistDetail.entries` (`PlaylistEntryView.id` is the entry id) | `library/domain/playlists/playlist_store.dart:105,21`, `library/domain/playlists/playlist_models.dart:143,207` |
| `play_tracks` | `visibleOf`, then `PlayerController.playTracksForTool(visible, contextLabel:, startIndex:)` returning `ToolPlayResult` (`previous`: `ReplacedQueue?`, `previousIndex`, `shuffled`) via `playerControllerProvider` | `playback/state/player_controller.dart:836`, `playback/domain/removed_queue_entry.dart:28`, `playback/domain/replaced_queue.dart:7`, `playback/state/playback_providers.dart:25` |
| `queue_tracks` | `visibleOf`, then `PlaybackCommands.playNext` (position next) or `enqueue` (end) via `playbackCommandsProvider` | `playback/domain/playback_commands.dart:23,26`, `playback/state/player_controller.dart:480,496`, `playback/state/playback_providers.dart:66` |
| `remove_from_queue` | `PlayerController.removeEntriesForTool(entryIds)` returning the `RemovedQueueEntry` list really removed | `playback/state/player_controller.dart:805`, `playback/domain/removed_queue_entry.dart:4` |
| `create_playlist` | `visibleOf`, then `PlaylistStore.createPlaylist(name:, tracks:)` (returns the uid) | `library/domain/playlists/playlist_store.dart:28` |
| `add_to_playlist` | `resolvePlaylistIds`, `visibleOf`, `PlaylistStore.addToPlaylists(tracks:, playlistUids:)` returning `AddToPlaylistsResult` | `library/domain/playlists/playlist_store.dart:56,105`, `library/domain/playlists/playlist_models.dart:274,305` |
| `remove_from_playlist` | `resolvePlaylistIds`, `resolveEntryIds(playlistUid, entryIds)`, `removeEntriesNow(playlistUid, entryUids)` returning the `PlaylistEntryView` list removed | `library/domain/playlists/playlist_store.dart:114,123` |

Every one of the 14 tools has a public API; none needs a change outside `ai/`.
Gaps the adapters work around (all inside `ai/data`):

- **`add_to_playlist` result is counts only.** `AddToPlaylistsResult`
  (`outcomes[].added` / `skipped`, `addedTrackCount`) does not say which tracks
  were added or skipped. The `done` part lists the visible input tracks minus
  those `PlaylistStore.countExisting` (`playlist_store.dart:25`) reported as
  already present, and its counts come from the result; the track list is
  best effort, the counts exact.
- **`create_playlist` returns only the uid.** The new playlist's integer id
  (for later calls) is found by `listWritable()` and the uid. `addToPlaylists`
  with `newPlaylistNames` would create and add in one transaction but also
  returns counts only; `createPlaylist(tracks:)` is used because it keeps every
  given track.
- **`remove_from_queue` returns entry and track ids, no titles.** Snapshot
  titles come from `visibleOf`; a track hidden since then gets its id as
  title.
- **`get_track_info` reads one track at a time.** `TrackHit` has no genre,
  language or duration, and `trackInfoProvider` has no batch form; with at
  most 50 ids this is one query per id.
- **`get_listening_stats` is not filtered by visibility.** `HistoryStore.top`
  returns tracks with `TrackInfo.status`; the tool drops hidden and missing
  ones.
- **`queue_tracks` into an empty queue starts playback** (`playNext` and
  `enqueue` replace an empty queue). The result text says so.
- **`get_lyrics` for a track that is not playing** answers only what is stored
  or local (`storedTrackLyricsProvider`); it never triggers an online lookup.
