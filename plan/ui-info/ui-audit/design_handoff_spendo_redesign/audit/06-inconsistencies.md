# 06 — Điểm không nhất quán & vấn đề khách quan (AS-IS)

Mức độ: **cao** = sai chức năng/không đọc được/chặn tác vụ; **TB** = gây nhầm hoặc phá nhất quán rõ; **thấp** = thẩm mỹ/kỹ thuật.

## A. Lỗi hiển thị & dữ liệu

| # | Mô tả | Nơi xuất hiện | Mức |
|---|---|---|---|
| A1 | Icon loại ví **luôn** là `circleEllipsis` vì `WalletType.iconName` ('wallet','landmark','smartphone','credit_card','trending_up','more_horiz') không có case trong `categoryIcon()` | `wallet.dart:21-28` ↔ `category_icons.dart:4-23`; render tại `wallets_screen.dart:314,451`, `wallet_detail_screen.dart:269`, `wallet_form_sheet.dart:277`, `add_transaction_sheet.dart:737,808` | cao |
| A2 | Ký hiệu ₫ hiển thị 2 lần ("0 ₫ ₫") do `formatVND` đã kèm ₫ rồi thêm `Text('₫')` | `add_transaction_sheet.dart:415-430` | cao (cần xác nhận trên thiết bị — screenshot cũ chưa có AnimatedMoneyText) |
| A3 | "Số dư" trên Home = thu − chi **của tháng**, nhưng progress bar ngay dưới = tổng ví **mọi thời gian** (x1/x2) — hai số khác bản chất trong 1 card, không nhãn | `summary_card.dart:80` (summary.balance) vs `:114-130` (totalWalletBreakdownProvider) | cao |
| A4 | Transactions **không có loading state**: trong lúc stream chưa emit, `filteredTransactionsProvider` trả `[]` → hiện "Chưa có giao dịch nào" | `transactions_screen.dart:134-138`, `transaction_provider.dart:32` | cao |
| A5 | WalletDetail: ví không tồn tại/đã xoá → spinner vĩnh viễn, AppBar trống | `wallet_detail_screen.dart:41-46` | cao |
| A6 | Hạn mức tháng sau khi đặt **không hiển thị ở đâu** (`BudgetCard` không được dùng; Home không có) | `budget_card.dart` dead; `home_screen.dart` không import | cao |
| A7 | Ghi chú thanh toán khoản vay nhập được nhưng không bao giờ hiển thị | `loan_detail_screen.dart:613-625` (input) vs `_PaymentTile :515-537` | TB |
| A8 | `warnBeforeHours` có trong model & preset nhưng không có UI và bị bỏ khi tạo reminder | `recurring_reminder.dart:24,175`, `reminder_form_sheet.dart:108-121` | TB |
| A9 | Stats tab "Danh mục" báo "Chưa có dữ liệu" khi tháng chỉ có thu nhập (chỉ tính expense); bar chart cũng chỉ vẽ expense dù có income | `stats_provider.dart:74-82`, `stats_screen.dart:291, 636, 758` | TB |
| A10 | Ví archived → `TransactionDetailSheet` ẩn hàng "Nguồn tiền" dù giao dịch có walletId (`walletsProvider` chỉ active) | `transaction_detail_sheet.dart:30-34` | TB |
| A11 | Nút submit LoanForm phụ thuộc `_titleCtrl.text` nhưng không lắng nghe controller → trạng thái nút không cập nhật khi gõ tên | `loan_form_sheet.dart:341-349` | TB |
| A12 | `showDatePicker` LoanForm `firstDate: now` nhưng `initialDate = _dueDate` (có thể quá khứ khi sửa) → vi phạm assert | `loan_form_sheet.dart:65-71` | TB |
| A13 | "Còn N ngày" dùng `difference(now).inDays` không normalize → "Còn 0 ngày" | `loan_list_screen.dart:155`, `loan_detail_screen.dart:352` | thấp |
| A14 | `_progressCtrl` khai báo, không dùng | `splash_screen.dart:139-142` | thấp |
| A15 | Screenshot trong repo 4 tab, code 3 tab; `lib/structure.txt` thiếu nhiều file | `screenshots/`, `lib/structure.txt` | thấp |
| A16 | Widget Android chỉ dùng danh mục ghim khi **đủ 4 slot**; ghim 1–3 slot trong Settings không có tác dụng, widget vẫn hiện 4 ô mặc định | `SpendoWidgetMedium.kt:76` vs `widget_pin_section.dart` (cho phép ghim từng ô) | cao |

