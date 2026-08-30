# 10 — Stats (Thống kê)

## A. Metadata
- **Tên**: `StatsScreen`
- **Route**: `/stats` (`app_router.dart:27`) — push, có back
- **File**: `lib/features/stats/presentation/screens/stats_screen.dart` (964 LOC) + `widgets/stats_time_selector.dart` (198) + `widgets/date_range_picker_sheet.dart` (266) + `providers/stats_provider.dart` (109)
- **Vào từ**: Home grid "Thống kê", AllFeatures "Thống kê"
- **Thoát đi**: back; sheet `DateRangePickerSheet` → `showDateRangePicker`

## B. Mục đích
Thống kê thu/chi/ròng theo khoảng thời gian (mặc định tháng hiện tại, **state riêng** `statsDateRangeProvider` không chung với `selectedMonthProvider`): pie chi theo danh mục và bar theo ngày/tuần + bảng chi tiết ngày.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar centerTitle + bottom TabBar
│ ‹  [Tháng 8/2026 ▾]  ›  (Hôm nay)│ StatsTimeSelector (‹ › chỉ ở mode month; custom: icon date_range 14 + label 13 primary)
│   Danh mục    │   Theo ngày   │ TabBar 2 tab, indicatorSize.label                     :47-51
├───────────────────────────────┤
│ ┌ Thu ┐ ┌ Chi ┐ ┌ Ròng ┐      │ _StatsSummaryRow h76: 3 box surfaceContainerLow r10 pad H8 V6; label 11; số 12 w700 màu :76-162
│ │+1.0M│ │-500K│ │+500K │      │
│ ───────────────────────────── │ Divider
│ TabBarView                    │
│  [Danh mục]                   │  [Theo ngày]
│   ╭─────╮                     │  Chi tiêu theo ngày 13 w600
│   │ pie │ 220                 │  ▂▅▃▇▂ bar 200 (rod width 8/5, đỏ α.8, r3)
│   ╰─────╯                     │  Chi tiết từng ngày 13 w600
│  Tổng chi: X ₫ 13             │  Hôm nay      +…  ròng
│  ● Ăn uống  65.4%  85.000 ₫   │               -…
│  ● Di chuyển 34.6% 45.000 ₫   │  Hôm qua      …
└───────────────────────────────┘ (không FAB, không bottom nav)
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `StatsTimeSelector` | AppBar title Row | | | | mode month: `IconButton chevron_left` compact · label Container pad H8 V4 r8 bg primary α.06 [Text 15 w600 onSurface, `arrow_drop_down` 18] · `IconButton chevron_right` (disabled grey.shade300 nếu tháng hiện tại); mode custom: Container bg primary α.10 [`date_range_rounded` 14 primary, label 13 w600 primary, dropdown]; chip reset "Hôm nay"/"Tháng này" 11 w600 primary r20 (AnimatedSwitcher 260ms) khi không phải tháng hiện tại | `statsDateRangeProvider` | ‹ ›; tap label → `DateRangePickerSheet`; chip → tháng hiện tại | `stats_time_selector.dart:24-179` |
| 2 | `TabBar` | AppBar.bottom | | 48 | | tabs 'Danh mục', 'Theo ngày'; `indicatorSize: label`; màu theme M3 | `_tab` | tap/swipe | `:47-51` |
| 3 | `_StatsSummaryRow` | `SizedBox(76) > AnimatedSwitcher` | body top | 76 | pad H16 V10 (data) / V14 (skeleton) | 3 `Expanded` gap 8 | loading → 3 `SkeletonBlock(h48)`; error → `_StatsSummaryError` (circleAlert 18 + "Không thể tải thống kê" 13 + TextButton Thử lại); data → `_StatsSummaryValue` | | `:55-62, 76-245` |
| 3a | `_StatsSummaryValue` | DecoratedBox | | | pad H8 V6 | bg `cs.surfaceContainerLow` r10; label 11 onSurfaceVariant; `AnimatedMoneyText` 12 w700 center ellipsis màu | Thu `+` income; Chi `-` expenseAlt; Ròng `+` nếu >0 màu theo dấu | | `:192-245` |
| 4 | Divider h1 | | | | | | | | `:63` |
| 5 | `TabBarView[_CategoryTab, _DailyTab]` | Expanded | | | | mỗi tab bọc `_StatsStateTransition` (AnimatedSwitcher 380ms fade + slide y.025, `SizedBox.expand` key) | | | `:64-70, 858-885` |
| 6 | `_CategoryTab` loading | `_StatsChartLoading` | center pad 24 | | | SkeletonBlock 190×170 r28; 20; 150×14; 12; 220×12 | | | `:887-912` |
| 7 | `_CategoryTab` error | `_StatsError` | center | | | circleAlert 48 error; "Không thể tải thống kê"; OutlinedButton Thử lại | invalidate tx + categories | | `:940-964` |
| 8 | `_CategoryTab` empty | `_EmptyStats` | center | | | `chartPie` 48 outlineVariant; "Chưa có dữ liệu"; "Thêm giao dịch để xem thống kê" 12 | `byCategory.isEmpty` (chỉ **expense**) | | `:916-938` |
| 9 | `_CategoryPieChart` | `SizedBox(220) > PieChart` | data | | pad all 16 | sections màu `category.color ?? outlineVariant`; radius 60 (72 khi touch); title `'NN%'` 12 w600 white nếu >5%; `centerSpaceRadius 48`; `sectionsSpace 2`; swap anim 380ms | `entries` sort desc | touch → highlight section | `:307-314, 355-428` |
| 10 | "Tổng chi: X" | Row center | | | 8 trên | 13 w500 onSurfaceVariant + AnimatedMoneyText | `total` | | `:316-337` |
| 11 | `_LegendRow` ×N | Row | | pad V6 | 20 trên | dot 12 màu; tên 13 Expanded; `'65.4%'` 12 onSurfaceVariant; 12; `formatVND` 13 w600 | | **không tap** | `:339-347, 430-476` |
| 12 | `_DailyTab` tiêu đề chart | Text | | | pad (16,20,16,16) | 13 w600 onSurface | 'Chi tiêu theo ngày' (≤31 ngày) / 'Chi tiêu theo tuần' (32–90); **ẩn chart** nếu >90 ngày | | `:525-543` |
| 13 | `BarChart` | `SizedBox(200)` | | | 16 dưới | `maxY = max×1.2`; grid ngang 4 vạch outlineVariant .5; bottom title `d/M` 9px mỗi 5 ngày (daily) / đầu tuần; rod chỉ **expense** `expenseAltColor` α.8, width 8 (≤15 ngày) / 5 / 10 (weekly), r3; tooltip bg inverseSurface, 11 w500 | `statsDailyTotalsProvider` | touch → tooltip | `:572-789` |
| 14 | 'Chi tiết từng ngày' | Text 13 w600 | | | 24 trên | | | | `:546-554` |
| 15 | `_DailyRow` ×N | Row | | pad V6 | | `SizedBox(72)` date 12 onSurfaceVariant (`formatDayHeader`); Expanded Column end: `+income` 12 xanh (nếu >0), `-expense` 12 đỏ (nếu >0); 16; net 13 w600 màu | sort ngày desc | không tap | `:555-564, 792-856` |
| 16 | `DateRangePickerSheet` | sheet | | pad (16,12,16,32) | | handle; "Chọn khoảng thời gian" 15 w700; 4 `_PresetTile` (ListTile dense r10, tileColor primary α.08 nếu chọn; leading `check_circle`/`circle_outlined` 20; title 14 w700/w500; subtitle 11); Divider 24; ListTile "Tùy chọn..." icon `date_range_rounded` primary | `current` | preset → `onPicked` + pop; Tùy chọn → `showDateRangePicker` (Theme override lớn `:142-198`) | `date_range_picker_sheet.dart` |

