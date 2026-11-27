# Plugin host API

What a plugin script (lyrics, translate, source) sees and the limits it runs
under. Code: `rust/crates/kanaru_plugin_runtime/` (`src/limits.rs` holds every
cap, `src/js/host_prelude.js` the script-facing objects). The runtime knows
nothing about hosts, consent or the network: the app answers `fetch` and stream
calls through the `PluginHost` trait (see
[system-architecture-plugin-runtime.md](./system-architecture-plugin-runtime.md)).

Every call runs in a fresh QuickJS engine; globals do not survive between calls.

## Script contract

The entry file and every file it `load()`s run as classic global scripts in one
scope, in sloppy mode. There is no module system: `import`, `export` and
dynamic `import()` are errors, and `std`, `os`, `require`, `setTimeout`,
`setInterval`, `XMLHttpRequest` and `WebSocket` do not exist (`sleep` is the
only wait). Promises can be created but are never resolved: nothing runs the
job queue.

After the entry file ran, the host calls the global `execute(input)` once.
`input` is the request's JSON, parsed: any JSON value the caller sends (object, array, string, number, boolean or `null`). It must return a value made by
`Response`:

| Call | Result |
|---|---|
| `Response.success(data)` | status `ok`, `output_json` = `JSON.stringify(data)` (`null` for `undefined`) |
| `Response.error(message, {kind, retryAfterSec})` | status `scriptError`, `error_message` = `message` (cut at 1000 characters), `error_kind` = `kind`, `retry_after_sec` = `retryAfterSec` |

`kind` is one of eight values; anything else, or none, is `server`:

| `kind` | Meaning |
|---|---|
| `rateLimited` | the service asked to slow down (pauses the plugin; `retryAfterSec`) |
| `invalidResponse` | the answer was not what the script expected |
| `server` | the service failed, or any unknown kind |
| `auth` | the key or login was refused |
| `quota` | the quota or plan limit is used up (a rate limit that lasts) |
| `unavailable` | the item is gone: removed, or geo-blocked for this user |
| `network` | a network failure the plugin saw itself |
| `unsupported` | content the plugin cannot play or serve, for example a livestream |

`retryAfterSec` counts only as a finite number of 0 or more (rounded down).
Returning anything else (a Promise, `undefined`, a plain object) is
`scriptError` with kind `invalidResponse` and the message `execute must return
Response.success or Response.error`; a missing `execute` is `scriptError` too.

### `load(name)`

`load('util.js')` runs another file of the package's `src/` in the same global
scope. `name` must match `^[A-Za-z0-9_.-]+\.js$` and be a file sent with the
request, else `load` throws an `Error` the script may catch. A file runs at
most once per call (the entry file counts as loaded). `crypto.js` is the
bundled CryptoJS 4.2.0 (defines `CryptoJS`: AES ECB/CBC with PKCS7, MD5,
SHA1/256/512, HMAC, `enc.Base64`, `enc.Hex`, `enc.Utf8`); a package file of that
name is never used. There is no secure random source: calls needing a random
salt or IV (`AES.encrypt` with a passphrase) throw; pass an explicit key and IV.

## Result

`PluginRuntime::run` always returns a `ScriptResult`. These fields are filled
on every status:

| Field | Meaning |
|---|---|
| `status` | `Ok`, `ScriptError`, `Timeout`, `Memory`, `Stack`, `Cancelled`, `OutputTooLarge`, `Internal`, `Busy` |
| `output_json` | data of `Response.success`; empty unless `Ok` |
| `error_message`, `error_kind`, `retry_after_sec` | explanation of a non-`Ok` status; kind and retry hint for script-reported failures. Kinds: `None`, `RateLimited`, `InvalidResponse`, `Server`, `Auth`, `Quota`, `Unavailable`, `Network`, `Unsupported`. Unknown kinds are `server`; each consumer folds the rest (see Errors under `lyrics`) |
| `js_error` | the exception that ended the run (`message`, `stack` with `file:line:col`). Set for thrown errors, syntax errors, and for `Timeout`, `Memory`, `Stack` and a cancel of a running job. Not set for `Busy`, `Internal`, `OutputTooLarge`, `Response.error`, a non-`Response` return or a missing `execute` |
| `logs` | console lines captured before the run ended |
| `fetch_failure` | the first failing `fetch` of the call, even if the script caught the error |
| `storage_json` | the whole new `localStorage` map, only when the script changed it and finished on its own (`Ok` or `ScriptError`) |

Other statuses: `Cancelled` also for an unknown, used or cancelled-before-start
job id; `Internal` means the runtime failed (a worker panicked, `input_json` is
not JSON, the entry file is not in the request, two files share a name), the next
job still runs; `Busy` means every worker is busy and the queue is full, nothing
ran.

`check_script(name, code)` compiles a file without running it and returns
`None` or the message and 1-based line.

