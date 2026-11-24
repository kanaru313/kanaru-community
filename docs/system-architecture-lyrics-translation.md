# System architecture: lyrics translation

Translation of the shown lyrics through installed `translate` / `ai-translate`
plugins. Code: `lib/src/lyrics/{domain,data,state}/translation/`. This page
covers the engine and its providers (no UI watches them yet). Tables:
[system-architecture-database.md](./system-architecture-database.md)
(`lyrics_translations`, `track_translation_prefs`). Running a plugin (bridge,
fetch, consent, deadline, logs, 429 pause, run gate) is the plugin runner's:
[system-architecture-plugins.md](./system-architecture-plugins.md).

## Flow

```
trackLyricsProvider(track) (shown lines) ─┐
translation on / service / target (settings) ─┤
track_translation_prefs (per-song target) ─┤
effectiveTranslationServiceProvider ─────────┘
        ▼ trackTranslationProvider(track)   autoDispose, listens, never owns a run
  content hash → saved row of the service, complete       → ready (or same)
                 else newest complete row of another live plugin → other(id), no run
                 else no service                          → failed(noService)
                 else 1 s debounce → TranslationJobs.request
        ▼ translationJobsProvider            keep-alive, owns every run
  gate (one run at a time, FIFO) → TranslateRunner → PluginRunner.run
        ▼ each finished chunk is merged into the row at once (complete = 0);
          after the last chunk the row is completed (source language, settings)
```

The view provider only subscribes. Its inputs are `ref.listen`ed, never
`watch`ed, so a change never rebuilds it and never lets go of a running job.
The jobs owner is `TranslationJobsNotifier` (`translation_engine_providers.dart`);
its state is `Map<JobKey, JobStatus>`: only keys that run or failed have an
entry, the result of a finished job is the saved row.

## Cache and job identity

- Row key: `(content_hash, install_id, target_lang)`; the hash is the sha256 of
  the non-blank lines joined by `\n` (timestamps, gaps and words ignored).
- Job key: the same triple. One job per key; a second request joins it.
- Lines sent: the unique trimmed non-blank lines, chunked by the plugin's
  `translate.maxLines` / `maxChars`. Caps: 1000 lines, 20 000 characters, 20
  chunks per song; above them nothing is sent (`tooLong`).
- A target language the plugin does not list in `spec.languages` (exact code
  match; `zh-Hans` and `zh-Hant` differ) fails before any send with
  `unsupportedLanguage(target)`; nothing is sent or cached.
- A resume reads the row and sends only the lines it lacks, so a dispose, a
  kill or a failed chunk never loses billed work. After a restart the
  detected-language votes of the earlier chunks are gone: the source language
  is voted from the chunks of that run (a complete row keeps what was voted).
- `settings_json` = `{pluginVersion, model, style, instructionHash}` read from
  the plugin's stored config for the run (`PluginTranslationServices`); the
  instruction text is never stored. A saved row whose settings differ from the
  plugin's now shows `settingsDiffer`; nothing re-runs by itself. A row whose
  chunks span a settings save keeps the settings of its first chunk, so it
  reads as differing and "Dịch lại" is offered.
- Model, style and the note ("Lời dặn thêm") are the plugin's own settings
  (`model`, `style`, `customInstruction`), written by the commands through
  `PluginActions.configWrites`; a key the manifest does not declare is
  `ConfigWrite.unknownKey`. A run never carries `configAppend`.

## Gate and cancellation

- `TranslationGate` lets one translate run through at a time, app-wide, in the
  order asked. At the front of the line a waiter that is no longer wanted is
  dropped before it sends.
- Wanted = the job has a watching view, translation is on, and the job's plugin
  is the chosen live service (`mayRun`), checked at the top of each step, at
  the front of the gate and again after the plugin was re-read, right before
  the send.
- A chunk that was sent is never cancelled by translation: its result is
  cached even when every view went away (the owner, not the view, holds the
  run). Only a forced re-run ("Dịch lại") passes a `RunCancel`; cancelling it
  keeps the old row.
