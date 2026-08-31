# 28 — _AddMappingSheet (Thêm tài khoản ngân hàng SePay)

## A. Metadata
- **Tên**: `_AddMappingSheet(ref)` (private, `sepay_connection_section.dart:215-420`)
- **Route**: modal `showModalBottomSheet(isScrollControlled)` (`:138-144`)
- **Vào từ**: Settings › Kết nối ngân hàng tự động › "Thêm tài khoản ngân hàng"
- **Thoát đi**: Huỷ / submit → pop

## B. Mục đích
Ánh xạ số tài khoản + ngân hàng (SePay) → ví trong Spendo để giao dịch tự động vào đúng ví.

## C. Layout skeleton
```
╭───────────────────────────────╮ pad (16,16,16, viewInsets+24) — KHÔNG scroll
│           ━━━━ 40×4           │ handle 40 (khác chuẩn 36)
│ Thêm tài khoản ngân hàng 16 w600│
│ Điền thông tin tài khoản bạn đã kết nối trên SePay 12│
│ (20)                          │
│ ┌ 💳 Số tài khoản *        ┐  │ TextField number outline r12 prefixIcon creditCard 18
│ ┌ 🏛 Ngân hàng *          ▾ ┐ │ DropdownButtonFormField 14 mã bank
│ ┌ 👛 Nguồn tiền trong Spendo * ▾ ┐│ Dropdown wallets (load async getAll)
│ ┌ 🏷 Tên hiển thị (tùy chọn) ┐│ hint 'VD: Thẻ lương, Thẻ chính'
│ (24)                          │
│ [  Huỷ  ] [    Thêm kết nối    ]│ OutlinedButton flex1 | FilledButton flex2 (theme mặc định, không custom shape)
╰───────────────────────────────╯
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| 1 | Handle | **40×4** margin B16 outlineVariant | | | `:270-279` |
| 2 | Title / sub | 16 w600 / 12 onSurfaceVariant; 4; 20 | | | `:281-289` |
| 3 | Số tài khoản | TextField `TextInputType.number`, label 'Số tài khoản *', `OutlineInputBorder(r12)`, `prefixIcon creditCard 18` | `_accountCtrl` | | `:293-303` |
| 4 | Ngân hàng | `DropdownButtonFormField<String>` label 'Ngân hàng *', prefix `landmark`; items 14 mã: VCB TCB MB ACB VPB BID CTG STB TPB OCB MSB VIB SHB HDBank | `_bankCtrl.text` (không setState → dropdown hiển thị dựa initialValue `[UNKNOWN: có cập nhật hiển thị sau chọn không]`) | | `:307-323` |
| 5 | Nguồn tiền | Dropdown label 'Nguồn tiền trong Spendo *', prefix `wallet`; items `_wallets` (load async `WalletRepository().getAll()`) | `_selectedWalletId` | | `:327-341` |
| 6 | Tên hiển thị | TextField label + hint, prefix `tag` | `_labelCtrl` | | `:345-355` |
| 7 | Buttons | Row: `OutlinedButton('Huỷ')` flex 1; 12; `FilledButton` flex 2 spinner 18 / 'Thêm kết nối' — **theme mặc định M3** (pill, h40) khác mọi nút khác | `_loading` | Huỷ → pop; submit → validate (SnackBar 'Vui lòng điền đầy đủ thông tin bắt buộc') → `addMapping` → pop; lỗi → SnackBar 'Lỗi: …' | `:359-384, 390-419` |

## E. Vùng bố cục
Column min không scroll; ~420px + keyboard số → vừa màn 640 `[UNKNOWN]`.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Wallets chưa load | dropdown rỗng (không disabled, không hint) |
| Không có ví | dropdown rỗng → không thể submit (validate fail) — không hướng dẫn tạo ví |
| Validate fail | SnackBar (hiện dưới sheet ở Scaffold cha) |
| Loading | spinner trong nút |
| Lỗi | SnackBar 'Lỗi: …' |

## G. Tương tác
Nhập/chọn; Huỷ; Thêm kết nối.

## H. Animation/transition
Không.

## I. Dữ liệu hiển thị
Mã ngân hàng 3–6 ký tự viết tắt (không tên đầy đủ, không logo).

## J. Responsive & edge cases
Keyboard number + 4 field: sheet có thể chạm top; không scroll.

## K. Text hiển thị
`Thêm tài khoản ngân hàng` · `Điền thông tin tài khoản bạn đã kết nối trên SePay` · `Số tài khoản *` · `Ngân hàng *` · `VCB` … `HDBank` · `Nguồn tiền trong Spendo *` · `Tên hiển thị (tùy chọn)` · `VD: Thẻ lương, Thẻ chính` · `Huỷ` · `Thêm kết nối` · `Vui lòng điền đầy đủ thông tin bắt buộc` · `Lỗi: …`

## L. Nhận xét nhanh
- Style khác biệt so với mọi form khác: handle 40, outline r12, prefixIcon, nút theme mặc định, 2 nút ngang (Huỷ/Thêm) — như viết bởi người khác.
- Validate bằng SnackBar thay vì inline; không disable nút khi thiếu.
- Không hướng dẫn khi chưa có ví.
