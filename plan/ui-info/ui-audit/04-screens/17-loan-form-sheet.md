# 17 — LoanFormSheet (Thêm / Sửa khoản vay)

## A. Metadata
- **Tên**: `LoanFormSheet(existing?, initialType?)`
- **Route**: modal `showModalBottomSheet(isScrollControlled)`
- **File**: `lib/features/loan/presentation/widgets/loan_form_sheet.dart` (382 LOC)
- **Vào từ**: LoanList (+/FAB/CTA), LoanDetail ✎
- **Thoát đi**: X / submit → pop; `showDatePicker` (`useRootNavigator: false`)

## B. Mục đích
Nhập loại (vay/cho vay), tên, người liên quan, hạn (tuỳ chọn), ghi chú, số tiền gốc.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad L16 R16 T(12+safeTop) B(viewInsets); SingleChildScrollView
│           ━━━━ 36×4           │
│ [X]    Thêm khoản vay   (40)  │ IconButton close shrinkWrap · 16 w600 · SizedBox 40
│ [ Tôi đang vay ][ Tôi cho vay ]│ 2 Expanded chip pad V10 r10; red400 / green500 α.12; 13 w600  :165-210
│ ┌ Tên khoản vay (vd: Vay mua xe) ┐│ TextField autofocus outline r10
│ ┌ Người cho vay | Người vay ┐  │ label đổi theo loại                              :231-244
│ ┌ 📅 Ngày hết hạn (tuỳ chọn)  [x] ┐│ GestureDetector Container pad 12 border cs.outline .8 r10; 13  :248-291
│ ┌ Ghi chú (tuỳ chọn) ┐        │
│                   5.000.000 ₫ │ Text 28 w600 accent ls−1 + '₫' 14
│ ─────────────────────────────  │ Divider 12
│   Numpad                      │
│ [     Thêm khoản vay      ]   │ FilledButton bg accent pad V12 r10; disabled nếu loading|!hasValue|title rỗng
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | Handle + header | như WalletForm (`SizedBox(40)` cân phải) | 16 | 16 w600 | `_isEdit` | X → pop | `:126-161` |
| 2 | Type chips | Row 2 Expanded, pad right 6 cho chip đầu; `AnimatedContainer 150ms` pad V10 r10; bg color α.12 / transparent; border color / outlineVariant .8; 13 w600 center | 12 dưới | color: borrowed `red.shade400`, lent `green.shade500` | `_type` (mặc định `initialType ?? borrowed`); đổi type **reset màu** (`_colorHex = palette[0]` / `[12]`) | tap | `:165-210` |
| 3 | Tên | TextField outline r10 pad H12 V10, autofocus | 10 | | `_titleCtrl` | | `:214-227` |
| 4 | Người | TextField label `'Người ${borrowed ? 'cho vay' : 'vay'}'` | 10 | | `_contactCtrl` | | `:231-244` |
| 5 | Ngày hết hạn | `GestureDetector > Container` pad H12 V12 border `cs.outline` .8 r10: `calendar_today_outlined` 16; text 13 onSurfaceVariant/onSurface; Spacer; `close` 16 nếu có ngày | 10 | | `_dueDate` | tap → `showDatePicker(initial now+30d, first now, last +10y)`; x → null | `:248-291, 64-75` |
| 6 | Ghi chú | TextField | 12 | | `_noteCtrl` | | `:295-307` |
| 7 | Số | Row end Text `formatted` 28 w600 accent ls−1 + '₫' 14 | | | `_amountCtrl` | | `:311-331` |
| 8 | Divider 12 .5 | | | | | | `:332` |
| 9 | Numpad | | | | | | `:334-337` |
| 10 | Submit | `FilledButton` bg accent pad V12 r10; spinner 18 / Text 14 w600 | pad (0,8,0,16) | | disabled `_loading \|\| !hasValue \|\| title.isEmpty` — **nhưng** `_titleCtrl` không có listener → nút không rebuild khi gõ tên (chỉ rebuild khi `_amountCtrl` đổi hoặc setState khác) | | `:339-376` |

## E. Vùng bố cục
Scroll toàn sheet; top padding + safe area; không SafeArea bottom.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Thêm | 'Thêm khoản vay'; loại theo `initialType`; màu `palette[0]` `#FF6B6B` (borrowed) / `palette[12]` `#66BB6A` (lent); nút 'Thêm khoản vay' |
| Sửa | prefill; **màu giữ nguyên** nhưng đổi loại sẽ reset màu; nút 'Lưu thay đổi'; `startDate` giữ nguyên (không sửa được) |
| Date picker | dialog Material mặc định (không theme override như Stats) |
| Nút disabled | gõ tên xong nút vẫn xám cho đến khi nhập số (vì rebuild bởi `_amountCtrl`) — nếu nhập số trước rồi gõ tên: nút **vẫn disabled** đến khi có setState khác `[UNKNOWN: chưa kiểm chứng runtime]` |
| Lỗi lưu | không bắt |

## G. Tương tác
| Trigger | Kết quả |
|---|---|
| Chip loại | đổi type + màu + label "Người …" |
| Ngày | date picker → set; x → clear |
| Numpad | số gốc |
| Submit | add/update → pop |
| X / kéo | đóng, mất dữ liệu |

## H. Animation/transition
Chip 150ms; không khác.

## I. Dữ liệu hiển thị
| Field | Format |
|---|---|
| Hạn | `'Hạn: d/M/yyyy'` |
| Số | `formatted` + ' ₫' |
| Màu | không cho chọn (tự theo loại) dù model có `colorHex` và palette |

## J. Responsive & edge cases
- Keyboard (autofocus tên) + numpad cùng hiện; sheet cuộn dài.
- `firstDate: now` → khi sửa loan có hạn trong quá khứ, `initialDate = _dueDate` < firstDate → `showDatePicker` **assert/throw** `[UNKNOWN: chưa kiểm chứng; Flutter yêu cầu initialDate ≥ firstDate]`.
- Không có ngày bắt đầu chọn được.

## K. Text hiển thị
`Thêm khoản vay` · `Chỉnh sửa khoản vay` · `Tôi đang vay` · `Tôi cho vay` · `Tên khoản vay (vd: Vay mua xe)` · `Người cho vay` · `Người vay` · `Ngày hết hạn (tuỳ chọn)` · `Hạn: d/M/yyyy` · `Ghi chú (tuỳ chọn)` · `₫` · `Lưu thay đổi`

## L. Nhận xét nhanh
- Nút submit phụ thuộc tên nhưng không lắng nghe `_titleCtrl` → trạng thái nút không đồng bộ.
- Không chọn ngày bắt đầu, không lãi suất, không lịch trả — model đơn giản nhưng form vẫn dài vì numpad.
- Date picker mặc định không theme (Stats có theme riêng) → 2 diện mạo picker.
- Sửa loan có hạn quá khứ có thể crash date picker.
