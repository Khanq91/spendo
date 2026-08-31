# 27 — _VisualModeSheet & _ThemeColorSheet (Settings › Giao diện)

## A. Metadata
- **Tên**: `_VisualModeSheet`, `_ThemeColorSheet` (private trong `settings_screen.dart:1269-1366`) + `VisualModePicker` (`lib/shared/widgets/visual_mode_picker.dart`)
- **Route**: modal `showModalBottomSheet` (không scrollControlled) (`settings_screen.dart:218-222, 261-265`)
- **Vào từ**: Settings › Đồ họa / Màu chủ đạo
- **Thoát đi**: chọn → pop

## B. Mục đích
Chọn chế độ đồ hoạ (Normal/Fancy) và 1/5 màu chủ đạo.

## C. Layout skeleton
```
_VisualModeSheet                          _ThemeColorSheet
╭─────────────────────────────╮           ╭─────────────────────────────╮
│ SafeArea pad (20,16,20,20)  │           │ SafeArea pad V16            │
│ Chọn đồ họa 16 w600         │           │ Chọn màu chủ đạo 16 w600 (pad H20 V8)│
│ Hiệu ứng chỉ thay đổi… 12   │           │ ● Rose (Mặc định)        ✓  │ ListTile swatch 24
│ (14)                        │           │ ● Indigo Midnight           │
│ ┌ ○ Bình thường          ◉ ┐│ tile pad H16 V14 r12 │ ● Emerald Wealth            │
│ │   Giao diện nhẹ…          ││           │ ● Slate Premium             │
│ └───────────────────────────┘│           │ ● Amber Warm                │
│ (12)                        │           ╰─────────────────────────────╯
│ ┌ ✨ Xịn xò              ○ ┐│
│ │   Nền aurora…             ││
│ └───────────────────────────┘│
╰─────────────────────────────╯
(Không có drag handle ở cả 2)
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| V1 | Title / subtitle | 16 w600 onSurface / 12 onSurfaceVariant; 4; 14 | | | `settings_screen.dart:1284-1297` |
| V2 | `VisualModePicker(useGlass: false)` | 2 `_VisualModeTile`: `PressableScale(r12) > AnimatedContainer 260ms` bg `primaryContainer` α.5 (selected) / `surface`; pad H16 V14; Row[icon `circle`/`sparkles` 22 primary/onSurface, 12, Column[title 15 w700, 4, subtitle 12 onSurfaceVariant h1.25], 12, `AnimatedSwitcher` icon `circleCheck` primary / `circle` outline 20]; gap 12 | `visualModeProvider` | tap → `setMode` + pop | `visual_mode_picker.dart:21-148` |
| C1 | Title | 16 w600 pad H20 V8; 8 | | | `:1327-1338` |
| C2 | ListTile ×5 | leading swatch 24 circle `scheme.swatch`; title `scheme.label` 14; trailing `check` 16 primary nếu chọn | `themeProvider.colorScheme` | tap → `setColorScheme` + pop | `:1339-1360` |

## E. Vùng bố cục
Sheet ~250 / ~330px, `SafeArea` bottom có.

## F. Trạng thái màn hình
Selected theo provider; không loading.

## G. Tương tác
Tap → đổi + pop ngay (không preview).

## H. Animation/transition
Tile bg 260ms; tick 140ms scale+fade.

## I. Dữ liệu hiển thị
Label enum; swatch hex.

## J. Responsive & edge cases
Không có preview màu trước khi áp dụng; đổi màu rebuild toàn app tức thì.

## K. Text hiển thị
`Chọn đồ họa` · `Hiệu ứng chỉ thay đổi phần trình bày, không ảnh hưởng dữ liệu.` · `Bình thường` · `Giao diện nhẹ, ổn định và tiết kiệm tài nguyên.` · `Xịn xò` · `Nền aurora, điều hướng liquid glass và hiệu ứng mềm hơn.` · `Chọn màu chủ đạo` · `Rose (Mặc định)` · `Indigo Midnight` · `Emerald Wealth` · `Slate Premium` · `Amber Warm`

## L. Nhận xét nhanh
- Hai sheet thiếu drag handle trong khi 14 sheet khác có.
- Tên màu tiếng Anh ("Emerald Wealth") giữa app tiếng Việt; "Xịn xò" là ngôn ngữ thân mật khác tông với phần còn lại.
- Mode/Sáng/Tối nằm ngoài (3 ListTile) còn màu & đồ hoạ nằm trong sheet → 2 pattern cho 3 tuỳ chọn cùng nhóm.
