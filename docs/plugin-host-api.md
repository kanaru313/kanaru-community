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
`input` is the request's JSON, parsed. It must return a value made by
`Response`:

| Call | Result |
|---|---|
| `Response.success(data)` | status `ok`, `output_json` = `JSON.stringify(data)` (`null` for `undefined`) |
| `Response.error(message, {kind, retryAfterSec})` | status `scriptError`, `error_message` = `message` (cut at 1000 characters), `error_kind` = `kind`, `retry_after_sec` = `retryAfterSec` |

`kind` is `rateLimited`, `invalidResponse`, `auth`, `quota` or `server`;
anything else, or none, is `server`. `retryAfterSec` counts only as a finite
number of 0 or more (rounded down). Returning anything else (a Promise,
`undefined`, a plain object) is `scriptError` with kind `invalidResponse` and
the message `execute must return Response.success or Response.error`; a missing
`execute` is `scriptError` too.

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
| `error_message`, `error_kind`, `retry_after_sec` | explanation of a non-`Ok` status; kind and retry hint for script-reported failures. Kinds: `None`, `RateLimited`, `InvalidResponse`, `Server`, `Auth`, `Quota`. The app folds `Auth` (lyrics) and unknown kinds to `server` |
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
| `fetch` request body | 256 KiB (`MAX_FETCH_REQUEST_BODY_BYTES`) | `InvalidRequestError` |
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
is ignored). A body over 256 KiB throws `InvalidRequestError` without crossing
to the host. The host does the authoritative checks (host allowlist, consent,
header and body rules) and answers with an outcome.

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
| `InvalidRequestError` | the host refused the request, or the body is over 256 KiB |
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
(what is left of the call).

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

`emit(value)` exists only in streaming runs (`typeof emit` is `'undefined'`
otherwise). It serialises with `JSON.stringify` and hands the text to the host
at once. `TypeError` when the value cannot be serialised or has a lone
surrogate; `RangeError` over the event or total limit. The payload never appears
in an error message or log.

## What is absent

`XMLHttpRequest`, `WebSocket`, `require`, `import`, `setTimeout` and
`setInterval`, modules, file and process APIs, WebView, and `cacheStorage`.

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
