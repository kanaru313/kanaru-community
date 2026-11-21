# Plugins module

`lib/src/plugins/` holds what the app knows about a plugin package: the
manifest, the config schema and its value rules (this file, § Package), the
zip reader (§ Package zip), the catalog (§ Catalog), the install ids and the
update diff (§ Ids and update diff). Everything
under `plugins/domain/` is plain Dart (no Flutter, drift or platform).
Plugins themselves live in `kanaru313/kanaru-plugins`; the app ships none.

## Package

`plugins/domain/package/` and `plugins/domain/config/`. The parser only
reads. What is stored later is the **original `plugin.json` text**, never a
re-encoding of the model, so fields the model does not know (`changelog`,
`metadata.network`, future keys) survive for later readers. Unknown fields
are ignored, not errors.

```
parseManifest(String text) -> Result<PluginManifest, List<PackageProblem>>
parseConfigSchema(Object? config) -> Result<List<ConfigField>, PackageProblem>
```

It stops at the first problem, so the list has one item. JSON is read
through typed helpers (`json_read.dart`); no member access is dynamic.

### Fields

| Field | Rule |
|---|---|
| BOM | a leading U+FEFF is dropped before decoding |
| `metadata.apiVersion` | int >= 1; supported = 1; above that `NeedsNewerApp` |
| `metadata.type` | `lyrics`, `translate`, `ai-translate`, `streaming`; anything else `UnsupportedKind` ("needs a newer Kanaru") |
| `name` | 1-80 code points after cleaning |
| `version` | int, 1 to 2^31-1 |
| `author` | optional, <= 80 |
| `description` | optional, <= 500, newlines kept |
| `hosts` | 1-20 strings, trimmed, lower-cased, deduplicated, then the host rules below |
| `languages` | optional, never invalid; library keys via `languageKey` (ISO 639-3; a code it does not know is dropped); `*` / `all` / `any`, a non-list or a list over 50 = global (empty); <= 20 kept |
| `script` | object, at most 50 entries; key `^[A-Za-z0-9_.-]{1,64}$`, file `^[A-Za-z0-9_.-]{1,100}\.js$`; **every key is kept** in `PluginManifest.scripts`; required: lyrics `search` + `lyrics`, translate and ai-translate `translate`, streaming `search` + `stream`. Shipped streaming manifests declare 10 keys (`search, stream, home, genre, album, playlist, artist, related, autocomplete, resolve`). That the files exist is checked against the unpacked package (§ Catalog) |
| `metadata.regexp` | optional string <= 500 code points that compiles as a Dart `RegExp`. **Untrusted:** a backtracking pattern can run for minutes, so never match it on the UI isolate without a bound (QuickJS with the run interrupt, or a short-lived isolate with a timeout, and a capped input length) |
| `translate` | translate-family kinds only; see below |
| `config` | optional object, see below |

`metadata.network` and `changelog` are not parsed.

Text cleaning (`text_clean.dart`): control (Cc), format (Cf: bidi
overrides, zero-width, BOM) characters and U+2028 / U+2029 are removed and
edges trimmed; lengths count code points. A problem's `detail` echoes
attacker text, so it is shown with those characters as `?` and cut to 200
code points.

### Host rules (`host_rules.dart`)

- An entry is a public DNS name (no IP literal, no `localhost`, no
  single-label name, no `.local` / `.internal` / `.lan` / `.home.arpa` /
  `.localdomain` / `.test` / `.invalid` / `.example` / `.onion` / `.corp` /
  `.home` / `.intranet`, labels <= 63, name <= 253, alphabetic top label), or
  `*.` + such a name. A public name may still resolve to a private address:
  resolved addresses are checked when a request is made, not here.
- Wildcards: streaming plugins only, at most 10 distinct, never over one of
  a shared-hosting base (22: `github.io`, `workers.dev`, `s3.amazonaws.com`,
  `ngrok.io`, `googleusercontent.com`, ...) or a name under one, and never over
  a country registry name (`co`, `com`, `net`, `org`, `gov`, `edu`, `ac`, `or`,
  `ne`, `go` + a 2-letter TLD: `*.co.uk`, `*.com.vn`).
