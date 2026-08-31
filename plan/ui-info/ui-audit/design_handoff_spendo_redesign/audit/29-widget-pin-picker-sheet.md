# 29 — _CategoryPickerSheet (Chọn danh mục cho widget slot)

## A. Metadata
- **Tên**: `_CategoryPickerSheet(allCats, currentSlots, currentSlotIndex)` (private, `widget_pin_section.dart:180-268`)
- **Route**: modal `showModalBottomSheet<Category>` (không scrollControlled) (`:73-81`)
- **Vào từ**: Settings › Widget màn hình chính › tap slot
- **Thoát đi**: tap category → pop(cat); ngoài → pop(null)

## B. Mục đích
Gán 1 danh mục chi vào 1 trong 4 slot của Android widget medium.

## C. Layout skeleton
```
╭───────────────────────────────╮
│           ━━━━ 36×4           │ margin V10
│ Chọn danh mục cho slot 2 15 w600│ pad (16,4,16,12)
│ ───────────────────────────── │
│ [▢] Ăn uống                 › │ ListTile leading 36 r8 α.15 icon 18; title 14
│ ───────────────────────────── │ Divider indent 56
│ [▢] Di chuyển  (mờ)           │ isUsed: title onSurfaceVariant, subtitle 'Đang dùng ở slot khác' 11, không trailing, không tap
│ [▢] Học tập                 › │
│ (16)                          │
╰───────────────────────────────╯ Flexible ListView shrinkWrap
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | Handle | 36×4 margin V10 | | | `:205-213` |
| 2 | Title | 15 w600 pad (16,4,16,12) | `currentSlotIndex+1` | | `:214-221` |
| 3 | Divider h1 | | | | `:222` |
| 4 | `Flexible(ListView.separated shrinkWrap)` | sep `Divider(h1, indent 56)` | `allCats` (expense) | | `:223-263` |
| 4a | ListTile | leading 36 r8 cat α.15 icon 18; title 14 (onSurfaceVariant nếu used); subtitle 'Đang dùng ở slot khác' 11 nếu used; trailing `chevron_right` 18 nếu không used | `usedIds` = slots khác | tap (nếu không used) → pop(cat) | `:232-260` |

## E. Vùng bố cục
Sheet không scrollControlled → tối đa ~50% màn; list cuộn bên trong.

## F. Trạng thái màn hình
Used items mờ; không empty state khi `allCats` rỗng.

## G. Tương tác
Tap → chọn; không có "Bỏ chọn" trong sheet (xoá slot bằng nút x nhỏ 12px trên card).

## H. Animation/transition
Không.

## I. Dữ liệu hiển thị
Tên + icon + màu danh mục.

## J. Responsive & edge cases
Nhiều danh mục: cuộn trong 50% màn.

## K. Text hiển thị
`Chọn danh mục cho slot N` · `<tên danh mục>` · `Đang dùng ở slot khác`

## L. Nhận xét nhanh
- Xoá slot qua icon x 12px góc card (tap-target ~12px) — khó chạm; sheet không có tuỳ chọn "Trống".
- Không preview widget thực tế.
