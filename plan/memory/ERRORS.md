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

## [Phase 1] - 2026-07-09 16:17
- User observed the Home loading skeleton covered Summary/Wallet cards; avoid wrapping the entire Home body in loading skeleton for transaction stream states.

## [Phase 1] - 2026-07-10 08:40
- Sandboxed `dart format` and scoped `flutter analyze` again hung without output; running the Flutter 3.44.5 commands outside the sandbox completed normally.
- The first scoped analyzer found 1 stale unused import and 5 deprecated `withOpacity` calls in the touched Wallets file; cleanup was limited to that file, and the rerun reported no issues.
- The scoped widget test passed with exit code 0, but Flutter still printed `unable to find directory entry in pubspec.yaml: assets/images/`; keep this existing asset configuration warning separate from Phase 1 motion behavior.
- `audit/flutter_analyze.txt` was regenerated during this session and now reflects a full-project run with 0 errors and 156 existing warnings/infos; it remains a generated/concurrent worktree change and was not edited manually.

## [Phase 1] - 2026-07-10 10:52
- Sandboxed pinned-Flutter widget testing timed out at 60 seconds with no output; the identical test outside the sandbox completed successfully in 11.5 seconds.
- The successful test still emits the existing `assets/images/` directory warning from `pubspec.yaml`; it does not fail the test and is outside this UI-motion phase.

## [Phase 1] - 2026-07-10 11:11
- Category-switch text overlap was caused by the `ListView` key containing `selectedCat`, which made `AnimatedSwitcher` paint old and new transaction lists simultaneously during its transition.

## [Phase 1] - 2026-07-10 11:25
- `flutter devices` did not return within the sandbox timeout, so live-device acceptance could not be performed in this session.
- Pinned Flutter 3.44.5 widget test completed successfully outside the sandbox, but printed `unable to find directory entry in pubspec.yaml: assets/images/`; retain as an existing configuration warning, not a test failure.

## [Phase 1] - 2026-07-10 11:40
- User confirmed the Phase 1 test/acceptance is stable; Phase 1 closed without additional code changes.

## [Phase 2] - 2026-07-10 11:40
- Initial scoped analyzer found a real error after replacing a `Text`: `AnimatedMoneyText` did not expose the existing `overflow` parameter. Added the parameter and forwarded it to both static and animated `Text` branches.
- Rerun has 0 errors and 28 existing warnings/infos, mostly `withOpacity`, unused imports/locals, and unrelated async-gap diagnostics in the touched feature files.

## [Phase 2] - 2026-07-10 11:52
- Scoped analyzer after Wallets/Transactions wiring still reports 28 existing warnings/infos and no errors.
- Motion widget regression test passes; no new test failure observed.

## [Phase 2] - 2026-07-10 12:05
- Pinned Flutter 3.44.5 scoped analyzer for `wallet_detail_screen.dart` timed out in the sandbox without analyzer output; this matches the repo's previously recorded Flutter sandbox timeout behavior.
- `git diff --check` passed after the Wallet Detail changes. No compile/test result for this newly touched screen was available in-sandbox; rerun the pinned analyzer outside the sandbox if needed.

## [Phase 3] - 2026-07-10 12:32
- Sandboxed Flutter commands remain unreliable, but pinned Flutter 3.44.5 outside the sandbox completed formatting and scoped analysis. Analyzer reported 19 existing warnings/infos and no errors in `add_transaction_sheet.dart`.
- The regression test emitted the existing dependency/package resolution output and completed with `All tests passed!` (1 test).

## [Phase 3] - 2026-07-10 12:45
- Scoped analyzer after switching amount motion to `AnimatedMoneyText` still reports only the same 19 existing warnings/infos and no errors.
