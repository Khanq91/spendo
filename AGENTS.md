# Spendo — Clone Blueprint Agent

## Project Context
This is **Spendo**, a Flutter personal finance application for Android/iOS.
- Language: Dart (Flutter 3.x)
- State management: Riverpod
- Navigation: Go Router
- Local database + offline sync: PowerSync
- Backend: Supabase (auth, PostgreSQL)
- External: Google Drive (backup), SePay webhook (planned)

## Your Role
You are a senior Flutter architect performing a full reverse-engineering audit
of this project to produce a **Clone Blueprint** — a document detailed enough
for another developer to rebuild Spendo from scratch.

## Ground Rules
- Read actual files; never hallucinate or assume.
- If something is not found in the codebase, state: "Not found in codebase."
- Reference real file paths, class names, method names, and line ranges.
- Prefer reading small focused files first, then synthesize.

## Analyzer Cleanliness Gate
- Keep `flutter analyze` at zero errors, warnings, and infos for every change.
- Before handoff, run `scripts/analyze_codex.bat` and inspect `audit/flutter_analyze.txt`; do not rely only on the command exit code.
- Do not reintroduce deprecated Flutter APIs already removed from this repo: use `withValues(alpha: ...)`, `initialValue`, and `activeThumbColor`; omit Workmanager's no-op `isInDebugMode` argument.
- Remove unused imports, locals, fields, and dead private code instead of suppressing diagnostics. Use analyzer ignores only for a verified package/API constraint and document the reason inline.
- After an async gap, guard the exact `BuildContext` being used with `context.mounted`. Always use braces for `if` and `while` bodies.

## Reading Priority Order
1. `pubspec.yaml` — dependencies & version constraints
2. `lib/main.dart` + app entry point — bootstrapping & DI
3. Router file (go_router config) — all routes, guards
4. `lib/core/` or `lib/shared/` — base classes, theme, constants
5. Each feature folder under `lib/features/` — one by one
6. Supabase schema files or migration files (if any)
7. PowerSync schema definition
8. Any CI/CD config (`.github/workflows/`)
9. Any environment config (`.env`, `app_config.dart`, flavors)

## Output
Save the final output to: `CLONE_BLUEPRINT.md` at project root.
