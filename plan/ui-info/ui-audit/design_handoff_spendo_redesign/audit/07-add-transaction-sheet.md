# 07 — AddTransactionSheet (Thêm / Sửa giao dịch)

## A. Metadata
- **Tên**: `AddTransactionSheet` (cả thêm và sửa, `existing != null` → edit)
- **Route**: modal `showModalBottomSheet(isScrollControlled: true)`; cũng là đích của route `/add?category_id&note&amount` (`app_router.dart:29-42, 84-100`)
- **File**: `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart` (1061 LOC) + `numpad.dart` (50) + `amount_input_controller.dart` (46)
- **Vào từ**: FAB (`app_bottom_nav.dart:100-106`), Home grid "Thêm" & AllFeatures (`/add`), notification tap, Android widget, TransactionDetail "Chỉnh sửa"
- **Thoát đi**: `Navigator.pop` sau lưu; kéo xuống/tap ngoài; `NotePickerScreen` (push, trả kết quả); `_WalletPickerSheet`; 2 AlertDialog cảnh báo

## B. Mục đích
Nhập số tiền bằng numpad, chọn loại Chi/Thu, chọn danh mục, ghi chú (có gợi ý & auto-match danh mục), tuỳ chọn ghi vào ví; cảnh báo vượt hạn mức/ví âm trước khi lưu.