## B. Token / màu / typography lệch

| # | Mô tả | Nơi | Mức |
|---|---|---|---|
| B1 | Hai màu đỏ cho cùng nghĩa "chi": `#F06292` (`expenseColor`) ở list item/detail; `#E53935` (`expenseAltColor`) ở summary/day header/stats/toggle | `transaction_list_item.dart:25` vs `summary_card.dart:155`, `grouped_transaction_sliver.dart:124` | TB |
| B2 | `#6C63FF` (tím) hard-code 16 lần cho budget/backup/auth — không thuộc scheme, không đổi theo màu chủ đạo | `budget_screen.dart:135,165`, `budget_type_sheet.dart:48`, `settings_screen.dart:81,87,111,117,727,743,781,835` | TB |
| B3 | `Colors.grey.shade300/400/500/600/800` cố định → tối/không đọc được trong dark mode | `transaction_detail_sheet.dart:47,226,230,238`, `transaction_list_item.dart:91,101`, `month_selector.dart:80`, `stats_time_selector.dart:113` | cao |
| B4 | `Colors.white` cố định làm text trên `cs.primary` thay vì `onPrimary` | `month_picker_sheet.dart:124`, pie title `stats_screen.dart:399`, `summary_card.dart` | thấp |
| B5 | Splash + MaterialApp#1 + Android widget dùng palette hồng cũ `#F06292`/tím; Welcome dùng theme MaterialApp#1 (light only) → user chọn dark/Indigo vẫn thấy hồng/sáng | `main.dart:68`, `splash_screen.dart:233-242`, `welcome_screen.dart:88-91`, `widget_layout_*.xml` | TB |
| B6 | 16 cỡ chữ (9–48), 12/13/14 dùng lẫn cho cùng vai trò; tiêu đề sheet 15 (9 nơi) vs 16 (6 nơi); section header 11/12/13 | xem `02-design-tokens.md §2` | TB |
| B7 | 15 giá trị radius; nút submit r10 (5 sheet) vs r12 (3 sheet); leading icon box r8/r10/r12/circle | `02 §4`, `03 §16.8-16.9` | TB |
| B8 | Spacing lẫn 2/3/6/10/14/18/22 ngoài lưới 4/8; 30 tổ hợp `fromLTRB` | `02 §3` | thấp |
| B9 | Feature grid 18 màu Tailwind riêng, không thuộc palette/scheme | `home_feature_actions.dart:25-198` | thấp |
| B10 | `navigationBarTheme`, `chipTheme` trong theme gần như không được dùng (nav tự vẽ; chip tự vẽ) | `app_theme.dart:84-106,121-127` | thấp |
| B11 | Chuỗi tiếng Anh giữa app tiếng Việt: splash messages, tên màu chủ đạo, "Slot N", "Backup", "Widget" | `main.dart:80-115`, `app_theme.dart:16-20`, `widget_pin_section.dart:169`, `home_feature_actions.dart:166,149` | thấp |
| B12 | "Huỷ" vs "Hủy" | `settings_screen.dart:494` vs `gdrive_backup_section.dart:135,357` | thấp |

## C. Component trùng chức năng, cài đặt khác nhau

