# PLAN — Sổ theo dõi: khoản vay không liên kết tiền của app

> Nối tiếp `plan/loan-tra-gop/PLAN.md` (v2 — đã xong cả 3 GĐ, commit
> `8901960`, baseline **371 test**). **File này thắng** cho mọi quyết định
> của feature này; quy tắc UI chung vẫn theo HANDOFF-STATE mục 2–3
> (`plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`).
>
> Cập nhật bảng tiến độ mục 1 khi xong.

## 0. Bối cảnh — vì sao feature này nhỏ

Sau v2, **sợi dây duy nhất** nối khoản vay với tiền của app là `transactions`:
payment tạo giao dịch Trả nợ/Thu nợ
([add_payment_sheet.dart:134](../../lib/features/loan/presentation/widgets/add_payment_sheet.dart)),
tiền gốc tạo giao dịch Đi vay/Cho vay nếu bật "Ghi vào ví". Ví và Thống kê
không đọc bảng `loans` — chúng chỉ nhìn transactions.

→ "Khoản vay chỉ để theo dõi" = **không tạo transaction, chấm hết**. Không
phải sửa gì ở Thống kê, Ví, Home. Mọi thứ còn lại của khoản vay (đợt,
waterfall, remaining, nhắc hạn) giữ nguyên y hệt.

Đọc trước: quyết định 2.1–2.11 của `plan/loan-tra-gop/PLAN.md` (đặc biệt
2.6 payment→transaction, 2.7 danh mục lazy, 2.10 nhắc đợt) — feature này
là công tắc tắt 2.6/2.8 theo từng khoản vay.

---

## 1. Tiến độ

| GĐ | Nội dung | Trạng thái | Commit |
|---|---|---|---|
| 1 — Sổ theo dõi | schema + trang riêng + branch payment/form | ✅ xong | `PENDING` |

Baseline trước khi làm: `flutter analyze` sạch · **371 test** · APK debug OK.

Quy trình: như HANDOFF-STATE mục 5 — analyze → test → build apk sạch →
tự kiểm mục 5 (Nghiệm thu) → **1 commit** → cập nhật bảng này → dừng chờ duyệt.

---

## 2. Quyết định đã chốt với user (2026-09-02)

### 2.1 Trục thứ 3 của khoản vay — "sổ nào"

Khoản vay đã có 2 trục độc lập: chiều (`type`: borrowed/lent) và cách trả
(`repayment_mode`: free/installment). Thêm trục thứ 3, cũng độc lập:

- **Sổ chi tiêu** (mặc định — hành vi v2): payment tạo transaction, có
  "Ghi vào ví" cho tiền gốc.
- **Sổ theo dõi**: KHÔNG tạo transaction ở bất cứ đâu, không đụng ví,
  không hiện trong Thống kê. Chỉ là cuốn sổ ghi nợ.

Cột mới `loans.is_tracking_only` INTEGER, **null/0 = sổ chi tiêu** → toàn
bộ loan hiện có không đổi gì, không migration ghi dữ liệu.

### 2.2 KHÓA lúc tạo — và vì thế KHÔNG có toggle

User chốt: cờ chọn 1 lần khi tạo, **không đổi được nữa** (chọn nhầm thì xoá
tạo lại). Kết hợp với trang riêng (2.3) → hệ quả đẹp: **form không cần
toggle nào** — đang đứng ở trang nào thì tạo ra loại đó:

- FAB ở trang Khoản vay → loan sổ chi tiêu (như v2).
- FAB ở trang Sổ theo dõi → loan `is_tracking_only = 1`.

`LoanFormSheet` nhận tham số `trackingOnly` (không phải state user sửa
được); khi **sửa** loan thì cờ không hiển thị, không đổi. Không có code path
nào flip cờ sau khi INSERT.

### 2.3 Trang riêng — "Sổ theo dõi", cấu trúc tái dùng trang Khoản vay

User chốt: không trộn vào list chính, không badge lẫn lộn — **1 trang
riêng, cấu trúc tương tự**. Hai sổ tách biệt hoàn toàn, kể cả phần tổng:

- Trang Khoản vay (`/loans`): chỉ loan sổ chi tiêu — header
  Đang vay/Cho vay chỉ cộng các loan này.
- Trang Sổ theo dõi (route mới **`/loans-tracking`** — cố ý KHÔNG đặt
  `/loans/tracking` để khỏi giẫm pattern `/loans/:id`): chỉ loan theo dõi,
  header tổng riêng của nó, cùng segmented Tất cả/Đang vay/Cho vay, cùng
  kiểu row, FAB riêng (2.2).

**Không viết màn mới** — parameter hoá `LoanListScreen` (vd
`LoanListScreen(trackingOnly: bool)`): title "Khoản vay" / "Sổ theo dõi",
empty-state text riêng, còn layout/row/summary/filter dùng chung. Đây là
điểm "cấu trúc có thể tương tự" user nói.

**Lối vào** (user chốt 2026-09-02; cùng ngày sửa lại phần Home thành
"3 + Xem thêm"):

