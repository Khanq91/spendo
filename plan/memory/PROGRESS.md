# Evidence-based Technical Audit — Progress

## Baseline — complete (2026-07-10)

- Đã đọc `plan/01-Prompt-audit.md`, `plan/02-Evidence-based-Technical-Audit-Plan.md`, `AGENTS.md` và `.skill/flutter-taste/SKILL.md`.
- Đã chụp `git status --short`; bảo toàn các file plan cũ đang được chuyển sang `old-plan/` và toàn bộ `screenshots/live_app/`.
- Phạm vi phiên này chỉ gồm tài liệu/bằng chứng audit; không sửa production code, dependency, schema hoặc hành vi ứng dụng; không tăng version.
- SDK thực tế: Flutter 3.44.0, Dart 3.12.0, DevTools 2.57.0 từ `D:\program\data\flutterDev\flutter\bin`.
- `flutter pub get --dry-run --enforce-lockfile` và `flutter pub get --enforce-lockfile` đều thành công; không dependency nào đổi.
- Format check fail: 62/122 file sẽ bị formatter thay đổi; đã dùng `--output=none` nên không file nào được format.
- `scripts/analyze_codex.bat` tạo lại `audit/flutter_analyze.txt`: 139 diagnostics = 0 error, 20 warning, 119 info. Footer ghi sai warning = 0 do regex của script.
- `flutter test --no-pub` fail vì `test/widget_test.dart` không có `main`; 7 test còn lại pass.
- Chỉ có Windows desktop và Edge; không có Android/iOS device hoặc emulator, nên chưa có cold-start/frame/scroll profile hợp lệ cho mobile.

## Architecture and data flow — complete (2026-07-11)

- Đã map riêng PowerSync/Supabase, localOnly data, SharedPreferences, Google Drive/Workmanager, SePay, notifications và Android widget; không ép tất cả vào một sơ đồ giả.
- Đã xác nhận auth Supabase không có route/caller, wallet_id vượt ranh giới synced/localOnly và SettingsScreen gom nhiều trách nhiệm.

## Performance — complete (2026-07-11)

- Đã audit startup, Riverpod watch scope, SQL reactivity/N+1, habit analysis, IndexedStack/timer và animation policy.
- Không có mobile device/emulator nên cold-start/frame/memory/battery claims chưa được đo và được gắn Likely trong báo cáo.

## UI/UX — complete (2026-07-11)

- Đã xem 5 ảnh chuẩn, 24 ảnh live và ảnh screenshots/live_app/ui_error/a94e39195eeedfb086ff.jpg; đã ánh xạ lỗi Danh mục tới Settings.
- Video MP4 có tồn tại nhưng viewer/browser/decoder không khả dụng trong môi trường hiện tại, nên không dùng video làm bằng chứng kết luận.
- Đã audit loading/error/empty, hierarchy, responsive risk, SafeArea/keyboard, semantics, reduce motion, dark/fancy và Liquid Glass bằng code + ảnh.

## Stability and security — complete (2026-07-11)

- Finding Critical: PowerSync gọi tx.complete() cả khi upload lỗi.
- Đã audit backup/restore/retention, background isolate, category integrity, iOS capabilities, account-local DB boundary và RLS/sync-rule evidence.
- Supabase migrations/RLS, PowerSync server sync rules và SePay webhook: Not found in codebase.

## Report — complete (2026-07-11)

- Báo cáo cuối: audit/TECHNICAL_AUDIT.md với đúng 7 phần, 30 findings, Top 10 theo công thức cố định và kế hoạch refactor có acceptance/test/rollback.
- Không triển khai quick win, không sửa production code, không đổi dependency/schema và không tăng version 1.7.6+11.

## [Phase 1] - 2026-07-13 09:55
- [x] Chỉ chọn STAB-001, finding Critical về tính toàn vẹn hàng đợi PowerSync; các finding backup, auth, wallet và session boundary nằm ngoài scope session này.
- [x] Chỉ gọi `CrudTransaction.complete()` sau khi toàn bộ thao tác Supabase thành công; exception tiếp tục được ném ra và batch được giữ pending để retry.
- [x] Thêm regression test cho thứ tự upload/complete khi thành công và không complete khi upload lỗi.
- [x] Tăng version từ `1.7.6+11` lên `1.7.7+12` cho session có thay đổi code.
- [ ] Chưa xác nhận runtime vì formatter, analyzer wrapper, focused test và full test đều timeout không có output trong môi trường hiện tại.
- Bước tiếp theo: chạy lại test connector và full verification trong Flutter shell ổn định; sau đó bổ sung failure-injection test ở mức PowerSync/Supabase trước khi mở rộng Phase 1.

