# Online contract fixtures

Real outputs of the `search`, `stream` and `autocomplete` scripts of the Audius, Jamendo and YouTube streaming plugins (none needs a key), read by `test/online/contract/fixtures_test.dart` to prove the online contract readers accept what real plugins answer. The tests never touch the network or the plugins clone.

## Record

Network needed; run by hand, never in CI. From the repo root:

```bash
node test/online/fixtures/record-fixtures.js \
  /home/hieunm/dev/apps/kanaru/kanaru-plugins test/online/fixtures
grep -rEn 'ip=|sig=|signature=|token=|key=' test/online/fixtures/*/ || echo clean
```

The recorder runs each script through the plugins clone's `tools/source_harness.js` with the app runtime's limits (10 sends, 20 s), carries storage from one script to the next, writes a file only when the script answered `ok`, and prints `slug script status sends durationMs`.

## Sanitising

`stream.json`: the `url` keeps scheme, host and path; the query becomes `fixture=1` and the fragment is dropped (signed stream links carry the recorder's IP and a signature). Header values are kept (these plugins set no cookies). The recorder exits non-zero when a written file still contains `ip=`, `sig=`, `signature=`, `token=` or `key=`. Never commit unsanitised output. Re-record when a plugin's output contract changes.

## Provenance

Recorded live on 2026-11-28, query `Blinding Lights` (autocomplete `blinding`), stream of the first track card of the search.

| Slug | Script | Plugin version | Sends | Duration ms | Source |
|---|---|---|---|---|---|
| audius | search | 4 | 1 | 1579 | live |
| audius | stream | 4 | 1 | 1065 | live |
| audius | autocomplete | 4 | 2 | 1796 | live |
| jamendo | search | 1 | 1 | 771 | live |
| jamendo | stream | 1 | 1 | 651 | live |
| jamendo | autocomplete | 1 | 1 | 536 | live |
| youtube | search | 3 | 1 | 788 | live |
| youtube | stream | 3 | 2 | 1076 | live |
| youtube | autocomplete | 3 | 1 | 210 | live |

No fixture is hand-written.

## Known deviations the fixtures keep

- `jamendo/autocomplete.json` is `{ "suggestions": [] }`; the contract is a plain array, so the reader refuses it.
- `jamendo/search.json` filters carry `id` instead of `input`; the reader drops all six with a note.
