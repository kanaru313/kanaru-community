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

## Network

Rules in `plugins/domain/net/` (plain Dart, address bytes only), transport in
`plugins/data/net/`. `plugins` imports `platform` (DAG edge added); Android
declares `INTERNET` in the main manifest.

- **Address classes** (`address_class.dart`): `public`, `local` (loopback,
  RFC 1918, CGNAT, link-local, ULA, site-local), `refused` (`0/8`, `::`,
  multicast, broadcast, reserved, documentation, transition ranges), and
  `mixed` for a set of answers that disagree. An IPv4-mapped IPv6 or NAT64
  address takes the class of the IPv4 address inside it. `198.18.0.0/15` is
  `public`: fake-ip TUN proxies (Clash, mihomo, sing-box) answer every lookup
  from it and route the connection to the real host; refusing it would break
  every public repository for those users. Local-looking names (`.lan`,
  `.local`, `localhost`, ...) are a hint only: a local name that resolves to a
  public address is refused.
- **Rules** (`address_rules.dart`, `judgeAddress`): no user info; only `http`
  and `https`; every answer of one lookup must have the same class; a public
  destination needs `https`; the repository address the user typed may be
  `http` for a local destination. A reference inside a catalog obeys the
  catalog's `AddressKind`: a public catalog points to public `https` only; a
  local catalog may point to local addresses (any scheme) and public `https`.
  `isCatalogReferenceAllowed(kind)` is the `isReferenceAllowed` callback of
  `parseCatalog`; the lookup-free subset only, the connection judges the
  resolved answer again.
- **Policies** (`net_policy.dart`): `repo` (catalog, cap 1 MiB, address chosen
  by the user), `package` (zip, cap 5 MiB, from a catalog), `icon` (cap
  64 KiB, from a catalog), `link` (package rules and cap, address chosen by
  the user). A `package` or `icon` fetch without a catalog kind is judged as
  `public`.
