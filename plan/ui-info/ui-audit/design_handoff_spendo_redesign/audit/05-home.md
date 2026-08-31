# 05 — Home (Trang chủ)

## A. Metadata
- **Tên**: `HomeScreen`
- **Route**: không có route riêng; tab index 1 (mặc định) trong `AppShell` (`app_bottom_nav.dart:27`)
- **File**: `lib/features/home/presentation/screens/home_screen.dart` (185 LOC) + `widgets/summary_card.dart` (365), `wallets/…/wallet_card_home.dart` (259), `widgets/feature_grid.dart` (89), `widgets/home_feature_actions.dart` (228), `widgets/month_selector.dart` (133), `transactions/…/grouped_transaction_sliver.dart` (189)
- **Vào từ**: AppShell mặc định; `context.go('/')` sau `/add`
- **Thoát đi**: `/reminders`, `/wallets`, `/add`, `/transactions`, `/loans`, `/stats`, `/features`, sheet BudgetType, sheet TransactionDetail, sheet MonthPicker, sheet WalletForm

## B. Mục đích
Tổng quan tháng đang chọn: số dư ròng tháng, thu/chi, ví, lối tắt tính năng, và danh sách giao dịch tháng.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar bg #F5F5F5, elevation 0, centerTitle
│   ‹  [Tháng 8/2026 ▾]  ›  [🔔]│ MonthSelector (title) + IconButton notifications_none_outlined  :33-59
├───────────────────────────────┤ CustomScrollView
│ (8)                           │
│ ╔═══════════════════════════╗ │ Balance card: margin H16, pad H20 V14, gradient primary, r16  summary_card:43-54
│ ║ Số dư 12 white70      [👁]║ │
│ ║ •••••• 24 w700            ║ │ AnimatedMoneyText mask '••••••' mặc định ẩn                :79-89
│ ║ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 5px   ║ │ _WalletProgressBar (x2/x1 toàn ví), label chỉ khi visible :114-130
│ ╚═══════════════════════════╝ │
│ (10)                          │
│ ┌ ↓ Thu nhập ····· 👁 ┐┌ ↑ Chi tiêu ····· 👁 ┐  2 _MiniCard, gap 10, pad H14 V10, r12, border 0.5 :138-161
│ └──────────────────────┘└──────────────────────┘
│ (12)                          │
│ ┌ [wallet] ● Tên ví   30.000.000 ₫  › ┐  WalletCardHome: border outlineVariant .8, r12, carousel h38 autoplay 3s
│ └──────────────────────────────────┘
│ (12)                          │
│  (⊕)    (🧾)    (👛)    (◎)   │ FeatureGrid 4 cột, tile 102, icon circle 56 α.12, icon 26  feature_grid:26-36
│  Thêm  Giao dịch  Ví  Hạn mức │ label 12 w600 h1.15, 2 dòng max
│  (🤝)    (🔔)    (◔)    (…)   │
│ Vay nợ Nhắc nhở Thống kê Xem thêm
│ (14)                          │
│ Hôm nay              -85.000 ₫│ _DayHeader plain: pad (16,12,16,4), 12 w600 onSurfaceVariant + net 12 w500 màu
│ ───────────────────────────── │ Divider indent 16
│ (◯) Ăn uống        -85.000 ₫  │ TransactionListItem: pad H16 V10, icon 40, tên 14 w500, note/giờ 12 grey, số 14 w600
│     An trua                   │
│ Hôm qua              -45.000 ₫│
│ …                             │
│ (80 spacer)             (+)   │ FAB từ AppShell
└───────────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `AppBar` | header | top | 56 (mặc định) | | `appBarTheme`: bg `#F5F5F5`/`#111111`, elev 0, centerTitle | | | `home_screen.dart:33` |
| 2 | `MonthSelector` | title Row | center | auto | | `IconButton chevron_left` compact; label `Container` pad H8 V4 r8 bg `primary` α.06: `formatMonthYear` 15 w600 + `arrow_drop_down` 18; `IconButton chevron_right` (disabled `grey.shade300` khi tháng hiện tại); chip "Hôm nay" 11 w600 primary, bg α.1, border α.3 .8, r20, chỉ khi ≠ tháng hiện tại (AnimatedSwitcher 200ms fade+size) | `selectedMonthProvider` | ‹ › đổi tháng; tap label → `MonthPickerSheet`; "Hôm nay" → tháng hiện tại | `month_selector.dart:36-131` |
| 3 | `IconButton notifications_none_outlined` | action | phải | 48 tap | | tooltip 'Nhắc nhở' | | `context.push('/reminders')` | `:54-58` |
| 4 | Balance card | Container | body #1 | width full−32, h auto | margin H16; pad H20 V14; wrapper pad T8 B12 | gradient `[darken(primary,.22)→primary]` TL→BR; r16 | | — | `summary_card.dart:43-133` |
| 4a | "Số dư" | Text | | | | 12 `white70` | hằng | | `:64-67` |
| 4b | Số dư | `AnimatedMoneyText` trong `ShaderMask` | | | 2 dưới label | 24 w700 white ls−.5; mask trắng→trắng α.75 | `summary.balance` (= income − expense **tháng**); `privacyMask '••••••'` khi `!_balanceVisible` (mặc định **ẩn**) | | `:69-90` |
| 4c | Eye toggle | GestureDetector | phải card | icon 20, pad 4 → tap ~28 | | `visibility_outlined/off` white70 | `_balanceVisible` | toggle (không lưu) | `:95-109` |
| 4d | `_WalletProgressBar` | Column | dưới, +10 | h5 bar; labels 10 | | track white α.2; bar white70 hoặc `redAccent` nếu x2>x1; labels "Đã dùng …" / "/ …" white60 chỉ khi visible; ẩn hoàn toàn nếu x1==x2==0 (thay bằng SizedBox 8) | `totalWalletBreakdownProvider` (x1 = initial+income **mọi thời gian**, x2 = expense) | | `:114-130, 169-252` |
| 5 | `_MiniCard` ×2 | Container | body #2 | Expanded, gap 10 | pad H14 V10; wrapper H16 | bg `cs.surface`, r12, border `color` α.2 w.5; icon circle pad 6 bg α.15 icon 14; label 11 onSurfaceVariant; số 13 w600 `color` ellipsis; eye 16 pad 4 | Thu nhập: `summary.income` `incomeColor` `arrow_downward_rounded`; Chi tiêu: `summary.expense` `expenseAltColor` `arrow_upward_rounded`; mỗi card có `_visible` riêng mặc định ẩn | toggle riêng | `:138-161, 282-365` |
| 6 | `WalletCardHome` | Container | body #3 | h ≈ 62 (38 + 24) | margin H16; pad H16 V12; wrapper B12 | border `outlineVariant` .8, r12, **không nền** | `walletsProvider` | tap → `/wallets` | `wallet_card_home.dart:121-154` |
| 6a | Icon wallet | Lucide | trái | 18 | 10 phải | onSurfaceVariant | | | `:135` |
| 6b | `PageView` chip | carousel | giữa | h38 | | `_WalletChip`: dot 8 màu ví, 8, tên 13 w600 màu ví ellipsis, 8, balance 12 w500 (đỏ nếu âm) / spinner 12 | `wallets[i]`, `walletBalanceProvider(id)`; autoplay 3s/400ms easeInOut nếu >1 ví, dừng khi reduce motion hoặc tab ẩn | swipe đổi trang (không dừng autoplay) | `:138-147, 162-226` |
| 6c | chevron_right | Icon | phải | 16 | 8 trái | onSurfaceVariant | | | `:150` |
| 7 | `FeatureGrid` | GridView | body #4 | 4 cột, `mainAxisExtent 102`, spacing 10/6, `shrinkWrap`, không scroll | pad (16,0,16,14) | `_FeatureTile`: `PressableScale` r12; circle 56 bg `action.color` α.12, icon 26 `action.color`; 10; label 12 w600 h1.15 center 2 dòng ellipsis | 8 action (`buildHomeFeatureActions`) | tap | `feature_grid.dart`, `home_feature_actions.dart:20-71` |
| 8 | Skeleton | `SliverList` 4× `SkeletonTransactionItem` | body #5 (loading) | mỗi item pad H16 V10: block 42×42, 12, [120×14, 8, 72×12], 86×14 | | pulse 1100ms `surfaceContainerHighest` α .55↔.9 r8 | `transactionsProvider.loading` | | `home_screen.dart:172-185`, `skeleton_transaction_item.dart` |
| 9 | Error block | `_HomeTransactionLoadError` | body #5 | Center pad H16 V24 | | `circleAlert` 32 `cs.error`, 8, "Không thể tải giao dịch" onSurfaceVariant, 8, `OutlinedButton('Thử lại')` | `.error` | retry → `ref.invalidate(transactionsProvider)` | `:142-170` |
| 10 | Empty | `SliverFillRemaining(Center)` | body #5 | | | `receiptText` 48 `outlineVariant`, 12, "Chưa có giao dịch nào" onSurfaceVariant, 4, "Tap + để thêm" 12 | `txs.isEmpty` | | `:100-128` |
| 11 | `GroupedTransactionSliver(style: plain)` | SliverList | body #5 | | | `_DayHeader` pad (16,12,16,4) + `Divider` indent/endIndent 16; rows `MotionListItem` stagger 30ms×index(≤6) fade+translate y10 | `txs`, `categoryMap` | row tap → `TransactionDetailSheet` | `:129-132`, `grouped_transaction_sliver.dart` |
| 12 | Spacer | `SizedBox(80)` | cuối | | | | | | `:135` |