- The platform may still cancel a sent chunk (plugin update or remove):
  `RunCancelled(pluginChanged)`; that chunk is lost and sent again (at most
  three switches in a row, then `server`).
- Before each send the plugin is read again: a changed version sends nothing
  for the old plan and plans again; the in-memory partial of the old version
  (detected languages, forced lines) is dropped.
- Forced re-run: ignores the saved row, keeps it on screen
  (`loading(background: true)`), collects the lines in memory and replaces the
  row only when every chunk is done. When every view goes away the chunk in
  flight still finishes, no new chunk is sent, and the finished lines stay in
  memory as the forced partial of (key, plugin version, settings). A retry or
  a new "Dịch lại" with the same version and settings sends only the missing
  lines; another version or other settings drops the partial, and so does
  cancelling. A kill of the app loses it (accepted).

## Failures

`TranslateRunner` is the only code that calls the plugin runner: one
exhaustive `switch` over `RunOutcome` (no `default`), after the run contract's
consumer table (PLUG-02 C3, Translation column):

| Outcome | Result |
|---|---|
| `RunOk` valid | chunk, cached |
| `RunOk` rejected by the output rules | `reportRejectedOutput(id, 'translate', reason)` + `invalidResponse` (the sticky failure below when there is one) |
| `RunOk` echo (every text equals its source) + `fetchFailure` / `rateLimitSeen` | failure of that kind, not cached |
| `RunScriptError` auth / quota / rateLimited / invalidResponse / server | `badKey` / `quota` / `rateLimited(until)` / `invalidResponse` / `server` |
| `RunFailed` timeout / memory, stack, outputTooLarge / internal | `network` / `invalidResponse` / `server` |
| `RunCancelled(caller)` | nothing |
| `RunCancelled(pluginChanged)` | sent again |
| `RunBusy` | sent again once, then `server` |
| `RunPaused(until)` | `rateLimited(until)` |
| `RunNeedsConfig(fields)` | `needsConfig(fields)` |
| `RunUnavailable` notInstalled / others | `pluginGone` / `server` |

Sticky fetch failure (`RunOk` echo): `rateLimitSeen` or fetch kind
`rateLimited` → `rateLimited`; `network`, `abandoned` → `network`;
`blockedHost`, `notConsented`, `invalidRequest` → `server` (host or plugin
setup, a retry does not fix it); `invalidResponse` → `invalidResponse`.
`rateLimited(until)` is the plugin's pause end (`PluginPauses.until`), else now
plus the script's wait, else the runner's default pause.

- A failed job stays failed: no automatic retry (it would bill again). It is
  tried again by `retry` ("Thử lại", sends only the missing lines, in the
  failed job's own mode: a failed "Dịch lại" stays forced, and every view that
  watched it keeps watching), by a forced
  re-run, by a newer plugin version (once), and by a save of that plugin's
  settings (once per save).
- A save is counted while the plugin has a job (`PluginConfigEpochs`; the first
  emission of the store's stream is the baseline; a save landing between
  `listen` and that first emission is taken as the baseline, which is accepted). A job that fails in a later
  epoch than it started in is tried once more at once; failed jobs that a view
  watches are retried once per save while their failure stays visible until
  the retry answers; failed jobs nobody watches are forgotten (they run when
  the song is shown). A running chunk is kept.
- A database read failure (cache, plugin store) is a `server` failure with a
  retry, never "no translation" and never switches translation off.
- Logs carry the error type only, never lyric text, titles, keys or settings.

## Interface to the plugin runner (PLUG-02)

`PluginRunner.run(PluginRunRequest(installId, script: 'translate', input:
{lines, to, song: {title, artist, lyrics}}, timeout: spec.timeoutSec, kinds:
{translate, aiTranslate}, logInput: false), cancel: RunCancel?)` and
`reportRejectedOutput`. Nothing else of the runner is used.

## Providers and commands

