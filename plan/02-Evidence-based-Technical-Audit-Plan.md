# Spendo — Evidence-based Technical Audit

## Tóm tắt

- Thực hiện audit toàn diện nhưng không chỉnh sửa production code, dependency, schema, state management hoặc hành vi ứng dụng.
- Lưu kế hoạch thực thi tại `plan/04-evidence-based-technical-audit.md` và báo cáo cuối tại `audit/TECHNICAL_AUDIT.md`; giữ nguyên `audit/CLONE_BLUEPRINT.md`.
- Bảo toàn toàn bộ thay đổi chưa commit, đặc biệt việc chuyển plan cũ sang `old-plan/` và thư mục `screenshots/live_app/`.

## Quản lý trạng thái audit

- Chụp `git status` ban đầu
- Ghi progress mới theo các mốc: baseline, architecture/data flow, performance, UI/UX, stability/security và hoàn thành báo cáo.
- Giữ nguyên nội dung hiện có của `DECISIONS.md` và `ERRORS.md`; chỉ nối thêm quyết định hoặc lỗi mới có giá trị lâu dài trong quá trình audit.
- Không tăng version `1.7.6+11` vì phiên làm việc chỉ tạo tài liệu và bằng chứng audit.

## Thực hiện audit

1. **Baseline và bản đồ hệ thống**
   - Đọc đầy đủ manifest, lockfile, README, `.metadata`, CI/environment config, cấu hình Android/iOS, toàn bộ `lib/`, `test/`, `integration_test/` và các tài liệu kiến trúc hiện có.
   - Lập các luồng thực tế riêng biệt thay vì ép vào một sơ đồ giả: PowerSync offline-first, Supabase auth/sync, SharedPreferences settings, Google Drive backup, SePay và startup/background services.
   - Ghi lại Flutter/Dart thực tế; baseline quan sát hiện tại là Flutter 3.44.0 và Dart 3.12.0 nhưng báo cáo phải dùng kết quả chạy mới.

2. **Baseline lệnh**
   - Chạy `flutter pub get --dry-run --enforce-lockfile`; chỉ chạy `flutter pub get --enforce-lockfile` khi preflight không yêu cầu đổi resolution.
   - Chạy `dart format --output=none --set-exit-if-changed .` ở chế độ kiểm tra, không format lại file.
   - Chạy duy nhất `scripts/analyze_codex.bat` cho analyzer và đọc kết quả mới từ `audit/flutter_analyze.txt`. Đối chiếu cả diagnostic body và footer vì log hiện tại được tạo bằng SDK cũ hơn và số đếm footer có thể không khớp.
   - Chạy `flutter test --no-pub`; ghi riêng test pass/fail, warning cấu hình và test bị thiếu.
   - Nếu lệnh timeout hoặc không khả dụng, ghi nguyên nhân và bằng chứng; không sửa code để ép baseline pass.

3. **Review có bằng chứng**
   - Kiểm tra kiến trúc, Riverpod watch scope, dependency direction, widget gọi DB/API trực tiếp, class quá lớn, logic trùng lặp, error handling và testability.
   - Kiểm tra startup tuần tự, DB query lặp, rebuild, eager rendering, controller/listener disposal, async gap, cancellation, cache, background work và isolate usage.
   - Kiểm tra auth/session, PowerSync upload, timeout/retry, secrets/log nhạy cảm, storage, permissions, deep link, dữ liệu offline và recovery.
   - Đánh giá UI bằng toàn bộ 5 screenshot chuẩn, 25 ảnh trong `live_app` gồm ảnh `ui_error`, và video MP4; liên kết từng quan sát với route/widget/state tương ứng.
   - Áp dụng checklist từ `flutter-taste` cho hierarchy, tokens, state loading/error/empty, touch target, text scale, SafeArea, keyboard, responsive, accessibility, motion và Liquid Glass. Plan Liquid Glass cũ chỉ là bối cảnh, không phải nguồn sự thật.
   - Nếu có device/emulator, chạy profile không sửa code để kiểm tra cold start, frame timeline và scrolling ở các màn hình chính. Nếu không có, đánh dấu nhận định chưa đo là `Likely`, tuyệt đối không tuyên bố cải thiện runtime.

## Báo cáo và giao diện đầu ra

- `plan/TECHNICAL_AUDIT.md` gồm đúng bảy phần: Executive summary, Architecture map, Findings, Top 10, Refactor plan, Quick wins và Những việc không nên làm.
- Mỗi finding có ID theo nhóm (`ARCH`, `STATE`, `PERF`, `UI`, `STAB`, `SEC`), severity, confidence, file/vị trí, bằng chứng, tác động, cách tái hiện/đo, giải pháp ít rủi ro, rủi ro sửa và effort.
- Chấm Top 10 theo công thức yêu cầu với thang cố định: Impact 1–4, Frequency 1–4, Confidence `Confirmed=1.0`, `Likely=0.7`, `Optional=0.4`, Effort `S=1`, `M=2`, `L=3`; hòa điểm thì ưu tiên severity rồi confidence.
- Kế hoạch refactor chỉ được sinh từ findings đã ghi nhận; mỗi phase có phạm vi, acceptance, test/measurement và rollback. Dừng sau báo cáo, không triển khai quick win.
- Không thay đổi public API, provider, schema, model hoặc production type nào trong audit.

## Kiểm tra hoàn thành và giả định

- Mọi kết luận phải trỏ đến file, class/function và dòng thực tế; nội dung không tìm thấy phải ghi “Not found in codebase.”
- Mọi performance claim phải có số đo hoặc được ghi rõ là rủi ro chưa đo kèm phương pháp xác nhận.
- Kiểm tra cuối bằng `git diff --check` và `git status --short`; ngoài plan, report, progress, analyzer log được tạo lại và các append hợp lệ vào memory, source code phải không đổi.
- Do chưa nhận được lựa chọn khác, mặc định dùng `audit/TECHNICAL_AUDIT.md` và profile khi có thiết bị; thiếu thiết bị không chặn báo cáo nhưng phải được công bố rõ.
- “Xóa dữ liệu PROGRESS” được hiểu là truncate file trước khi bắt đầu rồi dùng chính file đó cho progress audit mới, không xóa file khỏi repository.
