# 18 — Reminders (Nhắc chi tiêu định kỳ)

## A. Metadata
- **Tên**: `RemindersScreen`
- **Route**: `/reminders` (`app_router.dart:43`)
- **File**: `lib/features/reminders/presentation/screens/reminders_screen.dart` (830 LOC)
- **Vào từ**: Home AppBar 🔔, Home grid "Nhắc nhở", AllFeatures, Settings "Quản lý nhắc nhở"
- **Thoát đi**: back; sheet `ReminderFormSheet` (4 lối)

## B. Mục đích
Quản lý nhắc nhở định kỳ (bật/tắt, sửa, xoá), tạo nhanh từ 6 preset, tạo từ gợi ý thói quen (habit detector chạy khi mở màn `:23`).

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back · 'Nhắc chi tiêu định kỳ' 16 w600 · [+]
├───────────────────────────────┤ ListView
│ GỢI Ý NHANH 12 w600 ls.5      │ _PresetSection pad (16,16,16,8); ẩn nếu mọi preset đã có
│ (+ Dầu gội)(+ Tiền điện)(+…)→ │ strip h44, chip border outlineVariant .8 r20 pad H12 V8: add 14 + title 13
│ ✨ GỢI Ý TỪ LỊCH SỬ CỦA BẠN   │ _HabitSuggestionSection; ẩn nếu rỗng
│ ┌ (↻) Xăng xe          Tạo  x ┐│ _HabitSuggestionTile margin H16 V4 pad H14 V10 bg primary α.04 border α.25 r12
│ │ Thường mỗi 7 ngày · lần cuối 3 ngày trước · Di chuyển ││ 11
│ └───────────────────────────┘ │
│ NHẮC NHỞ CỦA BẠN              │ pad (16,16,16,8)
│ (🔔) Tiền điện     [◉ ] [⋮]   │ _ReminderTile ListTile: leading 40 r10 primary α.12 / surfaceContainerHighest; title 14 w500; subtitle scheduleDetail 12 + cat.name 11 màu cat; trailing Switch + PopupMenu(Chỉnh sửa, Xoá)
│      Ngày 5 hàng tháng lúc 20:00│
│      Nhà cửa                  │
│ ┌ DEBUG — Test notification ┐ │ _DebugPanel chỉ kDebugMode
│ (80)                          │
└───────────────────────────────┘ (không FAB)
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | AppBar | title 16 w600; `IconButton(add)` | | | | + → `ReminderFormSheet()` | `:29-40` |
| 2 | Loading | `Center(spinner)` | | | | | `:42` |
| 3 | Error | `Center(Text('Lỗi: $e'))` | | | | | `:43` |
| 4 | `_EmptyState` | ListView[Padding V40 Column(bellOff 48, 'Chưa có nhắc nhở nào', 'Tạo nhắc nhở để không quên chi tiêu định kỳ' 12, 24, FilledButton.icon 'Thêm nhắc nhở'), _PresetSection([]), _HabitSuggestionSection([])] | | | `reminders.isEmpty` | | `:790-830` |
| 5 | `_PresetSection` | Column: label pad (16,16,16,8) 12 w600 ls.5; `SizedBox(44) ListView.separated` pad H16 gap 8 | | chip `PressableScale > Container` pad H12 V8 border outlineVariant .8 r20 [`Icons.add` 14, 4, title 13] | `kReminderPresets` lọc bỏ title đã có (case-insensitive) | tap → `ReminderFormSheet(preset)` | `:602-674` |
| 6 | `_HabitSuggestionSection` | Column: header Row [`sparkles` 13, 6, label 12 w600 ls.5] pad (16,16,16,8); tiles; 4 | | | `pendingHabitSuggestionsProvider` lọc bỏ keyword trùng title reminder | | `:108-154` |
| 6a | `_HabitSuggestionTile` | Container margin H16 V4 bg primary α.04 border primary α.25 .8 r12; pad H14 V10; Row [icon box 36 r9 primary α.1 `repeat` 16, 10, Expanded Column[keyword capitalized 13 w600, 2, `'Thường mỗi N ngày · lần cuối X · <cat>'` 11], 8, `TextButton('Tạo')` 12 w600 compact pad H10 V6, `PressableScale(x 14)` pad 4 r16] | | | `habit` | Tạo → form(preset từ habit: freq monthly ≥25d / weekly ≥6d / daily, iconName 'more_horiz', categoryId); x → `dismiss` | `:156-284` |
| 7 | Label 'Nhắc nhở của bạn' | Text 12 w600 ls.5 | pad (16,16,16,8) | | | | `:53-65` |
| 8 | `AnimatedSwitcher > Column` | 260ms | | key = join ids | | | `:66-85` |
| 8a | `_ReminderTile` | ListTile `isThreeLine: cat != null` | | leading `AnimatedContainer` 40 r10 bg primary α.12 (active) / surfaceContainerHighest; `AnimatedSwitcher` icon `bell` 18 primary / onSurfaceVariant; title `AnimatedDefaultTextStyle` 14 w500 onSurface / onSurfaceVariant; subtitle Column[`scheduleDetail` 12, cat.name 11 w500 màu cat]; trailing Row[`Switch(activeThumbColor primary)`, `PopupMenuButton(more_vert 18)` items 'Chỉnh sửa', 'Xoá' đỏ] | | `reminder`, `expenseCategoriesProvider` | switch → `toggleActive`; menu edit → form(existing); **delete → xoá ngay không xác nhận** (`:765-767`) | `:678-786` |
| 9 | `_DebugPanel` | Container margin (16,16,16,0) border orange α.5 1 r12 bg orange α.06 | | header `bug_report` 16 + 'DEBUG — Test notification' 12 w700 orange ls.5; Divider orange; Dropdown reminder; chip 5/10/15/30s; payload box monospace 11; `FilledButton.icon` orange 'Fire notification sau Ns'; `FilledButton.icon` purple 'Seed habit test data' | `kDebugMode && reminders.isNotEmpty` | | `:288-598` |
| 10 | Spacer 80 | | | | | | `:90` |