- `trackTranslationProvider(TrackId)` → `TranslationView{status, map,
  sourceLang, installId, settingsDiffer, settingsJson, linesDone,
  linesTotal}`; a watcher is what asks for the translation, so the UI must
  keep it watched while it shows or edits it. `linesDone / linesTotal` count
  unique lines (not chunks) while a run goes (`JobRunning.linesDone /
  linesTotal`) and after a non-forced run that failed half way: then `map`
  holds the lines of the saved incomplete row (`partialFailureView`), the
  status stays `failed`, and the views read it as "dịch dở n/m dòng". A forced
  run keeps its old complete row instead.
- `effectiveTranslationTargetProvider(TrackId)`: the language the track is
  translated into (song's own, else global, else the app language's default).
  It and `readTranslationPlan` both call `pickTranslationTarget`, so the
  modal's "Dịch sang" and the run never disagree.
- `translationLayoutProvider(TrackId)`: null while translation is off, else
  `{replace, rtl}` (display setting, target in `rtlLanguages`). Views watch it
  and watch `trackTranslationProvider` only when it is non-null.
- `translationCreditProvider(TrackId)`: who made the translation on screen
  (plugin name; model and style titles read from the plugin's `model` / `style`
  select fields by the ids in `settingsJson`; `other`; line counts of a partial
  run), null when none is shown (same language, plugin gone, nothing yet).
- `playingTranslationProvider`: the playing track's view, idle when nothing
  plays.
- `translationCommandsProvider`: `toggle`, `setService`, `setDisplay`,
  `setTarget(track, lang)`, `retranslate(track)`, `retry(track)`,
  `cancelRetranslate(track)`, `setModel`, `setStyle`, `setNote`.
- Seams: `translationAppLanguageProvider` (default `en`; `lib/kanaru.dart`
  overrides it with `translationAppLanguageOverride` from the appearance
  setting, the lyrics module cannot read it), `translationDebounceProvider` (1 s) and
  `translationTimerProvider` (tests).

## UI: translated lines (`lyrics/ui/translation/`)

Mockup: `mockups/screens/07-lyrics.md` (Dòng lời, Các lớp trong một dòng),
legend **Dịch**.

- **Per-line selection.** Synced, plain and card lines are built through
  `TranslatedLineScope`, which watches
  `trackTranslationProvider(id).select((v) => lineTranslationOf(line, v))`
  (`LineTranslation`: text, pending, replace, rtl). A chunk that arrives
  rebuilds only the built lines whose text it covers; the views never watch the
  whole view. No watch happens while `translationLayoutProvider` is null, so
  translation off asks for nothing.
- **Line widget.** `LyricsLine` takes one optional `LineTranslation`;
  `TranslatedLineText` draws it in the ambient (main) style: original with the
  translation under it, or the translation as the main line over a small dim
  original (Thay dòng; a line without a translation keeps its original). Gap
  lines, blank lines, translations equal to the source and the `same` status
  show nothing (`lineTranslationOf` over `translationFor`). Semantics label of
  a translated line: "original, translation".
- **Sizes and colours** (`translation_text_styles.dart`): synced translation
  0.62 of the line, w500, `onSurface` 64 % on the sung line, the dim level
  (never above 64 %) on the others; replaced original 0.5. Plain lyrics: 0.8 and
  0.7 of the plain size, `onSurfaceVariant`. Card: 13, w500, 64 %, one fixed row
  under the sung line while translation is on (blank for a gap), so the card
  keeps its height.
- **Pending.** `TranslationPlaceholder`: a bar 55 % wide, one translation line
  high, a light sweep of `KMotion.slow * 3`; still with animations off. Shown
  under every non-blank line while the status is loading and not a background
  re-run (which keeps the old lines instead).
- **Credit.** `TranslationCreditLine` is the last item of the synced and plain
  lists: "Dịch bởi plugin · model · phong cách · ngôn ngữ", "Bản có sẵn của
  plugin" for another plugin's saved translation, "… · dịch dở n/m dòng" for a
  partial run; centred with centred lyrics. Language names are the `lyricsLang*`
  keys (`translationLanguageName`).
