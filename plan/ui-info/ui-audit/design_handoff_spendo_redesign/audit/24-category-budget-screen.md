# 24 — CategoryBudgetScreen (Hạn mức theo danh mục) + _SetCategoryBudgetSheet

## A. Metadata
- **Tên**: `CategoryBudgetScreen` (DraggableScrollableSheet trong modal)
- **Route**: modal (`budget_type_sheet.dart:71-75`, `home_feature_actions.dart:222-228`)
- **File**: `lib/features/budget/presentation/screens/category_budget_screen.dart` (529 LOC)
- **Vào từ**: BudgetTypeSheet option 2; AllFeatures "Hạn mức danh mục"
- **Thoát đi**: kéo xuống; sheet con `_SetCategoryBudgetSheet`

## B. Mục đích
Xem danh mục chi đã có hạn mức (tiến độ tháng hiện tại theo `expensesByCategoryProvider` = tháng của Home), sửa/xoá, và đặt cho danh mục chưa có.

## C. Layout skeleton
```
╭───────────────────────────────╮ DraggableScrollableSheet initial .75, min .5, max .95
│           ━━━━ 36×4           │
│ Hạn mức theo danh mục 15 w600   2/8 danh mục 12│ pad (16,0,16,12)
│ ───────────────────────────── │ Divider
│ ĐANG THEO DÕI 11 w600 ls.5    │ _SectionLabel pad (16,16,16,6)
│ [▢] Ăn uống         [✎] [🗑]  │ _CategoryBudgetTile ListTile leading 40 r10; subtitle '850.000 ₫ / 1.000.000 ₫  ⚠️ Vượt hạn'
│      ▬▬▬▬▬▬▬▬▬▬ 4px           │ AnimatedProgressBar pad (56,0,16,8) xanh/cam/đỏ
│ ───────────────────────────── │ Divider indent 56
│ THÊM DANH MỤC | CHỌN DANH MỤC ĐỂ ĐẶT HẠN MỨC│
│ [▢] Di chuyển     Chưa đặt hạn mức   + Đặt │ _CategoryNobudgetTile: icon α.6; TextButton.icon 'Đặt' 12
│ (32)                          │
╰───────────────────────────────╯
 _SetCategoryBudgetSheet (sheet con):
╭───────────────────────────────╮
│           ━━━━                │
│ [▢] Đặt hạn mức | Sửa hạn mức 15 w600│ icon 32 r8 α.15 icon 16; tên cat 12
│                    1.000.000 ₫│ 32 w600 màu cat
│ ─────────────────────────────  │
│   Numpad                      │
│ [ Đặt hạn mức 1.000.000 ₫ ]   │ FilledButton bg màu cat minH48 r12; 'Cập nhật hạn mức' nếu sửa
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | `DraggableScrollableSheet(.75/.5/.95, expand false)` | | | kéo | `:31-36` |
| 2 | Handle | 36×4 margin V10 | | | `:40-48` |
| 3 | Header Row | 'Hạn mức theo danh mục' 15 w600; Spacer; `'${withBudget}/${all} danh mục'` 12 | `expenseCategoriesProvider`, `categoryBudgetMapProvider` | | `:50-71` |
| 4 | Divider h1 | | | | `:73` |
| 5 | `_SectionLabel` | Text 11 w600 ls.5 onSurfaceVariant pad (16,16,16,6) | 'Đang theo dõi' / 'Thêm danh mục' / 'Chọn danh mục để đặt hạn mức' (khi chưa có cái nào) | | `:148-168` |
| 6 | `_CategoryBudgetTile` | ListTile leading 40 r10 cat α.15 icon 20; title 14 w500; subtitle `'spent / budget'` 12 (+ `'  ⚠️ Vượt hạn'` đỏ nếu over) hoặc chỉ budget nếu progress null; trailing Row[`IconButton(pencil 16)` compact, `IconButton(trash2 16 red)` compact]; dưới: `AnimatedProgressBar` h4 pad (56,0,16,8) màu income / orange (≥.8) / expenseAlt (over); `Divider(indent 56)` | `progressMap[cat.id]` | ✎ → `_SetCategoryBudgetSheet(existing)`; 🗑 → **xoá ngay không xác nhận** (`:96-98`) | `:172-282` |
| 7 | `_CategoryNobudgetTile` | ListTile leading α.10 icon α.6; title 14 onSurfaceVariant; subtitle 'Chưa đặt hạn mức' 12 **outlineVariant** (contrast rất thấp); trailing `TextButton.icon(add 14, 'Đặt' 12)` compact primary; Divider indent 56 | | Đặt → sheet con | `:286-335` |
| 8 | `_SetCategoryBudgetSheet` | pad B(viewInsets) Column min: handle; header Row[icon box 32 r8 α.15 icon 16, 10, Column['Đặt hạn mức'/'Sửa hạn mức' 15 w600, cat.name 12]]; 12; số 32 w600 màu cat ls−1 + ₫; Divider 16; Numpad; `FilledButton` bg cat minH48 r12 AnimatedSwitcher 140ms | `existingAmount` prefill | save → pop | `:339-529` |

## E. Vùng bố cục
Sheet kéo được 50–95% màn; list cuộn bằng `scrollCtrl` của sheet; sheet con mở chồng lên (2 sheet).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Chưa có budget nào | chỉ section "Chọn danh mục để đặt hạn mức" + tất cả tile mờ |
| Có budget | 2 section |
| Over | subtitle đỏ + '⚠️ Vượt hạn'; bar đỏ |
| ≥80% | bar cam |
| Không có danh mục chi | header '0/0 danh mục', list trống **không empty state** |
| Loading categories | `expenseCategoriesProvider` trả [] khi loading → giống "không có" |
| Sheet con lỗi lưu | không bắt, `_loading` kẹt true |

## G. Tương tác
| Trigger | Kết quả |
|---|---|
| Kéo handle | resize .5–.95 |
| ✎ / Đặt | sheet con (chồng) |
| 🗑 | xoá tức thì |
| Numpad + Lưu | set → pop sheet con; list cập nhật qua stream |

## H. Animation/transition
Progress 360ms; nút label 140ms; sheet default.

## I. Dữ liệu hiển thị
| Field | Format |
|---|---|
| spent / budget | `formatVND(p.spent) / formatVND(budgetAmount)` |
| Đếm | `'A/B danh mục'` |
| Tháng | **không hiển thị** tháng nào đang tính spent |

## J. Responsive & edge cases
- Subtitle dài ('850.000 ₫ / 1.000.000 ₫  ⚠️ Vượt hạn') 12px + trailing 2 nút ~96px → có thể wrap 2 dòng.
- Sheet con + keyboard: không có keyboard (numpad) → OK.

## K. Text hiển thị
`Hạn mức theo danh mục` · `A/B danh mục` · `Đang theo dõi` · `Thêm danh mục` · `Chọn danh mục để đặt hạn mức` · `X ₫ / Y ₫` · `⚠️ Vượt hạn` · `Chưa đặt hạn mức` · `Đặt` · `Đặt hạn mức` · `Sửa hạn mức` · `₫` · `Đặt hạn mức X ₫` · `Cập nhật hạn mức`

## L. Nhận xét nhanh
- Xoá hạn mức tức thì không xác nhận/undo.
- Không hiển thị tháng đang tính tiến độ; hạn mức danh mục là **cố định mọi tháng** (model không có month) nhưng tiến độ theo tháng Home — không giải thích.
- Text 'Chưa đặt hạn mức' màu `outlineVariant` gần như không đọc được.
- Sheet chồng sheet (list → set) và tên class "Screen" cho một sheet.
