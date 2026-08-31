# 13 — WalletDetail (Chi tiết nguồn tiền)

## A. Metadata
- **Tên**: `WalletDetailScreen(walletId)`
- **Route**: `/wallets/:id` (`app_router.dart:45-49`)
- **File**: `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (568 LOC)
- **Vào từ**: tap tile ở Wallets
- **Thoát đi**: back; sheet `WalletFormSheet(existing)`; PopupMenu → archive (pop) / delete (dialog → pop); sheet MonthPicker; sheet TransactionDetail

## B. Mục đích
Xem số dư, mức sử dụng, và giao dịch của 1 ví (theo tháng hoặc toàn bộ); sửa/lưu trữ/xoá ví.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back · <tên ví> 16 w600 · [✎ 18] [⋮ 20]
├───────────────────────────────┤ CustomScrollView
│ ┌ [▢] Ngân hàng             ┐ │ _InfoCard margin (16,16,16,12) pad 16 bg color α.05 border α.3 r16
│ │     note (nếu có)         │ │ icon box 44 r12 α.15 icon 22 (circleEllipsis!); type.label 12; note 12
│ │ ───────────────────────── │ │ Divider
│ │ Số dư hiện tại 12         │ │
│ │ 30.000.000 ₫ 22 w700 màu ví│ │ AnimatedMoneyText (đỏ nếu âm)
│ │ Ban đầu: 20.000.000 ₫ 11  │ │
│ │ ▬▬▬▬▬▬▬▬ 6px + labels 10  │ │ _LightProgressBar (AnimatedProgressBar) màu ví / red.shade400
│ └───────────────────────────┘ │
│ (Theo tháng)(Tất cả)          │ _FilterBar pad H16 V8: 2 _FilterChip
│    ‹ [Tháng 8/2026 ▾] ›       │ MonthSelector (state cục bộ _month) chỉ khi Theo tháng
│ 3 giao dịch  +… -…            │ _MiniSummary pad (16,0,16,8) chỉ khi Theo tháng
│ ───────────────────────────── │ Divider
│ Hôm nay             -85.000 ₫ │ GroupedTransactionSliver plain
│ (◯) Ăn uống        -85.000 ₫  │
│ (80)                          │
└───────────────────────────────┘ (không FAB)
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AppBar | | | | | title `wallet.name` 16 w600; `IconButton(pencil 18)`; `PopupMenuButton(more_vert 20)` items: 'Lưu trữ'/'Bỏ lưu trữ', 'Xoá' (đỏ) | | ✎ → `WalletFormSheet(existing)`; menu | `:66-95` |
| 2 | Fallback | `Scaffold(AppBar(), Center(CircularProgressIndicator))` | | | | | `wallet == null` (đang load hoặc **đã xoá**) | | `:41-46` |
| 3 | `_InfoCard` | Container | sliver #1 | | margin (16,16,16,12); pad 16 | bg `color` α.05, border α.3 .8, r16 | | | `:232-345` |
| 3a | Icon box | Container 44 r12 | | | 12 phải | bg α.15; icon `categoryIcon(type.iconName)` 22 (**circleEllipsis**) | | | `:261-273` |
| 3b | `type.label` / note | Text | | | | 12 onSurfaceVariant ×2 | note chỉ khi non-empty | | `:279-294` |
| 3c | Divider | | | | 16 trên, 12 dưới | | | | `:300` |
| 3d | 'Số dư hiện tại' | Text 12 onSurfaceVariant | | | | | | | `:302-305` |
| 3e | Balance | `AnimatedMoneyText` | | | 4 | 22 w700 ls−.5 `color` / expenseAlt | `walletBalanceProvider`; loading `'...'`; error shrink | | `:307-323` |
| 3f | 'Ban đầu: X' | Text 11 onSurfaceVariant | | | | | `wallet.initialBalance` | | `:324-327` |
| 3g | `_LightProgressBar` | Column | | h6 + labels 10 | 12 trên | `AnimatedProgressBar` track color α.12 / red α.15; value `color` / `red.shade400`; r4; semantic 'Mức sử dụng nguồn tiền'; labels 10 onSurfaceVariant | `walletBreakdownProvider(id)`; ẩn 0/0 | | `:330-340, 348-397` |
| 4 | `_FilterBar` | Padding H16 V8 Column | sliver #2 | | | Row 2 `_FilterChip` (PressableScale > AnimatedContainer pad H12 V6 r20; bg primary α.12 / transparent; border primary / outlineVariant .8; 12 w600/w400) gap 8; nếu byMonth: 8 + `MonthSelector` | `_filter`, `_month` (state cục bộ, **không** dùng `selectedMonthProvider`) | chip tap; ‹ › / picker | `:401-494` |
| 5 | `_MiniSummary` | Row | sliver #3 (byMonth) | pad (16,0,16,8) | | `'N giao dịch'` 12; `+X` income; `-Y` expenseAlt 12 w500 (**Text thường**, không Animated) | `txs` | | `:498-540` |
| 6 | Divider h1 | | | | | | | | `:121` |
| 7 | Tx list | loading: `Padding(32) Center spinner`; error: `Center(Text('Lỗi: $e'))`; empty: `_EmptyTx` (receiptText 40, text 13, pad V48); data: `GroupedTransactionSliver(plain)` | | | | | `walletTxByMonthProvider` / `walletTxAllProvider` | row → TransactionDetailSheet | `:122-142, 544-568` |
| 8 | Spacer 80 | | | | | | | | `:143` |
| 9 | Dialog xoá | AlertDialog | | | | 'Xoá nguồn tiền?' / `'Xoá "<name>"? Hành động không thể hoàn tác.'` / Huỷ / Xoá đỏ | | | `:198-220` |
| 10 | SnackBar chặn xoá | | | | | bg expenseAlt: `'Ví còn N giao dịch. Hãy lưu trữ ví thay vì xoá.'` | `transactionCount > 0` | | `:186-196` |

## E. Vùng bố cục
Header 56; toàn body cuộn (card + filter + list trong CustomScrollView); không footer.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Wallet chưa load | AppBar trống + spinner giữa (không tiêu đề) |
| Wallet không tồn tại (đã xoá từ nơi khác) | **spinner vĩnh viễn** (cùng nhánh) |
| Balance loading | `'...'` |
| Tx loading | spinner pad 32 |
| Tx empty byMonth | 'Không có giao dịch trong tháng này' |
| Tx empty all | 'Chưa có giao dịch nào' |
| Tx error | `Lỗi: …` thô |
| Archived wallet mở từ… | không có lối vào (Wallets chỉ push từ tile active) nhưng menu có 'Bỏ lưu trữ' |
| Overflow | bar đỏ |
| Xoá bị chặn | SnackBar đỏ |

## G. Tương tác
| Trigger | Hành động | Kết quả | Điều hướng |
|---|---|---|---|
| ✎ | | | sheet WalletForm(existing) |
| ⋮ → Lưu trữ | `archive` không xác nhận → pop | về Wallets | pop |
| ⋮ → Bỏ lưu trữ | `unarchive` | ở lại | |
| ⋮ → Xoá | count tx → chặn (snackbar) hoặc dialog → delete → pop | | pop |
| Chip Theo tháng/Tất cả | `_filter` | MonthSelector + mini summary hiện/ẩn; provider đổi | |
| ‹ › / label / Hôm nay | `_month` cục bộ | | sheet MonthPicker |
| Row | | | sheet TransactionDetail |
| Không có: thêm giao dịch cho ví này, chuyển tiền giữa ví | | | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Balance | AnimatedMoneyText | 360ms |
| Progress | AnimatedProgressBar | 360ms |
| Chip | AnimatedContainer | 140ms |
| List ↔ empty | không (sliver thay tức thì) | |
| Rows | MotionListItem | 260ms+ |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null |
|---|---|---|---|
| Tiêu đề | `wallet.name` | | |
| Loại / note | `type.label`, `note` | 12 | note ẩn |
| Số dư | `walletBalanceProvider` | `formatVND` | `...` |
| Ban đầu | `initialBalance` | `'Ban đầu: ' + formatVND` | 0 → "Ban đầu: 0 ₫" |
| Progress | x1 = initial + income, x2 = expense | labels | |
| Mini summary | Σ tx tháng | | |

## J. Responsive & edge cases
- Note ví dài: Text không maxLines → card cao.
- Tháng cục bộ khởi tạo = tháng hiện tại, không đồng bộ với Home.
- Landscape: card ~200px + filter ~110 → list dưới fold.

## K. Text hiển thị
`<tên ví>` · `Lưu trữ` · `Bỏ lưu trữ` · `Xoá` · `<type.label>` · `Số dư hiện tại` · `...` · `Ban đầu: X ₫` · `Đã dùng X ₫` · `/ Y ₫` · `Mức sử dụng nguồn tiền` (semantic) · `Theo tháng` · `Tất cả` · `Tháng M/YYYY` · `Hôm nay` · `N giao dịch` · `Không có giao dịch trong tháng này` · `Chưa có giao dịch nào` · `Lỗi: …` · `Xoá nguồn tiền?` · `Xoá "X"? Hành động không thể hoàn tác.` · `Huỷ` · `Ví còn N giao dịch. Hãy lưu trữ ví thay vì xoá.`

## L. Nhận xét nhanh
- Ví bị xoá/không tồn tại → spinner vô hạn không thông báo.
- Tháng ở đây là state cục bộ thứ 3 (Home/Transactions dùng provider, Stats dùng provider khác, WalletDetail dùng local).
- Lưu trữ không xác nhận và pop ngay; Xoá thì có dialog — hai hành động cùng menu, mức bảo vệ khác nhau.
- Không có hành động "thêm giao dịch vào ví này" dù đang xem ví.