1. **App bar trang Khoản vay**: action icon (đề xuất `LucideIcons.notebookPen`,
   không có thì `bookOpen`), tooltip "Sổ theo dõi" — cửa ngữ cảnh "đổi sổ".
2. **Home — làm lại hàng shortcut thành "3 nổi bật + Xem thêm"**
   (`home_shortcuts.dart`):

   | Ô | Đi đâu | Vì sao được giữ |
   |---|---|---|
   | Vay nợ | `/loans` | không hiện diện sẵn trên Home |
   | **Sổ theo dõi** | `/loans-tracking` | feature mới — lối vào chính từ Home |
   | Nhắc nhở | `/reminders` | không hiện diện sẵn trên Home |
   | **Xem thêm** (`LucideIcons.layoutGrid`) | `/features` | mở màn Tất cả tính năng |

   - **Bỏ ô Ví và Hạn mức** — không mất lối vào: Home đã có
     `home_wallet_strip` (tap ví → `/wallets/:id`) và `home_budget_card`
     (tap → `/budget`); giữ shortcut là lặp lối vào ngay trên cùng màn —
     đúng loại lặp khiến màn Xem thêm cũ bị xoá hồi redesign. Danh sách ví
     `/wallets` vẫn còn 3 lối: strip (từng ví) · row Settings "Nguồn tiền" ·
     màn Tất cả tính năng.
   - **Màn "Tất cả tính năng"** — MỚI: route `/features`, file đề xuất
     `lib/features/home/presentation/screens/features_screen.dart`. List
     `SpendoSettingsRow` (icon + label + subtitle 1 dòng + count tái dùng
     provider như Settings): Ví · Khoản vay · Sổ theo dõi · Hạn mức ·
     Nhắc nhở · Danh mục. **Không** đưa Giao dịch / Thống kê / Cài đặt vào —
     chúng là tab thường trực ở bottom bar. Màn này chứa NHIỀU hơn hàng
     Home (6 > 3) nên không tái phạm lỗi "repeated this grid" của màn cũ.
   - Doc comment đầu `home_shortcuts.dart` đang kể chuyện tỉa 8 → 4 —
     **viết lại comment** theo cấu trúc mới, kẻo session sau tưởng nhầm
     mà "sửa" về 4 ô cũ.
3. **Settings**: `SpendoSettingsRow` "Sổ theo dõi" trong `_dataGroup`
   (`settings_screen.dart`), ngay dưới row "Khoản vay", icon `notebookPen`,
   `trailingText` = số loan theo dõi, push `/loans-tracking`.

⚠️ Kéo theo: row "Khoản vay" ở Settings đang đếm `loansProvider` (toàn bộ
loan) — sau khi tách sổ (2.5) phải đếm **riêng sổ chi tiêu**, row "Sổ theo
dõi" (cả ở Settings lẫn màn Tất cả tính năng) đếm **riêng sổ theo dõi**.
Nguyên tắc: mỗi row đếm đúng cái trang nó dẫn tới. Mọi lối vào Sổ theo dõi
(icon app bar · ô Home · row màn Tất cả tính năng · row Settings) đều
`context.push('/loans-tracking')`.

### 2.4 Hành vi khi `is_tracking_only = 1`

| Chỗ | Sổ chi tiêu (v2) | Sổ theo dõi |
|---|---|---|
| Ghi thanh toán | picker ví + tạo transaction | **ẩn picker ví, KHÔNG tạo transaction** — chỉ INSERT `loan_payments`; caption dưới ô tiền: "Chỉ theo dõi — không tạo giao dịch, không trừ ví" |
| Form tạo | có section "Ghi vào ví" | **ẩn hẳn section đó** (funding vô nghĩa) |
| 4 danh mục nợ (v2 §2.7) | lazy-create khi cần | **không bao giờ được tạo** từ loan theo dõi |
| Xoá payment/loan | xoá transaction liên kết | không có gì để xoá kèm (transaction_id luôn null) |
| Guard source='loan' (v2 §2.9) | có | không liên quan (không có transaction) |
| Nhắc đợt đến hạn (v2 §2.10) | có | **VẪN CÓ** — nhắc nhở chính là "theo dõi"; scheduler không lọc theo sổ |
| Deep-link `/loan-pay` | mở sheet như thường | vẫn mở — sheet tự branch theo cờ |
| Detail | như v2 | dùng chung màn, thêm 1 dòng nhỏ dưới header: "Sổ theo dõi — không liên kết ví & thống kê" (người vào từ notification biết ngay vì sao không có ví) |

### 2.5 Hai sổ không nhìn thấy nhau — mức dữ liệu

- `watchAll()` và `watchSummaryWithRemaining()` trong `loan_repository.dart`
  nhận cờ, WHERE `COALESCE(is_tracking_only, 0) = ?`. KHÔNG làm 2 hàm copy.
- Provider: `loansProvider`/summary chuyển thành **family theo sổ** (hoặc 2
  provider gọi chung repo) — trang nào watch đúng sổ đó.
- ⚠️ `loanFilterProvider` ([loan_provider.dart:48](../../lib/features/loan/presentation/providers/loan_provider.dart))
  đang là `StateProvider` **toàn cục** — 2 trang dùng chung sẽ dính filter
  của nhau. Tách: family theo sổ hoặc hạ xuống state cục bộ của màn.
