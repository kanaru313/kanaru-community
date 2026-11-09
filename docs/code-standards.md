# Code standards

The architectural rules are in [ARCHITECTURE.md](../ARCHITECTURE.md) and are
enforced by the gate. This file covers the rest.

## Naming

- Dart: `snake_case.dart` files, `UpperCamelCase` types, `lowerCamelCase`
  members.
- Rust: `snake_case.rs`, standard Rust naming.
- Tests mirror the source path: `lib/src/extension/...` is tested in
  `test/extension/`.

## Dart

- Lints: `flutter_lints` plus `avoid_dynamic_calls` as error
  (`analysis_options.yaml`). Fix warnings instead of silencing them.
- The architecture rules cannot be silenced with `// ignore:`; the CLI gate
  rejects such comments.
- Import `package:material_ui/material_ui.dart`, not
  `package:flutter/material.dart`. Icons come from `KIcons`
  (`packages/kanaru_ui`), which is the only file that names `Icons`.
- Widgets and layout tokens come from `kanaru_ui` (`KSpace`, `KRadius`,
  `KShape`, `KLayout`, `KMotion`); no width-based switching outside
  `kanaru_ui` and `shell/`.
- Errors: expected failures are values (`Result`, sealed `Ok`/`Err` in
  `foundation/result.dart`); unexpected ones propagate and are logged with
  `package:logging`. No silent catches.
- Platform differences sit behind an interface in `platform/`.
- Keep files under about 200 lines; split along module boundaries.
- Choice lists in UI are rows with the value on the left and a check mark on
  the right of the selected row, not radio buttons.

## Generated code

Never edit: `*.g.dart`, `*.drift.dart`, `lib/src/rust/`, `lib/l10n/gen/`,
`frb_generated.rs`. They are committed so a clean checkout analyzes. Regenerate
with the commands in the README (drift: `build_runner`; Rust bridge:
`flutter_rust_bridge_codegen generate`; l10n: `flutter pub get` or
`flutter gen-l10n`) and commit the result.

## Strings

All user-visible text goes through `lib/l10n/app_en.arb` (template) and
`app_vi.arb`. Add the key to both.

## Database

- Tables in `lib/src/database/tables/<module>_<group>_tables.dart`; SQL-only
  objects (FTS5 tables, triggers, seed rows) in a sibling `.drift` file.
- `schemaVersion` stays 1 until the first release. Change the tables in place;
  the debug schema guard asks to delete the developer database when the file
  differs. From the first release on, bump it and add a migration step.
- Every foreign key into `tracks` is `ON DELETE RESTRICT`, written explicitly
  (never the default `NO ACTION`). Owned child rows (`track_details`,
  `play_stats`) are deleted by the track GC; nothing references an owned child.
- Never `INSERT OR REPLACE` on `tracks` or `play_log`; use `ON CONFLICT`
  (`upsertTrackSnapshot`, `insertOrRevive`).
- Library reads filter with `visibleTrackWhere` / `isVisibleTrack`.
- Build every FTS `MATCH` input with `ftsPrefixQuery`, never by hand.
- An online track and the row that references it are written in one
  transaction.
- Extensions never add indexes or triggers to public tables; they migrate their
  own tables by hand through `extension_schema`.
- Update `docs/system-architecture-database.md` with every schema change; a
  test checks that each table, index and trigger is named there.

## Rust

- `unsafe` only in `kanaru_bridge/src/os.rs` (the file is created with the
  first OS call that needs it).
- `kanaru_media` and `kanaru_plugin_runtime` have no FFI and do not depend on
  each other; only `kanaru_bridge` knows flutter_rust_bridge. Explicit DTOs,
  no `#[frb(mirror)]`.
- `cargo clippy --all-targets -- -D warnings` must pass.

## Tests

- New logic comes with tests for the main path and the failure cases.
- Run the narrowest tests while working, `tool/check --rust` before a PR.
- With `material_ui`, `find.byTooltip` does not match its `Tooltip`; use a
  local finder as in `test/shell/shell_test.dart`.

## Commits

Conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `ci:`),
focused, no secrets.