## E. Vùng bố cục
- Header: AppBar 56 + TabBar 48 = 104 cố định.
- Body: summary 76 + divider cố định; TabBarView `Expanded` cuộn riêng từng tab (`SingleChildScrollView`).
- Không footer/FAB.

## F. Trạng thái màn hình
| State | Điều kiện | UI |
|---|---|---|
| Initial | | tháng hiện tại, tab Danh mục |
| Loading (lần đầu) | `isLoading && !hasValue` | summary skeleton; tab skeleton chart |
| Refresh (đổi range khi đã có data) | `hasValue` | giữ số/chart cũ và tween sang mới (không skeleton) |
| Empty | không expense (tab 1) / không tx (tab 2) | `_EmptyStats` — **tab Danh mục rỗng ngay cả khi có thu nhập** vì chỉ tính expense |
| Error | `hasError && !hasValue` | summary error inline + tab error block |
| Custom range | mode custom | ‹ › ẩn; label đổi màu primary + icon; chip "Tháng này" |
| Range > 90 ngày | | tab Theo ngày ẩn chart, chỉ còn bảng |
| Pie touch | `_touchedIndex` | section phồng 60→72 |

## G. Tương tác
| Trigger | Hành động | Kết quả | Điều hướng |
|---|---|---|---|
| ‹ › | tháng ±1 (`StatsDateRange.fromMonth`) | reload | |
| Tap label | | | sheet DateRangePicker |
| Preset (Tháng này / Tháng trước / 3 tháng gần nhất / Năm nay) | set range + pop | | |
| Tùy chọn... | `showDateRangePicker` (vi_VN, firstDate now−3y, lastDate today) → set custom + pop sheet | | dialog hệ thống full-screen |
| Chip Hôm nay/Tháng này | về tháng hiện tại | | |
| Tab tap / swipe ngang | đổi tab | | |
| Touch pie | highlight | | |
| Touch bar | tooltip `d/M\nX ₫` | | |
| Tap legend / daily row | **không có** (không drill-down sang list) | | |
| Back | pop; **range custom vẫn giữ** (provider global) | | |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Summary số | AnimatedMoneyText | 360ms | standard |
| Summary switch loading/data | AnimatedSwitcher | 360ms | standard / layout |
| Tab state (loading/empty/data) | fade + slide y.025 | 380ms | standard / layout |
| Pie/Bar data | fl_chart swap | 380ms | standard |
| Pie touch radius | implicit | 380ms | |
| Label range | AnimatedSwitcher | 360ms | |
| Chip reset | fade + size | 260ms | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null/rỗng |
|---|---|---|---|
| Label range | `StatsDateRange.label` | `Tháng M/YYYY` hoặc `dd/MM – dd/MM/yyyy` (hoặc `dd/MM/yyyy – dd/MM/yyyy` khác năm) | |
| Thu/Chi/Ròng | `statsSummaryProvider` | `+/-formatVND`; Ròng: `+` chỉ khi >0, âm hiện `-` từ formatVND? — `formatVND` **không** thêm dấu âm ngoài `int.toString()` → `-500.000 ₫` OK | 0 |
| Pie % | `entry/total*100` | `toStringAsFixed(0)%` trong section (ẩn ≤5%), `toStringAsFixed(1)%` ở legend | |
| Legend tên | `category?.name ?? 'Không rõ'` | | |
| Bar tooltip | `d/M\nX ₫` | | |
| Daily row date | `formatDayHeader` (Hôm nay/Hôm qua/d/M/yyyy) trong 72px | `d/M/yyyy` 12px ≈ 60px vừa | |
| Net | `income − expense` | `+X`/`-X` 13 w600 | |