## [Phase 7] - 2026-07-13 10:21
- [x] Chỉ xử lý ARCH-004: bỏ `test/widget_test.dart` placeholder không có `main` và thêm `flutter test --no-pub` trước bước ký/build APK trong CI.
- [x] Giữ nguyên production Dart, dependency và business behavior; tăng version từ `1.7.7+12` lên `1.7.8+13` theo quy ước session có code/config delivery.
- [x] `flutter test --no-pub`: 9/9 test pass khi chạy ngoài sandbox.
- [x] `scripts/analyze_codex.bat`: 139 diagnostics, 0 error, 20 warning, 119 info; không có diagnostic mới từ thay đổi này.
- [x] Workflow xóa mọi asset `.apk` cũ trong release `latest` ngay trước khi upload, nên sau mỗi push chỉ giữ APK vừa build; asset không phải APK không bị ảnh hưởng.
- [ ] `dart format --output=none --set-exit-if-changed .` vẫn fail baseline với 66/122 file cần format; không file nào bị sửa bởi check.
- Bước tiếp theo: sửa analyzer counter/ratchet warning trong một issue độc lập; không gộp broad format hoặc các finding data/auth vào ARCH-004.

## [Phase 7] - 2026-07-13 11:56
- [x] Chỉ xử lý phần analyzer counter của ARCH-005; không dọn 139 diagnostic hoặc format hàng loạt.
- [x] Đổi bộ đếm sang regex neo đầu dòng diagnostic, chấp nhận indentation của analyzer và không đếm metadata/footer.
- [x] Đối chiếu trên baseline hiện có: `0 error`, `20 warning`, `119 info`, khớp `139 issues found`.
- [x] Tăng version từ `1.7.7+12` lên `1.7.8+13` cho session có thay đổi script/config.
- [x] Wrapper chạy hoàn chỉnh: 139 diagnostic, footer đúng `0 error / 20 warning / 119 info`; exit 1 là baseline analyzer debt.
- [x] `flutter test --no-pub`: 9/9 test pass.
- [ ] `dart format --output=none --set-exit-if-changed .` vẫn fail baseline: 66/122 file sẽ đổi format; check không sửa file.
- Bước tiếp theo: nếu verification xanh theo baseline, cân nhắc warning ratchet CI như một issue riêng; không bật analyzer gate tuyệt đối khi debt hiện có chưa được quản lý.

## [Phase 4] - 2026-07-13 12:26
- [x] Chỉ xử lý STATE-001: số dư, breakdown, net worth và lịch sử Ví không reactive theo thay đổi của `transactions`; không chạm schema, sync, auth hoặc navigation.
- [x] Chuyển các nguồn dữ liệu Ví sang PowerSync watch query theo cả `wallets` và `transactions`; giữ nguyên tên provider và `AsyncValue` contract tại UI.
- [x] Thay vòng lặp 2N one-shot query bằng một aggregate SQL cho toàn bộ Ví active; query count của provider không còn tăng tuyến tính theo số Ví.
- [x] Thêm 3 regression test bằng temp PowerSync DB: summary từng Ví emit lại, total active wallets emit lại và lịch sử Ví emit lại sau insert transaction.
- [x] Tăng version từ `1.7.8+13` lên `1.7.9+14`.
- [x] Focused test 3/3 pass; full `flutter test --no-pub` 12/12 pass; scoped analyzer không có issue; final wrapper còn baseline 138 diagnostics = 0 error, 19 warning, 119 info.
- [ ] Chưa đo SQL latency/query plan trên fixture 1/20/100 Ví và chưa smoke test trên Android/iOS device; không tuyên bố đã tối ưu runtime.
- Bước tiếp theo: profile aggregate query với dataset thực và kiểm add/edit/delete/move transaction trên device; sau đó mới xem xét phần error-state còn lại của Phase 4/UI-001.

