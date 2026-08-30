# 25 — MonthPickerSheet

## A. Metadata
- **Tên**: `MonthPickerSheet(selected)` → trả `DateTime(year, month)` qua `Navigator.pop`
- **Route**: modal `showModalBottomSheet<DateTime>` (không `isScrollControlled`) từ `MonthSelector._openPicker` (`month_selector.dart:24-30`)
- **File**: `lib/features/home/presentation/widgets/month_picker_sheet.dart` (163 LOC)
- **Vào từ**: tap label tháng ở Home, Transactions, WalletDetail
- **Thoát đi**: tap ô tháng → pop(value); kéo/tap ngoài → pop(null)

## B. Mục đích
Chọn tháng/năm nhanh (tối đa 3 năm về trước, không tương lai).

## C. Layout skeleton
```
╭───────────────────────────────╮ pad (16,12,16,32)
│           ━━━━ 36×4           │
│        ‹   2026   ›           │ IconButton compact; năm 18 w700 ls−.5
│ (12)                          │
│ [Th.1][Th.2][Th.3][Th.4]      │ GridView 4 cột aspect 2.2 spacing 8; ô r8 border .8
│ [Th.5][Th.6][Th.7][Th.8]      │ selected: bg primary, text white; today: bg primary α.1 text primary border α.4; future: text outlineVariant no border
│ [Th.9][Th.10][Th.11][Th.12]   │
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | Handle | 36×4 outlineVariant margin B16 | | | `:49-57` |
| 2 | Year Row | `IconButton chevron_left` compact (disabled `outlineVariant` nếu `_year <= now.year−3`); Text `$_year` 18 w700 ls−.5; `IconButton chevron_right` (disabled nếu `_year >= now.year`) | `_year` | ±1 | `:60-92` |
| 3 | Grid | `GridView.builder` shrinkWrap 4 cột, spacing 8/8, aspect 2.2 (ô ~75×34) | 12 ô `Th.1..Th.12` | | `:97-158` |
| 3a | Ô | `GestureDetector > AnimatedContainer 120ms` r8 border .8; text 13 (w700 nếu selected/today) | disabled = tương lai; selected = `widget.selected`; today = tháng hiện tại | tap → `Navigator.pop(DateTime(_year, m))` | `:107-156` |

## E. Vùng bố cục
Sheet ~230px, không scroll, không SafeArea bottom (pad 32 cứng).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Năm hiện tại | tháng tương lai mờ, tháng hiện tại viền primary nhạt |
| Năm khác | tất cả 12 tháng chọn được |
| Selected | ô primary trắng |

## G. Tương tác
‹ › năm; tap tháng → pop; không "Hôm nay"/"Huỷ".

## H. Animation/transition
Ô AnimatedContainer 120ms; sheet mặc định.

## I. Dữ liệu hiển thị
`_months` hằng 'Th.1'…'Th.12'; `_year`.

## J. Responsive & edge cases
Text `Colors.white` trên primary (không dùng `onPrimary`); OK với 5 seed hiện tại nhưng không theme-safe.

## K. Text hiển thị
`Th.1` … `Th.12` · `<năm>`

## L. Nhận xét nhanh
- Giới hạn 3 năm cứng; không chọn tương lai (hợp lý cho thống kê, nhưng Stats có picker riêng khác hoàn toàn).
- Không có nút quay về tháng hiện tại trong picker.