- **Anchor.** After a translation arrives, changes or goes away,
  `SyncedLyricsView` invalidates the measured heights and re-anchors the sung
  line once per frame without animating (the font size never animates).
- RTL: `Text.textDirection = rtl` on the translation when the target is in
  `rtlLanguages`.

## UI: the Dịch lời modal (`lyrics/ui/translation/modal/`)

Mockup: `mockups/screens/07-lyrics.md` (Modal Dịch lời, T1–T9), legend **Modal**
and **Modal lỗi dịch**. Entry points (header button, pill, `T`, ⋮) are a later
change; they call `showTranslateModal`.

- **Frame.** `showTranslateModal(context, trackId, {followsPlaying})` opens a
  sheet (mobile) or a 440 dp dialog (desktop) through `showTranslateFrame`.
  Each sub-page (`Dịch vụ dịch`, `Dịch sang`, `Tinh chỉnh AI`) is its own route
  over the modal, so Esc and Back close the topmost first. All routes of one
  open modal register in `TranslateModalControl`; `closeAll()` pops them
  topmost first (a store or settings link, "Dịch lại", the song changing).
- **State read.** `trackTranslationProvider(id)` (status, map, source language,
  `settingsDiffer`, line counts), `translationCreditProvider`,
  `effectiveTranslationTargetProvider`, `translateServicesProvider` (installed
  translate / AI plugins, the chosen one, "gone" when it is chosen but not
  installed) and `translateTuneProvider(installId)` (model / style select
  fields with the user's own choices, their stored values, the note).
  `translateSettingsDiff` compares `settingsJson` of the shown translation with
  the plugin now (model, style, note hash, version) for the bottom bar.
- **Body.** Preview (sung line, else the first line with text, through
  `TranslatedLineScope`; [Dưới dòng | Thay dòng] writes `setDisplay`; credit and
  ⟳) · language row (source = read-only label from the plugin's `detected`,
  `KSwitch`, target ▾) · service row · "Tinh chỉnh AI" row (AI plugins only) ·
  one status line · "Phiên âm" (dim, "Sắp có", only for ja / zh / ko lyrics) ·
  bottom bar only for another plugin's copy or differing settings. With no
  translate plugin the service rows are the "Chưa có tiện ích dịch" card.
- **Status line** (`translate_status_line.dart`, strings in
  `translate_failure_labels.dart`): one strip per `TranslationFailure`
  (`errorContainer`; 429 shows the clock and no button; the buttons are
  [Thử lại] `retry`, [Cấu hình] plugin page, [Đổi dịch vụ] / [Chọn] service
  page); "dịch dở n/m dòng" for a failed run that left lines; "Đang dịch… n/m
  dòng" with [Huỷ] (`cancelRetranslate`) only for a forced run; "đã là <ngôn
  ngữ>" for `same`. On the mobile shell two buttons go on their own row.
- **Dịch lại** (`retranslateInBackground`): the modal closes, the old
  translation stays, a listener on the track's translation (which also keeps
  the run held) shows "Đã dịch lại · <style or plugin>" when the forced run
  ends ready, and lets go when it fails or never starts (5 s).
- **Free limits.** "Áp dụng cho" is always on "Mọi bài" (the other two segments
  are inert with the Pro caption and `ProBadge`); the model, style and
  "Lời dặn thêm" write the plugin's own settings (`customInstruction`) through
  `TranslationCommands`, one note for every song. A refused `ConfigWrite`
  shows its error line under the field; the note saves on focus loss, on
  [Xong] / [Dịch lại] and when the page closes.
- Links (`translate_links.dart`): store `/settings/plugins?kind=translate`,
  plugin page, ⚙ `/settings/lyrics`; the modal closes (and the desktop Now
  Playing panel) before the router moves.

## Not here (Pro or later)

Per-song or per-queue service and note, translate ahead ("Dịch trước"), the
source-language picker, streaming translate, transliteration and the cache
clear on the Data page. Public code only holds the locked surface.