- `HostPattern.matches(host)`: a wildcard matches exactly one label
  (`[a-z0-9-]{1,63}`) in front of its base; the apex and deeper names do not
  match; a host ending in `.` never matches.
- `hostSetCovers(consented, candidate)`: true when every candidate entry is
  listed in `consented`, or is a plain name one label under a consented
  wildcard. A wildcard is covered only by the same wildcard. The install
  and update flow uses it to decide "Cần xem".

### Translate block (`translate_spec.dart`)

`languages` 1-200 strings; codes outside `translationLanguageCodes` or
repeated are dropped (a block with none left is refused). `maxLines`
10-200 (default 50), `maxChars` 1000-20000 (4000), `timeoutSec` 1-600
(15), clamped to 90 at read time.

### Config schema

At most 20 fields, key `^[A-Za-z0-9_]{1,40}$`, title 1-80, subtitle <= 300,
placeholder <= 200. Sealed `ConfigField`:

| Mode | `format` | Notes |
|---|---|---|
| `input` -> `InputField` | `text` (default), `multiline`, `number`, `integer`, `url` | length bounds (text), `rows` 1-10, `min` / `max` / `step` (numbers; integers in the JS-safe range) |
| `select` -> `SelectField` | `single` (default), `multiple` | 1-50 options (none when `custom`), `custom` only on single, `minItems` / `maxItems` |
| `toggle` -> `ToggleField` | none | bool default |
| `list` -> `ListField` | `text` (default), `number`, `integer`, `url` | <= 50 items |
| `map` -> `MapField` | `text` | text keys and values, <= 50 rows |

- **No secrets.** `secret` is not a format: a field with it (or any other
  unknown format) refuses the package with `UnknownConfigFormat`
  (`config.<key>.format`). Every config value is plain text.
- A default is checked against the field's own value rules and kept typed
  (`num`, `int`, `bool`, `List<String|num|int>`, `Map<String, String>`); a
  number default written as a decimal string becomes a number.
- `ai-translate` must declare `model` and `style` (single selects with
  options, or `custom` for the model; a custom `model` is `required`) and
  `customInstruction` (a text input).
- `PluginManifest.userEndpointFields`: the `format: url` inputs and lists
  (the address the user types; the install screen says the plugin will
  contact it).

### Value rules (`config_value_rules.dart`, `config_required.dart`)

`valueProblem(field, value)` returns the first `ValueProblem` or null; the
config store and form use it for every write. A `custom` single select
is checked against its effective field (manifest options plus the user's own
choices); the config store must merge them before calling it. Lists and maps may be
JSON-decoded. URL values: https only, a host, no credentials, no
whitespace / control / format characters, <= 2000. Map keys: 1-100 code
points, no control characters, no outer space, `__proto__` refused, case
sensitive. `missingRequiredConfig(schema, config)`: a toggle is never
missing; absent, whitespace-only text, empty list or map is.

### Problems (`package_problem.dart`)

Sealed `PackageProblem` (`detail` = field path, host or type):
`InvalidManifest`, `UnknownConfigFormat`, `NeedsNewerApp`, `UnsupportedKind`,
`InvalidHost`, `InvalidWildcardHost`, `WildcardHostNotAllowed`,
`SharedHostingWildcard`, `TooManyWildcardHosts`; and from the zip reader
(§ Package zip): `NotAZip`, `PackageTooLarge`, `UnsafeEntry`, `TooManyEntries`,
`MissingManifest`, `MissingScript`, `ScriptNotUtf8`. The screens map each to
one "Lý do" line.

### Tests

`test/plugins/domain/` (parser, hosts, config schema, value rules, corpus).
`test/plugins/fixtures/manifests/` holds all 42 shipped manifests (see its
README for the plugins-repo commit); the corpus test parses each with zero
problems and checks that streaming manifests keep their 10 script keys.

