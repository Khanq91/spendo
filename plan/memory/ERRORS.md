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

## [Phase 4] - 2026-07-13 12:26
- Baseline analyzer wrapper lại treo không output trong sandbox và phải dừng; chạy ngoài sandbox hoàn tất với 139 diagnostics = 0 error, 20 warning, 119 info. Không coi timeout là kết quả analyzer.
- Lần đầu chạy PowerSync DB regression test fail trước assertion vì `powersync_x64.dll` không nằm trên loader path; sau khi dùng custom `PowerSyncOpenFactory`, loader tiếp tục thiếu `sqlite3.dll`.
- Workaround test ổn định: resolve `powersync_flutter_libs` từ `.dart_tool/package_config.json`, nạp DLL PowerSync bằng absolute path và override SQLite Windows sang `winsqlite3.dll` của hệ điều hành ngay trong DB isolate. Không copy binary vào repo.
- Final wrapper exit 1 do analyzer debt còn lại nhưng giảm đúng một warning cũ trong file đã chạm: 138 diagnostics = 0 error, 19 warning, 119 info; scoped analyzer cho 4 file STATE-001 báo `No issues found`.
- Final format check exit 1: 63/123 file sẽ đổi format; `--output=none` không ghi file và `git diff --check` pass. Không format hàng loạt ngoài scope.
- Full test pass 12/12. Chưa có Android/iOS device run, query-plan benchmark hoặc runtime metric cho 1/20/100 Ví.

## [Phase 4] - 2026-07-15 16:55
- Baseline sandbox `dart format --output=none --set-exit-if-changed .` treo sau 60 giây; chạy ngoài sandbox hoàn tất. Final check vẫn fail baseline với 63/124 file cần format, không ghi file vì dùng `--output=none`.
- `scripts/analyze_codex.bat` hoàn tất ngoài sandbox nhưng exit 1 do 138 diagnostic tồn tại (0 error, 19 warning, 119 info); scoped analyzer cho 4 file UI-001 báo `No issues found`.
- Full `flutter test --no-pub` chạy ngoài sandbox pass 14/14. Không có Android/iOS device hoặc emulator nên không xác nhận được visual layout, retry với DB thật hay navigation trên thiết bị.
- WalletCardHome vẫn nằm trong danh sách formatter baseline; đã tránh broad format và chỉ giữ thay đổi UI-001 cần thiết trong file đó.

## [Phase 4] - 2026-07-15 22:39
- Helper `apply_patch` trong Windows sandbox tiếp tục fail với `helper_unknown_error`; workaround là gọi trực tiếp Codex apply-patch helper ngoài sandbox cho từng patch scoped. Không dùng shell write hoặc broad rewrite.
- Focused test lần đầu fail vì AnimatedSwitcher còn giữ outgoing empty state trong transition và nút retry Home nằm dưới viewport 800×600. Test được sửa để chờ transition kết thúc và dùng viewport 800×1000; production layout không bị thay đổi để chiều test.
- Final format check exit 1 với 60/126 file lệch format baseline; `--output=none` không ghi các file đó. Chỉ bốn file Dart trong scope được format trực tiếp.
- Analyzer wrapper baseline và final đều exit 1 do cùng 138 diagnostic tồn tại, nhưng đều có 0 error và cùng breakdown 19 warning / 119 info; scoped analyzer cho bốn file đã chạm báo `No issues found`.
- `pubspec.lock` đã dirty trước session và được bảo toàn, không chỉnh hoặc hoàn nguyên. `audit/flutter_analyze.txt` thay đổi do hai lần chạy wrapper theo yêu cầu.

