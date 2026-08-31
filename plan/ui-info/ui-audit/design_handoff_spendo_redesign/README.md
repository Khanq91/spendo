# Handoff: Spendo Redesign (v1.7.26 → TO-BE)

## Tổng quan
Redesign toàn bộ UI app Spendo (Flutter, Material 3, offline-first, tiếng Việt hard-code) theo design direction mới: **cấu trúc M3 giữ nguyên, da mới "Organic"** — nền cream–sand, primary rose, sage phụ, terracotta tertiary, bo góc tròn đẩy mạnh (pill), Figtree + Caprasimo, Lucide icons stroke 2.25, brand #F06292 giữ cho FAB + tab indicator.

Phạm vi: 25 màn TO-BE (xem `03-screens.md`), chia 8 phase (xem `04-phases.md`). Màn 25 · Chuyển tiền giữa ví là ROADMAP — ngoài phạm vi.

## Về các file thiết kế
File trong `mockups/` là **design reference viết bằng HTML** (mở bằng browser hoặc đọc source — mọi style nằm inline). KHÔNG copy HTML vào app. Nhiệm vụ là **tái tạo pixel-perfect các thiết kế này trong codebase Flutter hiện có**, dùng đúng pattern sẵn (Riverpod, go_router, MotionSpec, fl_chart…).

Kèm theo (do người dùng cung cấp, nằm ở thư mục `uploads/` của dự án thiết kế hoặc do bạn tự thêm):
- **Bộ audit AS-IS** `00-overview.md` → `31-*.md` — hiện trạng code với ref `file:line` chính xác. Đọc file audit tương ứng TRƯỚC khi sửa màn nào.
- **Screenshot app thật** — đối chiếu hành vi hiện tại (một số đã lỗi thời so với code; code là chuẩn).

## Fidelity
**High-fidelity.** Màu, chữ, spacing, bo góc, copy đều là giá trị cuối. Tái tạo đúng hex/px trong spec; sai lệch chỉ chấp nhận khi nền tảng bắt buộc (density, safe area, text scale).

## Thứ tự đọc
1. `MASTER-PROMPT.md` — prompt mồi, dán vào Claude Code để bắt đầu.
2. `01-tokens.md` — token màu light + dark, chữ, hình khối, spacing, motion, mapping sang Flutter.
3. `02-components.md` — spec component dùng chung (hợp nhất ≥5 nhóm widget private trùng lặp).
4. `03-screens.md` — 26 mục: mockup ↔ audit AS-IS ↔ thay đổi chính.
5. `04-phases.md` — 8 phase, mỗi phase có prompt mồi + tiêu chí nghiệm thu.

## Quyết định đã chốt (không mở lại)
- Brand #F06292 chỉ cho FAB + tab indicator (icon trên brand: #551D30); nút chính dùng primary #8C4A5E.
- "Lặp lại" trong Add Transaction tạo **nhắc nhở**, không tự nhân bản giao dịch.
- Settings hub = 3 nhóm card (Dữ liệu / Kết nối / Ứng dụng), bỏ list phẳng.
- Gộp: 3 sheet ngân sách → 1 trang `/budget`; MonthPicker + DateRangePicker → PeriodPickerSheet; StartupGate → Splash; bỏ AllFeatures, NotePicker cũ (thay bằng màn 02b), AuthScreen (dead code).
- Splash offline-first: KHÔNG có nút "Tiếp tục ngoại tuyến".
- Dark mode: chỉ đổi token (bảng dark trong `01-tokens.md`), không thiết kế lại màn.
- Shell 4 tab: Trang chủ · Giao dịch · Thống kê · Cài đặt (code hiện tại có 3 tab — thêm lại Cài đặt vào shell).

## File
- `mockups/00 - Foundation.dc.html` — token sheet trực quan (light + dark).
- `mockups/01…07 *.dc.html` — 26 màn theo cụm tính năng.
- `mockups/android-frame.jsx`, `mockups/support.js` — khung preview, bỏ qua khi implement.