## [Phase 4] - 2026-07-15 16:55
- [x] Chỉ xử lý lát cắt UI-001 cho Stats và thẻ Ví trên Home; TransactionScreen và Home transaction-list error/retry vẫn ngoài scope session này.
- [x] Root cause: các derived provider dùng `valueOrNull ?? []`, nên lỗi tải đầu tiên bị suy diễn thành dữ liệu rỗng; WalletCardHome còn ẩn hẳn lỗi bằng `SizedBox.shrink()`.
- [x] Stats hiển thị error state + retry cho summary, tab Danh mục và tab Theo ngày; thẻ Ví hiển thị thông báo gọn + retry thay vì biến mất. Dữ liệu cũ khi refresh lỗi vẫn được giữ vì chỉ chuyển error state khi `!hasValue`.
- [x] Thêm regression widget tests cho `Stream.error` ở Stats và WalletCardHome; tăng version `1.7.9+14` lên `1.7.10+15`.
- [x] Focused test pass; full `flutter test --no-pub`: 14/14 pass; scoped analyzer: `No issues found`; wrapper cuối: baseline 138 diagnostics = 0 error, 19 warning, 119 info.
- [ ] `dart format --output=none --set-exit-if-changed .` vẫn fail baseline: 63/124 file cần format, gồm WalletCardHome vốn đã lệch format; check không ghi file. Chưa có Android/iOS device smoke test.
- Bước tiếp theo: thực hiện TransactionScreen và Home transaction-list của UI-001 như một lát cắt riêng, kèm test error/retry và không thay đổi provider API.

## [Phase 4] - 2026-07-15 22:39
- [x] Chỉ xử lý lát cắt UI-001 còn lại cho TransactionsScreen và danh sách giao dịch Home; không chạm provider API, repository, schema, navigation hoặc các finding auth/backup.
- [x] Root cause: TransactionsScreen chỉ watch danh sách derived nên mất trạng thái lỗi của `transactionsProvider` và render empty/summary 0; Home chỉ in exception thô, không có hành động retry.
- [x] TransactionsScreen watch thêm `AsyncValue`, chỉ hiện error state khi lỗi tải đầu tiên chưa có value, ẩn mini-summary gây hiểu nhầm và retry bằng cách invalidate đúng `transactionsProvider`. Home dùng error state tiếng Việt + retry thay cho exception thô.
- [x] Thêm 2 widget regression test: lỗi không còn hiện empty state và nút “Thử lại” thực sự rebuild provider trên cả Transactions lẫn Home.
- [x] Tăng version từ `1.7.10+15` lên `1.7.11+16`.
- [x] Baseline: analyzer wrapper `138 diagnostics = 0 error / 19 warning / 119 info`; full test `14/14` pass.
- [x] Final: focused test `2/2` pass; scoped analyzer `No issues found`; full test `16/16` pass; analyzer wrapper giữ nguyên baseline `138 = 0/19/119`; `git diff --check` pass.
- [ ] Final format check vẫn fail baseline: 60/126 file sẽ đổi format; `--output=none` không ghi file. Chưa smoke test trên Android/iOS device, nên chưa xác nhận layout/scroll/retry với DB thật.
- Bước tiếp theo: smoke test hai error state trên device/emulator nếu có; sau đó chọn một finding mới thành session độc lập thay vì mở rộng thêm trong Phase 4.

## [Phase 5] - 2026-07-15 23:03
- [x] Chỉ xử lý STAB-008: exception ở bước khởi tạo bắt buộc có thể để splash đứng vô hạn; không chạm thứ tự bootstrap, timeout, DB, Supabase, backup nền hoặc cleanup.
- [x] Root cause: `SplashScreen._startInit` await `onInit` không catch exception, không có error state và không có đường retry.
- [x] Catch lỗi tại boundary splash, ghi log kèm stack trace, giữ người dùng ở splash, hiển thị thông báo tiếng Việt + nút “Thử lại”; chỉ điều hướng sau một lần init hoàn tất.
- [x] Guard duplicate init và reset progress/status trước mỗi retry; không nuốt lỗi để tiếp tục vào app khi service bắt buộc chưa sẵn sàng.
- [x] Thêm widget regression test chứng minh lần đầu throw không điều hướng và lần retry thành công mới mở màn tiếp theo.
- [x] Tăng version từ `1.7.11+16` lên `1.7.12+17`.
- [x] Baseline và final analyzer wrapper giống nhau: 138 diagnostics = 0 error / 19 warning / 119 info; exit 1 do technical debt hiện có.
- [x] Baseline full test 16/16 pass; final focused test 1/1 và full test 17/17 pass.
- [ ] Final format check vẫn fail baseline: 59/127 file sẽ đổi; `--output=none` không ghi file. Chưa smoke test lỗi init thật trên Android/iOS/Windows.
- Bước tiếp theo: smoke test bằng failure injection ở bootstrap trên runtime; sau đó tách critical/optional init và đo startup trong một session Phase 5 riêng trước khi cân nhắc timeout.

