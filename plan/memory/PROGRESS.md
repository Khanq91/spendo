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