## C. Layout skeleton
```
╭───────────────────────────────╮ bottomSheetTheme: bg surface, r20 top (FAB) | app_router/global_fab truyền shape giống
│           ━━━━ 36×4           │ handle margin V10                                    :371-379
│      Chỉnh sửa giao dịch      │ chỉ edit mode, 13 w600 onSurfaceVariant, pad B4     :381-392
│ [Chi] [Thu]        1.234.567 ₫│ _TypeToggle ×2 (pad H14 V6, r8) · Spacer · AnimatedMoneyText 32 w600 color ls−1 · '₫' 14  :394-433
│ (10)                          │
│ (Ăn uống ✨)(Di chuyển•)(…)→  │ ChoiceChip strip h36 (48 nếu chip chọn có budget), pad H16, gap 8  :438-535
│ (8)                           │
│ Ghi chú (tuỳ chọn)...     [🔍]│ TextField no border 13 + icon search 18            :540-574
│ ☐ Ghi vào nguồn tiền  (Ví ▾)  │ chỉ khi có ví; Checkbox 24 + text 13 + _SelectedWalletChip khi bật  :577-612
│ ─────────────────────────────  │ Divider h12 .5
│   1      2      3             │ Numpad GridView 3 cột aspect 1.6, key border dividerColor α.15 w.5, số 22 w400
│   4      5      6             │ ẩn khi keyboard mở (isKeyboardVisible)             :616-620
│   7      8      9             │
│  00      0      ⌫             │
│ ┌───────────────────────────┐ │ FilledButton minH48 r12 bg color: 'Chi 1.234.567 ₫' / 'Thu …' / 'Lưu thay đổi'  :622-672
│ └───────────────────────────┘ │ pad (16,8,16,16) + viewInsets.bottom
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 0 | `Padding(bottom: viewInsets.bottom)` > `Column(min)` | root | | | | không SafeArea, không scroll | | | `:364-368` |
| 1 | Handle | Container | top center | 36×4 r2 | margin V10 | `cs.outlineVariant` | | (sheet drag) | `:371-379` |
| 2 | Title edit | Text | | | pad B4 | 13 w600 onSurfaceVariant | "Chỉnh sửa giao dịch" chỉ khi `_isEditMode` | | `:381-392` |
| 3 | `_TypeToggle` "Chi" | `PressableScale > AnimatedContainer` | trái | pad H14 V6 → h≈31 | gap 8 | active: bg `#E53935` α.12, border `#E53935` .8; inactive: transparent, border outlineVariant; r8; label 13 w600 | `_isExpense` | `_switchType(true)` → reset category | `:398-403, 1021-1061` |
| 4 | `_TypeToggle` "Thu" | | | | | color `#43A047` | | `_switchType(false)` | `:405-410` |
| 5 | Số tiền | `AnimatedMoneyText` | phải | 32 w600 ls−1 | | color `#E53935` / `#43A047` | `_amountCtrl.value` qua `formatVND(round)` → hiện `"0 ₫"` khi rỗng | | `:412-425` |
| 6 | `'₫'` | Text | | 14 onSurfaceVariant | 4 trái | | | | `:427-430` (→ hiển thị "0 ₫ ₫" **hai ký hiệu ₫** vì `formatVND` đã kèm ₫ — `currency_formatter.dart:5`) |
| 7 | Chip strip | `SizedBox(h36\|48) > ListView.separated horizontal` | | pad H16, gap 8 | | | `cats = categories where isIncome == !_isExpense` (`:93-94`) | | `:438-535` |
| 7a | Chip | `PressableScale(deferTapToChild) > ChoiceChip` | | pad H4 (theme +) | | `showCheckmark: false`; label Column[Row[name 12 (w600 `color` nếu chọn / w400 onSurfaceVariant), ✨`auto_fix_high` 10 nếu auto-chọn, `_BudgetDot` 6 nếu có budget & chưa chọn], `_MiniProgressBar` 48×3 + '%' 9 nếu chọn & có budget]; bg/selectedColor/border theo `_resolveChip*` (xanh/vàng/cam/đỏ α.06–.15 theo % budget) | `budgetProgressMap` (`categoryBudgetProgressProvider`) | `onSelected` → `_selectedCategoryId`, `_userPickedCategory=true` | `:467-532, 678-713, 832-894` |
| 8 | Note field | `TextField` | | pad H16 | | 13 `cs.onSurface`; hint 'Ghi chú (tuỳ chọn)...' 13 onSurfaceVariant; no border; dense; contentPadding V4 | `_noteCtrl` | `onChanged: _autoSelectCategory` (matchCategory keyword → iconName → category, chỉ khi user chưa tự chọn; scroll chip vào view 300ms) | `:545-559, 262-283` |
| 9 | Search icon | GestureDetector | phải note | icon 18, pad L8 → tap ≈ 26 | | onSurfaceVariant | | `_openNotePicker` → push `NotePickerScreen` | `:561-571, 294-316` |
| 10 | Wallet row | Row | | pad H16 V4 | | `Checkbox` trong `SizedBox(24)` compact shrinkWrap; text 13 onSurfaceVariant; Spacer; `_SelectedWalletChip` (pad H10 V4, bg color α.12, border α.4 .8, r20; icon `categoryIcon(type.iconName)` 12 = **luôn circleEllipsis**, tên 12 w600, `arrow_drop_down` 14) | `wallets.isNotEmpty`; `_trackWallet`; auto chọn ví đầu (`:357-359`) | checkbox toggle; chip → `_WalletPickerSheet` | `:577-612, 718-753` |
| 11 | `Divider(height 12, thickness .5)` | | | | | | | | `:614` |
| 12 | `Numpad` | `GridView.count(3, aspect 1.6, shrinkWrap)` | | cao ≈ 4 × (width/3/1.6) ≈ 4×75 = 300 @360w | | `InkWell > Container(border dividerColor α.15 w.5) > Center(Text 22 w400 \| backspace_outlined 20)` | `_amountCtrl.press`; ẩn khi `viewInsets.bottom > 0` | tap | `:616-620`, `numpad.dart` |
| 13 | Submit | `FilledButton` | | `minimumSize(∞, 48)`, r12 | pad (16,8,16,16) | bg `color`; disabled khi `_isSubmitting \|\| !hasValue \|\| category null`; child `AnimatedSwitcher` 420ms: spinner 20 white \| Text 15 w600 | label: edit → 'Lưu thay đổi'; else `'Chi ' + formatted + ' ₫'` / `'Thu …'` | `_submit` | `:622-672` |
| 14 | `_WalletPickerSheet` | sheet con | | | | handle; "Chọn nguồn tiền" 15 w600 pad (16,4,16,12); Divider; `ListTile` mỗi ví: leading 36 r8 bg α.15 icon 18, title 14, subtitle `type.label` 12, trailing `check` 18 primary nếu chọn; SizedBox 16 | `wallets` | tap → set + pop | `:757-828` |
| 15 | `_BudgetWarningDialog` | AlertDialog | | | | icon Text '⚠️' 32; title 16 w600 center "Đã vượt hạn mức!"/"Sắp vượt hạn mức"; content: "Danh mục: X" 13, `_InfoRow` ×3 (Hạn mức/Đã chi cam/Khoản này đỏ) 13, Divider 16, `_InfoRow` bold "Vượt hạn +…" đỏ, 8, giải thích 12; actions `TextButton('Huỷ bỏ')` onSurfaceVariant, `FilledButton('Vẫn thêm')` bg `red.shade600` | `categoryBudgetProgressProvider` | | `:149-180, 896-978` |
| 16 | Dialog ví âm | AlertDialog | | | | icon '⚠️' 28; title 15 w600 "Ví đang âm!"/"Số dư không đủ"; `_InfoRow` Ví / Số dư hiện tại (đỏ nếu <0 else cam) / Khoản chi đỏ / Divider / Thiếu bold đỏ; text 12; `TextButton('Huỷ')`, `FilledButton('Vẫn thêm')` bg `orange.shade700` | `WalletRepository.calculateBalance` | | `:182-260` |