## [Phase 2] - 2026-07-15 23:15
- [x] Chỉ xử lý STAB-006: dừng xóa giao dịch cũ tự động dựa trên việc có một backup Drive gần đây; không mở rộng sang backup schema, atomic restore, manifest hoặc retention UI mới.
- [x] Root cause: startup coi backup mới nhất không quá 30 ngày là bằng chứng đủ để xóa mọi transaction quá 730 ngày, dù không có backup ID, timestamp/hash theo row hoặc high-water mark chứng minh snapshot chứa dữ liệu hiện tại.
- [x] Bỏ bước `_cleanupOldData` khỏi `_initServices` và xóa câu SQL `DELETE FROM transactions WHERE created_at < ?`; startup không còn đường xóa hàng loạt transaction theo tuổi dữ liệu.
- [x] Bỏ dialog “Chính sách lưu trữ” cùng preference một lần hiển thị vì dialog tuyên bố transaction quá hai năm sẽ bị xóa vĩnh viễn và rule quá một năm bị ẩn không được tìm thấy trong codebase.
- [x] Tăng version từ `1.7.12+17` lên `1.7.13+18` cho session có thay đổi code.
- [x] Baseline và final analyzer wrapper giống nhau: 138 diagnostics = 0 error / 19 warning / 119 info; exit 1 do technical debt hiện có. Scoped analyzer chỉ còn một info `isInDebugMode` đã có sẵn trong `main.dart`.
- [x] Baseline và final full test đều pass 17/17. Không thêm source-inspection test vì test đó không kiểm chứng runtime; xác minh scoped bằng diff và `rg` cho thấy không còn `_cleanupOldData`, retention notice hay câu SQL xóa theo cutoff trong `lib`.
- [ ] Final format check vẫn fail baseline: 60/127 file sẽ đổi format; `--output=none` không ghi file. Chưa chạy app trên device/emulator, chưa đo tăng trưởng DB và chưa có thiết kế retention thay thế với preview/snapshot verification.
- Bước tiếp theo: xây backup manifest/row counts và retention preview trong một session Phase 2 riêng; chỉ cho phép xóa row sau khi chứng minh row đó nằm trong snapshot có thể restore.

## [Phase 2] - 2026-07-15 23:28
- [x] Chỉ xử lý STAB-002: tác vụ Google Drive nền mở PowerSync trước khi Supabase được khởi tạo trong background isolate; không mở rộng sang backup schema, restore atomicity, iOS config hoặc retention.
- [x] Root cause: callbackDispatcher gọi openDatabase(), trong khi hàm này luôn chạy _setupSync() và truy cập Supabase.instance; Supabase chỉ được khởi tạo trong UI isolate.
- [x] Thêm tùy chọn setupSync mặc định true cho openDatabase; handler backup nền dùng setupSync: false, vẫn mở/migrate DB local nhưng không tạo PowerSync connector hoặc auth listener trong background isolate.
- [x] Tách runGDriveBackgroundTask để giữ orchestration có thể test và giữ nguyên contract WorkManager: task lạ trả success, chưa Google sign-in thì dừng an toàn, exception trả failure, timestamp chỉ ghi sau upload thành công.
- [x] Thêm 4 regression test cho thứ tự thành công, silent sign-in thất bại, upload throw và task không liên quan; tăng version 1.7.13+18 lên 1.7.14+19.
- [x] Baseline: analyzer wrapper 138 = 0 error / 19 warning / 119 info; full test 17/17 pass. Final: focused test 4/4, full test 21/21 pass; analyzer giữ nguyên 138 = 0/19/119; scoped analyzer không có diagnostic mới.
- [ ] Final format check vẫn fail baseline: 60/129 file sẽ đổi format; --output=none không ghi file. Chưa chạy WorkManager task thật trên Android/iOS và chưa xác nhận cạnh tranh truy cập cùng file DB giữa UI/background isolate.
- Bước tiếp theo: chạy periodic task trên thiết bị với app foreground/background/terminated, kiểm gdrive_last_backup_time và file Drive; nếu có lock hoặc isolate được tái sử dụng, xử lý lifecycle/idempotent open trong issue riêng.

