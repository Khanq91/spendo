# 06 — Transactions (Giao dịch)

## A. Metadata
- **Tên**: `TransactionsScreen`
- **Route**: tab index 0 trong `AppShell` **và** route push `/transactions` (`app_router.dart:23-26`) — 2 instance độc lập, cùng share `selectedMonthProvider`, `selectedCategoryFilterProvider`, `searchQueryProvider` (global StateProvider)
- **File**: `lib/features/transactions/presentation/screens/transactions_screen.dart` (364 LOC)
- **Vào từ**: bottom nav tab 0; Home grid "Giao dịch"; AllFeatures "Giao dịch"
- **Thoát đi**: sheet TransactionDetail, sheet MonthPicker; (bản push) back

## B. Mục đích
Xem danh sách giao dịch theo tháng, lọc theo 1 danh mục, tìm theo note/số tiền; mở chi tiết từng giao dịch.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar centerTitle
│   ‹ [Tháng 8/2026 ▾] ›   [🔍]│ title = AnimatedSwitcher(MonthSelector | TextField 'Tìm kiếm...')  :51-94
├───────────────────────────────┤
│ (Tất cả)(Ăn uống)(Di chuyển)…→│ _CategoryFilterBar h48, ListView ngang pad H16, chip gap 6   :186-226
│ 3 giao dịch   +18.000.000 ₫ -130.000 ₫│ _MiniSummaryRow pad (16,6,16,8), 12                     :282-326
│ ───────────────────────────── │ Divider h1
│▓ Hôm nay              -85.000 ₫▓│ _DayHeader filledHeader: bg surfaceContainerHighest, pad (16,8,16,6)
│ (◯) Ăn uống        -85.000 ₫  │ TransactionListItem + Divider indent 68 endIndent 16
│     An trua                   │
│▓ Hôm qua              -45.000 ₫▓│
│ …                             │
│ (80)                    (+)   │ FAB từ shell (chỉ bản tab)
└───────────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `AppBar.title` `AnimatedSwitcher` | switcher | header | | | 420ms `screenDuration`, curve standard | `_showSearch` | | `:51-94` |
| 1a | `MonthSelector` | (như Home) | | | | key `transaction_month_title` | `selectedMonthProvider` | ‹ › / picker / Hôm nay | `:76-93` |
| 1b | `TextField` search | input | | full title width | | `autofocus`, style `cs.onSurface`, hint 'Tìm kiếm...' 15 onSurfaceVariant, `InputBorder.none`; key `transaction_search_title` | `_searchCtrl` → `searchQueryProvider` onChanged | gõ → filter realtime | `:60-75` |
| 2 | `IconButton` search/close | action | phải | 48 | | `Icons.search_outlined` ↔ `Icons.close` | `_showSearch` | toggle; đóng → clear query | `:96-105` |
| 3 | `_CategoryFilterBar` | `SizedBox(48, ListView horizontal)` | body #1 | h48 | pad H16; chip gap 6 | | `categoriesProvider` (cả thu **và** chi, thứ tự DB) | | `:186-226` |
| 3a | `_FilterChip` "Tất cả" + mỗi category | `PressableScale > SizedBox(48) > Center > AnimatedContainer` | | h ≈ 24 (pad H12 V4) trong tap-box 48 | | bg `c` α.12 khi chọn / transparent; border `c` / `outlineVariant` .8; r20; label 12 w600/w400 `c` / onSurfaceVariant; `c = cat.color ?? cs.primary` | `selectedCategoryFilterProvider` | tap: chọn / bỏ chọn (toggle) | `:228-278` |
| 4 | `_MiniSummaryRow` | Row | body #2 | | pad (16,6,16,8) | "N giao dịch" 12 onSurfaceVariant · Spacer · `AnimatedMoneyText '+…'` 12 w500 income · 10 · `'-…'` expenseAlt | tính từ `txs` đã lọc | | `:282-326`; ẩn khi lỗi ban đầu `:118` |
| 5 | `Divider(height 1)` | | | | | theme | | | `:119` |
| 6 | `Expanded(AnimatedSwitcher)` | body #3 | | | | 420ms | 3 nhánh: error / empty / list (key riêng) | | `:120-151` |
| 6a | `_TransactionLoadError` | Center Column | | | | `circleAlert` 48 error, 12, "Không thể tải giao dịch", 8, `OutlinedButton Thử lại` | `hasError && !hasValue` | retry invalidate | `:158-182` |
| 6b | `_EmptyState` | Center Column | | | | icon `searchX`/`receiptText` 48 outlineVariant; text; "Tap + để thêm" chỉ khi không filter | `hasFilter = selectedCat != null \|\| _showSearch` | | `:330-364` |
| 6c | `CustomScrollView[GroupedTransactionSliver(filledHeader), SizedBox 80]` | | | | | header bg `surfaceContainerHighest`; row + `Divider(h1, indent 68, endIndent 16)` | `filteredTransactionsProvider` | row tap → detail | `:139-149` |

