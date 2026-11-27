# Online sources architecture

The `online` module (`lib/src/online/`) sits above `library`, `playback` and `plugins` (`architecture.yaml`). It owns what streaming plugins (`metadata.type = streaming`) return and how the app turns it into rows and playback. This document grows with the module; today it covers the contract.

## Layout

- `domain/contract/`: pure Dart models and limits. No Flutter, drift or `data/` import.
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
