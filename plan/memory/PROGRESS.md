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