- `watchPaidByLoan()` key theo id → dùng chung được, không sửa.
- Rà nốt consumer của `loansProvider`/`activeLoansProvider` ngoài feature
  (transaction_detail_sheet chỉ lookup theo id — an toàn; Home shortcut chỉ
  push route — an toàn).

---

## 3. Schema delta

`lib/core/db/schema.dart` — bảng `loans` thêm:

```dart
Column.integer('is_tracking_only'),   // null/0 = sổ chi tiêu, 1 = sổ theo dõi
```

PowerSync localOnly tự migrate (tiền lệ: repayment_mode ở v2).

**Bắt buộc kèm:** `lib/core/utils/backup_service.dart` — thêm cột vào
export/import của `loans`; backup cũ thiếu cột phải import được (null → 0).

---

## 4. Phạm vi (1 GĐ, 1 commit)

1. **Schema + backup** — mục 3.
2. **Domain** — `loan.dart`: `isTrackingOnly` (fromMap/copyWith/toMap đủ bộ).
3. **Repository + provider** — mục 2.5.
4. **List** — parameter hoá `loan_list_screen.dart` + route `/loans-tracking`
   trong `app_router.dart` (cạnh `/loans`, khai báo tách bạch với
   `/loans/:id`) + action icon app bar (2.3) + FAB truyền `trackingOnly`
   xuống form.
5. **Home + màn Tất cả tính năng + Settings** — `home_shortcuts.dart` đổi
   thành 3+Xem thêm · `features_screen.dart` MỚI + route `/features` trong
   `app_router.dart` · `settings_screen.dart` (`_dataGroup`: row "Sổ theo
   dõi" mới + sửa count row "Khoản vay" đếm theo sổ) — chi tiết ở 2.3.
   Rà `integration_test/screenshot_test.dart`: nếu có bước tap shortcut
   Ví/Hạn mức ở Home thì cập nhật bước đó.
6. **Form** — `loan_form_sheet.dart` nhận `trackingOnly`, ẩn "Ghi vào ví",
   ghi cờ khi INSERT; sửa loan không đụng cờ.
7. **Payment sheet** — `add_payment_sheet.dart` branch theo `loan.isTrackingOnly`:
   ẩn ví, bỏ nhánh tạo transaction + resolver danh mục, thêm caption (2.4).
8. **Detail** — dòng marker (2.4).
9. **Tests** (nền 371): unit repo lọc 2 sổ + summary tách sổ · widget form ẩn
   funding · widget payment sheet tracking không tạo transaction & không tạo
   danh mục (verify bảng categories trống) · widget trang Sổ theo dõi
   (empty state + chỉ hiện loan tracking) · filter 2 trang không dính nhau ·
   Home 4 ô mới (Vay nợ / Sổ theo dõi / Nhắc nhở / Xem thêm) dẫn đúng nơi ·
   màn Tất cả tính năng đủ 6 row đúng route · 2 row Settings đếm đúng
   từng sổ · detail marker.

## 5. Nghiệm thu

- Tạo loan từ Sổ theo dõi (cả free lẫn theo đợt) → ghi 3 payment → bảng
  `transactions` không thêm dòng nào, ví không đổi, Thống kê không đổi,
  4 danh mục nợ không xuất hiện trong màn Danh mục.
- remaining/waterfall/tiến độ đợt của loan theo dõi chạy đúng như loan thường.
- Trang `/loans`: không thấy loan theo dõi, tổng Đang vay/Cho vay không cộng
  chúng — và ngược lại.
- Vào được Sổ theo dõi từ đủ 4 lối (icon app bar Khoản vay · ô Home · row
  màn Tất cả tính năng · row Settings).
- Home: hàng shortcut đúng 4 ô mới; ô Ví/Hạn mức đã bỏ nhưng wallet strip
  và budget card vẫn dẫn đúng trang; "Xem thêm" mở màn Tất cả tính năng đủ
  6 mục; row "Khoản vay" và "Sổ theo dõi" (Settings + Tất cả tính năng) đếm
  đúng từng sổ.
- Đổi filter ở trang này, trang kia không đổi theo.
- Loan theo dõi có lịch đợt → notification vẫn lên; tap từ trạng thái app
  kill → mở đúng sheet, sheet không có picker ví.
- Loan cũ (v2) nguyên trạng ở `/loans`, hành vi payment như cũ.
- Backup → restore: cờ giữ nguyên; backup từ bản cũ (thiếu cột) import sạch.
- `flutter analyze` · `flutter test` (371 + mới) · `flutter build apk --debug`
  đều sạch.

## 6. Backlog (không làm lần này)

- "Chuyển sổ" một loan sau khi tạo (user đã chốt khóa lúc tạo; nếu sau này
  cần, làm dạng "nhân bản sang sổ kia rồi đóng bản cũ" thay vì flip cờ).
- Ghi chú "theo dõi hộ ai" (trường contact đã có sẵn, cân nhắc thêm nhãn
  quan hệ).