## [Phase 5] - 2026-07-15 23:03
- Windows sandbox và helper `apply_patch` tích hợp tiếp tục fail với `helper_unknown_error`; patch scoped được áp dụng bằng Codex apply-patch executable ngoài sandbox, không ghi file trực tiếp.
- Focused test lần đầu fail vì assertion điều hướng chạy trước chuỗi delay + exit/navigation transition; đổi test sang `pumpAndSettle` sau retry, không thay timing production.
- Scoped analyzer báo 9 `withOpacity` deprecation có sẵn trong `splash_screen.dart`; không dọn chúng trong STAB-008. Full wrapper baseline/final đều giữ 138 diagnostics = 0/19/119.
- Final format check exit 1 với 59/127 file lệch format baseline; `--output=none` không ghi các file đó. Hai file Dart trong scope đã được format trực tiếp.
- Full widget test chỉ dùng callback giả throw/succeed; chưa xác nhận UI retry với lỗi Supabase/PowerSync/plugin thật hoặc layout trên thiết bị.

## [Phase 2] - 2026-07-15 23:15
- Helper `apply_patch` trong Windows sandbox tiếp tục fail với `helper_unknown_error`; patch scoped được áp dụng bằng Codex apply-patch executable ngoài sandbox, không dùng shell ghi file trực tiếp.
- Final format check exit 1 với 60/127 file lệch format baseline; `--output=none` không ghi các file đó. Chỉ hai file Dart trong scope được format trực tiếp.
- Analyzer wrapper baseline/final đều exit 1 do cùng 138 diagnostic tồn tại (0 error / 19 warning / 119 info). Scoped analyzer chỉ báo deprecated `Workmanager.isInDebugMode` có sẵn, ngoài STAB-006.
- Full test baseline/final đều pass 17/17. Không có Android/iOS device hoặc emulator runtime check; chưa xác nhận startup thực tế và ảnh hưởng dung lượng DB sau khi dừng retention.
- Preference `shown_retention_policy_notice` có thể còn trong SharedPreferences của người dùng cũ nhưng không còn reader/writer; đây là dữ liệu inert, không cần migration xóa trong issue bảo toàn dữ liệu này.

## [Phase 2] - 2026-07-15 23:28
- Helper apply_patch tích hợp tiếp tục fail với windows sandbox: helper_unknown_error; hai lần gọi wrapper .bat ngoài sandbox cũng fail do truyền patch UTF-8/newline. Patch scoped cuối cùng được áp dụng bằng Codex apply-patch executable ngoài sandbox, không ghi file trực tiếp.
- Lần chạy focused test và scoped analyzer song song làm mất output test khi analyzer exit 1 vì info baseline; focused test được chạy lại độc lập và pass 4/4.
- Analyzer wrapper baseline/final đều exit 1 với cùng 138 diagnostic tồn tại (0 error / 19 warning / 119 info). Scoped analyzer chỉ còn deprecated Workmanager.isInDebugMode đã có sẵn trong main.dart.
- Final format check exit 1 với 60/129 file lệch format baseline; --output=none không ghi file. Bốn file Dart trong scope đã được format trực tiếp.
- Full test tăng từ baseline 17/17 lên final 21/21 pass. Chưa có Android/iOS runtime check cho WorkManager, Google silent sign-in, upload Drive hoặc concurrent PowerSync DB access; không tuyên bố backup nền đã được xác nhận end-to-end.

## [Phase 2] - 2026-07-16 08:13
- Analyzer wrapper, formatter và Flutter test tiếp tục treo không output trong sandbox; các lệnh tương ứng chạy ngoài sandbox hoàn tất với Flutter 3.44.5/Dart 3.12.2.
- Final analyzer wrapper exit 1 do debt còn lại nhưng không có error; tổng giảm từ baseline 138 (0/19/119) xuống 136 (0/17/119) vì `loansAdded`/`loansSkipped` không còn unused.
- Repo-wide format check exit 1 với 62/130 file lệch format baseline; `--output=none` không ghi file. Formatter scoped ban đầu làm lộ formatting-only diff trong hai repository và backup service; các hunk ngoài STAB-003 đã được loại trước handoff nên ba file này vẫn được formatter liệt kê.
- Test PowerSync dùng `initializeDatabaseForTesting` một lần trong isolate và native loader đã có workaround `powersync_x64.dll` + `winsqlite3.dll`; không copy binary vào repo.
- Full test pass 23/23 và focused backup test pass 2/2. Chưa xác nhận share/file picker/Drive restore end-to-end trên thiết bị; STAB-004 partial write khi payload lỗi vẫn còn nguyên và không được coi là đã sửa.

