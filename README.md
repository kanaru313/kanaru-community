# Kanaru

A Material 3 music player built with Flutter. Local files come first; remote
sources and plugins follow. Targets Android (primary) and Linux desktop, each
with its own shell (bottom bar on mobile, sidebar and top bar on desktop).

This repository is the core open source app and the only Flutter runner.
Additional features can be added through extension packages (see
[ARCHITECTURE.md](ARCHITECTURE.md)).

License: GPL-3.0-or-later (see [LICENSE](LICENSE)).

Status: repository skeleton (modules, shells, router, gate) with the schema v1
tables and database helpers; no library UI yet.
Playback, library scanning and lyrics are not built yet; see
[docs/project-roadmap.md](docs/project-roadmap.md).

## Development setup

The toolchain (Flutter 3.47.4, Dart 3.13.3, Rust stable with the Android
targets, GTK and libmpv for Linux) comes from `flake.nix`:

```bash
nix develop            # or: direnv allow
flutter pub get        # resolves the pub workspace (app, packages/kanaru_ui, rust_builder)
```

Run every command below inside that shell, or prefix it with `nix develop -c`.
Android builds need `ANDROID_HOME` (the flake defaults it to `~/Android/Sdk`).

## Commands

```bash
flutter run -d linux                     # or: -d <adb serial>
flutter analyze                          # Dart lints only
dart analyze                             # lints plus the architecture analyzer plugin
dart run tool/check_architecture.dart    # architecture gate (rejects `// ignore:`)
flutter test                             # app tests
(cd packages/kanaru_ui && flutter test)  # design system tests
(cd tool/architecture_lint && dart test) # gate tests
flutter pub run build_runner build --delete-conflicting-outputs   # drift codegen
RUSTC_BOOTSTRAP=1 flutter_rust_bridge_codegen generate             # after editing rust/crates/kanaru_bridge/src/api
cargo test --manifest-path rust/Cargo.toml
cargo clippy --manifest-path rust/Cargo.toml --all-targets
```

On NixOS, `dart run` fails for Flutter packages in this shell: use
`flutter pub run ...` (the gate script `tool/check_architecture.dart` is run
with plain `dart run`, which works because it spawns a pure Dart package).

## The gate

```bash
tool/check          # Dart checks
tool/check --rust   # plus cargo test and clippy
```

It runs `flutter analyze`, `dart analyze`, `dart run tool/check_architecture.dart`,
`flutter test` in the app, in `packages/kanaru_ui` and the gate's own tests in
`tool/architecture_lint`. Run it before opening a PR; CI runs the same checks.

Why `dart analyze` and not only `flutter analyze`: the architecture rules
(module DAG, layer rules, layout API rules) are an analyzer plugin configured
in `analysis_options.yaml`. `flutter analyze` does not load analyzer plugins,
so it passes code that `dart analyze` rejects. The CLI
`tool/check_architecture.dart` checks the same rules without the analyzer and
also rejects `// ignore:` comments for them, so the gate cannot be silenced.

## Running isolated

Data lives in `<XDG data home>/kanaru/` (database `kanaru.db`),
config and cache likewise under `kanaru`. To keep a dev run away from
real data, set all three XDG variables:

```bash
R=/tmp/kanaru-dev
XDG_CONFIG_HOME=$R/config XDG_DATA_HOME=$R/data XDG_CACHE_HOME=$R/cache \
  flutter run -d linux
```

## Repository layout

| Path | What |
|---|---|
| `lib/src/<module>/` | App modules by domain (see ARCHITECTURE.md) |
| `lib/kanaru.dart`, `lib/kanaru_bootstrap.dart`, `lib/main.dart` | Public API, startup, entry point |
| `lib/l10n/` | ARB files (en, vi); generated code in `lib/l10n/gen/` |
| `packages/kanaru_ui/` | Design system (tokens, theme, widgets), knows nothing about music |
| `packages/kanaru_extensions/` | Extension list of this build; empty in the public repo |
| `rust/` | Cargo workspace: `kanaru_media`, `kanaru_plugin_runtime`, `kanaru_bridge` |
| `rust_builder/` | cargokit glue that builds `kanaru_bridge` |
| `tool/` | `check` (gate), `check_architecture.dart`, `architecture_lint/` (analyzer plugin and CLI) |
| `architecture.yaml` | Module DAG used by the gate |
| `android/`, `linux/` | Platform runners |

Contributing: see [CONTRIBUTING.md](CONTRIBUTING.md).
