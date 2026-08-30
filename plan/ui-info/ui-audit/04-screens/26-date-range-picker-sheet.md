# 26 — DateRangePickerSheet (Stats)

## A. Metadata
- **Tên**: `DateRangePickerSheet(current, onPicked)`
- **Route**: modal `showModalBottomSheet` (không scrollControlled) từ `StatsTimeSelector._openPicker` (`stats_time_selector.dart:182-197`)
- **File**: `lib/features/stats/presentation/widgets/date_range_picker_sheet.dart` (266 LOC)
- **Vào từ**: tap label thời gian ở Stats
- **Thoát đi**: preset → `onPicked` + pop; "Tùy chọn..." → `showDateRangePicker` (full-screen Material) → pop sheet sau khi chọn

## B. Mục đích
Chọn preset khoảng thời gian hoặc khoảng tuỳ ý cho Stats.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad (16,12,16,32)
│           ━━━━ 36×4           │
│ Chọn khoảng thời gian 15 w700 │
│ (16)                          │
│ ◉ Tháng này        Tháng 8/2026│ _PresetTile ListTile dense r10; tileColor primary α.08 nếu chọn
│ ○ Tháng trước      Tháng 7/2026│ leading check_circle/circle_outlined 20; title 14 w700/w500; subtitle 11
│ ○ 3 tháng gần nhất Th.6 – Th.8/2026│
│ ○ Năm nay          01/01/2026 – nay│
│ ───────────────── (24)        │ Divider 24
│ 📅 Tùy chọn... 14 w600 primary│ ListTile dense
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | Handle | 36×4 margin B12 | | | `:28-36` |
| 2 | Title | 15 w700 onSurface | | | `:38-45` |
| 3 | `_PresetTile` ×4 | `Material(transparent) > ListTile(dense, shape r10, tileColor primary α.08 nếu selected)`; leading `check_circle` primary / `circle_outlined` outlineVariant 20; title 14 w700 primary / w500 onSurface; subtitle 11 onSurfaceVariant | `isSelected` tính từ `current.mode/start` | tap → `onPicked(range)` + pop | `:49-92, 223-266` |
| 4 | Divider h24 | | | | `:94` |
| 5 | Tùy chọn | ListTile dense leading `date_range_rounded` 20 primary; title 14 w600 primary; shape r10 | | → `_openCustomPicker` | `:97-119` |
| 6 | `showDateRangePicker` | `locale vi_VN`; firstDate `now−3y`; lastDate today; `Theme` override: appBar bg scaffold, colorScheme primary/onPrimary white/surfaceTint transparent/surface scaffold; `DatePickerThemeData` (bg scaffold, rangeSelectionBackgroundColor primary α.12, overlay transparent, shape r24, dayStyle w500); textButton primary w600 14; input theme filled cardColor r12, focused border primary 1.5 | | chọn → `onPicked(custom)` + pop sheet | `:125-204` |

## E. Vùng bố cục
Sheet ~330px không scroll.

## F. Trạng thái màn hình
Selected tile theo `current`; custom range không khớp preset → không tile nào chọn.

## G. Tương tác
4 preset + custom; không huỷ riêng.

## H. Animation/transition
Không.

## I. Dữ liệu hiển thị
| Preset | Subtitle |
|---|---|
| Tháng này | `Tháng M/YYYY` |
| Tháng trước | `Tháng M/YYYY` |
| 3 tháng gần nhất | `Th.M – Th.M/YYYY` |
| Năm nay | `01/01/YYYY – nay` |

## J. Responsive & edge cases
`showDateRangePicker` trên Android là full-screen dialog Material; iOS cũng Material (không Cupertino).

## K. Text hiển thị
`Chọn khoảng thời gian` · `Tháng này` · `Tháng trước` · `3 tháng gần nhất` · `Năm nay` · `Tùy chọn...` · subtitle như bảng

## L. Nhận xét nhanh
- Khác hoàn toàn MonthPickerSheet (grid tháng) dù cùng mục đích "chọn thời gian" → 2 picker cho 2 màn.
- Theme override 50 dòng chỉ cho date range picker; date picker ở LoanForm và time picker ở Reminders/Settings không có override tương ứng.