## Package zip

`plugins/domain/package/`. `readPackage(Uint8List zip)` returns
`Result<PluginPackage, PackageProblem>` (the first problem, never a part).
It is pure, synchronous and CPU-bound on up to 5 MiB: callers run it in
`Isolate.run`. Nothing is written and no script runs; the syntax check is the
`ScriptChecker` seam (`install/script_checker.dart`, implemented in the data
layer).

```
readZip(bytes)      zip_reader.dart        safe unpack -> ZipContents (raw bytes)
readPackage(bytes)  package_reader.dart    + manifest, scripts, sha256 -> PluginPackage
```

`PluginPackage`: `manifestBytes` (the `plugin.json` entry byte for byte, what
is written to disk), `manifestText` (the same decoded as UTF-8, a leading BOM
not part of it, what the database keeps), `manifest`, `scripts` (file name to
decoded source), `icon?`, `sha256` (of the zip, lower-case hex), `size`.
`scripts` holds every `src/<name>.js` of the zip, not only the ones the
`script` map names: shipped streaming plugins ship a `common.js` that the
others `load()`. Every file the map names must be there (`MissingScript`).

Order of work in `readZip`:

1. File over 5 MiB: `PackageTooLarge`.
2. **Pre-scan of the central directory** (`zip_directory_scan.dart`), before
   the zip parser allocates anything: no zip64, no multi-disk, at most 50
   records (`TooManyEntries`, counted on the end record and while walking),
   name / extra / comment of a record at most 1 KiB (central and local), an
   end record that closes the file (the last end signature in the file; no
   trailing bytes, no fake record inside the comment; signature bytes inside
   entry data, such as a stored nested zip, are fine), a local header that
   agrees with its central record on name, method and flags (the
   data-descriptor bit may differ), a walk that ends exactly at the
   announced count and size, and no two entries whose local header plus data overlap or reach the
   directory.