## E. Vùng bố cục
Header 56; body ListView; không footer/FAB (nút + ở AppBar và trong empty state).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Loading | spinner |
| Error | text thô |
| Empty | icon + CTA + preset strip + habit section (nếu có) |
| Data | preset (nếu còn) + habit (nếu có) + list |
| Reminder tắt | leading xám, title xám, switch off |
| Habit analyzing | `habitAnalysisProvider` chạy ngầm; không loading indicator |
| Debug | panel cam (chỉ debug build) |

## G. Tương tác
| Trigger | Kết quả | Điều hướng |
|---|---|---|
| + / CTA | form trống | sheet |
| Preset chip | form prefill title/freq/amount/icon→category | sheet |
| Habit Tạo | form prefill | sheet |
| Habit x | dismiss (biến mất, không undo) | |
| Switch | toggle active (reschedule notification) | |
| ⋮ Chỉnh sửa | | sheet |
| ⋮ Xoá | **xoá ngay** | |
| Tap tile (ngoài switch/menu) | **không có** | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Leading bg / title color | AnimatedContainer / AnimatedDefaultTextStyle | 260ms |
| Bell icon | AnimatedSwitcher | 140ms |
| List key change | AnimatedSwitcher (fade) | 260ms |
| Preset chip / habit x | PressableScale | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format |
|---|---|---|
| Preset | `kReminderPresets`: Dầu gội (monthly, 50k), Tiền điện (monthly, 300k), Tiền nước (monthly, 100k), Xăng xe (weekly, 100k), Đồ ăn vặt (weekly, 50k), Tiền thuê nhà (monthly, 3tr) | title |
| Habit | `keyword` (capitalize), `medianGapDays`, `daysSinceLast` ('hôm nay' / 'N ngày trước'), cat.name | |
| scheduleDetail | `'Mỗi ngày lúc HH:mm'` / `'Mỗi Thứ N lúc HH:mm'` / `'Ngày D hàng tháng lúc HH:mm'` (`recurring_reminder.dart:110-134`) | |
| amountHint | **không hiển thị** trong tile | |
| nextTrigger / warnBeforeHours | **không hiển thị** | |

## J. Responsive & edge cases
- Tile 3 dòng + Switch + menu ở trailing: trailing rộng ~100px; title dài wrap.
- Habit subtitle dài (`Thường mỗi 30 ngày · lần cuối 25 ngày trước · Sức khoẻ`) 11px 1 dòng không ellipsis → có thể overflow trên màn hẹp `[UNKNOWN]`.

## K. Text hiển thị
`Nhắc chi tiêu định kỳ` · `Gợi ý nhanh` · `<preset title>` · `Gợi ý từ lịch sử của bạn` · `Thường mỗi N ngày · lần cuối hôm nay|N ngày trước · <cat>` · `Tạo` · `Nhắc nhở của bạn` · `<scheduleDetail>` · `Chỉnh sửa` · `Xoá` · `Chưa có nhắc nhở nào` · `Tạo nhắc nhở để không quên chi tiêu định kỳ` · `Thêm nhắc nhở` · `Lỗi: …` · debug: `DEBUG — Test notification` `Chọn reminder:` `Fire sau:` `Payload sẽ gửi:` `Fire notification sau Ns` `Đang schedule...` `Seed habit test data` `🔔 "X" sẽ hiện sau N giây` `✅ Đã seed test data`

## L. Nhận xét nhanh
- Xoá reminder không xác nhận, không undo — trái với mọi nơi khác (dialog).
- Tile không hiển thị số tiền gợi ý, lần nhắc kế tiếp, cảnh báo trước — thông tin có trong model nhưng ẩn.
- Hai loại "gợi ý" (preset tĩnh & habit động) với 2 kiểu chip/tile khác nhau xếp trên list chính.
- Tiêu đề AppBar "Nhắc chi tiêu định kỳ" khác label lối vào "Nhắc nhở"/"Quản lý nhắc nhở".
