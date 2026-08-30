# 19 — ReminderFormSheet (Thêm / Sửa nhắc nhở)

## A. Metadata
- **Tên**: `ReminderFormSheet(existing?, preset?, preselectedCategoryId?)`
- **Route**: modal `showModalBottomSheet(isScrollControlled)`
- **File**: `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart` (519 LOC)
- **Vào từ**: Reminders (+, preset, habit, ⋮ Chỉnh sửa)
- **Thoát đi**: submit → pop; `showTimePicker`

## B. Mục đích
Nhập tên, danh mục chi, số tiền gợi ý, tần suất (ngày/tuần/tháng), ngày trong tuần/tháng, giờ nhắc.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad L16 R16 T12 B(viewInsets); SingleChildScrollView
│           ━━━━ 36×4           │ (không có nút X)
│ Thêm nhắc nhở 15 w600         │
│ ┌ Tên (vd: Dầu gội, Tiền điện...) ┐│ TextField outline r10, autofocus khi thêm
│ Danh mục 13 w500              │
│ (🍴 Ăn uống)(🚗 Di chuyển)…→  │ strip h40 (KHÔNG pad ngang), chip icon 14 + tên 12, màu cat
│ ┌ Số tiền gợi ý (tuỳ chọn)  ₫ ┐│ TextField number, suffixText ₫ (keyboard hệ thống, KHÔNG numpad)
│ Tần suất 13 w500              │
│ [Hàng ngày][Hàng tuần][Hàng tháng]│ 3 Expanded chip pad V8 r8 primary α.12
│ Ngày trong tuần (weekly)      │
│ [T2][T3][T4][T5][T6][T7][CN]  │ 7 Expanded pad V6 r6 bg primary khi chọn, 11
│ Ngày trong tháng (monthly)    │
│ ┌ Ngày 5                  ▾ ┐ │ DropdownButtonFormField 1..28
│ Giờ nhắc nhở 13 w500          │
│ ┌ 🕐 20:00        Tap để thay đổi ┐│ Container border outlineVariant .8 r10 pad 12; giờ 15 w500 primary
│ [       Tạo nhắc nhở       ]  │ FilledButton theme pad V12 r10
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | Handle | 36×4 | 16 dưới | | | | `:167-177` |
| 2 | Title | Text 15 w600 | 16 | | 'Chỉnh sửa nhắc nhở' / 'Thêm nhắc nhở' | | `:179-183` |
| 3 | Tên | TextField outline r10 H12 V10; `autofocus: !_isEdit` | 12 | | `_titleCtrl` (preset title) | | `:185-198` |
| 4 | 'Danh mục' | 13 w500 | 8 | | | | `:201-208` |
| 5 | Chip strip | `SizedBox(40) ListView.separated` **không padding ngang** (chip đầu sát mép 16 của sheet — OK vì Padding cha), gap 8; chip `AnimatedContainer 150ms` pad H10 V6 bg cat α.15 / transparent, border cat / outlineVariant .8, r20, icon 14 + tên 12 w600/w400 | 12 | | `expenseCategoriesProvider`; auto chọn: preselected → preset.iconName match (postFrame setState) → first | tap | `:210-262, 135-153` |
| 6 | Số tiền gợi ý | TextField `keyboardType number`, `suffixText '₫'`, outline r10 | 12 | | `_amountCtrl` (TextEditingController, **không** format nghìn) | | `:265-279` |
| 7 | 'Tần suất' + 3 chip | Row Expanded, pad right 8 trừ cuối; `AnimatedContainer 150ms` pad V8 r8 bg primary α.12 / transparent, border primary / outlineVariant; 12 w600/w400 center | 12 | | `_frequency` (mặc định monthly / preset) | | `:282-335` |
| 8 | Ngày trong tuần | Row 7 Expanded `AnimatedContainer 100ms` margin R4 pad V6 r6 bg primary / transparent, border; 11 w700 onPrimary / w400 onSurfaceVariant | 12 | | chỉ khi weekly; `_dayOfWeek` 1..7 | | `:338-385` |
| 9 | Ngày trong tháng | `DropdownButtonFormField<int>` outline r10 pad H12 V8; items 'Ngày 1'…'Ngày 28' | 12 | | chỉ khi monthly; `_dayOfMonth` | | `:387-420` |
| 10 | Giờ | `GestureDetector > Container` pad 12 border outlineVariant .8 r10: `access_time` 18, 8, `HH:mm` 15 w500 primary, Spacer, 'Tap để thay đổi' 12 | 20 | | `_hour:_minute` (mặc định 20:00) | → `showTimePicker` | `:431-481` |
| 11 | Submit | `FilledButton` theme (primary) pad V12 r10; spinner 18 / Text 14 w600 | 16 dưới | | disabled chỉ khi `_loading`; tên rỗng → `_submit` return im lặng | | `:484-512` |

## E. Vùng bố cục
Scroll toàn sheet; không safe top; không X.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Thêm trống | title rỗng, category đầu, monthly ngày 1, 20:00 |
| Từ preset | title/amount/freq prefill; category theo icon (postFrame → nháy 1 frame) |
| Từ habit | title = keyword, category = habit.categoryId, freq tính từ gap |
| Sửa | prefill; `isActive` giữ; nút 'Lưu thay đổi' |
| weekly | hiện hàng T2..CN |
| monthly | hiện dropdown |
| daily | không thêm hàng |
| Tên rỗng submit | im lặng |
| Lỗi | không bắt |
| `warnBeforeHours` | **không có UI** dù preset có `defaultWarnBeforeHours` và model có field → giá trị preset **bị bỏ** khi tạo (constructor không truyền) |

## G. Tương tác
| Trigger | Kết quả |
|---|---|
| Chip danh mục / tần suất / thứ | set state |
| Dropdown ngày | set |
| Giờ | time picker hệ thống (không theme) |
| Submit | add/update + reschedule → pop |

## H. Animation/transition
Chip 150ms / 100ms.

## I. Dữ liệu hiển thị
| Field | Format |
|---|---|
| Giờ | `HH:mm` pad |
| Tần suất | `frequencyLabel` Hàng ngày/tuần/tháng |
| Thứ | T2…CN |
| Số tiền | số thô không phân cách |

## J. Responsive & edge cases
- 7 ô thứ trên màn 360: mỗi ô ~40px, chữ 11 OK.
- Keyboard che nút submit → scroll.
- Ngày 29–31 không chọn được (cố ý).

## K. Text hiển thị
`Thêm nhắc nhở` · `Chỉnh sửa nhắc nhở` · `Tên (vd: Dầu gội, Tiền điện...)` · `Danh mục` · `Số tiền gợi ý (tuỳ chọn)` · `₫` · `Tần suất` · `Hàng ngày` `Hàng tuần` `Hàng tháng` · `Ngày trong tuần` · `T2 T3 T4 T5 T6 T7 CN` · `Ngày trong tháng` · `Ngày N` · `Giờ nhắc nhở` · `HH:mm` · `Tap để thay đổi` · `Tạo nhắc nhở` · `Lưu thay đổi`

## L. Nhận xét nhanh
- Số tiền dùng keyboard hệ thống không format, trong khi mọi form tiền khác dùng numpad — không nhất quán.
- Không có UI cho `warnBeforeHours`; preset mang giá trị này nhưng bị bỏ.
- Không nút đóng; tên rỗng không báo lỗi.
- 4 kiểu chọn (chip, chip Expanded, ô ngày, dropdown) trong 1 form.