3. `archive`'s `ZipDirectory` reads the headers.
4. Names (`zip_entry_names.dart`), for every entry including ignored ones: no
   NUL, `\`, leading `/`, drive letter or `..`; no symlink mode; no case-
   insensitive duplicates (trailing `/` ignored). All `UnsafeEntry`.
5. Declared sizes of all entries, ignored ones too, add up to at most 5 MiB.
   A nested stray `plugin.zip` is not opened but counts.
6. One top folder is stripped when `plugin.json` sits at `<dir>/plugin.json`
   and every entry is under `<dir>/` (Finder's `__MACOSX/` entries and
   `.DS_Store` files are left out of that test and never decoded; they still
   count in the names, duplicate and size checks).
7. Only `plugin.json` (64 KiB), `icon.png` (64 KiB) and flat `src/<name>.js`
   (1 MiB each) are inflated; every other entry is never decoded. An entry
   whose declared size is over its cap is refused before decoding.
8. Inflating (`capped_output.dart`): stored or deflate only, not encrypted
   (`NotAZip`). Deflate goes through `ZLibDecoder().decodeStream(..., raw:
   true)` into a `CappedOutput` whose buffer is allocated once at the
   declared size and never grows; a write past it throws and the entry is
   `PackageTooLarge`. The `Inflate(bytes)` constructor without `output:` is
   never used (it is eager and unbounded). The result must equal the declared
   size and the CRC32.
9. Icon: PNG signature and IHDR, at most 256 x 256 (`icon_check.dart`). A bad,
   oversized or unreadable icon is dropped and the install goes on.

The `archive` calls (`ZipDirectory.read`, `ZipFileHeader.file.getRawContent`,
`ZLibDecoder.decodeStream`, `OutputMemoryStream`, `getCrc32`) exist in 4.5.2
and 4.6.0; the cap is our own so it does not depend on 4.6's `maxOutputSize`.

Tests: `test/plugins/domain/{zip_reader,capped_output,package_reader}_test.dart`;
hostile zips are built in the test from `test/plugins/fixtures/zip_builders.dart`.

## Catalog

`plugins/domain/catalog/`. `parseCatalog(bytes, url, {isReferenceAllowed})`
returns `Result<Catalog, CatalogProblem>`. `url` is the final address of the
catalog after redirects; relative `path` and `icon` resolve against it.

- Whole catalog: body at most 1 MiB (`tooLarge`); UTF-8 JSON
  `{metadata: {name 1-80, author <= 80}, data: [...]}`, at most 500 entries;
  a non-empty `data` of which no entry is usable is `invalidCatalog`.
- Entry: `slug ^[a-z0-9_-]{1,64}$`, `name` 1-80, `type`, `version` >= 1,
  `apiVersion` >= 1, `hosts` (manifest host rules for the entry's kind),
  `path`, `icon?`, `author?`, `description?`, `languages?`, `sha256?` (64 hex,
  kept lower-case), `size?` (1 to 5 MiB). A bad entry is dropped and counted
  in `Catalog.dropped`; a repeated slug keeps the first; a bad `sha256` or
  `size` drops the entry (a silent skip would disable the integrity check); a
  bad `icon` drops only the icon; a bad `languages` means global.
- References: `http(s)`, a host, no user info, at most 2048 characters once
  absolute, fragment dropped. The address policy (public against local
  networks) is the caller's: `isReferenceAllowed(uri)` is asked for each
  `path` (false drops the entry) and `icon` (false drops the icon).
- **Newer app**: an entry whose `apiVersion` is above the supported one, or
  whose `type` is not one of the four kinds, is kept with
  `CatalogEntry.needsNewerApp`; its `kind` is null for an unknown type. The
  store lists these under "Cần Kanaru mới hơn" and offers no install. (The
  old app dropped unknown types; the plan keeps them so the user sees what a
  newer Kanaru would offer.) An unknown type may list wildcard hosts.
- `canonicalRepoUrl(input)` (`repo_url.dart`): lower-case scheme and host,
  default port removed, fragment dropped, a bare root `/` dropped, path and
  query as typed; null for anything but `http(s)` with a host and no user
  info. This string is the repository identity.

Tests: `test/plugins/domain/{catalog_parser,repo_url}_test.dart`.

## Ids and update diff

`plugins/domain/install/`.

| Function | Value |
|---|---|
| `repoInstallId(repoUrl, slug)` | `plugin-` + `stableHashHex(['repo', repoUrl, slug], 32)` |
| `fileInstallId(name, author)` | `plugin-` + `stableHashHex(['file', name, author ?? ''], 32)`, for a file and for a link |

32 hex characters is 128 bits. `repoUrl` is the output of `canonicalRepoUrl`.
A repository id comes from the source (repository address + slug). A file or
link id comes from the manifest's own `name` and `author`, which the package
chooses, so it is not a trust boundary: two packages with the same name and
author share an id. What stops a spoofed update is the same-install-source
rule applied when installing (an update is accepted only from the source the
plugin was installed from, and a clash between ids of different sources is
refused), added with the install flow in a later PR.

`diffUpdate(consentedHosts, installedVersion, installedKind, candidate)`
(`update_diff.dart`) returns `UpdateDiff`: `newHosts` (candidate entries not
covered by `hostSetCovers`), `versionOrder` (newer / same / older),
`kindChange` (none; allowed inside the translate family; refused otherwise or
for an unknown kind) and `needsReview` (= `newHosts` not empty). The
candidate is a catalog entry (a hint before downloading) or a package (the
authority). `catalogMatches(entry, package)` lists where a downloaded package
differs from the entry that offered it (`kind`, `version`, `hosts` as sets,
`sha256` and `size` when the entry gives them); the install screen shows
"Gói không khớp danh sách" when it is not empty.

Tests: `test/plugins/domain/{install_id,update_diff}_test.dart`.
