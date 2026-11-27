# AI chat settings (Settings › AI chat)

The settings page of the AI chat. It sits in `screens/settings/` and reads the
engine's per-key settings providers (`ai/state/ai_settings_providers.dart`,
keys in `system-architecture-ai.md`). Every control applies and saves at once;
there is no Save button. This file grows with each part of the page; it
describes what has landed.

## Route and links

- `SettingsPaths.ai` (`/settings/ai`, `screens/settings/settings_routes.dart`)
  opens `AiSettingsPage`. The root row "Trò chuyện AI" is a normal row now (it
  was a "Coming soon" row); its desc is `settingsRootAiDesc`.
- `ai/ui/ai_settings_link.dart` declares `aiSettingsLocation`,
  `aiPluginStoreLocation` (`/settings/plugins?kind=aiChat`) and
  `aiPluginPageLocation(installId)`. The route reads the first; the chat UI
  imports them instead of `SettingsPaths` (`ai/ui` never imports `screens`).
  Same pattern as `lyrics/ui/lyrics_settings_link.dart`.

## Page sections (`screens/settings/ui/ai/`)

Order: Dịch vụ AI, Quyền, Hướng dẫn chung, Công cụ, Prompt mẫu, Lịch sử trò chuyện, Hộp xác nhận. Texts come from the `aiset`
l10n part (key prefix `aiSet`).

| Section | File | Reads / writes |
|---|---|---|
| Dịch vụ AI | `ai_services_section.dart` | `chatPluginsProvider` (installed ai-chat plugins with readiness and default model), `aiLastPluginProvider` ("dùng gần nhất"). A tap opens the plugin page; "Thêm dịch vụ AI" opens the store filtered to AI. |
| Quyền | `ai_permission_section.dart` | `aiDefaultPermissionProvider` through `LyricsChoiceRow<AiPermission>`; choosing Tự động goes through `confirmAutoMode` as the picker's `confirm:`. |
| Hướng dẫn chung | `ai_instructions_section.dart` | `aiInstructionsProvider` through `KTextFieldRow(maxLength: 2000)`. The setting counts code points while the field counts characters: an edit that would pass 2000 code points (a multi-code-point character) is rejected, the previous text and caret stay; the end is never cut. The field has the section title as its accessible name. |
| Công cụ | `ai_tools_section.dart` | one `KSwitchRow` per `AiToolGroup` (`aiToolGroupProvider(group)`: one key each), "Thống kê nghe" locked while the history is off (`historyEnabledProvider`), `aiVarBypassProvider` (no dialog). |
| Prompt mẫu | `ai_prompts_section.dart` | `aiPromptsProvider` through `ReorderableToggleList<int>` (value = index in the stored list); edits go through `promptTemplateOpsProvider` (`reorder`, `toggle`, `restoreDefaults`). Unreadable items and builtins without text stay in the list but are not shown, so a shown move is converted to list indices. A body with an unknown `{{variable}}` (`analyzeTemplate`) gets a "Biến lỗi" tag and the problem line replaces the body. Row tap and "Thêm prompt" show a "Sắp có" toast until the editor ships. "Khôi phục prompt mặc định" toasts how many builtins it added back. |
| Lịch sử trò chuyện | `ai_history_section.dart` | `aiChatStatsProvider` (reading / failed with Thử lại / "N cuộc trò chuyện · X MB"); "Xoá" is off while reading, while a delete runs and at 0, on when reading failed (stats count only conversations with a message, so the empty one the chat reopens is not counted). It asks, then calls `ChatSessionController.deleteAll` (stops the turn, clears the run logs of the chat plugins). The box adds "Câu trả lời đang chạy sẽ dừng." only while the turn is `streaming` or `runningTools`. |
| Hộp xác nhận | `ai_confirm_section.dart` | Added by the page only while `aiAutoAskProvider` is false; "Bật lại" writes true (the block goes away) and toasts. |

Service line (`ChatReadiness`): ready = default model, plus " · dùng gần nhất"
for the plugin in `ai.last_plugin`; needs a key = "Cần API key"; needs a model or other fields = "Cần cấu hình: <fields>" (a missing model reads as the model field); all red lines. A loading or failing plugin list shows no rows and no empty note.
When the plugin used last was removed and others are installed, a line under
the title says which one new chats use (`resolveChatPlugin`); the removed
plugin's name comes from its tombstone row (`aiRemovedPluginNameProvider`, only when `removedAt` is set) and the plugin new chats use from the engine's `aiChatPluginProvider`.

## Shared "Bật Tự động?" box (`ai/ui/auto_mode_confirm.dart`)

`confirmAutoMode(context, ref, scope: AutoModeScope)` is the `confirm:` of the
settings picker and of the chat's permission picker. With `ai.auto_ask` off it
returns true at once. Otherwise it opens the box over the picker (scope picks
the title): cancel, Esc and Back return false and change nothing; confirming
returns true, and with "Hiện lại lần sau" unticked it writes `ai.auto_ask`
false. A toast names the new state and, when unticked, where to turn the
question back on.

## Template and variable labels (`ai_catalog_labels.dart`)

The engine stores keys only. `builtinTemplateText(l10n, key)` returns the
label and body of a builtin template (`BuiltinTemplateKeys`), `null` for any
other key; `variableDescription(l10n, variable)` the description of an
`AiVariable`; `variableToken` writes `{{name}}`. ARB messages cannot hold a
literal `{{x}}` (no `use-escaping`), so bodies take the tokens as placeholders
and this file fills them.

## AI chat on the plugin pages (`screens/plugins`)

- Plugin page (`plugin_head_card.dart`): an `ai-chat` plugin gets the row
  "Dùng trong Trò chuyện AI" (desc + "Đổi ở Cài đặt › Trò chuyện AI", ↗) that
  opens `aiSettingsLocation`; the service itself is chosen in the chat input.
- Remove dialog: an `ai-chat` plugin lists "Các cuộc trò chuyện đã dùng plugin
  này" under "Vẫn giữ" (conversations stay readable).
- Store rows (`StoreRowFrame`): an installed `ai-chat` row whose
  `chatPluginsProvider` readiness is `ChatNeedsKey` shows "Cần API key" after
  the kind and author chips. Same answer as the chat composer.

## Not here yet

The prompt editor (tap a row, "Thêm prompt"): a later part (D2).
