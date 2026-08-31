# 16 — LoanDetail (Chi tiết khoản vay) + _AddPaymentSheet

## A. Metadata
- **Tên**: `LoanDetailScreen(loan)` — nhận object, tự watch `loansProvider` để cập nhật (`:27-32`)
- **Route**: không có; `Navigator.push(MaterialPageRoute)` từ LoanList (`loan_list_screen.dart:160-162`)
- **File**: `lib/features/loan/presentation/screens/loan_detail_screen.dart` (704 LOC)
- **Vào từ**: LoanList tile
- **Thoát đi**: back; sheet `LoanFormSheet(existing)`; sheet `_AddPaymentSheet`; 2 AlertDialog; pop sau xoá

## B. Mục đích
Xem thông tin khoản vay, tiến độ trả, ghi nhận/xoá thanh toán, tất toán/mở lại, sửa/xoá.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back · <title> 16 w600 · [✎ 18] [⋮ 20: Đánh dấu tất toán|Mở lại, Xoá]
├───────────────────────────────┤ CustomScrollView
│ ┌ (Tôi đang vay) (🔴 Quá hạn) ┐ │ _InfoCard margin (16,16,16,12) pad 16 bg color α.05 border α.3 r16
│ │ 5.000.000 ₫ 24 w700 typeColor│ │ typeColor: red400 (borrowed) / green500 (lent)
│ │ Anh A 13                   │ │ contactName
│ │ [Bắt đầu: 1/8/2026] [Hạn: 30/8/2026] │ _MetaChip 11 pad H8 V4 r6 bg surfaceContainerHighest / orange α.1
│ │ note 12                    │ │
│ └───────────────────────────┘ │
│ Đã trả: 1.000.000 ₫   Còn: 4.000.000 ₫│ _PaidSummaryRow pad (16,4,16,16) 12
│ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 6px           │ AnimatedProgressBar typeColor / green khi xong
│ ───────────────────────────── │ Divider
│ [ + Ghi nhận thanh toán ]     │ FilledButton.icon bg typeColor, pad (16,12,16,4); ẩn khi closed
│ Lịch sử thanh toán (1) 12 w600│ pad (16,12,16,4)
│ (✓) 1.000.000 ₫        [🗑]   │ _PaymentTile: leading circle 36 α.12 check 16; title 14 w500; subtitle formatDayHeader 12; trailing IconButton trash2 16 outlineVariant
│ (80)                          │
└───────────────────────────────┘ (không FAB)
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | AppBar | title `loan.title`; `IconButton(pencil 18)`; `PopupMenuButton` items 'Đánh dấu tất toán'/'Mở lại', 'Xoá' (expenseAlt) | | | | ✎ → LoanForm(existing); menu | `:44-77` |
| 2 | `_InfoCard` | Container | margin (16,16,16,12) pad 16 | bg `color` α.05 border α.3 .8 r16 (color = outlineVariant nếu closed) | | | `:269-410` |
| 2a | Type badge | Container pad H10 V4 bg typeColor α.12 border α.4 .8 r20; 11 w600 typeColor | | | `type.label` | | `:298-319` |
| 2b | Status badge | Container pad H8 V4 r20 bg red/orange α.12; 11 w600 | 8 trái | | `'🔴 Quá hạn'` / `'⚠️ Còn N ngày'` | | `:320-360` |
| 2c | Principal | Text 24 w700 ls−.5 typeColor | 12 trên | | `formatVND(principal)` (Text thường) | | `:364-372` |
| 2d | Contact | Text 13 onSurfaceVariant | 4 | | nếu non-empty | | `:373-379` |
| 2e | `_MetaChip` ×1-2 | Container pad H8 V4 r6 bg `surfaceContainerHighest` / orange α.1; 11 onSurfaceVariant / orange | 8 trên, gap 8 | | `'Bắt đầu: d/M/yyyy'`, `'Hạn: d/M/yyyy'` (warning nếu overdue/upcoming) | | `:381-398, 412-438` |
| 2f | Note | Text 12 onSurfaceVariant | 8 | | nếu có | | `:399-405` |
| 3 | `_PaidSummaryRow` | Column | pad (16,4,16,16) | Row: 'Đã trả: X' 12 onSurfaceVariant · Spacer · 'Còn: Y' 12 w600 typeColor/green; 6; `AnimatedProgressBar` h6 track typeColor α.15 | `payments` Σ | | `:442-496` |
| 4 | Divider h1 | | | | | | `:104` |
| 5 | `FilledButton.icon` | pad (16,12,16,4) | bg typeColor; `plus` 16; 'Ghi nhận thanh toán' | | ẩn khi `isClosed` | → `_AddPaymentSheet` | `:105-116` |
| 6 | 'Lịch sử thanh toán (N)' | Text 12 w600 onSurfaceVariant | pad (16,12,16,4) | | | | `:117-127` |
| 7 | `AnimatedSwitcher` | fade + SizeTransition topCenter 260ms | | empty: 'Chưa có thanh toán nào' 13 center pad H16 V24; data: Column `_PaymentTile` | key = join ids | | `:128-173` |
| 7a | `_PaymentTile` | ListTile leading Container 36 circle α.12 `check` 16; title `formatVND` 14 w500; subtitle `formatDayHeader(paidAt)` 12; trailing `IconButton(trash2 16 outlineVariant)` | | | **note của payment không hiển thị** | 🗑 → dialog | `:500-539` |
| 8 | Loading | `SliverToBoxAdapter(Center(spinner))` | | | | | `:85-88` |
| 9 | Error | `Center(Text('Lỗi: $e'))` | | | | | `:89-91` |
| 10 | Dialog xoá loan | 'Xoá khoản vay?' / 'Xoá khoản vay và toàn bộ lịch sử thanh toán. Không thể hoàn tác.' / Huỷ / Xoá | | | | → delete → pop | `:193-222` |
| 11 | Dialog xoá payment | 'Xoá thanh toán này?' (không content) / Huỷ / Xoá | | | | | `:234-257` |
| 12 | `_AddPaymentSheet` | Column min, pad L16 R16 T12 B(viewInsets) | | handle; 'Ghi nhận thanh toán' 15 w600; 12; `TextField` 'Ghi chú (tuỳ chọn)' outline r10; 12; số 28 w600 primary ls−1 + '₫' 14; Divider 12; Numpad; `FilledButton('Xác nhận')` pad V12 r10 theme color, AnimatedSwitcher 140ms spinner/label | `_amountCtrl`, `_noteCtrl`; `paidAt = DateTime.now()` cố định | submit → `addPayment` → pop | `:543-704` |