## J. Responsive & edge cases
- Nhiều danh mục (>8) với % nhỏ: nhiều section không nhãn; legend dài scroll OK.
- 3 box summary trên màn hẹp: số 12px ellipsis (ví dụ "+18.000.000 ₫" ~85px trong box ~100px → vừa, nhưng 10 chữ số sẽ ellipsis).
- Bar 31 ngày rộng 5px, nhãn mỗi 5 ngày — đọc được nhưng nhỏ (9px).
- Landscape: chart 220/200 + header 104 + summary 76 → cần cuộn.
- Dark: `surfaceContainerLow` từ fromSeed, OK; `grey.shade300` cho chevron disabled cố định.

## K. Text hiển thị
`Tháng M/YYYY` · `dd/MM – dd/MM/yyyy` · `Hôm nay` · `Tháng này` · `Danh mục` · `Theo ngày` · `Thu` · `Chi` · `Ròng` · `Không thể tải thống kê` · `Thử lại` · `Chưa có dữ liệu` · `Thêm giao dịch để xem thống kê` · `Tổng chi: ` · `NN%` · `Không rõ` · `Chi tiêu theo ngày` · `Chi tiêu theo tuần` · `Chi tiết từng ngày` · `Chọn khoảng thời gian` · `Tháng này` · `Tháng trước` · `3 tháng gần nhất` · `Năm nay` · `Th.M – Th.M/YYYY` · `01/01/YYYY – nay` · `Tùy chọn...`

## L. Nhận xét nhanh
- Thống kê chỉ về **chi**: pie bỏ qua thu; bar chỉ vẽ expense dù có `income` trong data; tab "Danh mục" báo "Chưa có dữ liệu" khi tháng chỉ có thu nhập.
- Không drill-down: tap legend/ngày không dẫn tới danh sách giao dịch tương ứng.
- Bộ chọn thời gian của Stats (`statsDateRangeProvider`) tách khỏi tháng của Home/Transactions → user đổi tháng ở Home rồi vào Stats thấy tháng khác.
- Header cố định 104 + summary 76 = 180px trước khi tới chart; summary 3 box chữ 12px là thông tin chính nhưng nhỏ nhất.
