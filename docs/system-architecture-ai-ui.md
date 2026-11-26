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

`chat_links.dart` holds the locations the chat links to (`aiSettingsLocation`,
`aiPluginStoreLocation`, `aiPluginPageLocation(installId)`); the settings work
replaces it with its own file.

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

| Provider | Holds |
|---|---|
| `chatViewProvider` | `historyOpen`, `renaming`, `renameText`; `back()` (rename, then history; true when it took a step), `startNewConversation()`, `deleteConversation(id)`, `commitRename()`, `ensureConversation()` |
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
ends a rename when another conversation opens. Body, in order: the history area
(`ChatHistorySlot`, empty until the history page) when the flag is set; nothing
while the messages load; the message list (not built yet) when there are
messages; with none: the no-plugin guide (`ChatNoPluginGuide`: cloud option
[Mở kho plugin AI] → `host.openSettings(aiPluginStoreLocation)`, consent line;
no MCP option until MCP exists) when no `ai-chat` plugin is installed, else the
greeting (`ChatEmptyGreeting`, with a slot for the prompt chips). The removed
and reinstalled plugin states are notices above the composer, not bodies.

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
