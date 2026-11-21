# Plugins module

`lib/src/plugins/` holds what the app knows about a plugin package: the
manifest, the config schema and its value rules (this file, § Package), the
catalog and the zip reader (§ Catalog), the install ids (§ Ids). Everything
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
| `languages` | optional, never invalid; library keys (ISO 639-3); `*` / `all` / `any`, a non-list or a list over 50 = global (empty); <= 20 kept |
| `script` | object, at most 50 entries; key `^[A-Za-z0-9_.-]+$`, file `^[A-Za-z0-9_.-]+\.js$`; **every key is kept** in `PluginManifest.scripts`; required: lyrics `search` + `lyrics`, translate and ai-translate `translate`, streaming `search` + `stream`. Shipped streaming manifests declare 10 keys (`search, stream, home, genre, album, playlist, artist, related, autocomplete, resolve`). That the files exist is checked against the unpacked package (§ Catalog) |
| `metadata.regexp` | optional string <= 500 code points that compiles as a Dart `RegExp` |
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
  `.localdomain`, alphabetic top label), or `*.` + such a name.
- Wildcards: streaming plugins only, at most 10 distinct, never over one of
  the 16 shared-hosting bases (`github.io`, `workers.dev`, ...).
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
config store and form use it for every write. Lists and maps may be
JSON-decoded. URL values: https only, a host, no credentials, no
whitespace / control / format characters, <= 2000. Map keys: 1-100 code
points, no control characters, no outer space, `__proto__` refused, case
sensitive. `missingRequiredConfig(schema, config)`: a toggle is never
missing; absent, whitespace-only text, empty list or map is.

### Problems (`package_problem.dart`)

Sealed `PackageProblem` (`detail` = field path, host or type):
`InvalidManifest`, `UnknownConfigFormat`, `NeedsNewerApp`, `UnsupportedKind`,
`InvalidHost`, `InvalidWildcardHost`, `WildcardHostNotAllowed`,
`SharedHostingWildcard`, `TooManyWildcardHosts`. The screens map each to one
"Lý do" line; zip and catalog problems join the hierarchy in § Catalog.

### Tests

`test/plugins/domain/` (parser, hosts, config schema, value rules, corpus).
`test/plugins/fixtures/manifests/` holds all 42 shipped manifests (see its
README for the plugins-repo commit); the corpus test parses each with zero
problems and checks that streaming manifests keep their 10 script keys.

## Catalog

Filled by the zip and catalog phase.

## Ids

Filled by the zip and catalog phase.