## E. Vùng bố cục
- Sheet `Column(mainAxisSize.min)` **không scroll**; chiều cao ≈ 10+4+10 + 31 + 10 + 36/48 + 8 + ~30 + ~32 + 12 + 300 + 8+48+16 ≈ **560–570px** trên màn 360 rộng → trên màn 640 cao chiếm ~88%; với `isScrollControlled` sheet có thể vượt màn khi keyboard mở (numpad ẩn bù lại).
- Không có nút đóng/huỷ; không AppBar; không SafeArea top (sheet hiếm khi chạm top).

## F. Trạng thái màn hình
| State | Điều kiện | UI |
|---|---|---|
| Initial (thêm) | | Chi chọn, số `0 ₫`, danh mục **đầu tiên** tự chọn (`:350-354`) không có ✨, note rỗng, checkbox ví tắt, nút disabled "Chi 0 ₫" |
| Prefill (route/notification/widget) | `preselectedCategoryId`, `prefillNote`, `prefillAmount` | category set + `_userPickedCategory=true`; note; số tiền nếu >0 |
| Edit | `existing` | title "Chỉnh sửa giao dịch"; amount/note/type/category/wallet prefill; nút "Lưu thay đổi"; **không** check budget/ví (`:105, 114`) |
| Auto-category | gõ note khớp keyword | chip đổi + ✨ + scroll vào view |
| Budget indicator | category có budget | chip có dot màu / khi chọn: strip cao 48 + mini bar + % |
| Keyboard mở | `viewInsets.bottom > 0` | numpad **biến mất**, sheet co lại; số tiền chỉ nhập được qua numpad → phải đóng keyboard |
| Submitting | `_isSubmitting` | nút disabled + spinner (cả khi đang chờ dialog) |
| Cảnh báo budget | expense, không edit, spent+new > budget | dialog #15 |
| Cảnh báo ví | trackWallet, expense, balance − new < 0 | dialog #16 (sau dialog budget nếu cả hai) |
| Không có category nào cho loại | `cats.isEmpty` | strip rỗng, nút disabled vĩnh viễn, **không có hướng dẫn** |
| Không có ví | `wallets.isEmpty` | hàng ví ẩn hoàn toàn |
| Error khi lưu | repo throw | **không bắt** → `finally` reset submitting; sheet vẫn mở, không thông báo |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| Tap Chi/Thu | `_switchType` | đổi màu, list chip đổi bộ, category về đầu, ✨ reset | — |
| Tap chip | chọn | | |
| Gõ note | auto-match | | |
| Tap 🔍 | | | push `NotePickerScreen` (MaterialPageRoute) → nhận `note` + `categoryId` |
| Tap checkbox ví | toggle | chip ví hiện/ẩn | |
| Tap chip ví | | | sheet `_WalletPickerSheet` |
| Numpad 0-9 | append (max 10 chữ số, không leading 0) | số cập nhật 360ms | |
| `00` | append nếu có số và ≤8 chữ số | | |
| `⌫` | xoá 1 ký tự | | |
| Long-press ⌫ | **không** xoá hết | | |
| Submit | check budget → check ví → repo add/update → pop | | pop |
| Kéo xuống / tap ngoài | đóng, **mất dữ liệu không hỏi** | | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Số tiền | AnimatedMoneyText | 360ms |
| Type toggle / chip / wallet chip | AnimatedContainer / ChoiceChip | 140ms / mặc định |
| Chip scroll vào view | `Scrollable.ensureVisible` alignment .3 | 300ms easeOut |
| Nút submit label | AnimatedSwitcher | 420ms |
| Mini progress | AnimatedProgressBar | 360ms |
| Sheet | mặc định Material bottom sheet | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Rỗng/dài |
|---|---|---|---|
| Số tiền | `AmountInputController.value` (int) | `formatVND` "1.234.567 ₫" + text ' ₫' riêng → **"… ₫ ₫"** | `0 ₫` |
| Nút | `_amountCtrl.formatted` "1.234.567" + ' ₫' | | "Chi 0 ₫" |
| Chip | `cat.name`, `cat.color` (không dùng cho chip — chip dùng màu loại) | | tên dài kéo chip rộng |
| Budget % | `progress.percent*100` clamp 0–999 | `'$n%'` 9px | |
| Ví | `wallet.name`, `type.label`, icon (lỗi map) | | |
| Dialog số | `formatVND` | | |