Feature grid nội dung (`home_feature_actions.dart:22-70`):
| Ô | Label | Icon | Màu | Đích |
|---|---|---|---|---|
| 1 | Thêm | `circlePlus` | `#16A34A` | `push('/add')` |
| 2 | Giao dịch | `receiptText` | `#2563EB` | `push('/transactions')` |
| 3 | Ví | `wallet` | `#0EA5E9` | `push('/wallets')` |
| 4 | Hạn mức | `target` | `#F59E0B` | sheet `BudgetTypeSheet` |
| 5 | Vay nợ | `handCoins` | `#DC2626` | `push('/loans')` |
| 6 | Nhắc nhở | `bellRing` | `#DB2777` | `push('/reminders')` |
| 7 | Thống kê | `chartPie` | `#7C3AED` | `push('/stats')` |
| 8 | Xem thêm | `ellipsis` | `#7A869A` | `push('/features')` |

## E. Vùng bố cục
- **Header**: AppBar 56 cố định; title là widget tương tác (MonthSelector) chiếm ~220px giữa.
- **Body**: `CustomScrollView` một trục; 4 khối cố định (card, mini cards, wallet, grid ≈ 100+64+62+230 = ~460px) nằm **trước** danh sách → trên màn 640px logic, list giao dịch bắt đầu dưới fold.
- **Footer**: bottom nav từ shell; list chừa 80.
- **Floating**: FAB từ shell.
- Không pull-to-refresh, không sticky header.

