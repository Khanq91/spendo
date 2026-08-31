# 14 — WalletFormSheet (Thêm / Sửa nguồn tiền)

## A. Metadata
- **Tên**: `WalletFormSheet(existing?)`
- **Route**: modal `showModalBottomSheet(isScrollControlled)` không truyền shape (dùng theme)
- **File**: `lib/features/wallets/presentation/widgets/wallet_form_sheet.dart` (480 LOC)
- **Vào từ**: Wallets (+ / nút cuối / empty CTA), WalletDetail ✎, Home WalletCardHome (khi chưa có ví)
- **Thoát đi**: X → pop; submit → pop; dialog chọn màu

## B. Mục đích
Tạo/sửa ví: tên, loại (6), màu (15), ghi chú, số dư ban đầu (numpad).

## C. Layout skeleton
```
╭───────────────────────────────╮ pad L16 R16 T(12 + safeTop) B(viewInsets)  :170-176
│           ━━━━ 36×4           │
│ [X]   Thêm nguồn tiền  (24)   │ IconButton close shrinkWrap · title 16 w600 center · SizedBox 24  :195-218
│ ┌ Tên (vd: MB Bank, Tiền mặt...) ┐│ TextField outline r10, autofocus                :222-235
│ Loại 13 w500                  │
│ (… Tiền mặt)(… Ngân hàng)(… Ví điện tử)│ Wrap chip 6 loại: icon 13 (circleEllipsis!) + label 12, pad H10 V6 r20  :248-302
│ (… Thẻ tín dụng)(… Đầu tư)(… Khác)│
│ Màu sắc 13   (● Chọn màu)     │ InkWell chip accent α.15 border accent, dot 16 + text 12 w600  :306-355
│ ┌ Ghi chú (tuỳ chọn) ┐        │ TextField outline r10                            :359-371
│ Số dư ban đầu 13 w500         │
│ ┌ ⓘ Số dư thực tế sẽ được tính tự động… ┐│ banner accent α.08 border α.2 r8, 11  :385-407
│                   1.000.000 ₫ │ Text 28 w600 accent ls−1 + '₫' 14 (Text thường)   :411-433
│ ─────────────────────────────  │ Divider h12 .5
│   1   2   3                   │ Numpad (~300px)
│   4   5   6                   │
│   7   8   9                   │
│  00   0   ⌫                   │
│ [     Tạo nguồn tiền      ]   │ FilledButton bg accent pad V12 r10, pad (0,8,0,16)  :442-474
╰───────────────────────────────╯ SingleChildScrollView
```

## D. Bảng component tree
| # | Element | Loại | Kích thước/Spacing | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|
| 1 | Handle | 36×4 r2 outlineVariant | 16 dưới | | | | `:183-192` |
| 2 | Header Row | `IconButton(close)` padding 0, constraints 0, shrinkWrap (tap ≈ 24) · Expanded title 16 w600 center · `SizedBox(24)` | 16 dưới | | `_isEdit` → 'Chỉnh sửa nguồn tiền' / 'Thêm nguồn tiền' | X → pop | `:195-218` |
| 3 | Tên | `TextField` labelText, `OutlineInputBorder(r10)`, contentPadding H12 V10, `autofocus` | 12 dưới | | `_nameCtrl` | | `:222-235` |
| 4 | 'Loại' | Text 13 w500 onSurface | 8 dưới | | | | `:239-246` |
| 5 | Type chips | `Wrap(8,8)` 6 × `GestureDetector > AnimatedContainer(150ms)` pad H10 V6; bg accent α.15 / transparent; border accent / outlineVariant .8; r20; icon `categoryIcon(t.iconName)` 13 + label 12 w600/w400 | 12 dưới | | `_type` (mặc định `cash`) | tap | `:248-302` |
| 6 | 'Màu sắc' + chip | Row: Text 13 w500; 12; `InkWell(r20) > Container` pad H12 V6 bg accent α.15 border accent .8 r20 [dot 16 accent, 8, 'Chọn màu' 12 w600 accent] | 16 dưới | | `_colorHex` (mặc định `palette[4]` `#96CEB4`) | → `showDialog` | `:306-355` |
| 7 | Dialog chọn màu | `AlertDialog` title 'Chọn màu' 16 w600, contentPadding 16, shape r16; `GridView` 5 cột spacing 6, ô vuông (không radius) màu palette; selected: border onSurface 2 + shadow α.5 blur 4 + `check` 18 white | | | `AppColors.palette` | tap → set + pop | `:93-163` |
| 8 | Ghi chú | `TextField` labelText outline r10 | 12 dưới | | `_noteCtrl` | | `:359-371` |
| 9 | 'Số dư ban đầu' | Text 13 w500 | 4 dưới | | | | `:375-382` |
| 10 | Info banner | Container pad H10 V8 bg accent α.08 border α.2 .8 r8; `info_outline` 14 accent; text 11 accent | 8 dưới | | hằng | | `:385-407` |
| 11 | Số | Row end: `Text(_balanceCtrl.formatted)` 28 w600 accent ls−1 (Text thường, không Animated) + 4 + '₫' 14 | | | `_balanceCtrl` (không có ₫ kép vì dùng `formatted`) | | `:411-433` |
| 12 | Divider h12 .5 | | | | | | `:434` |
| 13 | `Numpad` | | | | `_balanceCtrl.press` | | `:436-439` |
| 14 | Submit | `SizedBox(∞) FilledButton` bg accent pad V12 r10; spinner 18 / Text 14 w600 | pad (0,8,0,16) | | disabled chỉ khi `_loading` (**không** disable khi tên rỗng — `_submit` return sớm im lặng `:60`) | | `:442-474` |

