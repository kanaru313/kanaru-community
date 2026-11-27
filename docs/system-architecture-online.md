# Online sources architecture

The `online` module (`lib/src/online/`) sits above `library`, `playback` and `plugins` (`architecture.yaml`). It owns what streaming plugins (`metadata.type = streaming`) return and how the app turns it into rows and playback. This document grows with the module; today it covers the contract, the run client and failures.

## Layout

- `domain/contract/`: pure Dart models and limits. No Flutter, drift or `data/` import.
- `domain/failure/`: `OnlineFailure` (kind + class), `OnlineResult`, and `decideOnlineRun` (outcome to decision).
- `data/run/`: `StreamingRunClient`, `InstallRunQueue`, the isolate runner.
- `data/contract/`: readers that check plugin output once. They use `cleanText` and `pluginRequestHeaders` from `plugins/domain`.

`online` does not import `lyrics`, so it has its own output exception (`OnlineOutputException`) instead of the lyrics one.

## Contract

Script output formats and every limit: [plugin-host-api.md](./plugin-host-api.md) § Streaming scripts. Limits are constants in `domain/contract/contract_limits.dart`.

Models:

- `OnlineCard` (`kind` track / album / playlist / artist, `id`, `title`, optional subtitle, artist, `artists`, `album`, duration, artwork and web links). `toString` shows kind and id only.
- `OnlinePage` = `sections` (`PageSection`: layout `top|list|shelf`, cards, optional `moreFilter`) + `filters` + `next`. `PageRead` adds `notes` (positions and fixed reasons, never plugin text) and `rejectionSummary` for the app log.
- `StreamAnswer` (url, headers, mime type, expected `StreamContainer`, bitrate, UTC expiry); `toString` hides url and headers. `StreamRead` is `StreamPlayable` or `StreamUnsupported(mediaType)` (HLS and any type outside the allow-list).
- `OnlineCapabilities.fromScripts(keys)`: optional scripts a plugin declares (`search` and `stream` are required by the manifest).
- `item_ref.dart`: `encodeItemId` / `decodeItemId` (one canonical spelling per id), `isUrlShapedId`.

Readers (`data/contract/`): `readSearchOutput`, `readStreamOutput`, `readAutocompleteOutput`, built on `readCard` and the helpers in `output_json.dart`. Rules in short:

- A wrong top-level shape throws `OnlineOutputException` (fixed reason text). A bad card, section, filter or optional field is dropped or read as absent, with a note.
- Ids are never trimmed or rewritten; a URL-shaped id, `.`, `..`, a control character or a length over 200 drops the card.
- Links: `https` only, at most 2000 characters, no user info, no written port. The stream url allows 8 KiB and also refuses a written port.
- A page holds at most 200 cards over all sections; `sections` win over `items`; lazy sections and `more.script` are not read yet.

## Run client

`StreamingRunClient` is the only way the module runs a streaming plugin. Every request has `kinds = {streaming}` and `logInput: false` (the input holds what the user typed), and a time limit: `autocomplete` 5 s, `search` 20 s, `stream` 20 s.

- **Serial per install.** `search` and `stream` of one install run one at a time through `InstallRunQueue` (FIFO; a `stream` waits behind the run in flight but goes ahead of waiting searches). Reason: a run writes the plugin's whole storage map back, so two runs of one plugin would overwrite each other.
- **Autocomplete is outside the queue.** It must not wait behind a search, so it runs with `persistStorage: false`: empty storage, nothing saved, no write-back race. A newer autocomplete (or `cancelAutocomplete`) cancels the older one, which returns `OnlineAbandoned`. It never reports rejected output and never logs: a broken autocomplete only shows no suggestions. A plugin that needs a cached token for autocomplete will not get it.
- **Cancel.** A caller's `RunCancel` while waiting in the queue leaves the queue, the runner is never called and the result is `OnlineAbandoned`; while running it is passed to `PluginRunner.run`.
- **Validation.** `search` / autocomplete query is trimmed, 1-2000 code points (else `ArgumentError`; an empty autocomplete query returns no suggestions without a run); a `stream` id is not empty.
- **Reading.** Output over 64 KiB is read on another isolate. A reader exception is a failure `invalidOutput` and is reported to the plugin's log with its fixed reason; a page with dropped cards is still `OnlineOk` and its summary is reported. An `HLS` stream is `OnlineOk(StreamUnsupported)`: the caller maps it to the item-level `unsupported` cause.

## Failures

`OnlineFailure` has a `kind` and a class: **track** (this item only: `gone`, `unsupported`, `authRequired`, `invalidOutput`, `blockedHost`, `pluginMissing`), **network** (`network`) or **source** (everything else: `rateLimited`, `paused`, `needsConfig`, `busy`, `timeout`, `pluginChanged`, `server`, `authFailed`, `noScript`, `internal`). `decideOnlineRun` switches over every `RunOutcome` and error kind with no `default`, so a new case breaks the build.

| Outcome | Failure |
|---|---|
| `RunOk` | data; sticky: rate limit seen = `rateLimited`, else by the first failed fetch (network, rateLimited, invalidResponse = `invalidOutput`, blockedHost; consent / abandoned / invalid request = `server`). Counts only when the answer is empty. |
| script error `rateLimited` / `quota` | `rateLimited` (retry-after) |
| script error `network` / `unavailable` / `unsupported` | `network` / `gone` / `unsupported` |
| script error `auth` | `stream`: `authRequired` (track); `search` / autocomplete: `authFailed` (source) |
| script error `server` | by the failed fetch: network, `rateLimited`, `blockedHost`; else `server` |
| script error `invalidResponse` | by the failed fetch: network, `blockedHost`; else `invalidOutput` |
| `RunFailed` timeout | `network` if a fetch failed on the network, else `timeout` |
| `RunFailed` memory / stack / output too large / internal | `invalidOutput` / `invalidOutput` / `invalidOutput` / `internal` |
| cancelled by caller / by a plugin change | `OnlineAbandoned` / `pluginChanged` |
| busy / paused / needs config | `busy` / `paused(until)` / `needsConfig(fieldTitles)` |
| unavailable: not installed / unreadable / no script | `pluginMissing` / `internal` / `noScript` |

The `auth` split: on `stream` it means this item needs an account or an age check (other items may play); on `search` it means the source's own login or key is wrong, which the user fixes for the whole source.
