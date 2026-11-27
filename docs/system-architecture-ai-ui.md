# AI chat UI architecture

The chat screens over the engine described in `system-architecture-ai.md`.
This file grows with each UI part; it describes what has landed.

Code: `lib/src/ai/ui/` (widgets), `lib/src/ai/state/chat_view/` (view state that
outlives the widgets), `lib/src/shell/ui/chat_host_shell.dart` (the shell side).
`ai/ui` never imports `shell/` or `screens/`; it reaches them only through
`ChatHost`.

## One chat, two places

The chat is one widget, `ChatSurface` (below its header), shown in two places:

| Shell | Place | Header |
|---|---|---|
| Desktop (>= 1200 dp) | the shell's shared right panel (`RightPanelKind.chat`, 420 dp), swaps sideways with the queue | `RightPanelHeader`: `ChatHeaderTitle`, `ChatMenu`, ✕ "Đóng khung (Ctrl+J)" |
| Phone | page `/chat` on the root navigator (`ChatPageMobile`), slides up with `KMotion.chatPageSlide` (instant under reduced motion) | [⌄ close], `ChatHeaderTitle`, `ChatMenu` |

`AiExtension` (`ai/ai_extension.dart`, registered in `builtInExtensions`) adds
the `/chat` route and the flush hook. The old gate (`PanelSurface('chat')`,
`chatPanelSurfaceProvider`) is gone: the AI button, Ctrl+J and the panel are
always available, and an extension's top-bar action no longer hides the built-in
button. (The `PanelSurface` type and `ExtensionRegistry.panelSurface` stay in
`extension/` until a separate cleanup.)

## ChatHost

`ai/ui/chat_host.dart`: `isPanel`, `close()`, `openQueue()`,
`openSettings(location)`, and `chatHostProvider` (throws until overridden).
`lib/kanaru.dart` overrides it with `chatHostOverride`, a `ChatHostShell`
(`shell/ui/chat_host_shell.dart`) built on the right-panel provider and the
router:

- `isPanel`: the chat page is not the top route.
- `close()`: panel closes; page pops (`go('/')` when nothing to pop).
- `openQueue()`: panel swaps to the queue (the chat keeps its state); phone
  opens the queue sheet over the chat.
- `openSettings(location)`: `router.go(location)` (a page of Settings or the
  plugin store). On the phone this also drops the chat page and what is under
  it; the chat is reopened from the ✦ button.

`ai_settings_link.dart` (settings work) holds the locations the chat links to
(`aiSettingsLocation`, `aiPluginStoreLocation`, `aiPluginPageLocation`).

`openChatPage(router)` (same file as the host) is the one way to show the phone
page: pushes `/chat` when absent, pops back to it when it is below other pages,
does nothing when it is on top (a second ask never stacks a second page).

## Hand-over across 1200 px

`AppShell._syncChatPlace`, like the Now Playing hand-over:

- narrowing with the panel on the chat: panel closed, `/chat` pushed;
- widening with `/chat` on top: page popped, panel shows the chat;
- a window that starts narrow with the panel saved open on the chat: the panel
  is just closed (the phone never opens the chat by itself).

The panel's stand-in while the player does not exist yet (`_RightPanelGate`)
covers the chat too, so a chat restored open never makes the first build read
the player.

## View state that outlives the widgets (`ai/state/chat_view/`)

All keep-alive providers, so the panel swapping to the queue (the chat widget is
disposed) or the panel and the page replacing each other lose nothing. No
`GlobalKey` crosses a swap.

- The open conversation's messages stay loaded while the chat is off screen:
  `chatMessagesHoldProvider` (watched by the surface, not auto-disposed) listens
  to the engine's auto-dispose `chatMessagesProvider(id)` for the open id, so a
  swap keeps the pages already loaded; it is released when another conversation
  opens. Switching conversation also clears the send note and the scroll anchor.
- A refused send's note is recorded after the field is written (editing the
  field ends the note); a send that finishes after the chat left the screen
  still clears the sent text from the draft (`clearIfSent`). The draft never
  stores the IME composing range.