## E. Vùng bố cục
`SingleChildScrollView` → toàn sheet cuộn được (khác AddTransactionSheet). Padding top cộng `MediaQuery.padding.top` (`:175`) → chừa status bar khi sheet full-height. Không SafeArea bottom.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Thêm | title 'Thêm nguồn tiền'; loại Tiền mặt; màu `#96CEB4`; số `0`; nút 'Tạo nguồn tiền' |
| Sửa | title 'Chỉnh sửa nguồn tiền'; prefill (số dư ban đầu chỉ prefill nếu >0); nút 'Lưu thay đổi' |
| Tên rỗng + submit | **không phản hồi** (không lỗi, không disable) |
| Loading | nút disabled + spinner |
| Lỗi lưu | không bắt (finally reset) → sheet vẫn mở |
| Keyboard mở (autofocus tên) | sheet đẩy lên; numpad **vẫn hiện** (không ẩn như AddTransaction) → 2 bàn phím chồng |
| Dialog màu | `FocusScope.unfocus()` trước khi mở |

## G. Tương tác
| Trigger | Kết quả |
|---|---|
| X | pop, mất dữ liệu |
| Chip loại | đổi `_type` |
| Chọn màu | dialog grid → pop |
| Numpad | số dư ban đầu |
| Submit | add/update → pop |
| Kéo/tap ngoài | đóng |

## H. Animation/transition
Chip 150ms; không animation số.

## I. Dữ liệu hiển thị
| Field | Format |
|---|---|
| Loại | `WalletType.label`, icon lỗi map |
| Số dư ban đầu | `formatted` "1.000.000" + ' ₫' |
| Palette | 15 hex |

## J. Responsive & edge cases
- Sheet có thể cao > màn (autofocus keyboard + numpad 300 + form ~400) → scroll dài; keyboard + numpad cùng hiện.
- Tên/ghi chú dài: TextField cuộn ngang.
- Landscape: full-height sheet, cuộn.

## K. Text hiển thị
`Thêm nguồn tiền` · `Chỉnh sửa nguồn tiền` · `Tên (vd: MB Bank, Tiền mặt...)` · `Loại` · `Tiền mặt` `Ngân hàng` `Ví điện tử` `Thẻ tín dụng` `Đầu tư` `Khác` · `Màu sắc` · `Chọn màu` · `Ghi chú (tuỳ chọn)` · `Số dư ban đầu` · `Số dư thực tế sẽ được tính tự động từ các giao dịch ghi vào ví này.` · `₫` · `Tạo nguồn tiền` · `Lưu thay đổi`

## L. Nhận xét nhanh
- Form dài (7 khối + numpad) cho một entity đơn giản; số dư ban đầu bằng numpad trong khi tên/ghi chú bằng keyboard hệ thống → hai bàn phím.
- Submit không validate hiển thị (tên rỗng → im lặng).
- Nút X tap-target ≈24px (shrinkWrap, constraints 0).
- Màu chọn qua dialog riêng trong khi CategoryFormSheet hiển thị swatch inline → 2 pattern cho cùng việc.
