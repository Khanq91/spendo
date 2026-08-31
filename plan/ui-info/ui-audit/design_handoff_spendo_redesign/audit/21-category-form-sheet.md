# 21 — CategoryFormSheet (Thêm / Sửa danh mục)

## A. Metadata
- **Tên**: `CategoryFormSheet(existing?, isIncome)`
- **Route**: modal `showModalBottomSheet(isScrollControlled)`
- **File**: `lib/features/categories/presentation/widgets/category_form_sheet.dart` (292 LOC)
- **Vào từ**: Settings › Danh mục › Thêm / ✎
- **Thoát đi**: submit → pop; kéo/tap ngoài

## B. Mục đích
Đặt tên, chọn 1/15 màu, 1/16 icon cho danh mục thu hoặc chi.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad L16 R16 T12 B(viewInsets) — KHÔNG scroll
│           ━━━━ 36×4           │
│ Thêm danh mục 15 w600         │
│ ┌ Tên danh mục ┐              │ TextField outline r10 autofocus
│ Màu sắc 13 w500               │
│ ● ● ● ● ● ● ● ●              │ Wrap 8/8, swatch 32 circle; selected: border surface 3 + shadow α.5 blur 6 + check 14 white
│ ● ● ● ● ● ● ●                │
│ Icon 13 w500                  │
│ ▢ ▢ ▢ ▢ ▢ ▢ ▢                 │ Wrap 8/8, ô 40 r8 bg surfaceContainerHighest / color α.15; border outlineVariant .5 / color 1.5; icon 20
│ ▢ ▢ ▢ ▢ ▢ ▢ ▢                 │
│ ▢ ▢                           │
│ [       Thêm danh mục      ]  │ FilledButton bg accent pad V12 r10
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|
| 1 | Handle | 36×4 outlineVariant; 16 dưới | | | | `:118-128` |
| 2 | Title | 15 w600; 16 dưới | | `_isEdit` | | `:130-134` |
| 3 | Tên | TextField labelText 'Tên danh mục', outline r10, H12 V10, autofocus; 16 dưới | | `_nameCtrl` | | `:137-152` |
| 4 | 'Màu sắc' | 13 w500 onSurface; 8 | | | | `:155-163` |
| 5 | Swatches | `Wrap(8,8)` 15 × `GestureDetector > AnimatedContainer 150ms` 32 circle | selected: `Border.all(cs.surface, 3)` + BoxShadow color α.5 blur 6 + `check` 14 white | `_selectedColor` (mặc định `palette.first` `#FF6B6B`) | tap | `:164-205` |
| 6 | 'Icon' | 13 w500; 8 | | | | `:209-217` |
| 7 | Icon cells | `Wrap(8,8)` 16 × 40×40 r8 `AnimatedContainer 150ms`; bg color α.15 / `surfaceContainerHighest`; border color 1.5 / outlineVariant .5; icon `categoryIcon(name)` 20 color / onSurfaceVariant | | `_selectedIcon` (mặc định 'restaurant'); `_kIconNames` 16 (bao gồm 'more_horiz' → default circleEllipsis) | tap | `:218-253` |
| 8 | Submit | `SizedBox(∞) FilledButton` bg accent pad V12 r10; spinner 18 / 'Thêm danh mục'/'Lưu thay đổi' 14 w600; 16 dưới | | disabled chỉ khi `_loading`; tên rỗng → im lặng | add/update → pop; `DuplicateCategoryException` → SnackBar | `:257-286` |

## E. Vùng bố cục
`Column(min)` không scroll; cao ≈ 12+4+16+18+16+52+16+21+8+(2×32+8)+16+21+8+(3×40+16)+20+44+16 ≈ **470px** + keyboard (autofocus) ≈ 300 → **>770px** trên màn 640 → nội dung trên bị đẩy khỏi màn `[UNKNOWN: cần kiểm chứng; không có SingleChildScrollView]`.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Thêm | màu đỏ đầu, icon restaurant, nút 'Thêm danh mục' màu accent |
| Sửa | prefill; **không** đổi được loại thu/chi; nút 'Lưu thay đổi' |
| Loading | spinner |
| Trùng tên | SnackBar `error.toString()` (hiện dưới sheet? `ScaffoldMessenger.of(context)` của sheet → snackbar hiện ở Scaffold cha, bị sheet che một phần `[UNKNOWN]`) |
| Tên rỗng | im lặng |

## G. Tương tác
Tap swatch/icon → chọn; submit; kéo đóng.

## H. Animation/transition
Swatch/icon AnimatedContainer 150ms.

## I. Dữ liệu hiển thị
Palette 15 hex; 16 icon name; `isIncome` không hiển thị (không có nhãn "Danh mục chi/thu" trong sheet).

## J. Responsive & edge cases
- Không scroll + keyboard → tràn.
- Wrap tự xuống dòng theo width.

## K. Text hiển thị
`Thêm danh mục` · `Chỉnh sửa danh mục` · `Tên danh mục` · `Màu sắc` · `Icon` · `Lưu thay đổi` · (SnackBar lỗi trùng)

## L. Nhận xét nhanh
- Sheet không cuộn với autofocus keyboard → nguy cơ tràn/mất phần trên.
- Không cho biết đang tạo danh mục Chi hay Thu.
- Icon cố định 16 Lucide, không tìm kiếm; 'more_horiz' hiển thị cùng icon default.
- Màu chọn inline (khác WalletForm dùng dialog).
