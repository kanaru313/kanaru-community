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

## Tools (`ai/domain/tools/`, `ai/data/tool_env_*.dart`)

- `AiTool` (`ai_tool.dart`): `name`, `description`, `group` (the privacy
  group), `source` (builtin, plugin, mcp), `risk` (read, write, external),
  `parameters` (JSON Schema, the chat contract's subset), `call`, and for
  writes `describe(args, env)` (the confirm-card preview). `run(args, env)` is
  the only entry the loop uses: it validates `args` against `parameters`
  (`schema_validator.dart`, unknown arguments rejected), then calls `call`;
  a schema failure or a thrown error becomes an error `ToolOutcome` whose
  text never carries exception details. A write tool re-checks its own
  arguments in `call`, because the library may change between preview and run.
- `AiToolRegistry` (`ai_tool_registry.dart`): tools from `AiToolProvider`s by
  name (duplicate or over-64-character names throw). v1 has the built-in
  provider only (`readToolProvider`). The permission gate (`mayExecute`) reads
  a tool's `group` and `risk`; the registry offers no filtering of its own
  beyond `where`.
- `ToolEnv` (`tool_env.dart`): ports the tools call, with no Flutter or
  Riverpod: `LibraryPort` (visibleOf, search, details), `PlaybackPort`,
  `LyricsPort`, `HistoryPort`, `PlaylistsPort`. Adapters: `tool_env_impl.dart`
  (library, playlists, history) and `tool_env_player.dart` (playback, lyrics)
  take the concrete stores and small reader functions;
  `ai/state/tool_env_provider.dart` wires them on the live providers.
- Results are JSON text: `{total, offset, items: ["id|title|artist|album|year",
  ...], ...}` (`tool_rows.dart`). A cell is stripped of control, bidi and
  zero-width characters (`text/text_sanitizer.dart`, `sanitizeText`, reused by
  the write tools and the prompt data fences), cut at 200 characters, and has
  `\`, `|`, CR and LF escaped, so text can never forge a row. Over 16 KiB the
  `items` array is compacted to the rows that fit (at least one) and the result
  adds `truncated: true` and `nextOffset`; a row is never cut.
- Read tools: `get_now_playing`, `get_queue` (window of 50 around the current
  entry unless `offset` is given; items carry the entry id), `search_library`,
  `get_lyrics` (stored or local lyrics only, no timestamps; the result stays
  within 16 KiB of UTF-8 bytes, cut at a line, with `offset` (line) and
  `nextOffset` to page), `get_track_info` (at most 50 ids, `offset` pages over
  them and `nextOffset` counts ids, rows come in the order asked, `notFound` lists absent ones), `get_listening_stats` (error while history recording is
  off; hidden and missing songs are dropped and the totals count visible
  songs only, within the 1000 most played), `list_playlists`, `get_playlist_tracks` (entries of hidden tracks are
  left out). Every track id goes through `TrackLookup.visibleOf`. A song that
  is not visible never reaches the model: `get_now_playing` says
  `track: "unavailable"` with no `trackId`, and `get_queue` rows for it are
  `entryId||(unavailable)` (the entry id stays so the entry can be removed).

### Write tools (`write_tools.dart`, `queue_write_tools.dart`, `playlist_write_tools.dart`)

`play_tracks`, `queue_tracks`, `remove_from_queue` (queue groups) and
`create_playlist`, `add_to_playlist`, `remove_from_playlist` (playlist groups),
all `ToolRisk.write` on `WriteTool` (`write_tool_base.dart`).

- `plan(args, env)` is the one place a write is checked: it looks every track
  id up through `visibleOf`, applies the item caps and returns the confirm
  card (`describe`) and the action (`call`). `run` calls it again, so a library
  that changed since the card is re-checked. Absent ids are never sent to a
  store; they are listed in the result (`notFound`) and in `ToolDone.absent`.
  No visible id at all is a refusal. `remove_from_playlist` removes only the
  entries the card shows (entries of a song the user cannot see are reported
  as `notInPlaylist` and never sent to the store); none shown is a refusal.
- `ToolOutcome.done` (`ToolDone`) carries what the call changed; the loop adds
  the call id (`toPart`) and stores a `DonePart`. It is built from what the
  ports return, not from the request: removals list exactly the entries the
  player or store removed, a restored queue comes from `ToolPlayResult`
  (`ReplacedQueueSnapshot`: tracks in play order, `userOrder`, `shuffled`,
  `previousIndex`). `play_tracks` drops the user's pending undo like any play;
  `remove_from_queue` leaves it untouched.
- `ToolPreview.refused(reason)` (no card, the model gets the reason) covers a
  bad name, an unknown playlist and the caps. `ToolOutcome.limit` marks a cap
  refusal so the loop shows the limit card, also in Auto.
- Item caps (`item_caps.dart`): at most 50 removed (queue plus playlist) and
  200 added items per user turn. `TurnItemUsage.fromParts` counts the
  `DonePart`s of the turn's persisted messages; the session supplies it as
  `ToolEnv.turnUsage`, read at call time, so a retry or restart never resets
  it. A call that would cross a cap is refused whole. `play_tracks` counts as
  added items.
- Model-written text (playlist names) goes through `sanitizeModelText`
  (`model_text.dart`): control, bidi and zero-width characters removed, spaces
  collapsed, cut at 100 characters; a name that is empty afterwards is
  refused. Track titles in cards and done parts are cleaned the same way.
- `play_tracks.startIndex` counts in the given `trackIds`; if the song there
  is not visible the call is refused. The play context label is
  `ToolEnv.playContextLabel` (`aiChatPlayContextLabel`, localized by the
  session; the provider default is English).
- Ports: `PlaybackWritePort`, `PlaylistsWritePort` (`tool_env_write.dart`),
  adapters in `ai/data/tool_env_write.dart`. `add_to_playlist` names the added
  tracks by reading the playlist before the add (counts are the store's).
  `create_playlist` never fails after the playlist exists: if reading its id
  back fails the result has no `playlistId` (and a note), so the model does not
  create it twice.

## Conversation store (`ai/data/conversation_store.dart`)

`ConversationStore` over `ai_conversations` / `ai_messages`, split into
`conversation_rows.dart` (types, caps, error shape), `conversation_maintenance.dart`
(turns, flattening, blob caps, startup sweep) and `conversation_queries.dart`
(search, stats). `aiConversationStoreProvider` and `aiChatStatsProvider`
(count, bytes) live in `ai/state/`; the stats reload when `store.changes`
fires. It fires after every stored change a screen shows: an append, a
completed round, any won state move of a message (`transition`,
`resolveConfirm`, `startCall`), `endTurn` / `flattenTurn` that flattened,
`clearProviderBlobs`, the sweep, rename, auto title, permission, bind and
delete. Not for live-text flushes or a lost compare-and-set. Writes wake the
listeners once per microtask (coalesced), so nothing polls.

- **Turn:** a user message and every row after it (assistant, tool, event)
  up to the next user message. Its id is the id of the user message
  (`turnIdOf(messageId)`). Rows before the first user message belong to no
  turn.
- **Rows:** `append` takes `seq = max + 1` inside a transaction. `messages`
  returns one page in `seq` order: the newest `limit` (default 50) before
  `beforeSeq`; `blobs: false` reads the page with the provider blob left out
  (a list on screen never needs it). `latestTurn(conversationId)` reads the
  last user message and what follows, `openToolCards(conversationId)` the
  `pending` / `allowed` tool rows of the whole chat, both without blobs: they
  are what the loop reads. Only `ModelRound` reads the whole transcript with
  blobs (`LoopStore.history`), once per round. `startCall(messageId, write:)`
  moves `allowed -> running` and, for a write, reads the chat's permission in
  the same transaction: read-only wins. `search` matches title and message text (user and assistant
  text, live text), case-insensitive; it reads message text in pages, so its
  cost grows with the stored text.
- **State changes** are compare-and-set (`UPDATE … WHERE state = from`);
  false means another caller won. Legal moves (`transition`): streaming →
  complete | stopped | error; pending → allowed | skipped; allowed → running |
  skipped; running → done | error | unknown. `resolveConfirm` answers a
  pending card: allowed → `allowed` (the confirm part also keeps the
  `approvalHash` of the call the user saw); denied, deniedByNewMessage,
  expired → `skipped` (the confirm part keeps the status).
- **`completeRound(messageId, finalParts, blob, calls)`:** one transaction:
  CAS `streaming → complete`, live text cleared, one `tool` row per call
  (`[call, ConfirmPart(pending)]` in `pending` for ask-mode writes,
  `[call]` in `allowed` otherwise), blob cap enforced. A lost CAS writes
  nothing.
- **Caps (Dart only, no SQL CHECK; `ConversationStoreLimits`):** live text
  256 KiB UTF-8, cut on a character boundary and ending with `\n[…]` (later
  deltas store the same cut text); `parts_json` 1 MiB per row; provider blob
  256 KiB per message and 4 MiB per conversation. A blob over 256 KiB is
  stored as the marker `{"tooLarge":true}` and `completeRound` reports
  `blobTooLarge`; `endTurn(turnId)` then stores the turn flattened. Past 4 MiB
  the oldest turns are flattened in the same transaction (the running turn
  is never touched). Parts over 1 MiB, or blobs that still do not fit, mark
  the message `error(too_large)` and throw `AiStoreTooLarge`; the round is
  rolled back.
- **Flatten** (`flattenTurn`): text kept; tool-call and tool-result parts and
  blobs dropped together, an assistant row left empty is deleted. Tool rows
  stay with their display parts (done, confirm, error), so the turn's item
  usage and its "what the AI changed" cards survive, and a row left with
  nothing is deleted. A flattened turn is sent as plain text (no call, no
  blob); the loop treats a last round without calls as the end. A turn
  with a streaming, pending, allowed or running row is not flattened (false).
  `clearProviderBlobs(installId)` (plugin removed or reinstalled) flattens
  every turn that held a blob of that install; a version or model switch
  flattens at send time instead.
- **`error_json`** is `{code, kind, retryAfterSec?}` only.
  `AiStoredError.fromPlugin("ai:<code>…", kind:, retryAfterSec:)` keeps the
  code and drops everything after it; an unknown code or kind is `server`.
  Besides the contract codes (`AiErrorCode`) the app stores its own
  (`appErrorCodes`, `ai_error_code.dart`): `network`, `host_not_allowed`,
  `limit_reached`, and the snake-case name of any other card (`timeout`,
  `plugin_error`, ...). A plugin can never produce them. The host of a network
  card is not stored, so a reloaded card names no host.
- **Binding:** conversations and messages carry `installId` and
  `installGeneration`; `bind` moves a chat to another plugin.
- **Startup sweep** (`sweepAfterCrash`, once before any chat opens):
  `streaming → stopped` (live text kept, cut to the cap, plus an `ErrorPart`
  with code `cutOffByClose`), `running → unknown`. Blobs stay; pending and
  allowed cards are left alone: a new user message resolves them (see Loop)
  and the 24 h expiry covers the latest turn. No model call follows.
## Input and outcomes (`ai/domain/input/`, `ai/domain/output/`)

Pure Dart (no Flutter); they read the chat contract of `docs/plugin-host-api.md`.

- **Input** (`chat_input_builder.dart`): `buildChatInput(binding, history,
  tools, capabilities, system, boundary, finalRound)` returns the plugin's
  `input` (`{v:1, model, system, boundary, messages, tools, toolChoice,
  options}`) or `ChatInputTooLarge`. `history` is `HistoryRow`s (message plus
  blob text) in `seq` order; the last turn is the current one.
  - A turn is a user message and the rows up to the next user message. An
    assistant row gives one assistant message (text and `tool_call` parts,
    `provider` = its blob); the tool rows after it give one `tool` message
    with a `tool_result` per call, in call order. A call with no result
    (denied, skipped, unknown, never ran) gets an error result, so every call
    has its result. Neighbours of one role are merged. The app sends
    `isError`; the plugin adds the `Error: ` prefix the model reads, the app
    never does.
  - **Binding:** a turn is sent whole only when every assistant row that has
    calls or a blob carries the current install id, generation, plugin
    version and model and a readable blob (the store's oversize marker is not
    readable); else the whole turn is flattened to its text.
  - **Limit** (`byte_budget.dart`): `min(768 KiB, context x 2 x 0.75 -
    maxOutputTokens x 2)` UTF-8 bytes of `jsonEncode(input)` (the loop passes
    the plugin's own `maxOutputTokens` when the chat sets none). Over it, in
    order: flatten the oldest turns, drop the oldest turns (the first user
    message stays), elide the oldest tool-result contents of the current turn
    (calls, results and blobs stay), then `ChatInputTooLarge`. Trimming sums
    per-turn sizes (each turn is encoded once per mode); only the first try
    and the final result are encoded whole.
  - **The running turn is never flattened:** when its blob is the store's
    oversize marker the builder returns `ChatInputTooLarge` instead of hiding
    its calls and results. The loop ends such a turn right after the round
    (see Loop); the turn is flattened when it ends.
  - `data` parts are cleaned (`sanitizeText`) and every `<data` / `</data`
    is broken; chips are not sent (their data parts are).
- **Tools offered** (`tool_selection.dart`): none when the model has no
  `tools` capability; else the tools whose group switch is on, without
  external tools, and without writes in a read-only chat. The final round
  sends the same list with `toolChoice: "none"`.
- **System prompt** (`system_prompt.dart`): English, rules for ids, row
  format, untrusted data, approvals, `[[t:ID]]` citations; the user's general
  instructions last. `newChatBoundary` makes the per-request fence token.
- **Output** (`chat_output_parser.dart`): `parseChatOutput` returns
  `ChatOutputOk(ChatRoundOutput)`, `ChatOutputRejected` (shape, 9+ calls in a
  round, empty reply; the card is `bad_request`) or `ChatOutputLimit`
  (`ChatLimitExceeded`: more than 24 calls in the turn, or the loop's item
  counter via the `itemLimit` hook; its own card, never retried). Call ids
  are `t<turn>-r<round>-<n>`; a provider id outside
  `^[A-Za-z0-9_.:-]{1,64}$` is dropped; each call carries a `ChatCallRefusal`
  (unknown or over-long name: stored without args; raw args; any call in a
  final round) that the loop answers with an error result.
  `finish: "blocked"` is a normal result.
- **Readiness** (`chat_readiness.dart`): `chatReadiness(manifest,
  storedConfig, conversationModel, reinstalled)` is `ChatReady`,
  `ChatNeedsKey` (`chat.keyField` empty), `ChatNeedsModel` (neither the chat
  nor the plugin names one), `ChatNeedsConfig(titles)`, `ChatPluginRemoved`
  (manifest null) or `ChatPluginReinstalled`.
- **Outcomes** (`outcome_mapper.dart`): `mapChatOutcome(RunOutcome,
  ChatOutcomeContext)` returns a `ChatOutcomeView`: message end (complete,
  error, stopped, blocked), card kind, one action, the contract code to store,
  and parameters (host, retryAt, titles, the valid reply). No UI strings.
  Success wins over a sticky fetch failure or `rateLimitSeen`; a rejected
  `RunOk` shows the rate-limit or fetch card when one is behind it. A script
  `server` error with a failing fetch shows the fetch card; any other code
  shows its own. Rate-limit `retryAt` is the later of `now + retryAfter`
  (default 60 s) and the plugin pause. `RunBusy` is "stuck" from the third in a
  row with no stream active. `ChatOutcomeView.interrupted()` is the card for a
  turn cut off by closing the app.

## Variables and chips (`ai/domain/variables/`)

Pure Dart. Values and chip contents reach the model only as fenced
`DataPart`s, never as `TextPart`s.

- **Catalogue** (`variable_catalog.dart`): `AiVariable` (`now_playing`,
  `title`, `artist`, `album`, `lyrics`, `queue`, `input`) with its data
  `source`, privacy group (now_playing, title, artist, album -> nowPlaying;
  lyrics -> lyrics; queue -> queue; input -> none) and `l10nKey` (key only;
  the strings belong to the AI settings l10n part). `variableCatalog` lists
  them; `ToolGroupSwitches` is the "is this group on" callback.
- **Validator** (`template_analysis.dart`): `analyzeTemplate(body, switches)`
  returns spans `ok | unknown | groupOff`. One rule for the composer, the
  prompt list and the editor: an unknown `{{x}}` is literal text when sent
  from the composer and an error (`invalidAsSaved`) in a saved template.
- **Filler** (`variable_filler.dart`): `fillVariables` returns `FillDone`
  (text and data parts interleaved, `displayText` with values inline),
  `FillBlocked` (every `FillMissing(reason)`, `FillGroupOff`,
  `FillLeftoverInput`) or `FillOversize` (a value over 24 KiB UTF-8; call
  again with `shortVersion: true`: queue = 50 entries around the loaded one,
  other values cut with `\n[…]`). A group that is off blocks unless
  `varBypass`. `{{input}}` is never filled by the app. Values come from the
  tool-env ports (`variable_values.dart`).
- **Fence** (`data_fence.dart`): `fencedData` strips C0/C1, bidi and
  zero-width characters and breaks every `<data` / `</data` (same
  `fenceSafe` the input builder applies on the way out). The per-request
  `boundary` is `newChatBoundary` (`Random.secure`), the only source.
- **Chips** (`chip_ref.dart`, `chip_resolver.dart`): `chipRefOf` is the one
  mapping from `AskAiTarget` (`library/domain/ask_ai_target.dart`) to a
  `ChipRef`. `ChipResolver` checks the group (nowPlaying chip: nowPlaying;
  song, songs, album, artist, genre, language: trackInfo; playlist: playlists;
  same `varBypass`), reads data through `ToolEnv` plus `ChipScopePort`
  (album / artist / genre / language tracks and playlist uid -> model id),
  and returns `ChipResolved(chip, data)`, `ChipBlocked` or `ChipMissing`.
  There is no lyrics chip.
- **Title** (`title_rule.dart`): `conversationTitle(displayText)`: sanitised,
  first 40 characters, "…" added when cut.

## Loop (`ai/domain/loop/`, `ai/data/loop_store_adapter.dart`)

Pure Dart. `LoopDriver` runs the turns of one conversation on ports:
`LoopStore` (the stored transcript; `LoopStoreAdapter` implements it on
`ConversationStore`), `ModelRoundRunner` (one plugin run: input in, `RunOutcome`
out, text deltas through a callback, `cancel()`), `LoopEnvironment` (tool
registry and `ToolEnv`, fresh `LoopSettings` and `LoopPlugin` reads) and a clock.

- **Next step** (`ChatLoop.next`, pure): from the rows of the latest turn it
  returns `RunModel(round, finalRound)`, `AwaitConfirms`, `RunTools` (the
  allowed calls, in the model's order), `ExpireCards`, `Done` or
  `NeedsUserTap`. A round's calls run only after every card of that round is
  resolved (nothing `pending`); then the next round starts. Rounds 1 to 6 offer
  tools; round 7 is the final round (`toolChoice: "none"`); after it the turn is
  done. A call in the final round, an unknown tool or unparsed arguments is
  answered with an error result and never runs.
- **Turn state:** `TurnState { idle, streaming, runningTools, awaitingConfirm,
  error }` (`turnState`, `states`). `liveText` streams the deltas so the list
  does not rebuild per delta; the text is flushed to the store about once a
  second, at the end of a round, and by `flushLive()`.
- **Single flight:** one in-flight future (`inFlight`). `send` and `retry`
  return `DriverBusy` while it runs (the trigger is dropped, never queued).
  Allow and Deny are compare-and-set answers on the stored card, so they work
  during a flight (it re-reads the store before it parks) and two Allows of one
  card run the tool once. The flight ends when the turn is done, failed,
  stopped, or waits on a card (`awaitingConfirm`); Allow, Deny and Retry start
  the next flight. Before a model round the transcript revision (`seq` of the
  newest row) is compared in the same transaction as the streaming message
  insert (`ConversationStore.appendIfLatest`): a round never starts on a
  transcript that moved. A lost compare (or a history that no longer matches
  the snapshot) makes the pump read again and decide again; a second loss in
  a row ends the turn in `error` with the app's own error card, never
  silently. Every decision reads the latest turn only (`LoopSnapshot`: turn
  and revision, no blobs).
- **`runExclusive(body)`:** claims the flight for [body] (a plugin, model or
  rebind write). A round or tool run in flight is stopped first and awaited;
  a send, retry, Allow or Deny meanwhile finds the gate taken (`DriverBusy`,
  or the answer is stored and the turn goes on at the next tap). A turn that
  only waits on cards is left alone, its cards stay `pending`. `inspect()`
  runs after it.
- **Allow:** stores `callHash` (sha256 over the name and key-sorted args) in
  the card's `ConfirmPart(allowed).approvalHash` in the same compare-and-set
  that allows it, so the binding survives a restart. Execution recomputes the
  hash from the stored call; any difference is a refusal. A card that needed
  no confirmation has no hash.
- **Allow on an expired card** answers it `expired` and starts a flight, so
  the model reads the result and the turn goes on (or parks on the cards that
  are left).
- **`mayExecute`** runs right before every `allowed -> running` (reads too):
  no write in a read-only chat, the tool's group switch, external tools never,
  the plugin install id + generation and the model the round was made with
  unchanged; the read-only check is repeated inside `startCall`, in the same
  transaction as the move. A refusal stores `skipped` with the result "not run: not allowed
  now (...)". A pending card is valid until the next user message or 24 h
  (`expired`, also on a late Allow). A new user message moves every pending
  and allowed-not-run card of the conversation, earlier turns included, to
  `skipped` with `deniedByNewMessage` before the message is stored, so no
  older turn stays live and every turn can be flattened. `applyPermission()` after a
  switch to read-only denies pending and allowed-not-run writes at once.
- **Tools:** each call is stored `running` before it runs, then `done`, `error`
  or `skipped`; a 30 s timeout fails a read and marks a write `unknown` (it
  may have happened; never re-run). `ToolEnv.turnUsage` reads the `DonePart`s
  of the turn from the store before each call. A `limitReached` outcome stores
  the call as failed with an `ErrorPart` code `limit_reached`, skips the rest
  of the batch with "not run: the limit for this turn was reached" and ends
  the turn in `error`; the parser's `ChatLimitExceeded` ends the round the same
  way. `limit_reached` is a stored code of the app, not a plugin contract code.
- **Stop:** `stop()` sets a turn-level flag and cancels the runner. Streamed
  text stays (`stopped`), the call being run finishes, later calls are
  `skipped` with "not run: stopped by the user", pending cards are skipped the
  same way, no next round. A stop that lands while a round is being set up
  (before the plugin run exists) is honoured: the round checks the flag after
  its last read and after it stored the streaming message, and starts no run.
  `dispose()` (open, new chat, switch, app exit) stops only a flight that is
  active (round or tool run) and awaits it; cards of a turn that only waits
  on the user stay `pending` (valid until the next user message or 24 h).
  Only the user's Stop and a new user message deny them. Delete removes the
  chat with its cards. `dispose()` marks the driver closed first, so no
  trigger starts a flight after it.
- **Crash rules:** after a restart (`sweepAfterCrash`) `streaming -> stopped`
  and `running -> unknown`. `inspect()` only reads: it sets `turnState` and
  returns `NeedsUserTap` for a model round or allowed calls that wait, or
  `AwaitConfirms` for pending cards. Nothing runs until the user taps (Retry,
  Allow, Deny, send). Pending cards act only on tap; `unknown` writes are
  never re-run (the model reads "the result is unknown"). A call left
  `running` inside one app session (its run ended without storing a result)
  is moved to `unknown` by the next armed flight (`HealRunning`), so Retry
  never waits on it.
- **Blob over its cap:** when `completeRound` reports `blobTooLarge` and the
  reply has calls, the calls do not run (their cards go `skipped`, "not run:
  the conversation grew too large to go on", a confirm part is `denied` with
  reason `too_large`), the turn ends in `error` with the `too_large` card and
  is flattened at its end. A reply without calls ends the turn normally.
- **Failures:** a round that ends without a reply stores `stopped` or `error`
  with the contract code (or the card name in snake case, e.g. `timeout`,
  `plugin_updated`; a network or blocked-host failure is `network` /
  `host_not_allowed`, see Conversation store) and kind; `lastView` keeps the `ChatOutcomeView` of the
  last failed round and is cleared when a new flight starts; a flight that
  threw shows the app's own error card (`internalErrorView`). A plugin that is gone ends the turn in `error` with no
  stored row (the chat's readiness shows it). The plugin version that really
  ran (`RunOk.pluginVersion`) is stamped on the message.

## Session controller (`ai/state/chat_session*.dart`, `ai/data/chat_turn_runner.dart`)

`chatSessionProvider` (`ChatSessionController`, kept alive) is the chat UI's
only entry. It owns one `LoopDriver` for the open conversation and builds
everything the driver needs when it is needed; no dependency is kept across
an await. `state` is `{conversationId, turnState, lastView}`.

- **API:** `newConversation()` (reuses the open chat while it is empty; else a
  new one on the default plugin, the plugin's own `model`, the default
  permission), `open(id)`, `rename`, `delete(id)`, `deleteAll()`,
  `send(text, {shortVersion})`, `stop()`, `retry()`, `allow(callId)`,
  `deny(callId)`, `replayQueue(messageId)`, `switchPlugin(installId)`,
  `switchModel(model)`, `setPermission(permission)`, `flush()`. Switching
  operations run one at a time. The first open sweeps a crashed run once
  (`sweepAfterCrash`).
- **`send` returns** `SendSent(done, userMessageId)`, `SendMissingData(issues)`
  (a `{{variable}}` or an attached chip with no data or a group off; the
  attachments stay), `SendOversize(variables)` (call again with
  `shortVersion: true`), `SendBlocked(readiness)`, `SendBusy`, `SendFailed`.
  The message is chips (each with its fenced data) then the filled text.
  Attachments (`chatAttachmentsProvider`: `attach`, `attachTarget`, `detach`,
  `setSuggestions`) are cleared only by an accepted send, and only the chips that were sent
  (one attached while the send was prepared stays). The first message of
  a chat sets its auto title.
- **Open, delete, switch** stop a flight in flight and await its future (the
  run and the tool being run), then act; cards waiting on the user stay
  pending (delete removes them with the chat). Deleting the open chat opens a new empty one in
  the same call; `deleteAll` also clears the run log of every installed chat
  plugin (`PluginLogOps.clear`). `switchPlugin` and `switchModel` run their writes inside
  `runExclusive`, so no send, retry, Allow or Deny starts a round on the old
  binding meanwhile; a plugin switch also writes the `EventPart.pluginSwitch` line.
  `setPermission(readOnly)` calls `applyPermission()`.
- **Reads for the UI:** `chatPluginsProvider` (installed chat plugins with
  model list and readiness), `chatModelOptions` (the `model` select's options
  plus the user's choices, capabilities from the overlay or `chat.custom`),
  `chatConversationProvider(id)`, `chatReadinessProvider(id)`,
  `chatMessagesProvider(id)` (newest 50 without blobs, `loadOlder`; reloads on
  `store.changes`, the latest read wins),
  `liveTextProvider(messageId)` (streamed text, so a delta rebuilds one
  bubble), `chatStreamStatusProvider` (`thinking` / `generating`).
  `cardOfStoredError` maps a stored `{code, kind, retryAfterSec}` to a card
  after a reload (`network`, `host_not_allowed` and `limit_reached` are
  stored under their own codes, so those cards come back; an unknown code
  falls back to its kind, then to the server card).
- **Runner** (`ChatTurnRunner`): one streaming run of the `chat` script on
  `PluginRunner`: kinds `{aiChat}`, `persistStorage: false`, no input log, 300 s
  wall, idle from `chat.idleTimeoutSec`. `text` and `status` emits are parsed;
  a generation counter drops every event after a cancel or the outcome. The
  outcome's plugin version stamps the message (the loop does that).
- **Tool env:** `buildToolEnv(ref)` is a function, called per access with the
  session's `ref` (`toolEnvFactoryProvider` lets tests swap it); the play
  context label comes from `aiPlayContextLabelProvider` (the chat screen sets
  it from its localizations; until then the English default of `ToolEnv`).
- **Chips:** `ChipScopeAdapter` reads album, artist, genre, language scopes
  through `songIds` and `TrackLookup` (at most 200 rows, true total kept) and
  maps a playlist uid to its model id with `PlaylistStore.loadPlaylist`.
- **`replayQueue(messageId)`:** only a tool row of the latest turn; rebuilds the
  replaced queue from its still visible tracks in play order, starts at the
  entry that was playing (first when none) through
  `PlaybackWritePort.play`; the shuffle flag is not restored.
- **Blobs:** a listener on the installed plugins calls
  `clearProviderBlobs(installId)` when a chat plugin is removed or installed
  again (its install time changed). An update or a model switch clears
  nothing: those turns are sent flattened by the binding rule.
- **Flush:** the loop writes streamed text about once a second and at each
  round end. `flushChat(container)` (hook of `AiExtension`, registered in
  `builtInExtensions` by the chat UI) writes it on pause and exit; it does
  nothing when the session was never created.
