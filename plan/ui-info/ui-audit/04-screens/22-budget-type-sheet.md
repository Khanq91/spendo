# 22 — BudgetTypeSheet (Chọn loại hạn mức)

## A. Metadata
- **Tên**: `BudgetTypeSheet`
- **Route**: modal (`home_feature_actions.dart:206-212`)
- **File**: `lib/features/budget/presentation/widgets/budget_type_sheet.dart` (149 LOC)
- **Vào từ**: Home grid "Hạn mức" (cũng từ `BudgetCard`/`QuickActionsBar` dead)
- **Thoát đi**: option → `pop()` rồi `showModalBottomSheet` sheet kế tiếp (sheet-to-sheet)

## B. Mục đích
Bước trung gian chọn "Hạn mức cả tháng" hay "Hạn mức theo danh mục".

## C. Layout skeleton
```
╭───────────────────────────────╮ pad (16,12,16,32)
│           ━━━━ 36×4           │
│ Đặt hạn mức chi tiêu 15 w600  │
│ Chọn loại hạn mức bạn muốn thiết lập 12│
│ (20)                          │
│ ┌ [📅] Hạn mức cả tháng      › ┐│ _OptionCard pad 16 border outlineVariant .8 r14; icon box 44 r12 #6C63FF α.12 icon 22
│ │      Tổng chi tiêu trong tháng không vượt quá X ₫ ││ title 14 w600; subtitle 12
│ └───────────────────────────┘ │
│ (12)                          │
│ ┌ [🏷] Hạn mức theo danh mục  › ┐│ icon primary
│ │      Đặt giới hạn riêng cho từng danh mục chi tiêu ││
│ └───────────────────────────┘ │
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Tương tác | Source |
|---|---|---|---|---|
| 1 | Handle | 36×4 outlineVariant, margin B16 | | `:22-32` |
| 2 | Title / subtitle | 15 w600 / 12 onSurfaceVariant; 4 giữa; 20 dưới | | `:34-42` |
| 3 | `_OptionCard` #1 | `InkWell(r14) > Container(pad 16, border outlineVariant .8, r14)` Row[icon box 44 r12 `#6C63FF` α.12 `calendarDays` 22, 14, Expanded Column[title 14 w600, 2, subtitle 12], 8, `chevron_right` 18] | pop → sheet `BudgetScreen` | `:46-59, 84-149` |
| 4 | `_OptionCard` #2 | icon `tag` màu `cs.primary` | pop → sheet `CategoryBudgetScreen` | `:64-77` |

## E. Vùng bố cục
Sheet ~250px; không scroll.

## F. Trạng thái màn hình
1 state. Không hiển thị hạn mức hiện có (không biết đã đặt chưa).

## G. Tương tác
2 option → sheet kế tiếp (đóng sheet này trước → 2 animation nối nhau).

## H. Animation/transition
InkWell ripple; sheet mặc định ×2.

## I. Dữ liệu hiển thị
Tĩnh.

## J. Responsive & edge cases
Subtitle 12 wrap.

## K. Text hiển thị
`Đặt hạn mức chi tiêu` · `Chọn loại hạn mức bạn muốn thiết lập` · `Hạn mức cả tháng` · `Tổng chi tiêu trong tháng không vượt quá X ₫` · `Hạn mức theo danh mục` · `Đặt giới hạn riêng cho từng danh mục chi tiêu`

## L. Nhận xét nhanh
- Bước trung gian thuần điều hướng, không hiển thị trạng thái hạn mức hiện tại.
- Icon #6C63FF (tím) cho tháng vs primary cho danh mục — hai màu không có ý nghĩa phân biệt.
- Sheet mở sheet: đóng rồi mở lại tạo 2 animation liên tiếp.