Job ids: `begin_job()` returns an id, `run` runs under it, `cancel_job(id)`
stops it. An id runs once; cancelling an id that has not started removes it;
cancelling an unknown or finished id does nothing. `reset()` cancels every job.

## Limits

| Limit | Value | When hit |
|---|---|---|
| Heap | 32 MiB (`MEMORY_LIMIT_BYTES`), counted by a Rust allocator that flags a refused allocation | status `Memory` |
| JS stack | 1 MiB (`SCRIPT_STACK_BYTES`); the thread has 8 MiB, so the engine fails first | status `Stack` |
| Wall time per call | 15 s by default (`DEFAULT_WALL_TIME`), at most 90 s (`MAX_WALL_TIME`); counted from the moment a worker starts the job (`load()` included), queue wait not counted, so the caller keeps its own outer deadline | status `Timeout` |
| Output | 2 MiB of JSON (`MAX_OUTPUT_BYTES`) | status `OutputTooLarge` |
| Thrown-error text | message 1000 characters, stack 16 KiB (cut, not rejected) | cut |
| `fetch` request body | 1 MiB (`MAX_FETCH_REQUEST_BODY_BYTES`) | `InvalidRequestError` |
| HTTP sends per call (retries included) | 10 (`MAX_FETCH_SENDS`) | `TooManyRequestsError` |
| Unread `fetch` bodies and parsed `Html` documents in Rust memory | 16 MiB per call, shared (`RUST_BYTE_BUDGET`) | `RangeError`, call ends `Memory` |
| `Html.parse` text | 4 MiB (UTF-8 bytes) | `RangeError` |
| `localStorage` | 64 KiB of keys plus values | `QuotaExceededError` |
| Console | 500 characters per line, 50 lines per call | cut, `... N lines dropped` |
| Worker threads | 4 (`WORKER_THREADS`) | extra jobs wait |
| Queued jobs | 16 (`QUEUE_CAPACITY`) | the next waiting job is `Busy` |

A timeout and a cancel use an interrupt the script cannot catch, so
`try { while (true) {} } catch (e) {}` still stops. A cancel of a running job is
seen within about 100 ms (`CANCEL_POLL` is 50 ms).

## Host API

Besides `Response` and `load`, a script has these globals (ordinary properties:
a package may declare its own `sleep` or `console`). Everything is synchronous.

### `fetch(url, options?)`

`options`: `method` (`GET` default or `POST`, any case; else `TypeError`),
`headers` (object; `User-Agent` may be set; `Accept-Encoding`, `Host`,
`Connection`, `Content-Length`, `Transfer-Encoding`, `TE`, `Upgrade`,
`Keep-Alive`, `Trailer`, `Expect` and `Proxy-*` are dropped silently; a bad name
or value is `InvalidRequestError`), `body` (string, sent as UTF-8; an object is
sent as JSON with `content-type: application/json` unless a content-type header
is given), `queries` (object appended to the URL, percent-encoded; `undefined`
and `null` skipped), `timeout` (ms, cut to what is left of the call; a bad value
is ignored). A body over 1 MiB throws `InvalidRequestError` without crossing
to the host. The host does the authoritative checks (host allowlist, consent,
header and body rules) and answers with an outcome.

**Host rules.** The URL must be `https`, without user info, a port or an IP
literal, and its host must be on the plugin's `hosts` and consented by the user;
the exception is an address the user typed into a `format: url` setting of the
plugin (saved, not a default), which is allowed with its port. A name that
resolves to a private, loopback, link-local or mixed address is refused
(`BlockedHostError`) before anything is sent. The header drops above are done by
the host, so a script cannot forge `Host` or `Content-Length`. Redirects are not
followed: a 3xx is returned as the answer and the script may `fetch` its
`location` header (a new, checked request). A body over 4 MiB is
`InvalidResponseError`. A 429 or 503 is a normal answer (status, headers, body)
that the script reads itself; the host neither retries nor blocks later
requests, and only a script that ends with `Response.error(rateLimited)` pauses
the plugin. The overall timeout of one request is its `deadline_ms`, with no
shorter cap. Requests of one plugin start at least 100 ms apart. A `Network` answer for a
request that was never sent (spacing wait, no time left, DNS failure) still counts
as one of the script's sends.

On success `fetch` returns a frozen object `{status, ok (200-299), url (after
redirects), headers, header(name), text(charset?), json(), base64()}`. Header
names are lower case, repeated names joined with `, `; `header(name)` is
case-insensitive and returns `null` when absent. An HTTP error status such as
404 is still a successful `fetch`. A `Set-Cookie` header is visible exactly as
the host returns it (`res.header('set-cookie')`); there is no cookie jar, the
script keeps what it needs in `localStorage` and sends `Cookie` itself. A later
host API will handle cookies and `localStorage` for the hosts a plugin declares.