- Rename starts from the stored title (empty for an unnamed chat; the
  placeholder is only a hint); saving it unchanged is not a rename, so
  auto-titling stays.
- "Sao chép" on an answer copies the rendered text (`plainAnswerText`): markers
  dropped, `[[t:ID]]` lines as "title – artist" when known, else left out.
- Streaming cost: closed groups and the open blocks sit in their own
  `RepaintBoundary`; open block views are reused while their block is equal.
  Known track ids are cached per message and cover the loaded page only.

| Provider | Holds |
|---|---|
| `chatViewProvider` | `historyOpen`, `renaming`, `renameText`; `back()` (rename, then history; true when it took a step), `startNewConversation()`, `deleteConversation(id)`, `commitRename()`, `ensureConversation()` |
| `chatHistoryQueryProvider` | the history search text (auto-dispose: the next visit starts with the whole list) |
| `chatHistoryActionsProvider` | ids whose delete runs (rows busy); `delete(id)`, `open(id)`, `rename(conversation, text)` |
| `chatScrollAnchorProvider` | id of the message the list was scrolled to (read by the message list) |
| `composerDraftProvider` | the composer's `TextEditingValue` (text and selection) |
| `composerFocusRequestProvider` | a pending "put the cursor in the composer"; `consume()` is true for one caller only |

`ComposerDraftBinding` (`ai/ui/composer_draft_binding.dart`) gives a composer its
controller and focus node from those providers: it writes the draft on every
change (not on dispose: a provider must not change while the tree is torn down)
and takes a focus request after the frame, so a request made while the chat is
being built is kept, and of two composers alive during a swap only one takes it.

## Keys and Back

- Ctrl+J toggles the chat panel; Ctrl+Shift+O shows it and starts a new
  conversation (the open one when still empty), then asks for the cursor.
- Esc with nothing focused (shell's history key path) and the mouse Back button
  ask `chatViewProvider.back()` first (rename cancels, History returns to the
  conversation), then Now Playing, then the page history. In the rename input,
  Esc cancels (the field handles it itself).
- Phone: `ChatPageMobile` has `PopScope(canPop: !renaming && !historyOpen)`; Back
  steps out of rename mode, then History, then closes the page.

## Header and menu

`ChatHeaderTitle`: the open conversation's name ("Cuộc trò chuyện mới" while it
has none); a tap turns it into an input (Enter saves, Esc cancels, the ✓ of
`ChatMenu` saves; blank keeps the old name). `ChatMenu`: ✓ while renaming, and
⋮ (`KMoreButton` + `showKLayeredMenu`, one group): Cuộc trò chuyện mới
(Ctrl+Shift+O on desktop), Lịch sử trò chuyện (sets the history flag),
Đổi tên, Xoá cuộc trò chuyện này (confirm dialog, then
`ChatSessionController.delete`, which stops the turn and opens a new empty
conversation), Cài đặt AI (`host.openSettings`). The phone's header shows ✓ in
place of ⋮ while renaming.

## Frame and bodies

`ChatSurface` opens a conversation on first build (`ensureConversation`) and
ends a rename when another conversation opens. Body, in order: the history
page (`ChatHistoryPage`) when the flag is set; nothing
while the messages load; the message list (`ChatMessageList`) when there are
messages (a failed read shows `ChatMessagesError` with a retry); with none: the no-plugin guide (`ChatNoPluginGuide`: cloud option
[Mở kho plugin AI] → `host.openSettings(aiPluginStoreLocation)`, consent line;
no MCP option until MCP exists) when no `ai-chat` plugin is installed, else the
greeting (`ChatEmptyGreeting`, with a slot for the prompt chips). The removed
and reinstalled plugin states are notices above the composer, not bodies.

## History (`ui/history_page.dart`, `ui/history_row.dart`, `state/chat_view/history_view.dart`)

The history flag swaps the body for `ChatHistoryPage` and the header for
`ChatHistoryHeader` (set in `RightPanelHost._ChatContent` and `ChatPageMobile`):
[←] "Lịch sử trò chuyện" and, on the desktop panel only, ✕. The page holds
focus (`Focus(autofocus)`), so Esc reaches `chatViewProvider.back()` from the
list and from the empty search field (a search with text clears first).