## E. Vùng bố cục
Header 56; body CustomScrollView (card + SliverList); không footer.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Active | badge loại; nút ghi nhận; tiến độ |
| Upcoming | badge '⚠️ Còn N ngày' cam; meta chip Hạn cam |
| Overdue | badge '🔴 Quá hạn' đỏ |
| Closed | màu card outlineVariant, nút ghi nhận ẩn, menu 'Mở lại' |
| Trả đủ (remaining ≤ 0) nhưng chưa close | 'Còn: 0 ₫' xanh, bar xanh; **không tự tất toán** |
| Payments loading | spinner |
| Payments empty | text |
| Payments error | text thô |
| Loan bị xoá từ nơi khác | fallback `widget.loan` cũ (không báo) |
| AddPayment | không có ngày chọn; số > còn lại **không chặn** (`remaining.clamp(0, principal)` chỉ ở hiển thị) |

## G. Tương tác
| Trigger | Kết quả | Điều hướng |
|---|---|---|
| ✎ | | sheet LoanForm(existing) |
| ⋮ Đánh dấu tất toán / Mở lại | `close/reopen` không xác nhận | |
| ⋮ Xoá | dialog → delete → pop | pop |
| Ghi nhận thanh toán | | sheet |
| 🗑 payment | dialog → `deletePayment` | |
| Tap payment tile | **không có** (không sửa được payment) | |
| Back | pop | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Progress | AnimatedProgressBar | 360ms |
| Payment list ↔ empty | AnimatedSwitcher fade+size | 260ms |
| Submit label | AnimatedSwitcher | 140ms |
| Principal/còn lại | **không** animated | |

## I. Dữ liệu hiển thị
| Field | Format | Null |
|---|---|---|
| Ngày bắt đầu/hạn | `d/M/yyyy` (không pad) | hạn ẩn nếu null |
| Còn N ngày | `dueDate.difference(now).inDays` — không normalize giờ → có thể 'Còn 0 ngày' | |
| Đã trả / Còn | Σ payments / `principal − paid` clamp 0..principal | |
| Payment date | `formatDayHeader` (Hôm nay/Hôm qua/d/M/yyyy) | |
| Payment note | **không hiển thị** dù có nhập | |

## J. Responsive & edge cases
- Nhiều payment: SliverChildListDelegate (không lazy) — OK cho số lượng nhỏ.
- Note loan dài: wrap, card cao.
- Sheet AddPayment: keyboard (ghi chú) + numpad cùng lúc (không ẩn numpad).

## K. Text hiển thị
`<title>` · `Đánh dấu tất toán` · `Mở lại` · `Xoá` · `Tôi đang vay` · `Tôi cho vay` · `🔴 Quá hạn` · `⚠️ Còn N ngày` · `Bắt đầu: d/M/yyyy` · `Hạn: d/M/yyyy` · `Đã trả: X ₫` · `Còn: Y ₫` · `Ghi nhận thanh toán` · `Lịch sử thanh toán (N)` · `Chưa có thanh toán nào` · `Lỗi: …` · `Xoá khoản vay?` · `Xoá khoản vay và toàn bộ lịch sử thanh toán. Không thể hoàn tác.` · `Huỷ` · `Xoá thanh toán này?` · `Ghi chú (tuỳ chọn)` · `₫` · `Xác nhận`

## L. Nhận xét nhanh
- Ghi chú thanh toán được nhập nhưng không bao giờ hiển thị; ngày thanh toán luôn là "bây giờ", không chọn được.
- Trả đủ không tự tất toán; tất toán/mở lại không xác nhận nhưng xoá payment lại có dialog.
- Emoji làm badge trạng thái ('🔴', '⚠️') thay vì icon theme.
- Không có route → không deep link/khôi phục stack.