- `text(charset?)` decodes by the argument (any label `encoding_rs` knows: `utf-8`,
  `gbk`, `gb18030`, `big5`, `shift_jis`, `euc-kr`, ...; an unknown one throws
  `RangeError`), else by the `charset` of `content-type`, else UTF-8. Invalid
  bytes become U+FFFD. `json()` is `JSON.parse(text())`.
- A body is read once: it stays in Rust memory until the first `text()`, `json()`
  or `base64()`, then it is released and the result cached. `text()` and
  `json()` again return the cached text; `base64()` after `text()` (or the other
  way round) throws an `Error`.

Any other outcome throws an `Error` with a `name`:

| Name | Meaning |
|---|---|
| `NetworkError` | connection, TLS or timeout failure |
| `BlockedHostError` | the host is not on the plugin's allowlist, or the URL is not `https` |
| `NotConsentedError` | the user has not allowed the plugin to use the network |
| `AbortError` | the user stopped the lookup; the call ends `Cancelled` even if the script catches this |
| `InvalidRequestError` | the host refused the request, or the body is over 1 MiB |
| `InvalidResponseError` | the host refused the answer (a body over 4 MiB) |
| `RateLimitedError` | the server asked to slow down; has `retryAfterSec` when known |
| `TooManyRequestsError` | the call already used 10 HTTP sends; nothing is sent |

Each request carries `max_sends` (10 minus the sends used so far, at least 1);
the host must not send more, retries included. A reply that reports more is
counted as `max_sends`. Error messages made by the runtime are fixed texts: they
never contain the URL, headers, body or any `localConfig` value.

Every `FetchRequest` and `StreamCall` carries the run's `install_id`, so the
host can keep per-plugin state (cookies, consent) without the script knowing it.

**Sticky failure.** The first failing outcome of a call is stored as
`fetch_failure`, even when the script catches the error and returns
`Response.success([])`, so the caller does not cache that as "no result".
`TooManyRequestsError` is kind `InvalidRequest`.

**Waiting.** The script thread waits for the host until the call's deadline,
looking at the cancel flag every 50 ms. A host that never answers ends the call
as `Timeout`; a host call that panics is answered as `Network`; a cancel ends
the call `Cancelled` within about 100 ms. The request carries `deadline_ms`
(what is left of the call; in a streaming run each call, a stream open included, gets at most 90 s of it, `MAX_WALL_TIME` in `host/fetch/mod.rs`, however long the run may last). The app uses it as the overall timeout of the HTTP exchange, as given: connect is bounded separately (10 s) and there is no extra shorter cap, so a long request (an AI translation, 80 s) completes inside it. Time the host spends waiting between request starts of one plugin counts against `deadline_ms`.

**Memory.** Unread response bodies are charged to one 16 MiB Rust-side budget per
call (the heap cap does not see Rust memory). Going over throws `RangeError` and
the call ends `Memory`, even if the script catches the error.

### `sleep(ms)`

Blocks the script thread for `ms` (negative or not a number counts as 0). The
time counts toward the wall time; a cancel interrupts it.

### `localConfig.getItem(key)`

The plugin's configuration as the app set it (secrets included), as a typed
value (string, number, boolean, array, object) or `null` when not set.
Read-only; each call returns a fresh copy. The runtime never writes these values
to a log or message it makes.

### `localStorage`

`getItem(key)` (string or `null`), `setItem(key, value)` (both coerced to
strings), `removeItem(key)`, `clear()`. The script works on a copy of the stored
map; quota 64 KiB of keys plus values (`setItem` over it throws
`QuotaExceededError` and changes nothing). When the script changed the map and
the run ended `Ok` or `ScriptError`, `storage_json` is the whole new map. After
any other status nothing is returned. If two calls of one plugin run at once, the
last writer wins.

### `console` and `Log`

`console.log/info/warn/error/debug` and `Log.log` write one line: arguments
joined by a space (objects through `JSON.stringify`, `Error` as `String(error)`).
A line is cut at 500 characters; a call keeps 50 lines, after that the first 49
and a last entry `... N lines dropped`. Do not log secrets or song tags: only
config values are never logged by the runtime, song text is the author's duty.

### `Html.parse(text)`

Parses `text` as an HTML document (the browser parsing rules, via the `scraper`
crate; a fragment gets `<html><head></head><body>` around it) and returns its
`<html>` `Element`. The parse and every query run in Rust on the script thread.
The objects hold a private handle into a per-call arena that is dropped with the
call; a script cannot read or make up a handle, and `new` on the classes throws.

`Element`:

| Method | Returns |
|---|---|
| `select(css)` | `Elements`: the descendants (not the element itself) that match, in document order |
| `selectFirst(css)` | the first match or `null` |
| `text()` | text content, see below |
| `html()` / `outerHtml()` | inner / outer HTML; at most 4 MiB, more throws `RangeError` and the call ends `Memory` (html5ever's repair of misnested markup can clone one big attribute value thousands of times, and the output repeats each clone) |
| `attr(name)` | the attribute value, `""` when absent; the exact name is tried first (SVG keeps `viewBox`), then the lower-case name (HTML names are stored lower case). Names are local names without a namespace prefix: for `xlink:href` ask for `href` |
| `tagName()` | the tag name as the parser gives it: lower case for HTML elements, camel case for SVG ones (`foreignObject`) |

`Elements`: `size()`, `get(i)` (`null` when out of range), `first()` and
`last()` (`null` when empty), `text()` (the `text()` of each element joined with
`\n`), `attr(name)` (of the first element, `""` when empty), `map(fn)` (an array
of `fn(element, index)`), `forEach(fn)`, `toArray()` (an array of `Element`).
`get`, `first`, `last` and `toArray` make new `Element` objects on each call
(compare by content, not identity).

`text()` collapses HTML whitespace runs to one space, turns `<br>` into a line
break, starts and ends a line at `<p>`, `<div>`, `<pre>`, `<li>`, `<h1>` to
`<h6>`, `<tr>`, `<table>`, `<section>`, `<article>`, `<blockquote>`, `<header>`
and `<footer>`, separates table cells (`<td>`, `<th>`) with one space, keeps the
text of `<pre>` as written (spaces and every line break), keeps at most one
blank line in a row outside `<pre>`, and trims line breaks at both ends.
Non-breaking spaces are kept; comments, `<script>`, `<style>`, `<template>` and
`<noscript>` add nothing.

Selectors use the CSS selector syntax of the `selectors` crate (type, class, id,
attribute, combinators, `:not`, `:is`, `:has`, `:nth-child`, ...). Pseudo-classes
that depend on state (`:hover`, `:focus`, `:checked`, ...) are not in the grammar
and throw `SyntaxError`; the matcher never matches one in any case.
A selector the parser rejects (including a nested `:has`), or longer than 1024
bytes, throws `SyntaxError` with the selector text (cut to 80 bytes) and a short
reason. Strings passed in must be well-formed Unicode: a lone surrogate throws
`TypeError`.

Errors and limits:

| Limit | Value | When hit |
|---|---|---|
| Text | 4 MiB | `RangeError` |
| Documents per call | 8 (a refused parse uses no slot) | `RangeError` |
| Nodes per document | 200 000 | `RangeError`, and the call ends `Memory` even if the script catches it |
| Nesting depth | 512 levels (`<html>` is 1) | `RangeError` (page depth is not memory: the call goes on) |
| Byte budget | 160 bytes per node plus the input size, and the attribute text of every created element (clones included), against the shared 16 MiB | `RangeError`, call ends `Memory` |
| Selector | 1024 bytes | `SyntaxError` |
| Serialized HTML | 4 MiB | `RangeError`, call ends `Memory` |

The depth limit keeps `:has` far from the thread stack limit and bounds the cost
of one match; real pages are well under 100 levels. The parser gets the text
1 KiB at a time and looks at the cancel flag and the deadline after each piece;
its tree sink stops creating nodes at the node cap, so elements html5ever clones
while repairing markup cannot pass it, and the parse stops early once nesting
passes the limit by more than 64 levels. `select` runs the matching itself and
counts its work in steps (one per node looked at, one per KiB of attribute or
class text scanned, more for a case-insensitive substring search). The cancel
flag and the deadline are looked at every 65 536 steps, so a cancel or timeout
ends even a selector that needs minutes (many alternatives, `:has(x span)`, long
class lists on a large page); the call ends `Cancelled` / `Timeout`. A panic in
an `Html` native ends the call `Internal` even if the script catches the error.

## Lyrics scripts

A plugin of type `lyrics` declares two scripts, `search` and `lyrics`. Each is an ordinary script (above) whose `execute(input)` receives **one object** for `search` and the chosen result's `id` as a **bare string** for `lyrics`. It returns `Response.success(...)` or `Response.error(message, { kind, retryAfterSec })`. Plugins keep their own state in `localStorage` (a token, a cookie) and read settings with `localConfig`; the app sends nothing for them.

**`search`.** Input, automatic lookup of the playing track: `{ title, artist, artists, album, durationMs }`; a missing tag is `null`, `artist` is the primary artist, `durationMs` is in milliseconds. Input, a search typed by the user: `{ text }`. Output: an array of up to 20 items `{ id, title, artist, album?, durationMs?, lyrics? }`: `id` a stable string of 1-256 characters, `title` and `artist` non-empty, `durationMs` an integer above 0 and under 24 h, `lyrics` (when the search already returned it) a string of at most 1 MiB. An invalid item is dropped, not the whole list.

**`lyrics`.** Input: the chosen item's `id` as a string. Output: `null` (no lyrics), `{ instrumental: true }` (wins over data) or `{ data, type? }` with `type` `lrc` or `txt`. Anything else is an invalid response.

**Errors.** `Response.error` kinds: `rateLimited` (with `retryAfterSec` when the server said so), `invalidResponse`, `server`, `auth`, `quota`, `unavailable`, `network`, `unsupported`; an unknown kind is `server`. A failed `fetch` is a sticky failure (above): a script that catches it and returns an empty list still ends `Ok` with a `fetch_failure`, and the app treats "empty result + failure" as a failure, never as "no lyrics". For lyrics the app folds `auth`, `unavailable` and `unsupported` into a server failure, `quota` into a rate limit and `network` into a network failure. Translation maps `network` to its network failure, `unavailable` and `unsupported` to server, `auth` to a bad key and `quota` to quota. AI chat maps by the `ai:<code>` in the message, not by the kind. The run log writes the kind name; the log screen shows kinds without a label as written.

**Time.** The app runs `search` and `lyrics` with a 30 s script wall (plus 0.9 s for the pauses between requests); the chain of a token fetch, a search and a lyrics fetch fits in it. A run that needs more fails as a timeout.

## Streaming scripts

A plugin of type `streaming` declares `search` and `stream`, and may declare `autocomplete` (more scripts are read by later features). Each is an ordinary script whose `execute(input)` receives one object. The app checks the output once, with the limits below. Lengths count code points; text is cleaned (control, bidi and zero-width characters removed, trimmed). An item that breaks a rule is dropped and the app notes its position and a fixed reason, never the plugin's text.

**Ids** are handed back to the plugin exactly as sent, never trimmed. An id is 1-200 code points, has no control character, is not `.` or `..`, and is not URL-shaped (contains `://` or starts with `//`); a card with a bad id is dropped.

**`search`.** Input: `{ query, next?, filter? }` (`query` 1-2000 code points; `next` and `filter` are the tokens the plugin gave before). Output: an object with `sections` and/or `items`, optional `filters` and `next`. `sections` (a non-empty array, at most 20) win; otherwise `items` become one untitled `list` section; neither is invalid. A section is `{ title?, layout?, items, more? }`: `layout` is `top`, `list` or `shelf` (anything else reads as `list`); `title` is cut to 100 code points; a section without an `items` array (a lazy section) is dropped, and so is one left empty. `more.filter` (a string up to 8 KiB) is the filter that shows the whole section; `more.script` is not read. A page keeps at most 200 cards over all sections; a repeated id inside one section is dropped. `filters` is an array of at most 20 `{ title (1-50), input (1 byte to 8 KiB) }`. `next` over 8 KiB, empty, or equal to the input `next` reads as none.

**Card.** `{ kind?, id, title, subtitle?, artist?, artists?, album?, albums?, durationMs?, artworkUrl?, webUrl? }`. `kind` is `track` (default), `album`, `playlist` or `artist`; any other kind drops the card. `title` 1-300 code points (required). `subtitle` up to 300 and `artist` up to 200 read as absent when longer. `artists` is up to 10 `{ id?, title }` (title 1-200; an invalid id reads as absent). The album is `album` (a string) and/or `albums[0]` `{ id, title }`. `durationMs` is an integer above 0 and at most 24 h, else unknown. `artworkUrl` and `webUrl` must be absolute `https` URLs of at most 2000 characters, without user info or a written port (`:443` included), else absent.

**`stream`.** Input: `{ id, fresh? }`; `fresh: true` is sent only when true. Output: `{ url, headers?, mimeType, bitrate?, expiresAtMs? }`. `url`: absolute `https`, at most 8 KiB, no port written, no user info; else invalid. `headers`: at most 20 string pairs filtered like any plugin request header (a bad name or value is invalid); `range` and `if-range` are removed. `mimeType`: the type before `;` must be `audio/*`, `video/*` or `application/*`, else invalid. Playable types: `audio/mpeg`, `audio/mp3` (mp3); `audio/mp4`, `audio/x-m4a`, `video/mp4` (mp4); `audio/webm`, `video/webm`, `audio/x-matroska` (webm). The HLS types (`application/vnd.apple.mpegurl`, `application/x-mpegurl`, `audio/mpegurl`, `audio/x-mpegurl`) and every other type are well-formed but unsupported for now. `bitrate` and `expiresAtMs` (UTC epoch ms) are integers above 0, else unknown. The url and headers are checked before the type, so a bad url is invalid whatever the type.

**`autocomplete`.** Input: `{ query }`. Output: a JSON array of strings (an object such as `{ suggestions: [...] }` is invalid). Each is cleaned, 1-200 code points; non-strings, empty entries and repeats are skipped; the first 10 are kept.

Real outputs of these scripts (Audius, Jamendo, YouTube, recorded live; the README there lists two known Jamendo deviations) are in `test/online/fixtures/`.

**Errors.** The app reads `Response.error` kinds for streaming plugins like this: `unavailable` = the item is gone (removed or geo-blocked), `unsupported` = content the plugin cannot serve (a livestream), `auth` on `stream` = this item needs an account or an age check (on `search` it is a source problem the user fixes), `network` = the plugin saw the network fail, `rateLimited` / `quota` = wait and retry. A failure the runtime saw inside a run (a failed `fetch`, a 429) that the script caught still counts when the answer comes back empty: an empty page with such a failure is shown as that failure, never as "no results". A page with at least one card is shown as it is.

**Time.** `autocomplete` is cut after 5 s, `search` and `stream` after 20 s. One script of a plugin runs at a time (a `stream` goes ahead of waiting searches); `autocomplete` is the exception: it runs beside them, starts with an empty `localStorage` and saves nothing, and a newer call cancels the older one. The input of these scripts is never written to the run log.

## Streaming runs

An opt-in mode (`run_streaming`) used by AI-style plugins; lyrics and translate
runs never use it. Differences from a normal run:

| Limit | Value | When hit |
|---|---|---|
| Worker | 1 thread (`STREAM_WORKER_THREADS`), no queue; separate from the 4 normal workers | a second streaming run while one runs is `Busy` at once |
| Wall time | 300 s (`MAX_STREAM_WALL_TIME`); the caller may ask for less | status `Timeout` |
| Idle time of a stream read | default 60 s, at least 1 s, at most 90 s | `NetworkError` |
| Single wait for the host | `deadline_ms` plus a grace of a tenth of it, 1 s to 9 s (`MIN_OP_GRACE`, `MAX_OP_GRACE`) | `NetworkError`; the call is charged all the sends it was allowed |
| `emit` event | 64 KiB of JSON | `RangeError` |
| `emit` total per run | 8 MiB | `RangeError` |
| `emit` rate | 100 events/s after a burst of 50; `emit` waits (cancel and deadline honoured) | waits |
| Streams per call | 2 open, or dead and not yet closed (`MAX_OPEN_STREAMS`) | `TooManyStreamsError` |
| Body of one stream | 16 MiB of raw bytes; one read asks for at most 64 KiB | `InvalidResponseError`, stream closed |
| `readLine()` line | 1 MiB | `RangeError`, stream closed |
| Stream `text()` | 4 MiB decoded | `RangeError`, stream closed |

`fetch(url, {..., stream: true})` returns when the headers arrive, with a frozen
object that has `status`, `ok`, `url`, `headers`, `header(name)` and blocking
methods instead of the whole-body ones: `readLine()` (next line without its
terminator, `null` at the end; a line ends at `\n`, `\r\n` or `\r`), `read()`
(buffered or next text, never `''`; `null` at the end), `text()` (rest of the
body), `close()` (idempotent; later reads return `null`). The body is decoded
as UTF-8 only (a BOM is dropped). A read with nothing buffered waits up to the
idle time, then throws `NetworkError`. After an error, a limit or a give-up the
stream is dead and later reads return `null`; a dead stream keeps its place among
the 2 streams until the host answered the close. Opening counts as one HTTP send;
reads and closes count none. In a normal run the `stream` option is ignored.

**Host side (app).** A stream open is judged exactly like a one-shot `fetch`
(consent, allowlist, public address, `https`, header rules, 1 MiB request body,
per-plugin spacing, 10 HTTP sends per call) and nothing is followed: a redirect
is an answer. The body stays open for as long as the run lasts (the stream is
closed by itself when the run's wall passes) and is read in chunks of at most
64 KiB; a read that gets no bytes within the idle time is `NetworkError`. The
app keeps one stream table per run and closes every stream when the run ends or
is cancelled. A streaming run takes the app's single stream slot: another one
waits at most 10 s for it, then ends busy (nothing is run). The run log of a
streaming run keeps only its status, error kind and the `ai:<code>` start of the
error message (no input, console, stack or message text). Details:
[system-architecture-plugin-runtime.md](./system-architecture-plugin-runtime.md#streaming-runs-dart-side).

`emit(value)` exists only in streaming runs (`typeof emit` is `'undefined'`
otherwise). It serialises with `JSON.stringify` and hands the text to the host
at once. `TypeError` when the value cannot be serialised or has a lone
surrogate; `RangeError` over the event or total limit. The payload never appears
in an error message or log.

## Chat scripts

A plugin of type `ai-chat` declares one script, `chat`. `execute(input)` runs as a streaming run (`emit` exists) with `logInput: false` and **no persistent `localStorage`**: a chat run starts with empty storage and nothing it writes is saved, so key-rotation state lives inside one run. Settings are read with `localConfig`.

**Manifest.** `metadata.type` `ai-chat`, no wildcard hosts, `script.chat` required. The `chat` block is required for this kind and refused on every other kind (`InvalidManifest('chat')`). An update may only replace a plugin of the same kind.

```json
"chat": {
  "models": [
    {"id": "gemini-2.5-flash", "title": "Gemini 2.5 Flash", "tools": true, "vision": true, "context": 1048576}
  ],
  "custom": {"tools": true, "vision": false, "context": 32768},
  "keyField": "apiKeys",
  "idleTimeoutSec": 90
}
```

- `models` (optional, 0-50): a **capability overlay** keyed by model id, not the model list. `id` `^[A-Za-z0-9._:/@-]{1,120}$`, unique (`chat.models.id`); `title` 1-80 (default: the id); `tools` and `vision` booleans (default false); `context` an integer of 1024-10,000,000 tokens (default 32768).
- `custom` (optional): capabilities of any model without an overlay entry; default `{tools: false, vision: false, context: 32768}`.
- `keyField` (optional): key of the config field holding the API key(s). It must name a `required` input or list field (`chat.keyField` otherwise). The app uses it for "Cần API key" (composer, settings, store rows) and to tell "needs a key" from "needs a model".
- `idleTimeoutSec` (optional): 1-90, default 90. The longest silence between emits.
- The config must declare `model` as a single select with options and/or `custom: true` (`config.model` otherwise). It is **not** required (it may be): the composer always passes the conversation's model in the input, and the stored value only seeds new conversations. The composer's model list is the `model` options plus the user's custom choices.

**Input.**

```jsonc
{
  "v": 1,
  "model": "gemini-2.5-flash",              // wins over the config `model`
  "system": "…",                            // app system prompt + general instructions
  "boundary": "k7f3a9c2e1",                 // per-request random token for data fences
  "messages": [
    {"role": "user", "parts": [
        {"type": "text", "text": "…"},
        {"type": "data", "source": "lyrics", "text": "…"}]},
    {"role": "assistant", "parts": [
        {"type": "text", "text": "…"},
        {"type": "tool_call", "id": "t3-r1-0", "providerId": "call_abc", "name": "search_library", "args": {"query": "…"}}],
     "provider": { /* opaque; from this plugin install + version + model only */ }},
    {"role": "tool", "parts": [{"type": "tool_result", "id": "t3-r1-0", "providerId": "call_abc", "name": "search_library",
        "content": [{"type": "text", "text": "…"}], "isError": false}]}
  ],
  "tools": [{"name": "search_library", "description": "…", "parameters": { /* JSON Schema subset */ }}],
  "toolChoice": "auto",                     // "auto" | "none"
  "options": {"maxOutputTokens": null}      // non-null wins over the plugin config
}
```

- **Parts.** `text`, `data`, `tool_call`, `tool_result` (`content` is a list of parts). `image {mime, data(base64)}` is reserved (message part and inside `tool_result.content`); plugins drop image parts. A plugin refuses a `v` it does not know with `ai:bad_request`.
- **Tool parameters** are a plain JSON Schema subset: `type` (object, string, integer, number, boolean, array), `properties`, `required`, `items`, `enum`, `minimum`, `maximum`, `maxItems`, `description`.
- **`data` parts** carry untrusted text (`source` is one of `lyrics`, `queue`, `now_playing`, `track`, `album`, `artist`, `genre`, `language`, `playlist`, `input`). The app strips C0/C1 controls, bidi and zero-width characters and breaks every `<data` / `</data` in the text. A plugin renders each part as `<data-{boundary} source="…">…</data-{boundary}>` inside the user turn and never as plain instructions.
- **Tool call ids.** The app assigns `id` (`t<turn>-r<round>-<n>`, unique in the conversation). A provider id matching `^[A-Za-z0-9_.:-]{1,64}$` is kept as `providerId` and echoed back only to the same plugin install, version and model (see Binding), for the whole conversation; otherwise it is dropped. `name` must match a declared tool (at most 64 characters); a refused call is stored with its name cut to 64 and no args.
- **Provider-side tools are banned.** A plugin must not enable search grounding, URL context, code execution, web search, MCP connectors, or models whose name implies such tools. Only `tools[]` from the input is offered.
- **Final round.** The app sends the same `tools[]` with `toolChoice: "none"`; a call that arrives anyway is refused by the app.
- **Binding.** Conversations, provider blobs and provider ids are bound to the `installId` plus the install generation (the `plugins` row's install time when bound), the plugin version and the model. A different generation (remove, then reinstall) reads as "Plugin đã gỡ" with a way to choose another plugin. A turn whose binding no longer matches (plugin, version or model changed) is sent **flattened to text**: its tool calls, results and blob are dropped together, never a blob removed while its tool calls stay.
- **App guarantees.** Same-role turns are merged; every `tool_call` has its `tool_result`; every sent `tool_call` keeps its turn's blob (turns are atomic). The input is at most 768 KiB (UTF-8 bytes of `jsonEncode(input)`) and within the token budget from the model's `context`; each tool result is at most 16 KiB (arrays are compacted and paged, never cut inside a string); a provider blob is at most 256 KiB per message and 4 MiB per conversation. The runtime refuses request bodies over 1 MiB. The app does no LLM summarising.

**Emits.** At most 64 KiB each and 8 MiB per run (runtime limits): `{"t":"text","d":"<delta>"}` and `{"t":"status","s":"thinking"|"generating"}`. A plugin coalesces text deltas: at most one `text` emit per 50 ms or per 256 characters, flushed before it returns. Emitted text is shown live and kept as the message **only when no final result arrives** (stop, timeout, failure), capped at 256 KiB with a "…" marker. An unknown `t` is ignored.

**Time.** A run is cut after `idleTimeoutSec` without an emit or a returned result, and by the run's wall time; the emit limits above apply.

**Final result.** `Response.success({...})`, at most 2 MiB:

```jsonc
{"finish": "stop" | "tool_calls" | "length" | "blocked",
 "text": "<full assistant text, thinking excluded>",
 "toolCalls": [{"providerId": "call_abc", "name": "search_library", "args": {}}],
 "usage": {"input": 1234, "output": 321},
 "provider": { /* optional, at most 256 KiB */ }}
```

`toolCalls` holds at most 8 per round. Arguments that do not parse are sent as the raw string (`"args": "<raw>"`, never `{}`) and become an error result. `provider` stays with this message for the whole conversation and goes back only to the same install, version and model; it is never storage. The app treats tool calls as untrusted plugin output: caps per round (8) and per turn (24 calls); unknown names, bad or raw args, and calls not offered become error results.

**Errors.** `Response.error("ai:<code>", {kind, retryAfterSec})`: the code only, **no provider text in the message** (provider text may go to the plugin's run log, masked). The app stores `{code, kind, retryAfterSec?}` and never shows or logs provider text in full. An unknown code is `server`. `no_key` is never a plugin code.

| code | kind | Meaning |
|---|---|---|
| `key` | `auth` | Wrong API key |
| `quota` | `quota` | The provider account is out of quota |
| `rate_limit` | `rateLimited` (+ `retryAfterSec`) | Rate limited; no automatic retry |
| `config` | `invalidResponse` | Plugin settings incomplete (for example a "custom" preset without a base URL) |
| `bad_request` | `invalidResponse` | The provider refused the request |
| `model_not_found` | `invalidResponse` | The model no longer exists, or is refused because its name implies provider-side tools |
| `context_length` | `invalidResponse` | The conversation is too long for the model |
| `too_large` | `invalidResponse` | Too large to send; never triggers key rotation |
| `blocked` | `invalidResponse` | The model refused |
| `empty` | `invalidResponse` | The model returned nothing |
| `server` | `server` | Provider or plugin failure |

## What is absent

`XMLHttpRequest`, `WebSocket`, `require`, `import`, `setTimeout` and
`setInterval`, modules, file and process APIs, WebView, and `cacheStorage`.

Also absent: `eval` and `Function`. The globals are deleted, so `eval(...)`
and `Function(...)` throw `ReferenceError`. Any read of `.constructor` on a
function (plain, async, generator, async generator, including bound functions
and classes) throws `TypeError: Kanaru plugins cannot compile code at run time
(eval / Function are disabled)`. A plugin cannot compile code at run time; the
only code that runs is the package's own files. `load(name)` is not affected.

Compatibility note for plugin authors: `instanceof Function`, `Function.prototype`
by name, `fn.constructor`, Babel class helpers and `Function('return this')`
(lodash style) do not work. Use `Object.getPrototypeOf(function () {})` for the
function prototype and `globalThis` for the global object.

## Compatibility check

`rust/crates/kanaru_plugin_runtime/tests/compat_repo.rs` runs every plugin of a
plugin repository against a fake host (every fetch answered `200 {}`), locally
only: `KANARU_PLUGIN_REPO=http://127.0.0.1:8765/plugins.json cargo test -p
kanaru_plugin_runtime --test compat_repo -- --nocapture`, with the repository
folder served by `python3 -m http.server 8765 --bind 127.0.0.1`. Without the
variable the test skips itself, so CI never runs it. It fails on `Internal`,
`Stack`, `Memory` or `Timeout`, on a missing host global, on a failing
`check_script` and on a request without the run's `install_id`.

## Error mapping

A script that throws (or whose `execute` is missing or returns something that is
not `Response.success` / `Response.error`) ends `ScriptStatus::ScriptError` with
`ErrorKind::InvalidResponse`: a plugin bug, not a server failure. A request with
an empty `install_id` ends `ScriptStatus::Internal` ("install_id is empty")
without running the script.