- **Data:** `chatHistoryConversationsProvider` reads the store (`list()`, or
  `search(query)` for title and message text) and reloads on `store.changes`,
  keeping the list on screen meanwhile. `groupHistory(list, now)` (pure) splits
  by local calendar day: today, 1-7 days before today ("7 ngày qua"), older;
  `chatHistoryClockProvider` is the injectable clock; `chatHistorySectionsProvider` has no timer: the history page
  invalidates it when the app resumes and when it builds on a new day, so a
  list left open regroups. The list is not paged (rows are cheap); search
  is debounced (see below).
- **Row:** `SelectionRow` icon row (plugin icon, name, line "giờ | dd/mm · plugin
  · quyền"), the open conversation `selected` (tint). A plugin missing from
  `chatPluginsProvider` shows "plugin đã gỡ" in the error colour (the name is
  not known any more). ⋮ (`SelectionRowAction`) opens a layered menu: Đổi tên
  (an input in place of the name; Enter saves, Esc cancels) and Xoá (confirm
  dialog, then `chatHistoryActionsProvider.delete`).
- **Delete:** goes through `ChatViewNotifier.deleteConversation`, so the
  controller stops the turn and, for the open conversation, opens a new empty
  one in the same call; the history stays up on it. While it runs the row is
  disabled (dimmed, taps ignored).
- **Open:** `ChatSessionController.open(id)` (stops a running turn, Q5), then
  the history closes. [Cuộc trò chuyện mới] is `startNewConversation()`, drawn
  as `KListActionButton` (`kanaru_ui`: 48 dp filled `primaryContainer`, inset 8,
  icon + bold label; the `Ctrl+Shift+O` hint only on desktop).
- **Toast:** a delete that succeeded shows "Đã xoá cuộc trò chuyện"
  (`showAppSnackBarOn` on a messenger captured before the awaits); the same
  toast follows "Xoá cuộc trò chuyện này" of the ⋮ menu. A failed delete is only
  logged (`deleteConversation` / `ChatHistoryActions.delete` return false).
- **Not drawn by the mockup, not built:** empty-list text without a search (the
  open conversation is always in the list).

## Message list and answer renderer

Files in `lib/src/ai/ui/`: `message_list`, `message_bubble` (user bubble),
`assistant_message`, `assistant_blocks`, `chat_markdown` (`ChatBlockView`),
`track_row`, `track_actions`, `tool_card`, `tool_text`, `message_time`,
`chat_jump_button`, `chat_card_slot`, `messages_error`; the parser in
`markdown/` (pure Dart, no Flutter); view mapping in
`state/chat_view/{message_view,time_format}.dart`.

- **List:** a `CustomScrollView` with a centre (the first message loaded, or the
  saved scroll anchor): older pages are added above it (`loadOlder` within 600 px
  of the top), new text grows below, so neither moves what the reader sees.
  Within one viewport of the end it follows new text; further up it keeps its
  place and shows "Xuống cuối" (`ChatJumpButton`). The top message is saved in
  `chatScrollAnchorProvider` when scrolling ends.
- **Streaming:** only `AssistantMessage` of a streaming message watches
  `liveTextProvider(id)`. `AssistantBlocks` feeds a `ChatMarkdownStream`: closed
  blocks are parsed once and their widgets are reused (grouped by 40), only the
  open tail is parsed and rebuilt per delta. Dots (`KStreamingDots`) only while
  `turnState == streaming`; "Đã dừng" after Stop.
- **Grammar (own parser, no `markdown` package):** paragraphs (single newline =
  line break), flat bullet / numbered lists, `**bold**`, `` `code` ``, `[[t:ID]]`
  line. Everything else is literal text as typed (links, images, HTML,
  headings, quotes, fences); `*x*` loses its markers, `_` is never a marker. No
  model field holds a URL, so nothing in a block is tappable except a song row.
  Streamed output equals the full parse (property test).
- **Song row:** a `[[t:ID]]` line is a 36 dp row only when the id is in
  `ChatKnownTracks` (ids from this conversation's tool results); else the text.
  Tap plays through `playerControllerProvider` with the AI play context; the ⋮
  (desktop) or long press (phone) opens the library song menu. `ai` imports
  `library/ui` (the DAG allows `ai -> library`), so no `ChatHost` method is
  needed; `ChatTrackActions` is the test seam.
- **Tool card:** folded by default; "Đang chạy: ..." and a spinner while running.
  Every other tool row and every failed round is a card (see Cards):
  `chatCardBuilderProvider` is the slot, its default is `buildChatCard`.
- **Time:** footer time expands on tap / hover to "HH:mm · dd/MM/yyyy"; the
  copy button puts the text on the clipboard. A plugin switch shows the divider
  "Từ đây dùng <plugin> · <model>".

## Composer and pickers

Files in `lib/src/ai/ui/composer/`: `composer` (the box), `composer_field`,
`composer_text_controller`, `variable_list`, `context_chips`, `chip_labels`,
`prompt_chips`, `prompt_text`, `composer_notice`, `composer_buttons`,
`send_button`, `chat_plugin_icon`, `plugin_picker`, `permission_picker`,
`model_picker`; state in `state/chat_view/{composer_view,composer_inputs,
composer_send,prompt_apply}.dart`. `ChatSurface` shows `Composer` under the
body, except in History and in the no-plugin guide (no plugin, no messages).
The big prompt chips fill the greeting's `chips` slot; once the chat has
messages they are one small scrolling row above the composer.

- **Lock table** (`deriveComposerView`, pure; `composerViewProvider` feeds it
  the turn state, readiness, permission and struck chips): idle / error: Send,
  everything on. streaming / runningTools: Stop (tools: its tooltip says the
  running tool finishes and later calls do not run), plugin / model / permission
  pickers and prompt chips locked, the field stays editable. awaitingConfirm:
  Send and everything on (a new message denies the pending card; read-only
  denies pending calls). Send also needs `ChatReady` and no struck chip. A
  removed or reinstalled plugin makes the field read-only and disables the
  model button; the plugin picker stays on (the way out).
- **One note** above the field, by priority: readiness (key, model, config,
  removed, reinstalled) > struck chip > the note a refused send left
  (`composerSendNoticeProvider`: missing data, oversize, store failure; cleared
  by editing the text, by ×, by Huỷ and by an accepted send) > the gentle
  "model without tools" line. `ComposerNoticeView` maps them to `KInlineNotice`
  (warning tone; quiet for the gentle one). Plugin settings go through
  `ChatHost.openSettings(aiPluginPageLocation(id))`, "Tìm lời bài này" through
  `chatFindLyricsProvider` (the lyrics modal for the playing song).
- **Send:** `sendFromComposer` calls `ChatSessionController.send` and turns a
  refusal into the note; the field is cleared only by `SendSent` and only when
  the text is still what was sent. Oversize: [Gửi bản rút gọn] calls `send` with
  `shortVersion: true`.
- **Field:** `ComposerTextController` paints `{{variables}}` (group off or
  just-refused ones as warnings). Desktop shell: Enter sends, Shift+Enter new
  line; phone shell: Enter is a new line. **IME:** while `value.composing` is
  valid and not collapsed, Enter and the `{{` trigger do nothing, and the
  composing range keeps its underline inside a painted variable
  (`buildComposerSpan`). `{{` lists the catalogue names (not `{{input}}`),
  filtered by what follows; ↑ ↓ Enter / Tab / Esc work; a tap inserts.
- **Draft:** `ComposerDraftBinding` also reads the draft back, so parts that
  write `composerDraftProvider` (prompt chips) change the field.
- **Chips:** attached chips (× removes; struck while their tool group is off
  and `ai.var_bypass` is off) and the page / selection suggestions
  (`chatAttachmentsProvider.suggestions`, tap attaches).
- **Prompt chips** (`applyPrompt`): empty field and no `{{input}}`: send at
  once (a send that does not go through leaves the prompt in the field); typed
  text: prompt on top, text on the next line; `{{input}}`: only filled in with
  the blank selected. A prompt whose variable has no data now is dimmed with
  its reason ("Không có bài đang phát", "Hàng đợi trống").
- **Pickers** (`showSelectionPicker`, anchored dropdown on desktop, sheet on the
  phone, sizes decided in `kanaru_ui`): plugin (icon rows, state line from
  readiness, caption, footer "Thêm dịch vụ AI…" to the plugin store), permission
  (icon rows with descriptions; "Tự động" asks through
  `chatAutoModeConfirmProvider`, cancel keeps the picker open), model (text rows
  with Ảnh · Công cụ · context tags, struck when missing, "Tuỳ chỉnh" for added
  models). The permission control on the composer is the icon and a chevron
  only; tooltip "Quyền: <chế độ> · <mô tả>", semantics label "Quyền: <chế độ>".
- **Opening the model picker from elsewhere:** `modelPickerRequestProvider`
  (`request()`); the button row takes it after the frame and opens the picker
  anchored to the model button (dropped while the chat is locked). The error
  card's "Đổi model" calls `request()`.
- **Shared with the settings work:** `auto_mode_confirm.dart` (`AutoModeScope`,
  `confirmAutoMode`) is the default of `chatAutoModeConfirmProvider`
  (`chat_auto_confirm_provider.dart`, overridable in tests). Built-in prompt and
  variable texts come from the `aiset*` strings through `ai_builtin_texts.dart`
  (`builtinTemplateText`, `variableDescription`); the chat's `{{` list and
  prompt chips use it. It is a copy of the settings screens' helper, because
  `ai/ui` cannot import screens.
- **Tests:** `test/ai/ui/support/chat_ui_support.dart` now also fakes `send`,
  `stop`, `switchPlugin`, `switchModel`, `setPermission` (recorded in `calls`,
  they change `fakeChatBindingProvider`), readiness (`fakeChatReadinessProvider`),
  the composer's settings and prompt data; `test/ai/ui/composer/composer_harness`
  pumps the composer alone.

## Cards (`ai/ui/cards/`, `state/chat_view/card_view.dart`)

All cards are `KActionCard` (kit): round icon, title, second line, optional
reason, body slot, at most two buttons on their own row (one button at the end,
two share the row). `buildChatCard` (`chat_cards.dart`) picks the card of a
stored row:

| Row | Card |
|---|---|
| tool, `pending` / `allowed` | `ConfirmCard`: action, "<tool> · cần bạn cho phép", up to 6 songs (else 5 and "+N bài"), [Từ chối] [Cho phép]. An allowed card waits with no buttons |
| tool, `done` with a `ConfirmPart` / `DonePart` | `DoneCard` ("Đã làm: ..."): folded list of exactly what the API returned (added, removed, or "Hàng đợi cũ · N" for `play_tracks`); second line "Bạn đã cho phép / Tự động · <group> · ..." with what is already gone or not in the library |
| tool, `skipped` | `SkippedCard` (finished tone, no button): declined, declined by a new message, declined: no longer allowed (+ reason per `ExecRefusal`), expired, "Không chạy: bạn đã dừng", skipped by the item limit or size. `skipReasonOf` reads the stored `ConfirmPart` first, then the result text (Auto mode keeps no confirm part) |
| tool, `unknown` | `UnknownResultCard` ("Không rõ kết quả: ...", caution icon, no button): closed app or write timeout, then "Xem Hàng đợi / playlist trước khi nhờ AI làm lại." |
| tool `error` or assistant row with `limit_reached` | `LimitCard` (caution, no button, never retries) naming the call that did not run |
| assistant `error`, or `stopped` with an `ErrorPart` | `ErrorCard`: one per `ChatCardKind` (`errorCardSpec`, pure) |

- **Live or history:** `chatCardLiveProvider` / `chatTurnEdgesProvider` read the
  loaded window (always a suffix of the conversation): a card is of the latest
  turn when no user message follows it. Confirm and replay need the latest
  turn; an `ErrorCard` also needs to be the newest row (a retried round makes
  the earlier card read-only). `readOnly` removes buttons, the countdown clock
  and the alert role. [Xem] and [Mở hàng đợi] stay on old done cards;
  [Phát lại hàng đợi cũ] (`replayQueue(messageId)`) is latest-turn only.
- **One answer:** `ConfirmCard` keeps an in-flight flag (double tap, Allow then
  Deny: one controller call; a non-accepted answer re-arms the card);
  `ErrorCard` does the same for [Thử lại] (re-armed unless `DriverStarted`).
- **Confirm preview:** the stored card holds ids only, so
  `chatConfirmPreviewProvider` asks the tool's `describe` again on the library
  as it is now (summary = playlist name, songs); a refusal or an error leaves
  the card with what the call says. Rows come from `TrackRowsPreview` (cover 40,
  title, artist; text from the stored snapshot, cover from one batched `trackRowLoaderProvider` read per batch of rows shown, again when "+N bài" opens more, not a watch per row; "Không còn trong thư viện" only for ids whose read finished with no row, a failed read leaves them blank and is retried).
- **Error card source of truth:** the stored `ErrorPart` gives the kind through
  `cardOfStoredError`; for the newest row `chatLiveOutcomeProvider` (the
  session's `lastView`) wins, because it knows the host, the busy and timeout
  cards that the store keeps as plain `server`. Buttons follow the approved table
  (mockup 08), not `StoredErrorCard.action`: quota [Thử lại], too_large and
  context_length [Cuộc trò chuyện mới] (`chatViewProvider.startNewConversation`),
  model_not_found [Đổi model] (`modelPickerRequestProvider.request()`), blocked
  [Thử lại], blocked host no button, removed [Chọn plugin] (`showPluginPicker`),
  key / config [Mở cài đặt plugin], broken [Mở plugin] (`ChatHost.openSettings`
  with `aiPluginPageLocation`). Names: plugin from `chatPluginsProvider` (else
  "Plugin"), host from `chatCardHostProvider` (first declared host), model from
  the message.
- **Countdown:** a rate-limit card with an end time (`ErrorPart.retryAt` or the
  live view's) passes `KActionCardCountdown` (clock `chatCardClockProvider`,
  tests inject a fake): N giây / M phút S giây / "Thử lại lúc HH:MM" from an hour;
  at zero the button turns on, nothing is sent by itself.
- **[Xem]** on playlist cards goes through `chatPlaylistLocationProvider`
  (`playlistId` of the result to the playlist page, else the playlists list)
  and `ChatHost.openSettings(location)`.
- **Cut off when the app closed:** the running write is `unknown`
  (`UnknownResultCard`), the streamed text stays with "Đã dừng", then the
  assistant row (`stopped` + `cutOffByClose`) shows the "Lượt trả lời bị ngắt khi
  đóng Kanaru" card with [Thử lại].
- **Tests:** `test/ai/ui/cards/` (`card_harness.dart` pumps one card through
  `buildChatCard` in Vietnamese over `FakeChatSession`, which now fakes `allow`,
  `deny`, `retry`, `replayQueue` and `setView`).

## Play context label

`AiPlayContextLabelSync` (top of `AppShell`) sets
`aiPlayContextLabelProvider` from localizations ("Trợ lý AI" / "AI assistant")
and follows language changes. It sits in the shell, not in the chat surface,
because a tool call can start a queue while the chat is closed.

## Tests

`test/ai/ui/support/chat_ui_support.dart`: `FakeChatSession` (a
`ChatSessionController` without database or plugin; numbered conversations,
records calls), `chatUiOverrides`, `RecordingChatHost`. Shell tests use the same
overrides through `test/shell/support/desktop_now_playing_host.dart`
(`withChat`, `savedSettings`, `playerPhase`).

## "Hỏi AI" entry points

One interface, one implementation, no second route:

- `library/ui/menus/ask_ai_entry.dart`: `AskAiEntry.ask(context, AskAiTarget)`
  and `askAiEntryProvider` (null until the app overrides it; `library` cannot
  import `ai`). `lib/kanaru.dart` overrides it with `askAiEntryOverride`, an
  `AskAiEntryShell`.
- **Menus:** `loadMenuEnv` puts the entry in `MenuEnv.askAi`; builders call
  `askAiRow(env, title, target)` (`menu_items.dart`), which is the old
  "Sắp có" row while the entry is null. Targets: song (id, title, artists,
  album), album (key + title), artist (key + name), selection (ids only, at
  most `askAiMaxSongs`, plus the real count; no library read),
  playlist (uid + display name). The queue row menu, the Now Playing ⋮ and the
  song menu of a row inside the chat are the same song menu, so they need no
  code of their own. Genre, language, folder and Favorites menus have no
  Ask AI row (the mockup draws none).
- **Screens:** Now Playing mobile button row (tile 3, inert with a "coming
  soon" tooltip while there is no entry) and the desktop header ✦ after the
  Dịch pill (absent without an entry); both ask `AskAiTarget.nowPlaying()`.
  No ✦ on the lyrics header.
- **Detail pages (phone):** the ✦ of the mobile shell's `PageHeaderScope.trailing`
  (`mobile_shell.dart`) shows in every `PageHeader`, so album, artist, genre,
  language, playlist and Favorites headers are `[←] title [page actions] [✦]`
  (the playlist's ✏ comes before ✦). It opens the chat page; the page's chip is
  then offered as a dashed suggestion (`chatSuggestionsProvider` from
  `chatPageLocationProvider`). Desktop detail headers have no ✦ (the top bar
  has it). Tested in `test/shell/detail_header_ai_test.dart`.
- **`AskAiEntryShell.ask`** (`shell/ui/ask_ai_entry_shell.dart`): attaches the
  chip (`chatAttachmentsProvider.attachTarget`), closes the history list, shows
  the chat (desktop: `RightPanelKind.chat`, which also replaces the queue;
  phone: `openChatPage`, so a chat already on top is left alone and a second
  `/chat` is never pushed), then `composerFocusRequestProvider.request()`. The
  form factor is read from the caller's context at call time, falling back
  to the window size when that context is already gone.
- **Page suggestions** (`state/chat_view/page_suggestions.dart`):
  `chatPageLocationProvider` holds the location of the page the chat covers.
  `AppShell` writes it on every route change except while `/chat` is in the
  stack (on top, or with a page opened from inside the chat above it), so on desktop it follows the page beside the panel and on the phone it
  is the page captured before the push. `chatSuggestionsProvider(l10n)` returns
  the chips in order: Bài đang phát (only when a track is loaded), "N bài đã
  chọn" (selection), then the page's chip (album / artist / genre / language /
  playlist; a root page or a page without a chip adds none), all through
  `chipRefOf`. `ChatSuggestionsSync` (inside `ChatSurface`) listens to them and copies
  changes into `chatAttachmentsProvider.setSuggestions`; the first value is
  pushed after the first frame, never from `build`.

## Review fixes (behaviour notes)

- Liveness: event rows (plugin or model switch lines) are not a newer turn (`turnEdgesOf`); an error card stays live after a plugin switch.
- Selection chip and menu: ids only, at most `askAiMaxSongs` (= engine `chipMaxRows`); nothing is read from the library when the menu opens or the selection changes. A selection above the cap keeps its first `askAiMaxSongs` ids; the chip label carries the real count (`AskAiSongs.total` in `ChipRef.label`, read back with `songsChipTotal`), and the data the model reads then has `total: <real count>` and `listed: <rows sent>` ahead of the rows (`ChipResolver._songs`), so a cut list is not read as the whole selection.
- History search: the typed text (`chatHistoryQueryProvider`) is debounced into `chatHistorySearchProvider` (250 ms, `chatHistoryDebounceProvider`); store changes are coalesced with the same delay.
- `ChatPluginIcon.removed` draws the "?" tile only for an uninstalled plugin; no plugin or plugins still loading shows the AI glyph. History shows "Plugin đã gỡ" only when a plugin id is set but not installed.
- Skipped cards: the engine result wording is read in one function (`skipFromResultText`); the engine has no reason code for Auto mode yet.
- Empty chat frame: `Center` + shrink-wrapped `ListView` (no `LayoutBuilder`, architecture gate).