## [Phase 2] - 2026-07-16 08:39
- Baseline analyzer wrapper và full test trong sandbox đều timeout sau 120 giây không output; chạy ngoài sandbox với Flutter 3.44.5/Dart 3.12.2 hoàn tất. Không coi timeout sandbox là code failure.
- Formatter scoped Dart 3.12 ban đầu tạo nhiều formatting-only hunk trong `backup_service.dart`; các hunk ngoài STAB-004 đã được loại và implementation transaction được thu gọn để giữ thân restore cũ. Tránh format toàn file này trong issue hẹp khi repo còn baseline format debt.
- Final analyzer wrapper exit 1 do cùng 136 diagnostic baseline (0 error / 17 warning / 119 info); scoped analyzer cho production + test STAB-004 báo `No issues found`.
- Final format check exit 1 với 62/130 file lệch format; `--output=none` không ghi file. Focused test pass 4/4 và full suite pass 25/25.
- Test atomicity dùng SQLite trigger chỉ trong temp PowerSync DB để ép lỗi sau một insert và xác nhận rollback; trigger được drop trong `finally`, không chạm production schema.
- Chưa xác nhận restore local/Google Drive end-to-end trên Android/iOS, file rất lớn, hoặc file bị thay đổi đồng thời trong lúc restore; manifest/checksum vẫn ngoài scope.

## [Phase 2] - 2026-07-17 08:20
- Analyzer wrapper lần đầu treo trong sandbox và để `audit/flutter_analyze.txt` chỉ còn header; chạy lại ngoài sandbox hoàn tất, khôi phục artifact với baseline `136 = 0/17/119`.
- Focused test lần đầu fail compile vì `SqliteWriteContext` không phải type được PowerSync export; bỏ type nội bộ và dùng callback read/execute rõ ràng, sau đó focused tests pass.
- Scoped analyzer bắt `invalid_use_of_visible_for_testing_member` khi restore gọi helper repair; bỏ annotation test-only và đưa repair vào chính transaction restore, tránh commit restore rồi mới fail repair.
- Final scoped analyzer chỉ còn 2 info `withOpacity` có sẵn trong `category_form_sheet.dart`; final wrapper còn 135 diagnostics baseline và 0 error. Không dọn deprecated API ngoài STAB-005.
- Repo-wide `dart format --output=none --set-exit-if-changed .` bị policy runner từ chối vì đánh giá nguy cơ broad formatting dù `output=none`; không lách policy. Scoped format/check và `git diff --check` pass cho phần mới, nhưng repo-wide format chưa được xác nhận lại session này.
- Chưa có device/runtime smoke test. Nếu nhiều category duplicate đều có budget, repair bảo toàn row bằng cách cùng remap sang canonical nên có thể còn nhiều budget cho một category; không được tự xóa/merge amount khi chưa có policy sản phẩm.

## [Phase 6] - 2026-07-17 08:44
- Baseline analyzer wrapper và `flutter test --no-pub` trong sandbox đều treo không output và đã được dừng sau khoảng một phút; lần chạy analyzer còn để log tạm chưa hoàn chỉnh. Chạy lại ngoài sandbox đã tạo lại `audit/flutter_analyze.txt` đầy đủ và hoàn tất mọi verification.
- Final analyzer wrapper exit 1 do đúng baseline debt `135 diagnostics = 0 error / 16 warning / 119 info`; scoped analyzer cho production/test UI-003 báo `No issues found`.
- Repo-wide format check exit 1 với 62/131 file lệch format; `--output=none` không ghi file. Hai file Dart trong scope đã được format trực tiếp và `git diff --check` pass.
- Automated test xác nhận timer không đổi page khi Reduce Motion bật nhưng chưa chứng minh behavior trên setting hệ điều hành thật, carousel khi Home offstage hoặc chi phí CPU/battery; không tuyên bố đã tối ưu performance runtime.