- **Fetcher** (`HttpFetcher.get(uri, policy, {catalogKind, maxBytes,
  expectedSize, cancel, onProgress})`) returns
  `Result<FetchResult, FetchFailure>` and throws nothing. A new `HttpClient`
  per call, `findProxy` DIRECT, no bad-certificate callback. Per connection:
  resolve once, judge every answer, then dial only those addresses
  (`pinnedConnectionFactory`); for `https` the TLS handshake runs on that
  socket with the original host name, so SNI and certificate checks use the
  name. A factory call that is asked for a proxy refuses. Redirects are
  followed by hand, at most 3, each hop judged again with the catalog kind,
  which becomes `public` once any hop is public (a local origin cannot be
  used to reach the local network after a public hop, and the reverse).
  Every hop is a new connection (`persistentConnection = false`). Connect
  limit 10 s for lookup, dial and TLS together, total 20 s over all hops; the timeout and a cancel complete the
  result first and then `close(force: true)` the client, which destroys the
  sockets. Body read: a declared length over the cap, or the first byte past the
  cap arriving, is `tooLarge`, and the rest is not read. `onProgress(received,
  total)`: total is `expectedSize` (the catalog's `size`), else the declared
  length.
- **Failures** (`FetchFailure`): `network` (also too many redirects and a
  redirect without a usable `Location`), `timeout` (connect or total),
  `tooLarge`, `blockedAddress(reason)`, `badStatus(code)`, `invalidUrl`,
  `cancelled`. None carries an address or body.
- **User-Agent**: the caller passes `Kanaru/<version> (+<repository>)`; the
  default has no version (the app's version is not known to the module).
- **Stored repository class**: `effectiveAddressKind(stored, currentVerdict)`
  is the stricter of the class kept at the last good fetch and a fresh verdict
  on the repository address (public wins; a refused or unresolved verdict gives
  null: fail closed). The lookup and the storage of the class belong to the
  repository state code.
- **Known limit**: a fake-ip setup that also answers IPv6 from a private ULA
  range (for example sing-box `fc00::/18`) gives `{198.18.x, fcxx::}`, a mixed
  answer, which is refused; those users cannot reach public repositories.

Tests: `test/plugins/net/{address_rules,fetcher}_test.dart` (real loopback
`HttpServer` and `ServerSocket`, a fake resolver and a recording dialer; the
TLS cases use the certificate in `test/plugins/net/fixtures/`).

## Backup

Android full backup (Android 11 and older, `backup_rules.xml`) and cloud
backup (Android 12+, `<cloud-backup>` of `data_extraction_rules.xml`) leave
out `data/plugins` (packages) and `data/plugin-logs`. `data/` is
`AppPaths.dataDir` (`files/data`, the same base as the existing
`data/device_id` and `data/custom_covers` rules). The database restores the
installed list, and each package installs again from its source; logs are not
worth backing up. `<device-transfer>` excludes neither folder: the packages
move with the phone. A restore cannot be tried locally; the restore path (rows
without files) is covered by the Linux simulation in the install-flow checks.

## Storage

Code: `lib/src/plugins/data/store/`, providers in `plugins/state/plugin_store_providers.dart`. Table columns, CHECKs and the tombstone rule are in [system-architecture-database.md](./system-architecture-database.md#plugins-coded-with-the-plugin-store): `plugin_repos` (catalog, `address_class`), `plugins` (original `plugin.json` text, source, consented hosts, `removed_at`), `plugin_data` (config and custom choices, plain text).

**Writes.** Every write of `PluginRows`, `PluginRepoRows` and `PluginConfigStore` is one transaction and is meant to run on the serial write queue; the checks inside make a missed queue lose a write, never corrupt a row. `PluginRows.transaction` joins the current transaction, so an update is one unit: `switchPackage` (returns the row before and after) and `adaptToForm(old manifest config, new manifest config)`. A plugin row is never deleted: remove sets `removed_at`, clears `package_dir` and deletes the `plugin_data` row; installing the same id revives it with an empty config and the new consent. `updated_at` is `MAX(now, updated_at + 1)` on every switch, remove and revive. The manifest of a row is parsed once per `(install_id, updated_at)`; a text that no longer parses reads as null (the plugin is shown as broken).

**Package folders.** `dataDir/plugins/<install_id>/v<version>-<epochMs>/` holds the original `plugin.json` bytes, `icon.png` when kept, and `src/*.js` (re-encoded as UTF-8 from the decoded text). Names are shape-checked before any file system call (`plugin-` + 32 hex, `v<n>-<n>`, `[A-Za-z0-9_.-]+\.js`). Order for an install or update: write the new folder (each file flushed; a failure deletes it), then the database transaction, then delete the old folder (`remove` and `switchPackage` return what to delete; a failed delete is left to the sweep). `listFolders()` lists well-named folders only and never follows links; `deleteFolder` refuses bad names and prunes an emptied plugin folder.

**Reading a package.** `readPackage(row)` parses the folder, checks size caps and that every manifest script file exists, and refuses (`PluginPackageUnreadable`, no path in the reason) a folder whose `plugin.json` differs from the row's `manifest_json` (changed from outside, for example by a restore). Results are cached per folder (16 entries, oldest dropped); a failure or a mismatch is not cached. `exists(row)` is the restore check.

**Config store.** `setValue`: `unknownKey` (no live plugin or no such field), `invalidValue`, `tooLarge` (values or choices over 64 KiB); null or an empty string removes the value so the default applies. A value is checked against the effective field: for a `custom` single select the manifest options plus the user's choices. Choices: name up to 200 and note up to 300 code points, 50 options in all, a name equal to an option is only selected, removing the selected choice selects the first remaining option. `configForRun` reads stored, then default, then absent; a stored value that no longer fits is absent. `adaptToForm` keeps a value only if its field exists with the same mode and format and the value still fits; choices stay only on a field that is still a `custom` select; a plugin that is no longer live gives `unknownKey`. The save is an insert that selects only a live plugin, so a write that lost a race with a remove changes nothing.

**Repository class.** `plugin_repos.address_class` (`public` or `local`) is the class the fetcher reported at add or the last refresh. Phase services pass it as the catalog kind for package and icon fetches. Only an exact `local` reads as local; anything else reads as public, the strict class.

## Services

Code: `lib/src/plugins/data/{install,repos,native}/`, domain types in `plugins/domain/install/{held_package,prepare_result,repo_results}.dart`, wiring in `plugins/state/plugin_services_provider.dart` (`pluginServicesProvider`; tests override `pluginFetcherProvider`, `scriptCheckerProvider`, `documentPickerProvider`).

**Write queue.** `PluginWriteQueue` runs every mutation strictly one after another: install, update, repair, remove, config writes, repository add / remove and the writes of a refresh. Its first job is the sweep plus the restore scan; every later job waits for it. An error of a job reaches only its own caller (`onError` turns it into a typed result); a failing first job is logged and does not stop the queue. `key:` makes a call made while the same key is queued or running share that future. A job never awaits another `run` (it would wait for itself). Network time stays outside the queue: a download or a catalog fetch finishes first and only the write that follows is a job, so a slow server never holds up a config save.

**Sweep and restore scan.** `PluginSweeper.sweep` deletes every package folder no live row points to (a removed plugin, an old version left by a crash, a half-written install); when the live rows cannot be read it deletes nothing. `findMissing` lists live rows whose folder or `plugin.json` is gone as `RestoreCandidate(row, action)`: `download` for repository and link origin, `pickFile` for file origin. The services expose the first result as `startupRestore` and a fresh scan as `findMissingPackages()` (a queue job, for the next store open). Reinstalling is not done in the first job: the restore step runs one queue job per candidate, so a slow network at startup never blocks other writes. The same job deletes the run log files (`plugin-logs/<id>.jsonl`, `.jsonl.1`) of every id that is not a live plugin (a remove that crashed before its delete, a restored backup); when the live rows cannot be read it deletes no folder and no log.

**Repositories.** `PluginRepositories.add` canonicalizes the address (`canonicalRepoUrl`), checks for a duplicate, fetches under the `repo` policy, parses with the address rules of the class the fetch ended with, and inserts the row with its catalog and `address_class` in one write; any failure leaves nothing, and concurrent adds of one address share one run. Errors are `RepoError` values for the dialog lines (`invalidUrl`, `needsHttps`, `duplicate`, `network`, `timeout`, `badStatus`, `notACatalog`, `tooLarge`, `blocked` + reason, `storageFailed`). `remove` deletes the row only. `RepoRefresher`: `refresh(id)`, `refreshAll()` and `refreshStale()` (never fetched, last attempt failed, no catalog, or 6 h old or more; a time in the future counts as stale); at most 4 fetches at once, calls for one repository and `refreshAll` calls share one run; a failure keeps the last good catalog and stores only the error kind; a repository removed while its fetch ran is not written back.

**Stored catalog.** `catalog_json` holds the parsed catalog written back in the wire format with every reference absolute (`catalog_codec.dart`), so it reads the same whatever address it was fetched from (a redirect changes what a relative path resolves against). `CatalogCache` decodes it once per revision of the row. An entry of an unknown type is stored with the type `unknown` and stays listed as "needs a newer app".

**Address class at use.** A package or icon fetch of a stored repository takes the stricter of the stored class and a fresh look at the repository's own address (`RepoAddressGuard`, `effectiveAddressKind`): a repository stored `local` that now resolves public is held to the public rules. A refused or unresolvable address refuses the fetch (fails closed, never falls back to the stored class). A good answer is reused for 60 s.

**Icons.** `PluginIconCache`: catalog icons fetched on first use under the `icon` policy (64 KiB cap, PNG header check), memory only, 8 MiB with the least recently used dropped first; any failure is remembered for 60 s; concurrent asks share one fetch; `clearFailures()` after a refresh of all. Installed icons come from the package folder (`PluginFiles.readIcon`).

**Held package.** `HeldPackages.prepareFromRepo(repoId, slug)`, `prepareFromFile(PickedDocument)` (`DocumentPicker.read(maxBytes: 5 MiB + 1)` within 10 s; a late result is dropped and a late error swallowed) and `prepareFromLink(url)` (`link` policy) return a `PrepareOperation` (`progress` stream, `result` future that never throws, `cancel()`). Steps: bytes, `readPackage` in an isolate, syntax check of **every** `src/*.js` (10 s each; the unmapped helpers a script may `load()` included), for a repository entry `catalogMatches` (also `sha256` and `size` when the catalog gives them). A native library that cannot run the check refuses the package (`ScriptCheckUnavailable`), never accepts it unchecked. A package that reads but cannot be installed (script error, differs from the catalog) is still returned, with `ProblemsReview` listing the reasons; `refreshAndRetry(held)` refreshes the repository and prepares the entry again from the fresh catalog. Other results are `HeldPackage { token, package, installId, source, review, snapshot }` with `review` = `InstallReview`, `UpdateReview(diff)`, `RepairReview` (same version and same zip hash as the installed one) or `ProblemsReview`, and `snapshot` the installed version, hash, consented hosts and source of the live row with that id (null when none). The id comes from the source for a repository (`repoInstallId`) and from name + author for a file or link. Tokens are 128 random bits; at most two packages are held (the oldest goes), they expire after 10 minutes (checked on access, no timer), `discard(token)` drops one and `take(token)` releases it for the install job, which compares the snapshot with the row (`InstallSnapshot.sameAs`) and refuses a stale review. Nothing is written to the database or the disk before an install.

## Install and updates

Code: `lib/src/plugins/data/install/{package_writer,installer,updater,update_all,repairer,remover,restore_reinstall,config_writes}.dart`, rules in `domain/install/{install_rules,install_result,free_rule}.dart`, wiring in `state/plugin_actions_provider.dart` (`pluginActionsProvider` → `PluginActions`). Every result is typed (`InstallResult`: `Installed(outcome)`, `InstallRefused(failure)`, `InstallPrepareFailed`, `InstallNeedsReview(held)`); no call throws.

**Install (`installer.install(token)`).** The held package is taken (unknown or expired: `tokenExpired`). The job re-reads the row and compares it with the snapshot of the review (`InstallSnapshot.sameAs`): a difference is `reviewStale` (another update, a remove). `decideInstall` then applies: same origin (`sameOrigin`: a repository row only from the same repository url + slug, never by repository id; a file or link row only from a file or link) else `otherOrigin`; kind (`translate` and `ai-translate` may swap, any other change or an unreadable stored kind is `kindChange`); version (newer = update, same = `sameVersion`, older = `olderVersion`). A package with problems is `hasProblems`. Order of the write (`PackageWriter`): new folder, one transaction (`installOrRevive`, or `switchPackage` + `adaptToForm(old form, new form)`; consent `consented_hosts_json` = the package's hosts, `package_sha256`, empty `plugin_data` on a fresh install or revive), then delete the old folder. A config that cannot follow the new form (`adaptToForm` not `written`) aborts the transaction like a database failure. A database failure deletes the new folder (`databaseFailed`); a disk failure writes no row (`diskFailed`). The whole queue job runs under the exclusive run lease of the plugin (§ Runs), so runs of that plugin wait or are cancelled while the package switches. Two packages for one plugin run one after the other (no shared key): the second is judged against the row the first left (`reviewStale`). `InstallOptions`: `silentOnly` (a package adding hosts is not installed: `InstallNeedsReview`, or `needsReview` once the token is spent), `allowRepair`, `expectId`.

**Update.** A streaming plugin that does not hold the Free slot is left out of the update count, the Cập nhật section and update all (no download). Ids already flagged Cần xem are skipped by update all without a download. `updater.update(installId, {keepForReview})`: the row must be live and from a repository that is still added and lists a newer, supported entry (`resolveUpdate`; reasons are `repoRemoved`, `entryGone`, `needsNewerApp`, `noNewerVersion`). An entry that refuses the kind is `kindChange`; an entry listing hosts the user did not consent to is `needsReview` **without a download**. Otherwise download (outside the queue), then a silent install; a package that turns out to add hosts is `InstallNeedsReview` (kept held with `keepForReview`, else dropped) and flagged in memory. `updateAll.run()`: eligible plugins one after the other, a failure is recorded and the run goes on, concurrent calls share the run; progress is `UpdateAllState` in `PluginActivity`.

**Repair (`repairer.repair(installId)`).** Repository and link rows are downloaded again with all checks. Same version is written again only when the zip hash equals the stored `package_sha256` (silent: new folder, switch, delete old). A newer version follows the update rules (silent within consent, else `InstallNeedsReview` kept for the screen); the same version with another hash is `sameVersion`; a link that now serves another plugin is `wrongPlugin`. File rows give `needsFile`; `repairFromFile(installId, doc)` runs the same rules on the picked file (same origin; same version only with an equal hash).

**Remove.** `remover.remove(installId)`: under the run gate (§ Runs), one transaction (data deleted, `removed_at`, `package_dir` NULL), then the folder (a failure is left to the sweep). `removeSummary(installId)` is read fresh when the dialog opens (settings changed, options added). Config and custom-choice writes go through `PluginConfigWrites`, queue jobs like every other mutation (`ConfigWrite.failed` is a database failure, `unknownKey` a field or plugin that is gone); screens never call the store's writers.

## Restore / sync-ready

`pluginRestoreProvider` runs `restorer.restoreAtStartup()`; **nothing reads it yet**: PR C (Kho) / the app root must read it once at startup and call `restorer.restoreMissing()` whenever the store opens. Both wait for the first queue job, scan again (a stale list is never replayed) and go through the candidates one after the other. Repository and link rows: the repair path with `restore: true`, under the Free rule (§ Free rule). Hosts within consent: silent install; otherwise `InstallNeedsReview` is dropped and the plugin is flagged "Cần xem". Offline or a failed download leaves the plugin missing (`PluginActivity.missing`: `download`); `restorer.restoreMissing()` (a fresh scan, then the same work) is called when the store opens to retry. File rows stay `pickFile` until the user picks the file. The download is outside the queue; each write is its own job and re-reads the row, so a removed plugin is `pluginGone`.

## Runs

Code: `lib/src/plugins/domain/run/{run_outcome,run_request,plugin_engine,run_failure_mapping}.dart` (plain Dart), `lib/src/plugins/data/run/{plugin_runner,run_setup,run_gate,run_admission,run_cancel,plugin_pauses,fetch_handler,plugin_limiter,rust_plugin_engine}.dart`, `lib/src/plugins/domain/net/plugin_fetch_rules.dart`, `lib/src/plugins/data/net/plugin_http.dart`, providers in `state/plugin_run_provider.dart` (`pluginEngineProvider`, `pluginFetchHandlerProvider`, `pluginLimiterProvider`, `pluginRunnerProvider`, `pluginPausesProvider`, `pluginPauseProvider(installId)`). Nothing in the UI calls it yet; lyrics (online lookup) and translation reach a plugin only through `PluginRunner.run`. This section is the run contract both callers use: a change to a name, variant or rule is made here first.

**Request.** `PluginRunRequest { installId, script (a manifest script key), input (any JSON value: map, list, string, number, bool, null), timeout, configAppend (default empty), logInput (default true for search / lyrics, false for other scripts) }`. `run(request, {RunCancel? cancel})` never throws; `cancel()` is idempotent. `reportRejectedOutput(installId, script, reason)` is for a caller whose reader or validator refused a `RunOk` output: one app-log line and one run-log event (`invalidResponse`) with the plugin, the script and the caller's fixed reason text, never the output.

**Outcome (`RunOutcome`, sealed: callers switch without a default).**

| Variant | When |
|---|---|
| `RunOk(outputJson, fetchFailure?, rateLimitSeen?)` | the script returned data; never changed by a sticky fetch failure (the caller decides: an empty result with a failure is a failure, a found result counts) |
| `RunScriptError(kind, message, retryAfter?, fetchFailure?)` | the script reported it; `kind` stays raw (`rateLimited`, `invalidResponse`, `server`, `auth`, `quota`; the runtime's none is `invalidResponse`); `retryAfter` clamped 1 s .. 15 min |
| `RunFailed(reason, fetchFailure?)` | `timeout`, `memory`, `stack`, `outputTooLarge`, `internal` (also: the bridge call threw, a refused `configAppend`, an engine error) |
| `RunCancelled(reason)` | `caller` (its `RunCancel`) or `pluginChanged` (the run gate) |
| `RunBusy` | the runtime had no worker or queue slot (should not happen behind admission) |
| `RunPaused(until)` | the plugin is paused (below) |
| `RunNeedsConfig(fieldTitles)` | a required setting has no value (checked with the stored-or-default config, before the engine) |
| `RunUnavailable(reason)` | `notInstalled` (no row, tombstoned), `packageUnreadable` (manifest or package cannot be read), `noScript` (the manifest has no such script key) |

`PluginRunRequest.kinds` (default empty = no check) names the kinds a caller may run (lyrics `{lyrics}`, translation the translate family): a live row of another kind is `RunUnavailable(notInstalled)`, because a removed id can be installed again as another kind with the same name and author.

Nothing ran (the engine was not begun, nothing was sent) for `RunBusy`, `RunPaused`, `RunNeedsConfig`, `RunUnavailable` and for `RunCancelled` when the cancel came before dispatch. A cancelled job maps by who stopped it: the caller's token, the gate (`pluginChanged`) or the outer deadline (`RunFailed(timeout)`); `mapEngineResult` is a pure exhaustive mapping of the bridge status.

**Order of a run.** Gate shared lease (waits while the plugin is being switched) → pause check → row, manifest, package (`PluginFiles.readPackage`, cached), config → required settings → admission slot → `begin` → engine → mapping → pause from the outcome. The stored values are read once (`PluginConfigStore.read`): the run config (`resolveRunConfig`: stored, then defaults) and the saved `format: url` endpoints come from that one snapshot. The plugin's storage map, its clear counter (`storage_rev`) and the row's `updated_at` are read in the same setup (`PluginStorageStore.read`) and the map goes to the engine as `storageJson`.

**Run storage (`PluginStorageStore`).** The map a script keeps between runs lives in `plugin_data.storage_json` (a JSON object of strings, `''` = nothing); the runtime owns the 64 KiB quota, Dart only measures (`storageSizeBytes`, UTF-8 bytes of keys and values). When the engine result carries a new map and the run was not stopped (no caller cancel, no gate `pluginChanged`, no deadline), the runner **awaits** one guarded write-back as a write-queue job before it returns the outcome: `UPDATE plugin_data SET storage_json = ? WHERE install_id = ? AND storage_rev = <read at setup> AND EXISTS (live plugin row with updated_at = <read at setup>)`. An update, repair or remove since the run began, or a clear, makes it change nothing. The admission slot is already free (it follows the engine job); the gate lease is kept until the write ends. Runs of one plugin that start at the same counter overwrite each other: last writer wins. A failed write logs its error type once and the outcome is still returned. `PluginActions.clearStorage` empties the map and adds 1 to `storage_rev` in one queue job, so a run that began before the clear cannot bring its map back. The map stays on update (the data row survives `switchPackage`), goes with the row on remove, and a revived plugin starts empty.

**Run log (`plugin-logs/<installId>.jsonl`).** Code: `domain/logs/{run_log_event,log_redaction,run_log_limits,failure_log_line}.dart` (plain Dart), `data/logs/{plugin_run_log,plugin_log_reader,log_lines}.dart`, `data/run/run_log_recorder.dart`; providers `pluginRunLogProvider` (`state/plugin_services_provider.dart`) and `pluginLogReaderProvider` (`state/plugin_actions_provider.dart`). No UI yet.

- **What is written** (one JSON line, `RunLogRecorder` after the outcome): a failed run (`RunScriptError` kind or `RunFailed` reason as `kind`), a caller rejection (`reportRejectedOutput`, kind `invalidResponse`, the caller's fixed reason as `message`) and a `RunOk` run that printed to the console (`kind: ok`). Never written: `RunCancelled`, `RunBusy`, `RunPaused`, `RunNeedsConfig`, `RunUnavailable`, a refused `configAppend`, a run the plugin switch stopped, a run with no console output that ended well. Fields: `ts, installId, pluginName, version, script, query?, kind, message?, stack?, console[], requests[{method, host, path, status?, ms}]`. `query` is the run input and only for `logInput == true` (`search`, `lyrics`); `requests` come from `JobContext.requests` (the fetch handler adds one record per request, refused ones with no status, at most 100 per run) and hold no query string, header or body. Each line is capped (message 4000, stack 8000, 50 console lines of 500, query text 8000 characters, request path 300, host 253), after redaction; the request record holds the full path until then.
- **Writer (`PluginRunLog`).** One serial queue per plugin id, never awaited by a run (`append` returns at once). `<id>.jsonl` rotates to `<id>.jsonl.1` before it would pass 512 KiB (the old `.1` is replaced, lines older than 7 days are dropped), so a plugin's logs stay under 1 MiB; a line over 512 KiB is not written (one app-log warning, apart from the write-failure one). `append` can take the deletion counter read when its event was started, so a rejection that raced a remove is dropped. `delete(id)` removes both files inside the queue and bumps a per-id counter: writes queued before it are dropped, writes queued after it are written (a plugin installed again keeps its id). The remover deletes the log after a remove; the sweep deletes the logs of ids that are not live. A write failure logs its error type once per writer; a log never fails a run. Files sit in `<AppPaths.dataDir>/plugin-logs`, outside Android backup.
- **Reader (`PluginLogReader`, `PluginActions.logReader`).** `readLog(installId, {errorsOnly})` waits for the writes queued so far, reads both files, skips corrupt lines, keeps entries of the last 7 days, newest first, at most 500. `errorsOnly` keeps failures (`kind != ok`: failed runs and caller rejections) and drops `ok` runs that only printed. `clearLog(installId)` is `delete`. `logFolder` is the folder to open.
- **App log.** One INFO line per failed run (`Plugin "<name>" (<id>) <script> failed: <kind>`, plus `host=<host>` only when the failure was a blocked address, masked if it is a setting value): no song data, path, console or stack.
- **Redaction (`LogRedactor`, best effort).** Applied to `query`, `message`, `stack`, `console` and each request's `host` and `path`; the matches of every secret are found on the original text, overlapping or touching ones merge, and each merged span becomes one `***`: (1) the user-entered settings (input text / multiline / url, number as text, list items, map keys and values; selects and toggles stay readable; a stored key that is not in the schema is hidden) of 4 or more characters, with their percent-encoded and whole-URL forms, plus each token of a value split on whitespace, `,` or `;` of 8 or more characters; a value that is an absolute http(s) URL also hides its host (as stored and lowercased), path, each path segment and each query value of 8 or more characters (manifest hosts stay readable unless the user saved the same value); (2) every string value of the plugin's storage of 8 or more characters, before and after the run; (3) path segments of 16 or more characters of `[A-Za-z0-9_-]` become `…` (checked before the secrets, so a short secret inside a signed segment cannot break the shape); (4) the run's `configAppend` values and the header values (`Authorization`, `Cookie`, `Set-Cookie`, names holding `token` or `key`, 8 or more characters) the fetch handler put in `JobContext.maskValues` (collected for every request, refused ones and invalid header sets too, and the cookie value of a `Set-Cookie`; the set holds at most 256 values, and once it overflows the event keeps kind, script and counts but its message, stack, console lines and request paths become `…`); (5) when the request's `logInput` is false, `query` is never written and every input string of 8 or more characters (and each line of a multi-line one) is hidden in message, stack and console, since an AI provider's error can quote the prompt. A script can still print a secret in another form (base64, split in two): redaction is defence in depth, not a guarantee, and the screen's caption says so ("Kanaru che giá trị cài đặt, bộ nhớ riêng và token mà nó biết. Plugin vẫn có thể tự ghi thông tin khác: xem lại trước khi chia sẻ.").

**Run gate (`RunGate`).** One per process, created in `PluginServices`, handed through `pluginActionsProvider` to `PluginActions.runGate`, then to `PluginInstaller` and `PluginRemover`. A run holds a shared lease per install id. Install-over, update, repair, restore (all go through `installer.install`) and remove take an exclusive lease around the queue job, outside it: the id is closed (new runs wait), the leases' `changed` token is cancelled (a running job is cancelled in the runtime and ends `RunCancelled(pluginChanged)`; a run still waiting for a slot starts over on the new row), the lease waits for them up to 2 s and then switches anyway, and reopens when the action ends, however it ends. A run asked while the id is closed waits and runs on the new version (removed meanwhile: `RunUnavailable(notInstalled)`). Other ids are unaffected. A request already sent to a server cannot be recalled: an AI request can be lost on `pluginChanged` or at the deadline.

**Admission (`RunAdmission`).** 4 slots (the runtime's worker count), first come first served. A run takes a slot after the gate, setup and the required-settings check, and the slot is given back when the engine returns (also after an outer deadline: the worker is still busy until the runtime lets go). So nothing waits in the Rust queue, run time starts at dispatch, and a fan-out of many sources never turns queue time into `Timeout` or `Busy`. Waiting for a slot is not timed; the caller's cancel ends it.

**Time limits.** Run wall (`timeout_ms` to the engine) = `min(90 s, request.timeout + 9 x spacing)`, spacing `pluginSpacing` 100 ms (the allowance for the pauses between the up-to-ten sends of one call). Outer deadline = wall + 30 s, counted from dispatch: on expiry the runner cancels the job and returns `RunFailed(timeout)`. The per-fetch timeout is the fetch request's `deadline_ms` (see [plugin-host-api.md](./plugin-host-api.md)).

**Pause (`PluginPauses`, in memory).** Started only by the runner, only from a `RunScriptError(kind: rateLimited)` outcome: for its `retryAfter`, else 60 s. A quota error, a 429 the script handled (`rateLimitSeen`), a failure or a cancel never pause. The pause is checked once, at run start (`RunPaused(until)`); runs in flight finish. `pluginPauseProvider(installId)` is the observable `DateTime? until`; it updates when a pause starts and when it ends.

**Fetch binding (`fetch_handler.dart`).** Each run passes its own closure to the runtime: `(request) => handler.handle(request, jobContext)`. `JobContext` holds the install id, the job id, a `RunCancel` that is cancelled when the run is stopped for any reason (the handler then answers `abandoned`), and a snapshot taken at run start: the manifest hosts, the consented hosts and the saved user endpoints. A request whose `install_id` differs from the run's is answered `invalidRequest` without reaching the handler; a handler that throws is answered `network`.

**Network for plugin runs (`HttpPluginFetchHandler`, the only network path of a plugin).** Per request, in this order; nothing is sent until step 6 passed:

1. `install_id` is the job's, else `invalidRequest`; a cancelled job is `abandoned`.
2. The job's consented hosts are not empty, else `notConsented`. This is the snapshot taken at run start, never the live row, so a job draining after an update is judged by the version it started with.
3. The URL parses (`invalidRequest`), is `https`, has no user info, no IP literal, no local-looking or single-label name and no explicit port, else `blockedHost`.
4. The host (no port) is covered by both the manifest hosts and the consented hosts (`hostSetCovers`, wildcards included), or equals host and port of a `format: url` value the user saved (`JobContext.userEndpoints`: stored values only, never manifest defaults or `configAppend`; a saved `http`, local or IP value never counts; a saved value with a port allows that port, one without allows 443). Else `blockedHost`.
5. Method `GET` or `POST` (a GET with a body is refused). Headers: names lower-cased RFC 9110 tokens, values ASCII without control characters except tab, else `invalidRequest`; `accept-encoding`, `host`, `connection`, `content-length`, `transfer-encoding`, `te`, `upgrade`, `keep-alive`, `trailer`, `expect` and `proxy-*` are dropped silently; values of `authorization`, `cookie` and names containing `token` or `key` join the job's mask set.
6. `PluginLimiter` waits for the plugin's next start (100 ms after the previous start of the same plugin, first come first served, plugins independent). The wait counts against `deadline_ms`: a wait that would leave under 1 s answers `network` with nothing sent; a cancel ends the wait (`abandoned`) and gives the slot back.
7. `PluginHttpClient.send`: a new `HttpClient` per request, `findProxy` DIRECT, connections through `pinnedConnectionFactory` (one DNS lookup; every address of that answer must be public, so a private, loopback, link-local, reserved or mixed answer is `blockedHost` before a socket opens; `198.18.0.0/15` counts as public; IPv4-mapped and NAT64 take the class of the IPv4 they carry; this is not `judgeAddress`, which allows local `http` repositories). TLS on the original name, no bad-certificate callback, connect bounded 10 s, overall timeout = `deadline_ms` as given (no shorter cap), timeout and cancel `close(force: true)`. The default `User-Agent` is sent only when the script set none.
8. Redirects are never followed: a 3xx is an `ok` answer with `url` = the requested URL; the script may `fetch` the `location` header, a new request through steps 1-7. `sends` is always 1; no host retries.
9. The body is read up to 4 MiB (`pluginMaxResponseBytes`); over it is `invalidResponse`.
10. 429 and 503 are answered `ok` with status, headers and body like any status. The handler records `JobContext.rateLimitSeen` (the longest `Retry-After` of the run, seconds or HTTP date, clamped 1 s .. 15 min, else 60 s), which the runner puts on `RunOk`. It starts no pause, refuses no later fetch and never answers `rateLimited`.
11. Other statuses are `ok`. Response headers pass through (lower-case, one pair per value, `Set-Cookie` included, no jar); `Set-Cookie` values of 8 characters or more join the mask set.
12. Socket, TLS and timeout failures are `network`; a refused address is `blockedHost`.

No URL, header value, body or setting appears in any exception text or log line. Residual risk: behind a fake-ip proxy (Clash, sing-box TUN) every name resolves into `198.18.0.0/15`, which the public-only check accepts by design, so such a proxy can route an allowed name into the user's network; the check cannot see past the proxy.

**Engine (`PluginEngine`).** `reset()`, `begin()`, `cancel(job)`, `run(request, fetch)` with plain-Dart DTOs, so `domain/` never imports `lib/src/rust`. `RustPluginEngine` is the only importer of the bridge (besides the syntax check); a bridge call that throws becomes an `internal` result with one log line (the type only). Tests override `pluginEngineProvider` with a fake.

**`configAppend`.** Keys must be declared `input` fields of format `text` (never `url`, number, list, map, select, toggle) and each value at most 1000 characters; anything else is `RunFailed(internal)` with a log line. The runner sets `value = [stored-or-default, append].where(nonEmpty).join('\n')` from the same snapshot, never persists it and never uses it as a user endpoint.

## Free rule

`streamingSlotHolder` / `streamingInstallAllowed` (`free_rule.dart`, pure) are the one rule behind the install gate, the alerts and the store list. Without Pro only the slot holder may work: the oldest live streaming plugin whose package folder is there, or, when none has a folder, the oldest live streaming plugin. A plugin restored later never displaces a working one. `StreamingGate.streamingInstallAllowed(installId)` applies it to the rows and is checked for **every** write of a streaming package (install, revive, update, repair, repair from a file, restore); the holder's own update or repair is never blocked, a second streaming plugin stays `proRequired` on every path. Alerts and `buildStoreItems` use the same function with the missing folders known from `PluginActivity.missing` (so they need a restore scan to know them). The services read `proFeatureStatusProvider(ProFeature('plugins.multi-streaming'))` at every check; it follows the license's `changes`, so a change of license applies to the next check. `pluginStreamingUnlockedProvider` watches the same provider for the screens. The store shows such an entry as `locked`, the alerts as `proRequired`.

## Derived state

All in `lib/src/plugins/state/`, all mapping a database error to the error state with one log line (`joinAsync`, `asyncFailure`: type only). `storeItemsProvider` (entries × install state: `notInstalled`, `installed`, `updateAvailable`, `locked`, `needsNewerApp`) and `storeSectionsProvider` (search through `foldDiacritics` over name, author, repository name, hosts; filters `StoreFilter` kinds, states, languages, authors, repositories, set by `storeFilterProvider`; sections Cập nhật / Đã cài / Chưa cài, an updatable plugin only under Cập nhật). `updatesProvider` (`silent`, `needsReview`, `count`, `updateAllCount`; "Cần xem" = catalog hosts not consented or flagged in memory; an entry of a kind the app would refuse is no update, in the store list either). `pluginAlertsProvider` (`PluginAlert` per id: `missingRequiredConfig`, `packageMissing`, `broken`, `reinstallFromFile`, `proRequired`; `any` is the root red dot). `updatingIdsProvider`, `updateAllStateProvider`, `pluginActivityProvider`. `pluginPageProvider(installId)` (row, parsed manifest, alerts, updating, waiting review, missing, the newer version the repository lists with its new hosts and repository id, one entry per `format: url` field with the hosts typed so far, the titles of the required settings without a value) and `installedByKindProvider` (live rows by kind with restore state). `PluginActivity` holds what is not in the database (updating ids, review flags, missing folders, update-all progress) and is observable.

**Review fixes (services).** The services provider reads its inputs once (`ref.read`): a rebuild would build a second write queue whose sweep could delete a folder an install had written but not yet recorded. A refresh never lowers a stored `public` address class to `local` (only removing and re-adding the repository does); `refreshAll` also tells the icon cache to forget failures. `reviewOf` decides origin: a live plugin with the same id from another source (`sameOrigin` in `install_rules.dart`) gives `ProblemsReview` with `OtherOrigin`, and an installed kind this app does not know gives `InstalledKindUnknown`; install, update and repair map `OtherOrigin` to `otherOrigin`. `InstallSnapshot.sameAs` compares the exact source (`HeldSource.sameSource`). `RepoHeldSource.repoId` is null when the source was read from a row. A catalog whose normalized text passes 1 MiB (relative references become absolute) fails add and refresh as `tooLarge`.

## Screens

`lib/src/screens/plugins/` (imports only `plugins/{domain,state}`, `kanaru_ui`, the settings frame widgets and l10n; texts in `lib/l10n/parts/plugins_{en,vi}.arb`). Routes (`plugin_routes.dart`, mounted from `settings_routes.dart`, paths in `PluginPaths`): `/settings/plugins` (optional `?kind=lyrics|translate|streaming`), `/settings/plugins/repositories`, `/settings/plugins/p/:installId` (`PluginPaths.plugin(id)`), `/settings/plugins/p/:installId/logs` (`PluginPaths.pluginLogs(id)`, the Nhật ký page).

**Kho plugin** (`store/`). `SettingsScaffold(pinnedBelowHeader: search, actions: [Lọc, ⋮])`: header and the `KFilterField(persistent)` stay, the blocks scroll. Data is `storeViewProvider` (state): `storeSectionsProvider` plus the installed plugins that have no catalog entry (file / link installs), through the same `StoreFilter`; it returns domain-only rows (`StoreRowView`) so screens never see database rows. An entry that needs a newer app has no row, only the footer count. Blocks Cập nhật → Đã cài → Chưa cài, empty ones left out; nothing installed and no repository: only the guide card; repositories but no match: "Không có plugin khớp." with [Xoá bộ lọc]. Failed repositories show one `KInlineNotice` (filled error tone) at the top of the scrolling list: one repo (name, reason, saved time, retry), several, or offline (every repository failed with a network error).

Opening the store starts from a fresh filter (the route's `kind` fills the search with that kind's first English tag, `#lyric ` / `#translate ` / `#streaming `, via `storeSearchForKind`; Lọc stays empty, an unknown kind leaves the search empty), calls `StoreOps.onOpen()` (`refreshStale()` + `restorer.restoreMissing()`, each never throws) and reads `pluginRestoreProvider`. The Settings root plugin row reads the same provider (fire and forget, a failure is logged), because nothing at app start does yet. The row's dot (`SetupValueRow.alert`) shows when `pluginAlertsProvider.any` or an update needs review; it never shows while loading or after a database error.

**What the screens call.** `storeOpsProvider` (`StoreOps`, an interface: open tasks, refresh all / one, add, describe, remove a repository) and `repoViewsProvider` / `pluginIconProvider` are the only service reach; widgets never name data types. The flows that own their own screens plug into `storeActionsProvider` (`StoreActions`: open plugin, install, update, review, remove, update all, install from file, install from link); a null callback shows its control disabled; `storeActionsProvider` is wired to the plugin page (a tap on an installed row pushes `PluginPaths.plugin`) and to the install, update, update-all and remove flows below. `showAddRepositoryDialog(context, initialUrl:)` is public for the install-from-link flow.

**Search tags** (`plugins/domain/search/store_search.dart`): in the search field a `#word` naming an alias (English, case-insensitive: lyrics `lyric` `lyrics`; translate `translate` `translation`, covering `ai-translate` too; streaming `streaming` `music` `source`) keeps only that kind; several tags are the union; the other words search as before. An unknown `#word` is plain text; a `#…` that is still the start of an alias (`#ly`, a bare `#`) filters nothing. The tags are ANDed with Lọc, never counted in its badge or shown in its sheet, and vanish with the text. No suggestion row: the placeholder "#loại" is the only hint.

**Lọc** (`store_filter_*.dart`): a bottom sheet on mobile, a 360 panel under the Lọc button on desktop (`AnchoredPanelLayout`, right edges aligned, flips above). Groups Loại plugin (Lời bài · Dịch · Nguồn nhạc; Dịch covers `translate` and `ai-translate`) · Trạng thái (the three blocks) · Ngôn ngữ · Tác giả · Repository; empty groups are left out. Every tap edits the filter as it is at that moment. The badge counts chosen values, a kind group once.

**Repository** (`repos/`): rows, an icon-only `KFab` (bottom end, the list is padded below it), `showAddRepositoryDialog` (the service's typed result is mapped to the spec's lines; the field and Cancel are locked while it loads) and a Gỡ confirm.

**Install, update and remove** (`install/`, `problems/`, `updates/`, `remove/`). The flows read `installOpsProvider` (`state/install_ops.dart`, `InstallOps`: prepare from a store entry, an update, a file, a link or a refresh; discard; install; update in place; update all; remove preview and remove). It is the only reach into the services; the few data-layer result types the screens need (`UpdateAllState`, `UpdateOutcome`, `RemoveResult`) are re-exported from that file. Nothing is written before the user presses the button, and the held package is discarded on every way out of the screen.

- **One screen** (`PluginPackageScreen`, state in `PackageController`): a `KDialog` 600 wide (up to 840 high) on desktop, a full-screen route on mobile. Phases: loading ("Đang tải và kiểm gói…" with the progress line, [Cài] locked), ready, working ("Đang cài…" / "Đang cập nhật…", close locked), failed (`KInlineNotice` filled error with [Thử lại]; the retry prepares the package again). Install variant: icon 56, "Cài <tên>?", kind · version · author (self-declared), the source card (repository name and address, file name and size, or the link), the description, **Gửi dữ liệu tới** (`common/hosts_block.dart`: hosts in mono, a sentence per wildcard, one line per `format: url` field, "Không có địa chỉ cố định.", then the consent line), the dimmed "Sắp có" rows (static facts, ask the AI), [Huỷ] [Cài]. Update variant: "Cập nhật <tên>", kind · author, new hosts on `errorContainer` with MỚI, the update consent line only when hosts are new, [Để sau] [Cập nhật]. A package that adds hosts is only ever installed from this screen; "Cập nhật tất cả" and the in-place update never write it.
- **What the review decides** (`problems/install_problem.dart`): `InstallReview` shows the install variant; `UpdateReview` with a newer version shows the update variant; the same or an older version, a kind change, another origin, a script error or a catalog mismatch close the screen and open a dialog. The write step rechecks every rule against the installed row; a refusal that comes back (`reviewStale`, an expired token) prepares the package again with a short notice, `proRequired` locks [Cài] under the "Cần Kanaru Pro" band (file and link installs of a second streaming plugin; a store row of a second streaming plugin only says the Free rule in one line).
- **Problem dialogs**: "Không cài được" (red **Lý do** box, one line per `PackageProblem` or refusal; a host reason adds the public-names note), "Cần Kanaru mới hơn" (no box, with the apiVersion when known) and "Gói không khớp danh sách" ("Điểm khác biệt", the cache hint, [Đóng] [Làm mới rồi thử lại]: the repository is refreshed, then the entry is prepared again).
- **Entries**: [Cài] of a Chưa cài row; ⋮ Cài từ tệp… (`DocumentPicker`, `.zip`; the file is read in the prepare step: 5 MiB cap, 10 s, a late result is dropped); ⋮ Cài từ đường dẫn… (`KTextFieldRow`; a `plugins.json` link changes the helper and the button to [Thêm repository], which opens the add-repository dialog with the link); [Xem] of an update row; [Cập nhật] and **Cập nhật tất cả (n)**.
- **Updates**: [Cập nhật] runs in place (`updatingIdsProvider` shows the spinner and locks only that row); a failure puts "Không cập nhật được: <lý do>" under the chips (`updateFailuresProvider`) and the same sentence in a SnackBar; success says "Đã cập nhật <tên> lên bản N". Update all shows "Đang cập nhật i / n…" in the block header, and ends with one toast counting the updated, the to-review and the failed plugins.
- **Repair** (`InstallOps.repair`): the same package again for a repository or link plugin whose folder is missing (same hash: silent; newer: the update rules; a package that needs review is dropped and the update screen prepares it again). A file install has no repair button: the page says to remove it and install the file again.
- **Remove** (`removePluginFlow(context, ops, installId, {onBeforeRemove})`, reused by the plugin page): always asks; "Xoá <tên>?", author · bản N, **Sẽ bị xoá** (code, settings). No **Vẫn giữ** box yet: no built part reads a plugin's output, so no line is true; add lines per kind when they are. "Đã xoá <tên>" / "Không xoá được <tên>".

**Plugin page** (`page/`, route `/settings/plugins/p/:installId`). `SettingsScaffold(headerBuilder: …)`: the header is pinned and drawn by `PluginPageHeader` (`[←] · title · 🗑`, desktop `KPage` 720). The title is "Chi tiết plugin" and cross-fades (`SwapTitle`: fade + 4 dp slide, `KMotion.fast`, instant with reduced motion) to the plugin's name while the name in the head card is under the header; the page measures that after each scroll frame, so it also works when the list has dropped the head card. State pages keep the first title. States from `pluginPageProvider`: loading is blank; a database error says "Không đọc được danh sách plugin" [Thử lại] (invalidates the list); no row says "Plugin này không còn được cài." [Về Kho plugin]. 🗑 (critical `KIconButton`, "Xoá <tên>") runs `removePluginFlow(onBeforeRemove: …)`: once confirmed the page is blank until it leaves for the store, so the vanishing row never shows "không còn được cài"; a failed removal brings the page back.

Blocks, in order: head card (icon 48, name, "<tác giả> (tự khai báo) · bản N", AI tag for an AI translation plugin, the usage row: for a lyrics plugin "Tự tìm lời" with its place in the user's order (`lyricsSourcesProvider`: "Đang dùng · thứ 2 / 4" or the off sentence, no switch) opening Settings › Lời bài; for a translate plugin "Dịch vụ dịch mặc định" is "✓ Mặc định" when `translationServiceProvider` is this plugin's install id, else "Bài chưa chọn dịch vụ riêng dùng dịch vụ mặc định." and [Đặt làm mặc định], which writes the same setting as Settings › Lời bài › Dịch lời and the Dịch lời modal) · `UpdateBand` (`KInlineNotice` primary: [Cập nhật] runs `updatePlugin` in place and shows a spinner while the plugin updates from anywhere; [Xem bản cập nhật] when the new version adds hosts; an update that fails on the package itself turns the button into [Làm mới danh sách], which refreshes the repository only; none for file or link installs and removed repositories) · `PluginErrorBand` (one band, first match wins: Free second music source "Cần Kanaru Pro"; missing or unreadable package with [Cài lại] through `repairPluginFlow`, or the file sentence alone; required setting missing with [Mở cấu hình]) or, when none of those applies and `pluginPauseProvider` has a pause, `PluginPausedBand` ("Tạm dừng N phút … (429)", "hỏi lại sau HH:mm", [Nhật ký]; N is read once per pause; it goes when the pause ends) · `DetailsBlock` (Cài từ, Gửi dữ liệu tới: consented hosts one per line, wildcard sentence, one line per address field with the typed host or "(chưa nhập)", Cài lúc, Mô tả when present, Loại; then dimmed Dữ kiện tĩnh, Hỏi AI, Mã nguồn) · `ConfigSlot` (only built when the manifest has `config`; wraps the form's one section in `SetupSectionPulse`: [Mở cấu hình] scrolls to it and pulses it; the form is described in **Config form** below) · Kết nối as dimmed "Sắp có" rows (the runtime uses fixed limits) · `DataBlock` (`page/data_block.dart`, state in `plugins/state/plugin_run_info_provider.dart`): "Bộ nhớ riêng của plugin" "N KB / 64 KB" with [Xoá] (dimmed at 0; clears through `PluginActions.clearStorage`, which bumps `storage_rev`), for lyrics plugins "Lời đã lưu từ nguồn này" "86 bài · 1,2 MB" / "Chưa có" with [Xoá] (deletes the plugin's `online_lyrics` rows, never pins or `.lrc` files), the dimmed track-cache row of music sources, and the "Nhật ký" row ("N lỗi hôm nay · M mục" / "Không có lỗi") opening the log page; each [Xoá] asks first and says "Đã xoá …" or "Không xoá được dữ liệu". Not built (hidden): the music-source rows (Hiện ở Trực tuyến, Khi phát từ nguồn này) and the web page row.

**Nhật ký page** (`screens/plugins/logs/`, state in `plugins/state/plugin_logs_provider.dart`): chips [Tất cả | Lỗi], the redaction caption, one row per log entry (time, script, target, result; a failure in the error colour with its reason in words, console lines in monospace), the footer with the retention and the file path, and "Chưa có mục nào". Header: desktop 📂 "Mở thư mục log" (`FileManager.reveal` of the log folder), phone a share button dimmed "Sắp có"; 🗑 "Xoá nhật ký" asks first. Entries are read from the redacted files by `readPluginLog` (500 newest, 7 days); logs over 64 KiB are parsed on another isolate. The Kho ⋮ menu has the same folder entry on desktop and the dimmed "Chia sẻ nhật ký plugin…" on the phone. The remove dialog lists "Bộ nhớ riêng (N KB)" and "Nhật ký của plugin" under "Sẽ bị xoá", and a "Vẫn giữ" box per kind: lyrics (saved lyrics count, pins, `.lrc` files), translate and ai-translate ("Bản dịch đã lưu, cho đến khi bạn chọn Xoá các bản dịch đã lưu"; the clear action itself is not built yet).

### Config form

"Cài đặt của plugin" (`screens/plugins/config/`, built by `ConfigForm(installId, locked)` inside `ConfigSlot`). One `SetupSection`; one editor per manifest field in manifest order, chosen by the field's kind in `config_field_tile.dart`. Every value is plain text in the store (no secret format, no keyring). Spec: `mockups/screens/00-plugin-config.md` and `09-plugins.md` § 4.

**State** (`state/config_form_provider.dart`). `configFormProvider(installId)` maps `pluginConfigStatusProvider` (the same stream the page's "cần cấu hình" band reads, so both change together) to `ConfigFormData`: the fields as the user sees them (`effectiveField`: a `custom` select already holds the user's choices), the stored values (`valueOf` = stored, else default), and which choices are the user's own. `ConfigOps` (`configOpsProvider`) is the only write path: `setValue`, `addChoice`, `removeChoice` over `PluginActions.configWrites` (the write queue), never the store's writers. `ConfigWrite` is re-exported from there so screens never import `plugins/data`.

**Editors.** Text, multiline, number, integer, url: `TextFieldEditor` over `KTextFieldRow` (the default is the value in the box; no stored override while the text equals it; cleared goes back to the default and sends no value; `*` for required; the error replaces the helper line; − / + of a number save per tap). Toggle: `KSwitchRow`. Single select: a `SetupRowFrame` row (value line, ›) opening `showSelectionPicker` (title = field, caption = its subtitle). `custom` selects (every plugin kind) open `custom_choice_picker.dart` instead: own choices carry "Tự thêm" and a ✕ that removes them without closing, the footer [+ Thêm model…] opens `custom_choice_dialog.dart`; removing the last model shows "Chưa có model" under the row, a fresh install with no model shows only "Chưa chọn" (and the band). Multiple select: `KChip`s, saved at once in manifest order, at `maxItems` the rest are dimmed with "Tối đa n", below `minItems` is not saved. List and map: `KFieldRows`; a bad list item gets a red outline plus one line under the list, a map's name errors sit under the row's name box, the table is not saved while any row is wrong.

**Saving** (`config_commit.dart`, pure Dart). One `ConfigCommit` per field: one write in flight, the latest value submitted meanwhile waits (older waiting ones are dropped); a refusal is kept (`refusal`) until the user edits again or a save goes through, and one a waiting value replaces is not reported. The queue outlives its editor (`detach` only stops notifications), so an edit made just before the page closes is still saved: `dispose` of a text editor submits its last valid text. Checks (`config_checks.dart`, pure Dart, reusing the domain rules) run before a send: errors show only after the field was left once and go as soon as the text is right; text that does not fit is never sent; a value equal to the field's default is never stored as an override (it clears the stored one: `configOverride`); a text box left untouched takes an outside change that arrived while it was focused (a typed edit wins); adding or removing a custom choice waits for the field's pending saves; a cleared required value is shown as an error but still sent (stored empty), so the band appears at once. Refusals map `ConfigWrite` to the four sentences of the spec (`config_texts.dart`). An outside change shows in a box unless it is focused or its own save is in flight.

**Locked.** `ConfigForm.locked` is set by the page only for a broken or missing package and while this plugin updates in place: text fields are disabled, every other kind is dimmed (0.5) and out of reach. The lock covers every broken-package alert (`broken`, `packageMissing`, and `reinstallFromFile`: a file-installed plugin whose package folder is missing) and an in-place update.

**Known gaps.** `KFieldRows` commits on blur, Enter and remove, but not when it is disposed, so leaving the page with a list or map row still focused loses that row's last edit (needs a flush in `kanaru_ui`). The custom picker is composed locally because `showSelectionPicker` has no row action, footer or live options.
