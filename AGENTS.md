# Spendo — agent instructions

The working conventions for this repository live in **`CLAUDE.md`** (quality
gates, workflow with the maintainer, UI rules, the Snipz effect vault, the
cloud flag). Read that file first; this one only restates the hard gate so no
tool misses it.

## Analyzer cleanliness gate

- `flutter analyze --no-pub` must report zero errors, warnings and infos for
  every change; `flutter test --no-pub` must pass.
- Do not reintroduce deprecated Flutter APIs already removed from this repo:
  use `withValues(alpha: ...)`, `initialValue`, `activeThumbColor`; omit
  Workmanager's no-op `isInDebugMode` argument.
- Remove unused imports, locals, fields and dead private code instead of
  suppressing diagnostics. Use analyzer ignores only for a verified
  package/API constraint and document the reason inline.
- After an async gap, guard the exact `BuildContext` being used with
  `context.mounted`. Always use braces for `if` and `while` bodies.
- Do not commit unless the maintainer asks.

The Codex-era audit artefacts (`audit/CLONE_BLUEPRINT.md`,
`audit/TECHNICAL_AUDIT.md`, `audit/context_bundle.md`) are historical
snapshots from July 2026; `scripts/run_full_audit.sh` regenerates them.