## [Phase 2] - 2026-07-16 08:13
- [x] Chỉ xử lý STAB-003: backup “toàn bộ” bỏ sót ví archived, ngân sách tháng và lịch sử thanh toán khoản vay; không gộp STAB-004 atomic restore, auth/sync hoặc migration schema DB.
- [x] Nâng backup schema từ v3 lên v4, export/restore thêm `budgets`, `loan_payments` và toàn bộ wallets; reader vẫn chấp nhận backup v1-v3 thiếu các list mới.
- [x] Trả số lượng monthly budgets, loans và loan payments qua `BackupResult`/`RestoreResult`; cập nhật preview/kết quả backup local và Google Drive để không còn báo cáo thiếu các nhóm dữ liệu này.
- [x] Thêm regression test dùng temp PowerSync DB: round-trip bảo toàn archived wallet, monthly budget, loan/payment relation; test riêng xác nhận backup v3 vẫn đọc được.
- [x] Tăng version từ `1.7.14+19` lên `1.7.15+20`.
- [x] Baseline: analyzer `138 = 0 error / 19 warning / 119 info`, full test `21/21` pass. Final: focused test `2/2`, full test `23/23` pass; analyzer `136 = 0/17/119`, không có diagnostic mới.
- [ ] Repo-wide format check vẫn fail baseline: 62/130 file sẽ đổi, `--output=none` không ghi file. Ba file trong scope giữ style hiện tại để tránh formatting-only diff. Chưa smoke test backup/restore qua file picker, share sheet hoặc Google Drive thật trên Android/iOS.
- Bước tiếp theo: xử lý STAB-004 trong session riêng bằng typed validation + database transaction; sau đó mới thêm manifest/checksum và kiểm chứng restore failure không ghi partial rows.

## [Phase 2] - 2026-07-16 08:39
- [x] Chỉ xử lý STAB-004: restore có thể ghi một phần rồi fail; không gộp manifest/checksum, backup schema mới, auth/sync, retention hoặc UI refactor.
- [x] Parse và validate toàn bộ 8 nhóm payload thành `_RestorePayload` trước mọi DB read/write; kiểm tra list/object, kiểu field bắt buộc/nullable và chuỗi ngày ISO, đồng thời giữ backup v1-v3 đọc được khi các list mới không tồn tại.
- [x] Chạy toàn bộ existence check và insert thật trong một `PowerSyncDatabase.writeTransaction`; dry-run vẫn không ghi DB và public API `previewRestore`/`restore` giữ nguyên.
- [x] Thêm 2 regression test: payload sai kiểu ở phần sau ghi 0 row; lỗi SQLite sau insert đầu tiên rollback toàn bộ transaction.
- [x] Tăng version từ `1.7.15+20` lên `1.7.16+21`.
- [x] Baseline analyzer `136 = 0 error / 17 warning / 119 info`, full test `23/23` pass. Final focused test `4/4`, full test `25/25`, scoped analyzer `No issues found`, wrapper giữ nguyên `136 = 0/17/119`.
- [ ] Repo-wide format check vẫn fail baseline: 62/130 file sẽ đổi, `--output=none` không ghi file. Chưa smoke test file picker/share/Google Drive restore trên Android/iOS và chưa kiểm manifest/checksum.
- Bước tiếp theo: thêm manifest row counts/checksum như một issue Phase 2 riêng, rồi smoke test restore local/Drive trên thiết bị; không mở rộng STAB-004 thêm trong session này.