## E. Vùng bố cục
- Header AppBar 56 (title đổi thành search field, không có back vì trong shell; bản push có back tự động).
- Body `Column[filter 48, summary ~26, divider, Expanded list]` — filter và summary **không cuộn theo** (cố định).
- Footer nav + FAB (chỉ bản tab). Bản push `/transactions` **không có FAB** → không thêm được giao dịch từ đây.

## F. Trạng thái màn hình
| State | Điều kiện | UI |
|---|---|---|
| Initial | | tháng hiện tại, "Tất cả" chọn, search ẩn |
| Loading | `transactionsProvider` loading | **không có skeleton**: `filteredTransactionsProvider` trả `[]` → hiện Empty "Chưa có giao dịch nào / Tap + để thêm" trong lúc load (`transaction_provider.dart:32`) |
| Empty (không filter) | `txs.isEmpty` | receiptText + "Chưa có giao dịch nào" + "Tap + để thêm" |
| Empty (có filter/search) | | searchX + "Không tìm thấy giao dịch nào" |
| Error ban đầu | `hasError && !hasValue` | ẩn summary row; block lỗi + Thử lại |
| Error sau khi đã có data | | giữ list cũ (không báo) |
| Search mở | `_showSearch` | title thành TextField autofocus, icon → close; empty state coi là "có filter" ngay cả khi query rỗng |
| Category filter | | chip đổi màu theo `cat.color`; count & summary tính lại |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| 🔍 | `_showSearch = !` ; nếu đóng: clear ctrl + provider | title switch 420ms; keyboard | — |
| Gõ search | `searchQueryProvider = v` | list lọc realtime theo `note.contains` hoặc `amount.toString().contains` (`transaction_provider.dart:38-40`) | — |
| Tap chip | set/unset `selectedCategoryFilterProvider` | AnimatedContainer 140ms | — |
| ‹ › / label / Hôm nay | như Home (provider chung) | | sheet MonthPicker |
| Tap row | | | sheet TransactionDetail |
| Swipe row / long-press / pull-refresh / multi-select | **không có** | | |
| Back (bản push) | pop | | về màn trước; **filter/search state vẫn giữ** trong provider global → tab Transactions cũng bị lọc |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Title Month ↔ Search | AnimatedSwitcher fade | 420ms | easeOutCubic |
| List ↔ empty ↔ error | AnimatedSwitcher fade | 420ms | easeOutCubic |
| Chip | AnimatedContainer | 140ms | easeOutCubic |
| Summary số | AnimatedMoneyText | 360ms | |
| Rows | MotionListItem stagger | 260ms+ | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null |
|---|---|---|---|
| Chip label | `cat.name` (cả income & expense) | 12 | |
| "N giao dịch" | `txs.length` sau lọc | | 0 |
| Thu/Chi mini | Σ theo lọc | `+/-formatVND` | 0 |
| Day header / row | như Home (style filledHeader) | | |
| Search hint | hằng | | |

## J. Responsive & edge cases
- Nhiều category (>6): chip bar scroll ngang, không gợi ý có thêm (không fade edge).
- Search field trong AppBar title: width bị giới hạn bởi `centerTitle` + actions; text dài cuộn trong field.
- Query chỉ khớp note/amount, không khớp tên danh mục.
- Keyboard mở đè lên list phần dưới (Column không scroll phần filter) — list `Expanded` co lại, OK.
- Landscape: filter 48 + summary + AppBar chiếm ~130px.

## K. Text hiển thị
`Tháng M/YYYY` · `Hôm nay` · `Tìm kiếm...` · `Tất cả` · `<tên danh mục>` · `N giao dịch` · `+X ₫` · `-Y ₫` · `Hôm nay`/`Hôm qua`/`d/M/yyyy` · `Không rõ` · `Không thể tải giao dịch` · `Thử lại` · `Không tìm thấy giao dịch nào` · `Chưa có giao dịch nào` · `Tap + để thêm`

## L. Nhận xét nhanh
- Không có loading state riêng: trong lúc stream chưa emit, màn hiện "Chưa có giao dịch nào" (sai thông tin tạm thời).
- Filter/search là **state toàn cục** không reset khi rời màn → tab Transactions và Home dùng chung tháng, nhưng bản push `/transactions` để lại filter khi quay về.
- Chip filter trộn danh mục thu & chi trong một hàng, không nhóm, không nhãn loại; không lọc theo loại thu/chi, ví, khoảng ngày.
- Bản push `/transactions` mất FAB và bottom nav — cùng màn nhưng khả năng khác nhau tuỳ đường vào.