| # | Mô tả | Nơi | Mức |
|---|---|---|---|
| C1 | 14 bản pill chip chọn với pad/radius/font/animation khác nhau | `03-components.md §16.2` | TB |
| C2 | 15 bản drag handle inline; 1 bản màu `grey.shade300`; 1 bản 40px; 2 sheet không có | `03 §16.1` | thấp |
| C3 | 5 progress bar tự vẽ khác nhau dù đã có `AnimatedProgressBar` | `03 §16.6` | thấp |
| C4 | `MonthSelector` vs `StatsTimeSelector`: cùng anatomy, khác picker, khác motion token | `month_selector.dart`, `stats_time_selector.dart` | TB |
| C5 | `MonthPickerSheet` (grid tháng) vs `DateRangePickerSheet` (preset + range) — 2 picker thời gian | | TB |
| C6 | Chọn màu: swatch inline (CategoryForm) vs AlertDialog grid (WalletForm) vs không chọn (LoanForm) | `category_form_sheet.dart:164`, `wallet_form_sheet.dart:93` | TB |
| C7 | Nhập số tiền: numpad (6 form) vs TextField number (ReminderForm) | `reminder_form_sheet.dart:265` | TB |
| C8 | Icon danh mục: `CategoryIconWidget` tròn (2 nơi) vs box vuông r8/r10 tự vẽ (6 nơi) | `03 §7` | TB |
| C9 | Error state: có retry (4 màn) vs `Text('Lỗi: $e')` thô không retry (5 màn) | `03 §16.5` | TB |
| C10 | Loading: skeleton (Home, Wallets, Stats) vs spinner (Reminders, LoanList, LoanDetail, WalletDetail) vs không có (Transactions) | | TB |
| C11 | `_InfoCard` giống hệt ở WalletDetail và LoanDetail | `03 §16.7` | thấp |
| C12 | Nút đóng sheet: X (WalletForm, LoanForm, NotePicker) / không có (AddTransaction, CategoryForm, ReminderForm, Budget…) / Huỷ ngang (SePay) | | TB |
| C13 | Card tổng: gradient `darken→primary` (Home) vs `[primary, primary]` (Wallets) | `summary_card.dart:49`, `wallets_screen.dart:168` | thấp |
| C14 | SePay `_AddMappingSheet` dùng outline r12 + prefixIcon + nút theme M3 mặc định — khác mọi form khác | `sepay_connection_section.dart:293-384` | thấp |
| C15 | Dead code còn trong tree: `AuthScreen`, `GlobalFab`, `BudgetCard`, `LoanMiniCard`, `LoanSettingsTile`, `QuickActionsBar`, `WalletProgressBar` | `00-overview.md §5` | thấp |

## D. Trạng thái thiếu

| # | Màn | Thiếu | Mức |
|---|---|---|---|
| D1 | Transactions | loading (xem A4) | cao |
| D2 | AddTransactionSheet | lỗi lưu; không có category cho loại (nút disabled vĩnh viễn, không hướng dẫn); huỷ có dữ liệu | cao |
| D3 | StartupGate | error | thấp |
| D4 | Wallets, LoanList, Reminders, WalletDetail, LoanDetail | error có retry (chỉ text) | TB |
| D5 | CategoryBudgetScreen | empty khi không có danh mục chi; loading | TB |
| D6 | SePay AddMapping | wallets đang load / không có ví | TB |
| D7 | Settings › Danh mục | loading (hiện "0 danh mục") | thấp |
| D8 | WalletForm/LoanForm/CategoryForm/ReminderForm | validate inline (tên rỗng → im lặng) | TB |
| D9 | Budget/CategoryBudget/AddPayment sheets | lỗi lưu (không try/catch, `_loading` kẹt) | TB |
| D10 | Notification permission bị từ chối | không thông báo | TB |
| D11 | Toàn app | offline indicator / sync status (PowerSync) | thấp `[UNKNOWN: có cần không — ngoài scope UI]` |

## E. Navigation không đồng nhất