## [Phase 2] - 2026-07-17 08:20
- [x] Chỉ xử lý STAB-005: startup xóa category trùng mà không remap reference; không chạm auth, wallet sync boundary, manifest/checksum hoặc schema DB.
- [x] Thay câu `DELETE ... MIN(id)` bằng repair atomic: ưu tiên category default, rồi sort order/ID; remap `transactions`, `recurring_reminders`, `category_budgets`, `detected_habits` trước khi xóa duplicate.
- [x] Chặn add/rename trùng tên trong cùng loại tại `CategoryRepository`; form giữ mở và báo SnackBar thay vì tạo duplicate mới.
- [x] Backup v4 lưu/đọc `is_default` dạng optional; restore chạy repair trong cùng transaction nên không làm hồi quy atomicity của STAB-004 và backup cũ vẫn đọc được.
- [x] Thêm 3 regression paths: repair mọi reference, reject add/rename duplicate, restore remap duplicate trước khi trả kết quả; tăng version `1.7.16+21` lên `1.7.17+22`.
- [x] Baseline analyzer `136 = 0 error / 17 warning / 119 info`, full test `25/25` pass. Final focused test `7/7`, full test `28/28`; analyzer `135 = 0/16/119`, giảm một warning unused UUID trong file đã chạm; `git diff --check` pass.
- [ ] Repo-wide format check `output=none` bị policy runner từ chối; scoped check xác nhận `powersync_db.dart`, `category_repository.dart` và test mới đã format, còn `backup_service.dart`, form và backup test vẫn thuộc format debt có sẵn. Chưa smoke test startup/restore trên device hoặc dữ liệu thật có nhiều budget trùng.
- Bước tiếp theo: smoke test DB có duplicate category trên device và quyết định policy merge khi cả canonical lẫn duplicate đều có `category_budgets`; không tự chọn amount để tránh mất dữ liệu ngầm.

## [Phase 6] - 2026-07-17 08:44
- [x] Chỉ xử lý lát cắt UI-003 cho auto-carousel Ví trên Home khi Reduce Motion bật; Aurora, splash, bottom-nav và việc pause theo tab visibility nằm ngoài scope session này.
- [x] Root cause: `WalletCardHome` luôn tạo `Timer.periodic` và gọi `animateToPage`, không đọc `MediaQuery.disableAnimations` hoặc `accessibleNavigation` dù repo đã có `MotionSpec.shouldReduceMotion`.
- [x] Dùng policy motion dùng chung để không khởi động và hủy timer carousel khi Reduce Motion bật; giữ nguyên thao tác vuốt tay, dữ liệu, provider API và navigation.
- [x] Thêm widget regression test xác nhận carousel vẫn ở page 0 sau chu kỳ 3 giây và 400 ms animation khi `disableAnimations = true`; tăng version `1.7.17+22` lên `1.7.18+23`.
- [x] Focused test pass 2/2; full `flutter test --no-pub` pass 29/29; scoped analyzer báo `No issues found`; final wrapper giữ baseline `135 = 0 error / 16 warning / 119 info`; `git diff --check` pass.
- [ ] Repo-wide format check vẫn fail baseline: 62/131 file sẽ đổi format, `--output=none` không ghi file. Chưa smoke test Reduce Motion trên Android/iOS thật và chưa đo callback/ticker khi Home offstage.
- Bước tiếp theo: xử lý pause carousel khi tab Home không active như một lát cắt PERF-003 riêng có callback-count test; các animation Aurora/splash/bottom-nav của UI-003 tiếp tục tách riêng để giữ rollback nhỏ.

## [Phase 6] - 2026-07-17 09:10
- [x] Chỉ xử lý lát cắt PERF-003 cho timer auto-carousel Ví khi tab Home không active; lazy-create ba tab, Aurora, splash, auth và các finding dữ liệu nằm ngoài scope.
- [x] Root cause: `IndexedStack` giữ `HomeScreen` sống nhưng không truyền trạng thái active xuống subtree, nên `WalletCardHome` chỉ hủy `Timer.periodic` khi dispose hoặc Reduce Motion bật.
- [x] Bọc từng tab bằng `TickerMode` theo `_index`; `WalletCardHome` đọc `TickerMode.valuesOf(context).enabled` và hủy/không tạo timer khi Home inactive, vẫn giữ state, vuốt tay, provider API và navigation hiện tại.
- [x] Thêm widget regression test xác nhận carousel chuyển page khi active rồi giữ nguyên page sau khi Home inactive; tăng version `1.7.18+23` lên `1.7.19+24`.
- [x] Focused test pass 3/3; full `flutter test --no-pub` pass 30/30; scoped analyzer `No issues found`; wrapper cuối giữ baseline `135 = 0 error / 16 warning / 119 info`; `git diff --check` pass.
- [ ] Repo-wide format check vẫn fail baseline: 65/131 file được formatter báo sẽ đổi và `--output=none` không ghi file; lần rerun sau khi format riêng test bị policy runner từ chối. Chưa đo CPU/battery hoặc smoke test tab switching trên Android/iOS.
- Bước tiếp theo: đo timer/CPU khi đứng lâu ở Settings trên device; lazy-create tab lần đầu là lát cắt PERF-003 riêng vì có rủi ro restoration/scroll/Hero lớn hơn.
