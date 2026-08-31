# 04 — Kế hoạch 8 phase

Nguyên tắc: mỗi phase là 1 PR/branch chạy được, app không vỡ giữa chừng. Màn chưa redesign vẫn chạy trên theme mới (chấp nhận lệch nhẹ tới lượt nó). Sau mỗi phase: build + chạy smoke test theo tiêu chí nghiệm thu rồi mới sang phase sau.

---
## Phase 0 — Nền theme & hạ tầng
**Việc:**
1. Thay `ColorScheme.fromSeed` (`app_theme.dart`) bằng ColorScheme tường minh light + dark theo `01-tokens.md`; thêm `ThemeExtension SpendoColors` (brand/onBrand, income, expense, warning, 5 bậc surface).
2. Thêm font Figtree + Caprasimo (google_fonts hoặc asset); TextTheme theo thang chữ; kiểm tra glyph tiếng Việt của Caprasimo — thiếu dấu thì fallback Figtree 800.
3. Sửa **2 MaterialApp lồng nhau** (`main.dart` → SplashScreen host): Splash/Welcome phải chạy trong theme thật.
4. Quét thay ~38 `Icons.*` Material → Lucide tương đương.
5. Xoá dead code: AuthScreen, GlobalFab, BudgetCard, LoanMiniCard, LoanSettingsTile, QuickActionsBar.

**Nghiệm thu:** app build, mọi màn hiển thị nền cream/chữ nâu, không còn `fromSeed`, không còn `Icons.*`, splash mang theme user.

## Phase 1 — Shell & component dùng chung
**Việc:** Shell 4 tab (Trang chủ/Giao dịch/Thống kê/Cài đặt) bằng ShellRoute — hết mất bottom nav khi điều hướng; SpendoBottomNav + SpendoFab theo `02-components.md`; dựng bộ widget chung (Button, Chip, CategoryTile, TransactionRow, Card, SectionHeader, ProgressBar, Sheet+drag-handle, Numpad, FormField, EmptyState, SearchBar); bỏ route giả `/add` → mở sheet trực tiếp.
**Nghiệm thu:** 4 tab giữ state (IndexedStack), FAB brand nổi trên nav, các widget chung có sẵn để phase sau chỉ lắp.

## Phase 2 — Vòng lặp lõi: Home + Add
**Màn:** 01 Trang chủ, 02 Thêm giao dịch, 02b Gợi ý ghi chú (mockup file `01`, audit 05/07/09).
**Lưu ý:** mask số dư ••••••; card ngân sách ↔ CTA nét đứt; chip "Lặp lại" → tạo nhắc nhở; icon search ở ô ghi chú mở 02b (danh mục đang chọn giữ, gợi ý theo danh mục).
**Nghiệm thu:** thêm giao dịch end-to-end ≤ numpad → Lưu; 02b trả ghi chú về sheet.

## Phase 3 — Giao dịch & PeriodPicker
**Màn:** 03 Giao dịch, 04 Chi tiết, 24 PeriodPickerSheet (mockup `02`, `07`; audit 06/08/25/26).
**Lưu ý:** PeriodPicker gộp MonthPicker + DateRangePicker, gắn vào cả Home/Thống kê/Hạn mức khi tới lượt.
**Nghiệm thu:** tìm kiếm + lọc + chip lọc đang áp hoạt động; sửa ngày trong chi tiết; Nhân bản.

## Phase 4 — Ví & Hạn mức
**Màn:** 06, 07, 08, 09 (mockup `03`; audit 12/13/14/22/23/24).
**Lưu ý:** `/budget` là trang, thay 3 sheet cũ; cảnh báo ví âm inline.
**Nghiệm thu:** CRUD ví; đặt hạn mức tổng + theo danh mục từ 1 trang; progress đổi màu 85%/vượt.

## Phase 5 — Thống kê, Vay, Nhắc nhở
**Màn:** 10, 11, 12, 13 + form 16, 17 (mockup `04`, `05`; audit 10/15/16/17/18/19).
**Lưu ý:** fl_chart nhận màu token; legend tap → tab Giao dịch đã lọc; badge M3 thay emoji.
**Nghiệm thu:** chart light/dark đúng màu; ghi nhanh từ nhắc nhở tạo giao dịch.

## Phase 6 — Cài đặt & trang con
**Màn:** 05 hub, 14, 15, 20, 21, 22, 23 (mockup `02`, `05`, `06`, `07`; audit 20/21/27/28/29/31).
**Lưu ý:** hub 3 nhóm card; Danh mục/Giao diện/Sao lưu/Ngân hàng/Widget thành trang con có route; sao lưu dùng progress inline thay 3 dialog loading.
**Nghiệm thu:** mọi mục hub điều hướng đúng, đổi theme/màu/chế độ đồ hoạ áp dụng live.

## Phase 7 — Khởi động + Dark pass + QA
**Việc:** 18 Splash (gộp StartupGate, bỏ nút offline), 19 Welcome 2 trang (mockup `06`; audit 01/02/03); rà **dark mode toàn bộ 24 màn** theo bảng dark (không bóng, alpha tile 0.24); quét sạch hex/style inline còn sót → token; cập nhật 2 widget Android native (`widget_layout_*.xml`) màu mới.
**Nghiệm thu:** chạy trọn flow cài mới → welcome → home ở cả light/dark; không còn màu ngoài token.

---
### Prompt mồi cho TỪNG phase (dán vào Claude Code)
```
Đọc design_handoff_spendo_redesign/README.md, 01-tokens.md, 02-components.md,
03-screens.md, và mục "Phase N" trong 04-phases.md.
Với mỗi màn trong phase: đọc file audit AS-IS tương ứng (ref file:line) trước,
rồi mở mockup .dc.html theo bảng 03-screens.md và tái tạo pixel-perfect bằng
widget/token đã dựng. Không sửa logic nghiệp vụ trừ khi phase yêu cầu.
Làm xong: build, tự kiểm tra theo "Nghiệm thu", liệt kê file đã sửa.
Chỉ làm Phase N, không lấn phase sau.
```