## [Phase 6] - 2026-07-17 09:10
- Baseline analyzer wrapper và `flutter test --no-pub` treo không output trong sandbox; analyzer bị dừng đã để `audit/flutter_analyze.txt` chỉ có header. Chạy wrapper ngoài sandbox sau patch đã phục hồi log đầy đủ với baseline `135 = 0/16/119`.
- Scoped analyzer lần đầu phát hiện `TickerMode.of` deprecated trên Flutter 3.44.5; đổi sang `TickerMode.valuesOf(context).enabled`, rerun báo `No issues found`.
- Full test ngoài sandbox pass 30/30; focused WalletCardHome pass 3/3. Không có Android/iOS device measurement nên chưa xác nhận wake-up count, CPU, pin hoặc tab restoration thực tế.
- Repo-wide format check exit 1 và liệt kê 65/131 file baseline sẽ đổi; `--output=none` không ghi file. Test trong scope đã format riêng; production files vẫn giữ style hiện tại để tránh formatting-only diff. Policy runner từ chối lần rerun repo-wide, không lách bằng workaround.

## [Phase 6] - 2026-07-17 10:20
- Baseline analyzer wrapper và `flutter test --no-pub` tiếp tục treo không output trong sandbox; wrapper timeout còn có thể để log dở. Chạy lại ngoài sandbox đã khôi phục `audit/flutter_analyze.txt` hoàn chỉnh và lấy baseline đáng tin cậy.
- Regression test ban đầu fail đúng vì `AnimatedCrossFade` vẫn giữ text `Ăn uống` trong tree sau 50 ms collapse; sau khi đổi transition, focused test pass 1/1 và full suite pass 31/31.
- Scoped analyzer còn 9 warning/info có sẵn trong `settings_screen.dart` (`withOpacity`, `activeColor`, `_import` unused); final wrapper giữ nguyên repo baseline `135 = 0/16/119`, không dọn debt ngoài UI-002.
- Repo-wide format check exit 1 với 65/132 file baseline sẽ đổi; `--output=none` không ghi file. Chưa có device/golden test cho Fancy/dark, 12+ category, text scale 2 và frame giữa transition.

## [Phase 7] - 2026-07-17 10:40
- Baseline `flutter test --no-pub` trong sandbox treo 180 giây không output; Dart formatter scoped cũng treo 30 giây. Chạy ngoài sandbox hoàn tất: baseline test `31/31`, final test `33/33`.
- Analyzer trung gian sau cleanup còn một warning `_month` unused do helper `_isSelected` dead đã bị xóa; bỏ field/assignment không được đọc rồi rerun đạt `No issues found`.
- `git diff --check` lần đầu bắt trailing whitespace do call `withValues` nhiều dòng trong `quick_actions_bar.dart`; chỉnh lại argument layout rồi check pass.
- Final `dart format --output=none --set-exit-if-changed .` exit 1 và liệt kê 79/133 file sẽ đổi; đây là format debt có sẵn/mở rộng theo các file analyzer vừa chạm, lệnh không ghi file. Không dùng formatter broad trong session này.
- Wrapper chính thức chạy ngoài sandbox bằng Flutter 3.44.5/Dart 3.12.2 và ghi `audit/flutter_analyze.txt` sạch `0/0/0`. `flutter devices` chỉ có Windows/Chrome/Edge; không có Android/iOS để smoke test.