| # | Mô tả | Nơi | Mức |
|---|---|---|---|
| E1 | `/transactions` và `/settings` là bản push riêng của tab → mất bottom nav & FAB; state expand/filter không share | `app_router.dart:23-28`, `home_feature_actions.dart:32,152-199` | cao |
| E2 | `/add` `go('/')` sau khi đóng → mất ngữ cảnh (AllFeatures, Transactions) | `app_router.dart:99` | TB |
| E3 | GoRouter cho 10 màn nhưng LoanDetail & NotePicker dùng `Navigator.push` thuần | `loan_list_screen.dart:160`, `add_transaction_sheet.dart:297` | TB |
| E4 | 8/18 ô AllFeatures → `/settings` không anchor | `home_feature_actions.dart:152-199` | TB |
| E5 | Sheet mở sheet (BudgetType → Budget/CategoryBudget; CategoryBudget → Set; TransactionDetail → AddTransaction) → 2 animation liên tiếp | `budget_type_sheet.dart:52-57`, `transaction_detail_sheet.dart:194-203` | thấp |
| E6 | Tab mặc định ở giữa (Home) trong khi tab trái là Transactions | `app_bottom_nav.dart:23-29` | TB |
| E7 | Ba cơ chế "tháng": `selectedMonthProvider` (Home/Tx/Budget), `statsDateRangeProvider` (Stats), `_month` cục bộ (WalletDetail) | | TB |
| E8 | 3 lối "Thêm" trên Home (FAB, grid, route) / 3 lối "Thêm ví" trên Wallets / 3 lối "Thêm loan" trên LoanList | | thấp |
| E9 | Xoá: dialog xác nhận (giao dịch, ví, loan, danh mục, SePay) vs tức thì (reminder, hạn mức danh mục, hạn mức tháng, archive ví, tất toán) | `reminders_screen.dart:765-767`, `category_budget_screen.dart:96-98`, `budget_screen.dart:50-57` | cao |
| E10 | Welcome không back/swipe/indicator; Splash không skip | | thấp |

## F. Accessibility

| # | Mô tả | Nơi | Mức |
|---|---|---|---|
| F1 | Tap-target < 44dp: eye toggle balance 28 (`summary_card.dart:95-108`), eye mini card 24 (`:348-360`), icon 🔍 note 26 (`add_transaction_sheet.dart:561-571`), nút X sheet 24 (`wallet_form_sheet.dart:197-205`, `loan_form_sheet.dart:140-148`), x slot widget 12 (`widget_pin_section.dart:151-159`), x habit 22 (`reminders_screen.dart:240-251`), checkbox ví 24 (`add_transaction_sheet.dart:582-591`), clear due date 16 (`loan_form_sheet.dart:280-287`) | | cao |
| F2 | Nav bar tự vẽ không có `Semantics`/label cho 2 tab không chọn (chỉ icon) | `app_bottom_nav.dart:298-355` | TB |
| F3 | `Icon` không `semanticLabel` ở IconButton không tooltip: search/close (`transactions_screen.dart:96-105`), pencil/more_vert (WalletDetail, LoanDetail), add (Wallets/Loans/Reminders) | | TB |
| F4 | Contrast thấp: text `outlineVariant` làm nội dung ('Chưa đặt hạn mức' `category_budget_screen.dart:319`, 'Đã lưu trữ' `wallets_screen.dart:462`, 'Đã tất toán' `loan_list_screen.dart:218`); tên ví màu palette nhạt (`#FFEAA7`, `#FFD3B6`) trên nền trắng (`wallet_card_home.dart:191-197`) | | TB |
| F5 | Aurora + nav pill + splash + welcome không respect reduce-motion; carousel ví có respect | `aurora_theme_background.dart`, `app_bottom_nav.dart:240-268` | thấp |
| F6 | Chữ 9–10px cho thông tin (%, "Đã dùng", tên slot, badge) | `add_transaction_sheet.dart:885`, `summary_card.dart:234`, `widget_pin_section.dart:139` | TB |
| F7 | Emoji làm icon trạng thái/dialog ('⚠️', '🔴', '✅', '❌') — đọc bởi screen reader không nhất quán, không đổi màu theo theme | `add_transaction_sheet.dart:198,919`, `loan_detail_screen.dart:332`, snackbar Settings | thấp |
| F8 | Form sheet không cuộn (`CategoryFormSheet`, `AddTransactionSheet`, `TransactionDetailSheet`) → tràn ở landscape / màn thấp / font lớn | `category_form_sheet.dart:113`, `add_transaction_sheet.dart:368` | TB |
| F9 | Không dùng `textTheme` → text scale hệ thống áp dụng nhưng layout cố định (chip h36/48, nav 80) có thể cắt | toàn app | thấp |
