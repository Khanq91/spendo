# 08 — TransactionDetailSheet (Chi tiết giao dịch)

## A. Metadata
- **Tên**: `TransactionDetailSheet`
- **Route**: modal `showModalBottomSheet(isScrollControlled, bg surface, shape r20 top)` từ `TransactionListItem` (`transaction_list_item.dart:28-41`)
- **File**: `lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart` (245 LOC)
- **Vào từ**: tap row ở Home, Transactions, WalletDetail
- **Thoát đi**: pop; AlertDialog xoá → pop; "Chỉnh sửa" → pop + mở `AddTransactionSheet(existing)`

## B. Mục đích
Xem chi tiết 1 giao dịch (danh mục, số tiền, ngày giờ, ghi chú, loại, nguồn, ví) và xoá/sửa.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad (16,12,16,32)
│           ━━━━ 36×4           │ handle grey.shade300 (KHÔNG theo theme), margin B16   :42-50
│             (◯)               │ CategoryIconWidget 56, icon 26                      :53
│           Ăn uống 15 w600     │ :55-58
│         -85.000 ₫ 28 w700     │ màu expenseColor #F06292 / incomeColor              :62-75
│ (16) ───────────── (8)        │ Divider
│ 📅 Ngày            Hôm nay, 12:30│ _DetailRow: icon 16 grey400, label 13 grey500, value 13 w500 grey800 :82-87
│ 📄 Ghi chú              An trua│ chỉ khi note                                        :88-93
│ ↗ Loại                Chi tiêu│ value màu loại                                      :94-102
│ ✎ Nguồn              Thủ công │ hoặc ⚡ SePay màu #1E88E5                            :103-109
│ 👛 Nguồn tiền          Tên ví │ chỉ khi walletId khớp; value màu ví                 :111-117
│ (20)                          │
│ [ 🗑 Xoá ]      [ ✎ Chỉnh sửa ]│ OutlinedButton expenseColor r10 pad V12 | FilledButton primary r10 :122-158
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Handle | Container | center | 36×4 r2 | margin B16 | **`Colors.grey.shade300`** cố định | | | `:42-50` |
| 2 | `CategoryIconWidget(size 56, iconSize 26)` | circle | center | 56 | | bg `category.color` α.15 | `category` (null → grey + circleEllipsis) | | `:53` |
| 3 | Tên danh mục | Text | center | | 8 trên | 15 w600 | `category?.name ?? 'Không rõ'` | | `:55-58` |
| 4 | Số tiền | Text | center | | 4 trên | 28 w700 ls−.5 `expenseColor`/`incomeColor` | `'-'/'+' + formatVND(amount)` | | `:62-75` |
| 5 | Divider | | | | 16 trên, 8 dưới | theme | | | `:77-79` |
| 6 | `_DetailRow` Ngày | Row | | pad V6 | | `calendarDays` 16 `grey.shade400`; label 13 `grey.shade500`; Spacer; value 13 w500 `grey.shade800` | `formatDayHeader(createdAt) + ', ' + formatTime` | | `:82-87, 207-245` |
| 7 | Ghi chú | | | | | `fileText` | `note` nếu non-empty | | `:88-93` |
| 8 | Loại | | | | | `arrowUpRight`/`arrowDownLeft`; value màu loại | 'Chi tiêu'/'Thu nhập' | | `:94-102` |
| 9 | Nguồn | | | | | `Icons.bolt` / `LucideIcons.pencil`; value `#1E88E5` nếu SePay | 'SePay'/'Thủ công' | | `:103-109` |
| 10 | Nguồn tiền | | | | | `wallet`; value `wallet.color` | `walletsProvider` lookup by `walletId` | | `:111-117` |
| 11 | `OutlinedButton.icon` Xoá | button | trái Expanded | pad V12 | gap 12 | fg `expenseColor`, border `expenseColor` .8, r10; icon `trash2` 16 | | `_confirmDelete` | `:125-140` |
| 12 | `FilledButton.icon` Chỉnh sửa | button | phải Expanded | pad V12 | | bg `cs.primary`, r10; icon `pencil` 16 | | `_openEdit` | `:144-156` |
| 13 | AlertDialog xoá | dialog | | | | title "Xoá giao dịch?", content "Hành động này không thể hoàn tác.", `TextButton Huỷ`, `TextButton Xoá` fg expenseColor | | Xoá → `TransactionRepository().delete` → pop sheet | `:164-191` |

## E. Vùng bố cục
Sheet `Column(min)` không scroll; cao ≈ 12+20+56+8+18+4+34+16+1+8 + (5×~30) + 20 + 44 + 32 ≈ **420px**. Padding đáy 32 cố định (không dùng SafeArea/viewPadding).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Mặc định | như trên |
| Không note | ẩn hàng Ghi chú (không placeholder) |
| Không ví / ví đã xoá hoặc archived | ẩn hàng Nguồn tiền (archived: `walletsProvider` chỉ active → **ẩn dù có walletId**) |
| Category bị xoá | icon xám + "Không rõ" |
| SePay | dot badge không hiện ở đây (chỉ trong list), nhưng hàng Nguồn "SePay" xanh |
| Deleting | không có loading; `await delete` rồi pop (sheet đứng yên) |
| Delete error | không bắt → sheet vẫn mở, không thông báo |

## G. Tương tác
| Trigger | Hành động | Kết quả | Điều hướng |
|---|---|---|---|
| Xoá | dialog → delete → pop | sheet đóng, list stream cập nhật | |
| Chỉnh sửa | pop sheet → mở AddTransactionSheet(existing) | | sheet mới |
| Tap ngoài/kéo | đóng | | |
| Tap icon/danh mục/số | không có | | |

## H. Animation/transition
Không có animation riêng ngoài sheet mặc định.

## I. Dữ liệu hiển thị
| Field | Format | Null |
|---|---|---|
| Ngày | `'Hôm nay, 12:30'` / `'Hôm qua, …'` / `'d/M/yyyy, HH:mm'` | — |
| Số tiền | `formatVND` có dấu | — |
| Note | thô, 1 dòng (không maxLines nhưng Row → tràn nếu quá dài `[UNKNOWN: overflow]`) | ẩn |
| Ví | `wallet.name` màu `wallet.color` | ẩn |

## J. Responsive & edge cases
- Note dài: `_DetailRow` là `Row[Text label, Spacer, Text value]` không Expanded/ellipsis → note dài **overflow** (`:233-240`).
- Dark mode: `grey.shade300/400/500/800` cố định → handle & label/value tối trên nền `#1E1E1E` (grey800 gần như không đọc được).
- Landscape: 420px > chiều cao khả dụng ~330 → tràn.

## K. Text hiển thị
`<tên danh mục>` / `Không rõ` · `-X ₫` / `+X ₫` · `Ngày` · `Hôm nay, HH:mm` · `Ghi chú` · `Loại` · `Chi tiêu` · `Thu nhập` · `Nguồn` · `SePay` · `Thủ công` · `Nguồn tiền` · `Xoá` · `Chỉnh sửa` · `Xoá giao dịch?` · `Hành động này không thể hoàn tác.` · `Huỷ`

## L. Nhận xét nhanh
- Màu text hard-code `grey.shade*` phá dark mode; handle không theo theme (nơi khác dùng `outlineVariant`).
- Note dài overflow; ví archived bị ẩn thông tin.
- Xoá qua dialog xác nhận, không có undo; không có "nhân bản"/"chia sẻ".
- Màu chi ở đây `#F06292` khác màu chi ở summary/day header `#E53935`.