## [Phase 6] - 2026-07-17 16:51
- Baseline analyzer wrapper trong sandbox không có output trong khoảng một phút; lần chạy ngoài sandbox hoàn tất với Flutter 3.44.5/Dart 3.12.2 và `0/0/0`. Không coi thời gian chờ sandbox là code failure.
- Regression test Fancy lần đầu dùng `pumpAndSettle` và timeout vì Aurora có animation liên tục; đổi sang các `pump` duration hữu hạn, không thay production animation.
- Test đỏ trên code cũ: final Settings content bottom `505.1939` > glass bar top `504.0`; sau fix focused test pass `2/2` và full suite pass `34/34`.
- Repo-wide `dart format --output=none --set-exit-if-changed .` exit 1 với `79/133` file baseline sẽ đổi; lệnh không ghi file. Không format broad trong UI-010.
- Chưa có Android/iOS device hoặc emulator để xác nhận gesture navigation inset, 3-button inset và visual spacing thật; widget geometry test chỉ chứng minh contract layout trong Flutter test surface.

## [Phase 6] - 2026-07-18 13:30
- Helper `apply_patch` tích hợp tiếp tục fail với `windows sandbox: helper_unknown_error`; patch scoped được áp bằng executable Codex apply-patch ngoài sandbox, không dùng shell write hoặc broad rewrite.
- Regression test đỏ đúng trên code cũ: transaction target cao `32.0` thay vì tối thiểu 48 và Settings không tìm thấy `InkWell`; đây là bằng chứng tái hiện, không phải lỗi toolchain.
- Lần chạy scoped format check song song với focused test trả exit 1 từ formatter nên output test không được tổng hợp; focused test được chạy lại độc lập và pass `4/4`.
- Repo-wide format check exit 1 với `68/133` file sẽ đổi; `--output=none` không ghi file. Final analyzer wrapper sạch `0/0/0`, full test pass `35/35` và `git diff --check` pass sau khi append đủ ba log.
- `flutter devices` chỉ có Windows và Edge; chưa xác nhận target, focus traversal hoặc spacing bằng Accessibility Scanner/TalkBack/VoiceOver trên Android/iOS thật.

## [Phase 6] - 2026-07-18 13:43
- Helper `apply_patch` tích hợp tiếp tục fail với `windows sandbox: helper_unknown_error`; patch scoped được áp bằng executable Codex apply-patch ngoài sandbox, không dùng shell ghi file hoặc broad rewrite.
- Regression test đỏ đúng trên code cũ vì không tìm thấy `Chọn ngày`. Sau production fix, assertion nhãn hủy ban đầu dùng `HỦY` rồi `Hủy` không khớp SDK; Flutter 3.44 source dùng chính xác `Huỷ`, cập nhật expectation và focused test pass.
- Repo-wide `dart format --output=none --set-exit-if-changed .` exit 1 với `68/134` file baseline sẽ đổi; lệnh không ghi file. `loan_form_sheet.dart` vẫn nằm trong format debt có sẵn nên không format toàn file trong UI-008.
- Baseline/final analyzer wrapper đều sạch `0/0/0`; full test tăng từ `35/35` lên `36/36`. `flutter devices` chỉ có Windows và Edge, chưa xác nhận date picker trên Android/iOS thật.

## [Phase 6] - 2026-07-18 14:45
- Helper `apply_patch` tích hợp fail lặp lại với `windows sandbox: helper_unknown_error`; sau khi user cấp quyền rõ ràng, patch scoped được áp bằng Codex apply-patch executable ngoài sandbox, không dùng shell ghi file hoặc broad rewrite.
- Regression test đỏ đúng trên code cũ với `RenderFlex overflowed by 235 pixels on the bottom` tại `add_transaction_sheet.dart:367`; test đồng thời xác nhận custom numpad vẫn tồn tại khi keyboard inset là 300 px.
- Repo-wide `dart format --output=none --set-exit-if-changed .` exit 1 với `69/135` file baseline sẽ đổi; lệnh không ghi file. Test mới format sạch, production sheet vẫn nằm trong format debt có sẵn nên không format toàn file.
- Baseline/final analyzer wrapper đều sạch `0/0/0`; full test tăng từ `36/36` lên `37/37`. `flutter devices` chỉ có Windows và Edge, chưa xác nhận keyboard animation, IME thực hoặc split-screen trên Android/iOS.
