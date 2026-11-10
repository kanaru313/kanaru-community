# Project overview

Kanaru is a Material 3 music player built with Flutter for Android (primary)
and Linux desktop. The offline local player comes first; streaming and remote
sources follow, then plugins for lyrics and sources.

## Goals

- Mobile first, with a separate desktop shell from day one: every module works
  on both.
- Local files before anything else: scan, index, play, show lyrics, with no
  network.
- Open source core (GPL-3.0-or-later). The core remains complete and usable on
  its own, while supporting additional capabilities through the extension
  mechanism ([ARCHITECTURE.md](../ARCHITECTURE.md)).
- Strict module boundaries enforced by a gate, so the codebase stays easy to
  extend.

## Platforms

| Platform | Shell | Notes |
|---|---|---|
| Android | Bottom bar, pushed pages | Local files via MediaStore (planned) |
| Linux | Sidebar, top bar, back and forward | Native libs from `flake.nix` (GTK, libmpv) |

## Stack

Flutter 3.47.4 / Dart 3.13.3, Material 3 via `material_ui`, Riverpod, go_router,
drift (SQLite), Rust (tags, covers, plugin runtime) through flutter_rust_bridge
and cargokit, `media_kit` for playback (planned use).

## Current state

Wave-1 foundation: pub workspace, design system (`packages/kanaru_ui`),
architecture gate, module DAG, two shells, extension registry, the settings
store and device id, the schema v1 tables and helpers, and the shared contracts
the playback and library lanes code against. Playback, the scanner and the
library UI are seeds until those lanes land. See
[project-roadmap.md](project-roadmap.md).
