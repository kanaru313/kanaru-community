# Project overview

Kanaru is a Material 3 music player built with Flutter for Android (primary)
and Linux desktop. The offline local player comes first; streaming and remote
sources follow, then plugins for lyrics and sources.

## Goals

- Mobile first, with a separate desktop shell from day one: every module works
  on both.
- Local files before anything else: scan, index, play, show lyrics, with no
  network.
- Open source core (GPL-3.0-or-later). The author may ship a separate
  proprietary build on top of the core through the extension mechanism
  (ARCHITECTURE.md); the public code stays complete and usable on its own.
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

Skeleton: pub workspace, design system (`packages/kanaru_ui`), architecture
gate, module DAG, two shells with Home, Search, Library, Playlists, Online and
Settings placeholder pages, extension registry, empty database
(`extension_schema` only). See [project-roadmap.md](project-roadmap.md).
