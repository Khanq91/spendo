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

## [Phase 4] - 2026-07-10 16:54
- Pinned Dart formatting again hung in the sandbox with no output and was terminated; the identical Flutter 3.44.5 formatter completed successfully outside the sandbox.
- Scoped Flutter 3.44.5 analysis completed with no issues, and both focused widget tests passed; no Phase 4 code error remains known.
- Automated widget coverage proves lazy construction for 500 transactions but does not measure real-device frame timing, scroll-position feel, FAB/nav overlap, or detail-sheet interaction; those remain manual acceptance checks.

## [Phase 5] - 2026-07-10 17:05
- Sandboxed pinned Dart formatting timed out again after 30 seconds; the same formatter completed outside the sandbox in under one second.
- The first scoped analyzer run found one new unused local in `stats_screen.dart`; it was removed and the rerun reported `No issues found` for both touched Stats files.
- `pubspec.yaml` changed concurrently from `1.7.3+10` to `1.7.4+10`; this was not part of Phase 5 and was preserved without modification.
- The focused Stats widget test proves summary/pie/bar rendering and tab switching, but cannot prove real chart interpolation, tooltip interaction, light/dark/fancy contrast, or reduce-motion behavior; these remain manual device checks.

## [Phase 6] - 2026-07-10 18:23
- The integrated apply_patch helper repeatedly failed during Windows sandbox setup with helper_unknown_error. The same Codex patch helper was run outside the broken sandbox to apply scoped patches.
- The first scoped flutter analyze attempt timed out before output; rerunning with --no-pub completed normally.
- The user-supplied analyzer log reported 40 diagnostics and no errors. One new deprecated axisAlignment use and two safe unused imports were fixed; the rerun reports 37 pre-existing warnings/infos and 0 errors.
- Remaining diagnostics are mainly withOpacity deprecations plus existing async-context, activeColor/value deprecations, and the disabled Settings _import helper. Avoid mixing that cleanup into Phase 6 behavior work.
- Widget tests do not validate animation feel, sheet insets, list transition jank, or visual contrast on a real device; Phase 6 still needs the manual smoke checks listed in PROGRESS.md.

## [Phase 6] - 2026-07-10 18:32
- No implementation error in this documentation-only update. pubspec.yaml is currently 1.7.5+10 and was intentionally not bumped; future code-delivery sessions must perform and record the version bump before handoff.

## [Phase 7] - 2026-07-10 19:12
- The sandboxed apply_patch helper failed again with windows sandbox: helper_unknown_error; the same Codex apply-patch executable was run outside the broken sandbox for scoped edits, matching the recorded Phase 6 workaround.
- The previously recorded Flutter 3.44.5 path at D:\khang\data\flutterDev\flutter_windows_3.44.5-stable no longer exists. Formatting, analysis, and tests used the repo-configured Flutter 3.44.0 SDK at D:\program\data\flutterDev\flutter.
- The first regression batch used two stale test paths and exited failed before loading those files. The paths were corrected to test/features/transactions/presentation/widgets/grouped_transaction_sliver_test.dart and test/features/stats/presentation/screens/stats_screen_test.dart; the rerun passed all 7 tests.
- GlassAdaptiveScopeConfig is annotated experimental by liquid_glass_widgets 0.21.3; its deliberate use is isolated with an inline analyzer ignore and must be rechecked when the package is upgraded.
- Full flutter analyze --no-pub still exits 1 from 139 existing diagnostics but reports 0 errors (20 warnings, 119 infos). Scoped Phase 7 analysis has no new diagnostics; the only reported item is the existing deprecated Workmanager isInDebugMode use in main.dart.
- Automated tests do not prove adaptive GPU tier selection, persisted cold-start behavior, real-device scroll jank, or Reduce Transparency rendering; these remain mandatory manual Phase 7 acceptance checks.

## [Phase 7] - 2026-07-10 19:19
- No new implementation error was reported during manual acceptance; the user confirmed Phase 7 testing is complete.
- Existing analyzer diagnostics and the experimental `GlassAdaptiveScopeConfig` upgrade caveat remain recorded in the previous Phase 7 entry; no workaround or code change was needed for this closeout.

## [Phase 1] - 2026-07-13 09:55
- Baseline `scripts\\analyze_codex.bat` timeout sau 300 giây; `audit/flutter_analyze.txt` chỉ đến dòng `Flutter SDK:` nên là log chưa hoàn tất.
- Baseline `flutter test --no-pub` không có output và bị dừng khi tái hiện Flutter-shell hang đã biết.
- Scoped formatter và final `dart format --output=none --set-exit-if-changed .` đều timeout sau 60 giây.
- Focused connector test timeout sau 180 giây. Final analyzer wrapper và full test mỗi lệnh timeout sau 120 giây, đều không có output.
- `git diff --check` chỉ báo trailing whitespace có sẵn trong file user-owned `plan/01-Prompt-audit.md:64`; không sửa ngoài scope STAB-001. Không được tuyên bố runtime pass cho đến khi toolchain chạy xong.

## [Phase 7] - 2026-07-13 10:21
- `flutter test`, `dart format` và analyzer wrapper tiếp tục treo không output trong sandbox; chạy ngoài sandbox với Flutter 3.44.5/Dart 3.12.2 hoàn tất bình thường.
- Một lần analyzer wrapper bị dừng đã để `audit/flutter_analyze.txt` ở trạng thái chỉ có header; wrapper sau đó được chạy lại hoàn chỉnh ngoài sandbox, không chỉnh log thủ công.
- Analyzer vẫn exit 1 vì 139 diagnostic baseline. Footer wrapper ghi `Warnings = 0` nhưng body có 20 warning; đây là ARCH-005 ngoài scope và cần sửa counter riêng.
- Format check exit 1: 66/122 file sẽ đổi format. Do dùng `--output=none`, không có broad formatting trong worktree.
- Chưa thể xác nhận thao tác xóa asset trên GitHub Release tại local; cần một lần push lên `main`. Nếu upload thất bại sau bước dọn, release có thể tạm thời không còn APK cho tới lần workflow thành công tiếp theo.

## [Phase 7] - 2026-07-13 11:56
- Baseline `audit/flutter_analyze.txt` hoàn chỉnh có 139 diagnostic nhưng regex cũ trả `0/0/119`; warning bắt đầu bằng `warning -` nên pattern `' warning '` không match.
- Regex neo đầu dòng thử trực tiếp trên log và chạy qua wrapper thật đều trả `0/20/119`; analyzer vẫn exit 1 vì 139 diagnostic baseline.
- Analyzer, full test và format check đều treo không output trong sandbox; chạy ngoài sandbox hoàn tất. Full test pass 9/9, format check vẫn fail baseline 66/122 file và không ghi file do `--output=none`.
