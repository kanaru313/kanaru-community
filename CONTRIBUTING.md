# Contributing

Thanks for helping. Read [README.md](README.md) for setup and
[ARCHITECTURE.md](ARCHITECTURE.md) for where code goes.

## Before a pull request

Run the gate inside the nix shell and fix everything it reports:

```bash
tool/check --rust
```

It runs `flutter analyze`, `dart analyze` (with the architecture plugin),
`dart run tool/check_architecture.dart`, all Dart test suites, `cargo test` and
`cargo clippy`. CI runs the same checks plus `clippy -D warnings`.

- Add tests for new logic (main path and failures).
- Architecture violations are errors and cannot be silenced with `// ignore:`.
  If a rule is wrong for your case, open an issue instead.
- Do not edit generated code (`*.g.dart`, `*.drift.dart`, `lib/src/rust/`,
  `lib/l10n/gen/`, `frb_generated.rs`); change the source and regenerate.
- Keep pull requests focused: one change, with its docs.

## Commits

Conventional commits: `type(scope): summary`, with types such as `feat`, `fix`,
`refactor`, `test`, `docs`, `ci`. Keep each commit focused.

## Contributor License Agreement

Contributions from outside the project need a signed Contributor License
Agreement before they can be merged. The project is GPL-3.0-or-later; a
maintainer will provide the agreement on your first pull request.

## Plugins

Plugins live in a separate repository, not here.
