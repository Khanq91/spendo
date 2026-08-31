# 03 — Bản đồ màn hình (mockup ↔ AS-IS ↔ thay đổi chính)

Mockup: mở file `.dc.html`, tìm theo `id` (anchor `#id`). Audit AS-IS: file `.md` cùng tên trong bộ tài liệu hiện trạng.

| # | Màn | Mockup (file · id) | AS-IS | Thay đổi chính |
|---|---|---|---|---|
| 01 | Trang chủ | `01 …dc.html` · `#home` | 05-home | Header "Còn lại tháng này" + số dư 38/800; card ngân sách (hoặc CTA nét đứt khi chưa đặt); chip ví ngang; 4 ô tắt (Ví/Vay nợ/Nhắc nhở/Hạn mức — bỏ AllFeatures); Gần đây nhóm theo ngày trên fold; mask số dư (••••••) |
| 02 | Thêm giao dịch | `01` · `#add` | 07-add-transaction-sheet | Sheet 92%: Huỷ / segmented Chi\|Thu / Lưu; số tiền lớn màu theo loại; grid danh mục 4 cột; ô ghi chú + **icon search mở 02b**; chip gợi ý inline; chip meta (ngày · ví · Lặp lại→tạo nhắc nhở); numpad 000 |
| 02b | Gợi ý ghi chú | `01` · `#note-suggest` | 09-note-picker | Màn mới thay NotePicker: header X/Ghi chú/Xác nhận; input focus; grid danh mục (giống 02, danh mục đang chọn giữ); GỢI Ý = ghi chú đã dùng theo danh mục |
| 03 | Giao dịch | `02` · `#tx` | 06-transactions | SearchBar, segmented Chi\|Thu, nút Lọc + badge, chip lọc đang áp, list nhóm ngày |
| 04 | Chi tiết giao dịch | `02` · `#txdetail` | 08-transaction-detail-sheet | Ngày sửa được, note wrap, Nhân bản, xoá xác nhận |
| 05 | Cài đặt (hub) | `02` · `#settings` | 20-settings | 3 nhóm card (DỮ LIỆU/KẾT NỐI/ỨNG DỤNG) + trang con; footer version |
| 06 | Nguồn tiền | `03` · `#wallets` | 12-wallets | Icon đúng loại ví, card tổng tonal, 1 FAB, ví âm cảnh báo |
| 07 | Chi tiết nguồn tiền | `03` · `#walletdetail` | 13-wallet-detail | TonalCard header, FAB "Thêm giao dịch" gắn ví |
| 08 | Form nguồn tiền | `03` · `#walletform` | 14-wallet-form-sheet | Token form chung, swatch màu inline, validate inline |
| 09 | Hạn mức `/budget` | `03` · `#budget` | 22+23+24-budget* | Gộp 3 sheet cũ → 1 trang: tiến độ tổng + theo danh mục |
| 10 | Thống kê | `04` · `#stats` | 10-stats | Segmented Chi\|Thu, summary lớn, legend tap → Giao dịch đã lọc; fl_chart đổi màu token |
| 11 | Khoản vay | `04` · `#loans` | 15-loan-list | Header Đang nợ/Được nợ, segmented, tile "còn lại" + progress |
| 12 | Chi tiết khoản vay | `04` · `#loandetail` | 16-loan-detail | Badge M3 thay emoji, note thanh toán hiển thị |
| 13 | Nhắc nhở | `04` · `#reminders` | 18-reminders | 1 hàng gợi ý, tile "Lần tới · ~số tiền", nút Ghi nhanh |
| 14 | Danh mục | `05` · `#categories` | 21-category-form-sheet (list ở 20-settings) | Trang riêng `/settings/categories`, segmented Chi\|Thu, kéo sắp xếp |
| 15 | Form danh mục | `05` · `#catform` | 21-category-form-sheet | Ghi rõ loại, swatch + icon inline, cuộn được |
| 16 | Form nhắc nhở | `05` · `#reminderform` | 19-reminder-form-sheet | SegmentedButton tần suất, "Nhắc trước", số tiền ước tính |
| 17 | Form khoản vay | `05` · `#loanform` | 17-loan-form-sheet | Segmented loại, chip ngày, numpad, nút bám tên |
| 18 | Splash | `06` · `#splash` | 01-splash + 02-startup-gate | Theme thật (cream), gộp StartupGate, offline-first — KHÔNG có nút thoát mạng, chỉ progress + v1.7.26 |
| 19 | Welcome | `06` · `#welcome` | 03-welcome | Rút còn 2 trang (Đồ hoạ + Drive gộp trang 2), dots + Bỏ qua mọi nơi |
| 20 | Giao diện | `06` · `#appearance` | 27-visual-mode-and-theme-color-sheets | Trang `/settings/appearance`: chế độ Sáng/Tối/Hệ thống + 5 màu + Normal/Fancy, preview live — gộp 3 lựa chọn cũ |
| 21 | Sao lưu & đồng bộ | `06` · `#backup` | 20-settings (mục backup) | Trang riêng: gộp Drive + JSON + CSV, 1 card trạng thái sage, progress inline thay 3 dialog |
| 22 | Ngân hàng tự động | `07` · `#bank` | 28-sepay-add-mapping-sheet | Trang `/settings/bank` + form token chung; badge "tự động" tertiaryContainer |
| 23 | Widget màn hình chính | `07` · `#widgetpage` | 29-widget-pin-picker + 31-android-home-widgets | Preview thật, slot trống = CTA |
| 24 | PeriodPickerSheet | `07` · `#periodpicker` | 25-month-picker + 26-date-range-picker | Gộp 2 picker, dùng chung 4 màn (Home/Giao dịch/Thống kê/Hạn mức) |
| 25 | Chuyển tiền giữa ví | `07` · `#transfer` | — | **ROADMAP — không code đợt này** |

Xoá/dead code: AuthScreen (30-auth-screen-dead), AllFeatures (11-all-features), GlobalFab+showAddTransactionSheet, BudgetCard, LoanMiniCard, LoanSettingsTile, QuickActionsBar.
