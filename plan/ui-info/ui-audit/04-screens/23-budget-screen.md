# 23 — BudgetScreen (Hạn mức chi tiêu tháng) — thực chất là bottom sheet

## A. Metadata
- **Tên**: `BudgetScreen` (tên "Screen" nhưng render trong `showModalBottomSheet`)
- **Route**: modal (`budget_type_sheet.dart:53-57`, `home_feature_actions.dart:214-220`)
- **File**: `lib/features/budget/presentation/screens/budget_screen.dart` (205 LOC)
- **Vào từ**: BudgetTypeSheet option 1; AllFeatures "Hạn mức tháng"
- **Thoát đi**: Lưu / Xoá → pop

## B. Mục đích
Đặt/sửa/xoá hạn mức tổng cho **tháng đang chọn ở Home** (`selectedMonthProvider` `:43, 61`).

## C. Layout skeleton
```
╭───────────────────────────────╮ pad B(viewInsets)
│           ━━━━ 36×4           │
│ Hạn mức chi tiêu 15 w600  Xoá │ title + 'Tháng M/YYYY' 12; TextButton Xoá #E53935 13 chỉ khi đã có
│ Tháng 8/2026                  │
│                    5.000.000 ₫│ Text formatted 32 w600 #6C63FF ls−1 + '₫' 14
│ ─────────────────────────────  │ Divider 16 .5
│   Numpad                      │
│ [ Đặt hạn mức 5.000.000 ₫ ]   │ FilledButton bg #6C63FF minH48 r12; 'Cập nhật hạn mức' nếu đã có
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | Handle | 36×4 margin V10 | | | `:73-81` |
| 2 | Header Row | Column['Hạn mức chi tiêu' 15 w600, 'Tháng M/YYYY' 12 onSurfaceVariant]; Spacer; `TextButton('Xoá')` fg `#E53935` 13 nếu `hasBudget` | `currentBudgetProvider` | Xoá → `BudgetRepository.delete(key)` → pop (**không xác nhận**) | `:83-117` |
| 3 | Số | Row end: Text `formatted` 32 w600 `#6C63FF` ls−1 + '₫' 14 | `_amountCtrl` prefill postFrame từ budget hiện có | | `:122-147` |
| 4 | Divider 16 .5 | | | | `:149` |
| 5 | Numpad | | | | `:151-154` |
| 6 | Submit | `FilledButton` bg `#6C63FF` minH48 r12; `AnimatedSwitcher 140ms` spinner 18 / label 15 w600 | disabled nếu `!hasValue \|\| _loading` | `set(key, value)` → pop | `:157-200` |

## E. Vùng bố cục
Sheet ~430px không scroll; không SafeArea.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Chưa có budget | không nút Xoá; số 0; nút 'Đặt hạn mức 0 ₫' disabled |
| Đã có | prefill (sau 1 frame); nút Xoá; nút 'Cập nhật hạn mức' |
| Loading | spinner |
| Lỗi | không bắt (`_save` không try/catch; `_loading` không reset nếu throw) |

## G. Tương tác
Numpad; Lưu; Xoá không xác nhận; kéo đóng.

## H. Animation/transition
Nút label AnimatedSwitcher 140ms; số **không** animated (Text thường).

## I. Dữ liệu hiển thị
`'Tháng ${month.month}/${month.year}'`; `formatted` "5.000.000" + ₫.

## J. Responsive & edge cases
Tháng lấy từ Home; nếu mở từ AllFeatures sau khi đổi tháng ở Home → đặt cho tháng đó (đúng ý đồ nhưng không rõ ràng trong sheet ngoài dòng phụ 12px).

## K. Text hiển thị
`Hạn mức chi tiêu` · `Tháng M/YYYY` · `Xoá` · `₫` · `Đặt hạn mức X ₫` · `Cập nhật hạn mức`

## L. Nhận xét nhanh
- Không hiển thị đã chi bao nhiêu / còn bao nhiêu trong sheet đặt hạn mức.
- Màu #6C63FF cứng, không theo theme.
- Xoá không xác nhận (khác giao dịch/ví/loan).
- Sau khi đặt xong, **không có nơi nào trong UI đang dùng hiển thị tiến độ hạn mức tháng** (`BudgetCard` dead) ngoài AddTransactionSheet (chỉ hạn mức danh mục) → hạn mức tháng gần như vô hình.
