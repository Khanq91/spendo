## [Phase 0] - 2026-07-09 14:38
- Root `PROGRESS.md` was not found, so progress tracking is being created in `plan/memory/` as requested.
- `rg` found possible UI/copy encoding risk at `lib/features/wallets/presentation/screens/wallets_screen.dart:278` (`⚠️ Âm`) plus UTF-8 Vietnamese comments/strings; do not mix copy cleanup into the motion phase unless requested.
- `dart format lib\shared\widgets\motion plan\memory` timed out after 120s in this environment.
- `scripts\analyze_codex.bat` timed out after 240s; `audit/flutter_analyze.txt` only reached the `Flutter SDK:` header, so analyzer findings were not available.
- `Get-CimInstance Win32_Process` was denied by Windows permissions, so the stuck Flutter/Dart process command line could not be inspected from this session.
- User-run `scripts\analyze_codex.bat` completed with 0 errors but exit code 1 because the repo has existing warning/info diagnostics; the only new motion-folder diagnostic was an unnecessary `dart:ui` import in `animated_money_text.dart`.

## [Phase 0] - 2026-07-09 15:13
- Sandboxed `scripts\analyze_codex.bat` can timeout before `flutter --version`, while the same command outside the sandbox completed and regenerated `audit/flutter_analyze.txt`.
- The outside-sandbox analyzer used Flutter 3.38.9 from PATH, while the user-run log showed Flutter 3.44.5; keep this PATH difference in mind when comparing analyzer counts.

## [Phase 1] - 2026-07-09 15:47
- `dart format` timed out after 120s both with PATH default and with `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter\bin\dart.bat`; it may still partially format files before timing out.
- A sandboxed scoped `flutter analyze` run was interrupted by the user after running too long; user reran with Flutter 3.44.5 and reported 7 `withOpacity` infos, then those touched-file occurrences were replaced with `withValues(alpha: ...)`.
- Do not rely on default PATH Flutter for this repo; use `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter\bin` when comparing analyzer results.
- Escalated scoped analyzer with Flutter 3.44.5 completed successfully after the cleanup: no issues found.