## F. Trạng thái màn hình
| State | Điều kiện | Cái gì hiện/ẩn |
|---|---|---|
| Initial | mount | tháng hiện tại; số dư/thu/chi **ẩn** (`••••••`); wallet card ẩn nếu `walletsProvider` loading (`SizedBox.shrink` `wallet_card_home.dart:73`) |
| Loading tx | `transactionsProvider` loading | 4 skeleton row; summary card vẫn hiện với giá trị 0 (summaryProvider trả 0 khi `valueOrNull` null) |
| Empty tx | `txs.isEmpty` | `SliverFillRemaining` empty state chiếm phần còn lại |
| Error tx | stream error | block lỗi + Thử lại; summary = 0 |
| Wallet empty | `wallets.isEmpty` | CTA "Thêm nguồn tiền để theo dõi số dư" (tap → `WalletFormSheet`) |
| Wallet error | | "Không thể tải nguồn tiền" + TextButton Thử lại |
| Wallet balance loading | per chip | spinner 12 |
| Breakdown 0/0 | | progress bar ẩn |
| Overflow ví (x2 > x1) | | bar `redAccent`, track red α.3 |
| Offline | không có xử lý riêng (PowerSync local-first) | |
| Tháng khác hiện tại | | chip "Hôm nay" xuất hiện, `›` enable |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| `‹` | `selectedMonthProvider = month−1` | reload toàn bộ providers theo tháng | — |
| `›` (disabled ở tháng hiện tại) | month+1 | | — |
| Tap label tháng | `showModalBottomSheet<DateTime>(MonthPickerSheet)` | | sheet |
| Tap "Hôm nay" | set tháng hiện tại | chip biến mất | — |
| Tap 🔔 | | | push `/reminders` |
| Tap 👁 balance / thu / chi | toggle mask riêng từng ô | số hiện/ẩn; label progress hiện/ẩn theo balance | — |
| Tap WalletCardHome | | | push `/wallets` (hoặc sheet WalletForm nếu rỗng) |
| Swipe carousel ví | đổi `_currentPage` | | — |
| Tap ô grid | xem bảng | | push/sheet |
| Tap row giao dịch | `showModalBottomSheet(TransactionDetailSheet)` | | sheet |
| Scroll | CustomScrollView | | |
| Pull-to-refresh / long-press / swipe row | **không có** | | |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Số tiền (balance, thu, chi, day net **không**) | `AnimatedMoneyText` tween | 360ms | easeOutCubic (tắt khi mask) |
| Chip "Hôm nay" | AnimatedSwitcher fade+SizeTransition ngang | 200ms | mặc định |
| Carousel ví | `animateToPage` mỗi 3s | 400ms | easeInOut |
| Feature tile / row | `PressableScale` 0.96 | 100/140ms | easeOutCubic |
| Row list | `MotionListItem` opacity 0→1 + translate y10→0, delay 30ms×index (max 6) | 260ms(+delay) | easeOutCubic |
| Skeleton | pulse | 1100ms reverse | — |
| Đổi tháng | **không** transition (list thay tức thì; rows re-animate) | | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null/rỗng/dài |
|---|---|---|---|
| Tháng | `selectedMonthProvider` | `'Tháng M/YYYY'` (`date_helpers.dart:1-3`) | — |
| Số dư | `summaryProvider.balance` = Σincome − Σexpense của tháng | `formatVND(round)` → `1.234.567 ₫`; âm hiện `-1.234 ₫` (không đổi màu) | 0 khi loading; mask `••••••` |
| Thu / Chi | `summaryProvider.income/expense` | `formatVND` | ellipsis nếu dài |
| Progress x1/x2 | `totalWalletBreakdownProvider` (toàn thời gian, tất cả ví active) | `'Đã dùng ' + formatVND(x2)` / `'/ ' + formatVND(x1)` | ẩn nếu 0/0 |
| Tên ví / số dư ví | `walletsProvider`, `walletBalanceProvider(id)` | 13 ellipsis / `formatVND` | balance error → shrink |
| Day header | `formatDayHeader` → `Hôm nay` / `Hôm qua` / `d/M/yyyy` | net `+/-formatVND(abs)` màu income/expenseAlt | |
| Row: tên danh mục | `categoryMap[categoryId]?.name` | 14 w500 | `'Không rõ'` nếu category không tồn tại |
| Row: phụ | `note` nếu có, else `formatTime(createdAt)` `HH:mm` | 12 `grey.shade500`/`400` 1 dòng ellipsis | |
| Row: số tiền | `'-'/'+' + formatVND(amount)` | 14 w600 `expenseColor #F06292` / `incomeColor` | không ellipsis → tên dài đẩy số |
| Badge SePay | `transaction.isAutomatic` | dot 14 `#1E88E5` + `bolt` 8 góc dưới phải icon | |

