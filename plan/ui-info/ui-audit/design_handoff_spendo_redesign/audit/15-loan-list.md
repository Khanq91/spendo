# 15 — LoanList (Khoản vay)

## A. Metadata
- **Tên**: `LoanListScreen(filterType)`
- **Route**: `/loans`, `/loans?type=borrowed`, `/loans?type=lent` (`app_router.dart:50-57`)
- **File**: `lib/features/loan/presentation/screens/loan_list_screen.dart` (272 LOC)
- **Vào từ**: Home grid "Vay nợ"; AllFeatures 3 ô
- **Thoát đi**: back; `Navigator.push(MaterialPageRoute → LoanDetailScreen(loan))`; sheet `LoanFormSheet(initialType)`

## B. Mục đích
Danh sách khoản vay/cho vay (đang hoạt động & đã tất toán), thêm mới, vào chi tiết.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back · 'Khoản vay'|'Đang vay'|'Cho vay' 16 w600 · [+]
├───────────────────────────────┤ ListView pad B80
│ ĐANG HOẠT ĐỘNG (2) 12 w600 ls.4│ _SectionHeader pad (16,16,16,6)
│ [↙] Vay mua xe     5.000.000 ₫│ ListTile: leading 40 r10 bg color α.15 icon arrowDownLeft/UpRight 18; title 14 w500; subtitle contact|type.label 12; trailing principal 14 w600 red400/green500 + status 11
│     Anh A              Còn 3 ngày│
│ [↗] Cho B mượn     2.000.000 ₫│
│     B                         │
│ ĐÃ TẤT TOÁN (1) (muted)       │
│ [↙] Vay cũ (xám)   1.000.000 ₫│ màu outlineVariant, 'Đã tất toán' 11
│                          (+)  │ FAB heroTag 'loan_fab'
└───────────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | AppBar | title theo filter; `IconButton(add)` | | 16 w600 | `filterType` | + → form | `:28-39` |
| 2 | Loading | `Center(CircularProgressIndicator)` | | | | | `:41` |
| 3 | Error | `Center(Text('Lỗi: $e'))` | | | | không retry | `:42` |
| 4 | `_EmptyState` | Center Column | | `handCoins` 48 outlineVariant; msg; sub 12; 24; `FilledButton.icon(add, 'Thêm khoản vay')` | msg theo filter | | `:228-272` |
| 5 | `_SectionHeader` | Text | pad (16,16,16,6) | 12 w600 ls.4 onSurfaceVariant / outlineVariant (muted) | `'Đang hoạt động (N)'` / `'Đã tất toán (N)'` | | `:112-134` |
| 6 | `_LoanTile` | ListTile | | leading 40 r10 bg `loan.color` α.15 (outlineVariant nếu closed), icon 18; title 14 w500 onSurface/onSurfaceVariant; subtitle `contactName` hoặc `type.label` 12; trailing Column end: `formatVND(principal)` 14 w600 `red.shade400` (borrowed) / `green.shade500` (lent) / outlineVariant (closed) + status 11 ('Quá hạn' đỏ / 'Còn N ngày' cam / 'Đã tất toán' outlineVariant) | `loansProvider` → `_applyFilter` | tap → push LoanDetail | `:138-224` |
| 7 | FAB | `FloatingActionButton(heroTag 'loan_fab', CircleBorder, add 28)` | | theme | | → form | `:75-80` |

## E. Vùng bố cục
Header; body ListView; FAB endFloat; list pad bottom 80.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Loading | spinner giữa (không skeleton) |
| Error | text thô |
| Empty | icon + msg theo filter + CTA (cộng với AppBar + và FAB = 3 lối) |
| Data | 2 section; section ẩn nếu rỗng |
| Overdue | status 'Quá hạn' đỏ (`Colors.red`) |
| Upcoming (≤7 ngày) | 'Còn N ngày' cam — N = `dueDate.difference(now).inDays` (có thể 0 → 'Còn 0 ngày') |
| Closed | xám toàn bộ |

## G. Tương tác
| Trigger | Kết quả | Điều hướng |
|---|---|---|
| + / FAB / CTA | `LoanFormSheet(initialType: theo filter)` | sheet |
| Tile | | `Navigator.push` LoanDetail (không URL) |
| Swipe / long-press / filter trong màn | **không có** — filter chỉ qua query param từ AllFeatures; không có chip Đang vay/Cho vay trong màn | |

## H. Animation/transition
Không có animation riêng; route MaterialPageRoute mặc định.

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null |
|---|---|---|---|
| Title | `loan.title` | 14 | |
| Subtitle | `contactName` non-empty ?: `type.label` ('Tôi đang vay'/'Tôi cho vay') | | |
| Số | `principal` (**gốc, không phải còn lại**) | `formatVND` | |
| Status | `loan.status` | | active: không text |

## J. Responsive & edge cases
- Số gốc hiển thị, không phải số còn nợ → phải vào chi tiết mới biết còn bao nhiêu.
- Tiêu đề dài: ListTile wrap.
- Không phân biệt màu borrowed/lent ở icon nếu `loan.color` do user chọn trùng.

## K. Text hiển thị
`Khoản vay` · `Đang vay` · `Cho vay` · `Đang hoạt động (N)` · `Đã tất toán (N)` · `Tôi đang vay` · `Tôi cho vay` · `Quá hạn` · `Còn N ngày` · `Đã tất toán` · `Chưa có khoản vay nào` · `Chưa có khoản cho vay nào` · `Ghi lại khoản bạn đang vay` · `Ghi lại khoản bạn đã cho vay` · `Ghi lại khoản vay để theo dõi` · `Thêm khoản vay` · `Lỗi: …`

## L. Nhận xét nhanh
- Không có bộ lọc/tab trong màn; filter chỉ đến từ 3 ô riêng ở AllFeatures.
- Hiển thị số gốc thay vì số còn lại; không có tổng "đang nợ / được nợ".
- 3 lối thêm trên cùng màn (AppBar +, FAB, CTA).
- Dùng `Navigator.push` thuần → LoanDetail không có route, không deep link.