## J. Responsive & edge cases
- Màn thấp (<600px): sheet gần full; không scroll → phần trên có thể bị đẩy khỏi màn `[UNKNOWN: chưa đo]`.
- Keyboard: numpad ẩn; padding bottom theo viewInsets; ghi chú ở giữa sheet vẫn thấy.
- Note dài: TextField 1 dòng cuộn ngang (không maxLines) → OK.
- Nhiều danh mục: scroll ngang không gợi ý.
- Số 10 chữ số (9.999.999.999 ₫) ở 32px: chiếm ~200px, còn ~120px cho 2 toggle → vừa @360.
- Landscape: sheet cao 560 > màn ~360 → **tràn** (không scroll).

## K. Text hiển thị
`Chỉnh sửa giao dịch` · `Chi` · `Thu` · `₫` · `Ghi chú (tuỳ chọn)...` · `Ghi vào nguồn tiền` · `Chọn nguồn tiền` · `<type.label>` · `Chi X ₫` · `Thu X ₫` · `Lưu thay đổi` · `1…9` `00` `0` · `Đã vượt hạn mức!` · `Sắp vượt hạn mức` · `Danh mục: X` · `Hạn mức` · `Đã chi` · `Khoản này` · `Vượt hạn` · `Danh mục này đã vượt hạn mức. Thêm khoản này sẽ làm tăng thêm số tiền vượt hạn.` · `Thêm khoản chi này sẽ khiến danh mục "X" vượt hạn mức.` · `Huỷ bỏ` · `Vẫn thêm` · `Ví đang âm!` · `Số dư không đủ` · `Ví` · `Số dư hiện tại` · `Khoản chi` · `Thiếu` · `Số dư ví sẽ bị âm sau giao dịch này.` · `Huỷ` · `danh mục này` / `ví này` (fallback tên)

## L. Nhận xét nhanh
- Ký hiệu ₫ hiện 2 lần ("0 ₫ ₫") do `formatVND` đã kèm ₫ rồi lại thêm Text '₫' (`:417, 428`).
- Không thể chỉnh **ngày/giờ** giao dịch (luôn `now` khi thêm, giữ nguyên khi sửa) — thiếu field cơ bản.
- Numpad cứng ~300px chiếm >50% sheet; khi mở keyboard cho ghi chú, numpad biến mất → 2 chế độ nhập xung đột.
- Không có nút huỷ/đóng, đóng sheet mất dữ liệu không xác nhận; lỗi lưu không hiển thị.
- Chip category không dùng màu/icon danh mục (chỉ text màu đỏ/xanh theo loại) trong khi mọi nơi khác dùng màu riêng.