## J. Responsive & edge cases
- Màn thấp: list dưới fold; empty state `SliverFillRemaining` có thể chỉ còn vài chục px → icon 48 + 2 dòng text bị cắt/scroll.
- Số dư rất lớn (10 chữ số + ₫) ở 24px trong card width−72: vừa; mini card 13px với eye 16 + icon 26: có ellipsis.
- Tên ví dài: ellipsis; balance ví không ellipsis.
- Tên danh mục dài trong row: đẩy số tiền sang phải nhưng số không wrap (Row không Expanded cho số) → có thể overflow nếu tên quá dài `[UNKNOWN: chưa kiểm chứng render]`.
- Keyboard: không có input.
- Landscape: grid 4 cột giãn rộng; card gradient rất rộng.
- Danh sách rất dài: SliverList lazy, OK.

## K. Text hiển thị
`Tháng M/YYYY` · `Hôm nay` (chip) · `Nhắc nhở` (tooltip) · `Số dư` · `••••••` · `Đã dùng X ₫` · `/ Y ₫` · `Thu nhập` · `Chi tiêu` · `Thêm nguồn tiền để theo dõi số dư` · `Không thể tải nguồn tiền` · `Thử lại` · `Thêm` · `Giao dịch` · `Ví` · `Hạn mức` · `Vay nợ` · `Nhắc nhở` · `Thống kê` · `Xem thêm` · `Chưa có giao dịch nào` · `Tap + để thêm` · `Không thể tải giao dịch` · `Hôm nay` / `Hôm qua` / `d/M/yyyy` (day header) · `Không rõ` (category thiếu)

## L. Nhận xét nhanh
- "Số dư" là **ròng tháng** (thu − chi) nhưng thanh progress ngay dưới là **tổng ví mọi thời gian** — hai con số khác bản chất trong cùng card, không nhãn phân biệt.
- 3 nút mắt độc lập, mặc định ẩn hết, không lưu → mỗi lần mở app phải bấm 3 lần để xem số.
- ~460px nội dung tĩnh phía trên đẩy danh sách giao dịch (nội dung thay đổi hằng ngày) xuống dưới fold; grid 8 ô trùng 3 lối vào với bottom nav/FAB (Thêm, Giao dịch).
- Feature grid 8 màu icon riêng biệt (Tailwind) không thuộc scheme; ô "Xem thêm" dẫn tới AllFeatures gần như lặp lại grid này.
- Carousel ví tự chạy 3s, không có indicator, tên ví màu ví trên nền không có → dễ thấp contrast với màu palette nhạt (`#FFEAA7`, `#FFD3B6`).
