# PLAN — Khoản vay v2: trả theo đợt + liên kết ví

> Feature đầu tiên sau redesign. **Đây là file thắng** cho mọi quyết định của
> feature này; quy tắc UI chung (token, component, icon, font) vẫn theo
> `plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`
> mục 2 và 3 — đọc 2 mục đó trước khi viết widget đầu tiên.
>
> Cập nhật bảng tiến độ ở mục 1 của file này mỗi khi xong một giai đoạn.

## 0. Đọc gì trước khi bắt đầu

| Thứ tự | File | Để làm gì |
|---|---|---|
| 1 | **file này** | quyết định đã chốt với user, phạm vi từng GĐ |
| 2 | `HANDOFF-STATE.md` mục 2, 3, 5, 6 (đường dẫn ở trên) | token/component/quy trình analyze→test→build |
| 3 | `…/design_handoff_spendo_redesign/audit/15-loan-list.md`, `16-loan-detail.md`, `17-loan-form-sheet.md` | hiện trạng 3 màn loan (AS-IS thời điểm audit — code đã redesign xong Phase 5b, đối chiếu lại với code thật) |

Code loan hiện tại (~2000 dòng, đã redesign):

```
lib/features/loan/
  domain/loan.dart                      — Loan, LoanPayment, LoanType, LoanStatus
  data/loan_repository.dart             — CRUD + watchPaidByLoan + watchSummaryWithRemaining
  presentation/providers/loan_provider.dart
  presentation/screens/loan_list_screen.dart
  presentation/screens/loan_detail_screen.dart
  presentation/widgets/loan_form_sheet.dart
  presentation/widgets/add_payment_sheet.dart
```

Nguyên tắc bất biến: `remaining = principal − SUM(loan_payments.amount)` —
**đợt không bao giờ tham gia vào phép tính tiền**, chỉ tham gia vào việc
hiển thị kế hoạch và nhắc nhở.

---

## 1. Tiến độ

| GĐ | Nội dung | Trạng thái | Commit |
|---|---|---|---|
| 1 — Lịch trả góp | schema + màn tạo/sửa lịch + section Lịch trả ở Detail | ✅ xong | `0f55624` |
| 2 — Liên kết ví | payment/tiền gốc tạo transaction + 4 danh mục nợ | ✅ xong | |
| 3 — Nhắc đợt đến hạn | notification 1 ngày trước + deep-link | ⬜ chưa làm | |

Baseline trước GĐ1: `flutter analyze` sạch · **244 test pass** · debug APK
build được (kế thừa từ redesign, commit `adf1bf1`).

Baseline sau GĐ1: `flutter analyze` sạch · **307 test pass** (244 + 63 mới) ·
debug APK build được.

Baseline sau GĐ2: `flutter analyze` sạch · **342 test pass** (+35) · debug APK
build được.

Quy trình mỗi GĐ: giống HANDOFF-STATE mục 5 — đọc quyết định ở mục 2 dưới
đây → làm → `flutter analyze` + `flutter test` + `flutter build apk --debug`
đều sạch → tự kiểm mục "Nghiệm thu" của GĐ → **1 commit** → cập nhật bảng
này (+ mục 2 nếu phát sinh quyết định mới) → dừng chờ duyệt. Không lấn GĐ sau.

---

## 2. Quyết định đã chốt với user (2026-09-01)

### 2.1 Hai dạng trả — `repayment_mode`

- **`free` (Trả tự do)** — hành vi hiện tại: trả bao nhiêu đợt, mỗi đợt bao
  nhiêu cũng được, miễn đủ. KHÔNG có lịch.
- **`installment` (Trả theo đợt)** — có bảng lịch `loan_installments`.

Cột mới `loans.repayment_mode` TEXT, **null = 'free'** → toàn bộ loan cũ
tự thành Trả tự do, không cần migration ghi dữ liệu.

Đổi qua lại được cả hai chiều, bất cứ lúc nào, kể cả khi đã trả một phần:
- free → installment: nút **"Tạo lịch trả góp"** ở Detail, generator sinh lịch
  từ **số còn lại** (không phải gốc).
- installment → free: **"Xoá lịch"** ở Detail (confirm) — xoá hết installments,
  set mode về free. Payments không suy suyển.

### 2.2 Đợt = kế hoạch, thanh toán = thực tế — TÁCH BẠCH

`loan_installments` là dự định; `loan_payments` là chuyện đã xảy ra. **Không
có cột `is_paid`, không có `installment_id` trên payment.** Trạng thái từng
đợt suy ra bằng waterfall (2.3). Nhờ đó trả thiếu / trả dư / trả gộp 2 đợt /
trả sớm đều tự đúng, không cần luật đặc biệt.

### 2.3 Trạng thái đợt — FIFO waterfall, thuần hàm

Tiền đã trả rót vào các đợt theo thứ tự `seq`, đợt trước đầy mới tràn sang
đợt sau:

```
offset      = max(0, principal − sum(installments.amount))
allocatable = clamp(totalPaid − offset, 0, totalPaid)
```

rồi rót `allocatable` lần lượt: đợt nhận đủ `amount` → **Đã trả**; nhận một
phần → **Trả thiếu (còn X)**; chưa nhận gì và `due_date` đã qua → **Quá hạn**;
còn lại → **Chưa đến hạn**.

`offset` để cover trường hợp lịch tạo giữa chừng từ số còn lại (2.1): phần đã
trả trước khi có lịch không được rót vào đợt nào. Ví dụ: gốc 10tr, đã trả
4tr, tạo lịch 3 đợt × 2tr → offset = 10 − 6 = 4tr → allocatable = 0 → cả 3
đợt Chưa trả. Đúng.

Viết thành **hàm thuần** (vd `lib/features/loan/domain/installment_status.dart`)
nhận `(principal, installments, totalPaid, today)` trả về list trạng thái —
unit test kỹ chỗ này, nó là trái tim của feature.

### 2.4 Generator lịch — 2 cách nhập, phần lẻ dồn đợt cuối

Segmented control 2 chế độ:
- **Chia đều**: nhập số đợt N → tiền mỗi đợt = base = (tổng ÷ N) làm tròn
  xuống nghìn; **đợt cuối = tổng − base×(N−1)** (nuốt phần lẻ).
- **Theo số tiền**: nhập tiền mỗi đợt → N = ceil(tổng ÷ tiền); đợt cuối là
  phần còn lại (có thể nhỏ hơn).

Kèm: **ngày đợt đầu** (mặc định = due_date đợt kế từ hôm nay) + **chu kỳ**:
Hàng tháng (mặc định) / 2 tuần / Hàng tuần. Ngày trong tháng giữ nguyên ngày
của đợt đầu; tháng thiếu ngày (31 → tháng 30 ngày) thì lùi về ngày cuối tháng.

**Cap 100 đợt** — chặn ở validator (nhập "theo số tiền" quá nhỏ sẽ nổ số đợt).

Danh sách sinh ra **sửa được từng đợt** (tiền + ngày), **xoá đợt**, **thêm
đợt** (đúng yêu cầu gốc của user). Xoá/thêm xong đánh lại `seq` theo thứ tự
ngày. Dòng tổng ở đáy so với đích (gốc hoặc số còn lại):

- Khớp → `✓`
- Lệch → cảnh báo "Tổng các đợt thiếu/thừa X so với …" + nút **"Dồn vào đợt
  cuối"** — nhưng **vẫn cho lưu khi lệch** (đợt chỉ là kế hoạch, remaining
  luôn tính theo principal nên tiền không bao giờ sai).

### 2.5 Không lãi suất (v1)

Đợt chỉ chia tiền gốc. Vay có lãi → user tự cộng lãi vào số tiền từng đợt
(sửa tay được nên làm được). Không chừa cột. Backlog mục 7.

### 2.6 Payment luôn tạo transaction (từ GĐ2)

Ghi thanh toán = tạo đồng thời 1 dòng `transactions`:

| Loan type | Chiều transaction | Danh mục |
|---|---|---|
| `borrowed` (tôi vay) — trả nợ | `expense` | **Trả nợ** |
| `lent` (tôi cho vay) — thu nợ | `income` | **Thu nợ** |

- Ví: picker giống `add_transaction_sheet` (ví optional theo đúng convention
  của app — wallet_id nullable).
- `source = 'loan'` (cột source hiện chỉ bị check ở
  `transaction.dart:24` `isAutomatic => source == 'sepay'` → thêm giá trị mới
  an toàn).
- Liên kết: cột mới `loan_payments.transaction_id`.
- **Xoá payment → xoá transaction đi kèm** (1 `writeTransaction`).
- Payment cũ (transaction_id null) giữ nguyên, không backfill.

### 2.7 Bốn danh mục nợ — lazy-create, is_default=1, KHÔNG seed

User chọn "2 tên riêng" cho payment, và chọn "có ghi tiền gốc vào ví" —
tiền gốc chảy ngược chiều tiền trả nên cần đủ 4 tên, mỗi dòng tiền một
danh mục:

| Danh mục | is_income | Dùng cho | icon_name mới | Icon Lucide |
|---|---|---|---|---|
| **Trả nợ** | 0 (chi) | payment của khoản đi vay | `loan_repay` | `handCoins` |
| **Thu nợ** | 1 (thu) | payment của khoản cho vay | `loan_collect` | `coins` |
| **Đi vay** | 1 (thu) | tiền gốc vay VỀ ví | `loan_in` | `piggyBank` |
| **Cho vay** | 0 (chi) | tiền gốc cho vay RỜI ví | `loan_out` | `handshake` |

(4 icon trên là đề xuất — khi làm mở `lucide_icons_flutter` chọn lại nếu cái
nào không có; thêm 4 key vào switch trong `lib/core/utils/category_icons.dart`.)

- **KHÔNG thêm vào seed** (`powersync_db.dart:143`) — người không dùng khoản
  vay không phải thấy 4 danh mục rác. Chỉ tạo **lần đầu cần đến** (lazy).
- `is_default = 1` → không xoá được ([categories_screen.dart:192]
  `canDelete = !isDefault && count == 0`) → transaction nợ không bao giờ mồ
  côi danh mục.
- **Resolver** (vd `loan_category_resolver.dart` trong `features/loan/data/`):
  1. đọc id đã lưu trong SharedPreferences (`loan_cat_repay_id`…) → verify
     còn tồn tại;
  2. fallback: query `categories WHERE icon_name = '<key>' AND is_default = 1`
     (chống mất prefs sau restore backup) → adopt + lưu lại id;
  3. không có → INSERT mới + lưu id.
  Màu: chọn 4 hex kiểu seed hiện tại, cùng tông (vd đất/nâu cho hợp theme).

### 2.8 Tiền gốc — toggle "Ghi vào ví", mặc định TẮT

Form tạo khoản vay thêm mục **"Ghi vào ví"** (SwitchTile, mặc định tắt —
nợ có từ trước khi dùng app / tiền mặt ngoài ví là chuyện thường):

- Bật → hiện picker ví → khi lưu loan tạo thêm 1 transaction:
  đi vay → `income` "Đi vay"; cho vay → `expense` "Cho vay". `source='loan'`.
- Cột mới `loans.funding_transaction_id` TEXT nullable giữ liên kết.
- Xoá loan → xoá funding transaction + mọi transaction của payments
  (gom `transaction_id` trước khi xoá payments, tất cả trong 1
  `writeTransaction`).
- **Sửa principal sau khi đã ghi gốc → KHÔNG tự sửa transaction** (nó là
  lịch sử "tiền thực nhận lúc đó"). Detail hiển thị link tới GD gốc để user
  tự xử nếu muốn.
- Chỉ áp dụng cho loan **tạo mới**; loan cũ không backfill (muốn thì user
  tự ghi 1 giao dịch Đi vay/Cho vay bằng tay).

### 2.9 Transaction source='loan' — read-only phía màn Giao dịch

Ở `transaction_detail_sheet.dart` / `delete_transaction_action.dart`: nếu
`source == 'loan'` → chặn sửa & xoá, hiện "Giao dịch này thuộc khoản vay
«title»" + nút mở loan detail (lookup loan qua
`loan_payments.transaction_id` hoặc `loans.funding_transaction_id`).
Muốn đổi/xoá → thao tác từ phía khoản vay (xoá payment / xoá loan / tắt ghi
ví). Một chiều sự thật, không sync 2 chiều.

### 2.10 Nhắc đợt đến hạn (GĐ3)

- Mỗi đợt **chưa trả đủ** (theo waterfall) có `due_date` trong tương lai →
  đặt notification **09:00 sáng 1 ngày trước hạn**.
- **Dải id riêng `20000+`** — tránh đụng id 0 (daily), 1000+ (recurring
  reminders, `reminder_notification_service.dart:6`), 99/9999 (test). Hash từ
  installment id, giống cách `_notifId` của reminder.
- Payload đi theo pattern đã chốt ở HANDOFF-STATE 2.2 (route chỉ-cho-deep-link,
  như `/add`): path mới vd `/loan-pay?loan_id=…` trong
  `notification_service.dart:56-94 _handlePayload` → mở LoanDetail + tự bật
  `AddPaymentSheet` điền sẵn số tiền còn thiếu của đợt.
- Reschedule tại 3 chỗ: (a) app start — `main.dart` bước 4 (dòng ~122, cạnh
  chỗ scheduleAll reminders, cũng bọc try/timeout như vậy); (b) sau mọi thay
  đổi lịch; (c) sau mọi thay đổi payment (đợt được trả đủ thì cancel notif
  của nó).

### 2.11 UI — không có mockup cho màn mới

Màn sửa lịch + section Lịch trả **không có** trong `mockups/`. Dựng bằng
token + component sẵn có (HANDOFF-STATE mục 3: SpendoSheet, SpendoCard,
SpendoSettingsRow, `context.spendo`, tabular figures cho mọi số tiền, Lucide
stroke 2.25). Sketch bố cục ở mục 4/5 dưới là gợi ý, không phải spec cứng.

---

## 3. Schema delta (gom cả 3 GĐ — làm 1 lần ở GĐ1)

`lib/core/db/schema.dart`:

```dart
Table.localOnly('loans', [
  // … 9 cột cũ giữ nguyên …
  Column.text('repayment_mode'),           // 'free' | 'installment' | null=free   (GĐ1)
  Column.text('funding_transaction_id'),   // nullable                             (GĐ2)
]),
Table.localOnly('loan_installments', [     //                                      (GĐ1)
  Column.text('loan_id'),
  Column.integer('seq'),                   // 1-based, hiển thị "Đợt 3/12"
  Column.text('amount'),                   // TEXT như principal/amount hiện tại
  Column.text('due_date'),                 // ISO, ngày (bỏ giờ)
]),
Table.localOnly('loan_payments', [
  // … 4 cột cũ …
  Column.text('transaction_id'),           // nullable                             (GĐ2)
]),
```

PowerSync localOnly tự migrate khi schema đổi (thêm cột/bảng — data giữ
nguyên; đã có tiền lệ comment "thêm migration ALTER TABLE" ở transactions).

**Bắt buộc đi kèm:** `lib/core/utils/backup_service.dart` đang export/import
tường minh `loans` + `loan_payments` (dòng 24-25, 116-140, 217) → thêm
`loan_installments` + các cột mới vào cả export lẫn import (đếm
added/skipped như các bảng khác). Backup cũ thiếu cột mới phải import được
(default null).

---

## 4. GĐ1 — Lịch trả góp

### Phạm vi

1. **Schema** — toàn bộ mục 3 (kể cả cột GĐ2, thêm 1 lần cho đỡ migrate 2 lần;
   GĐ1 chưa ghi gì vào 2 cột transaction).
2. **Domain** — `loan.dart`: thêm `repaymentMode`, `fundingTransactionId`,
   class `LoanInstallment`; file mới `installment_status.dart` (hàm thuần 2.3)
   + `installment_generator.dart` (hàm thuần 2.4: sinh lịch, dồn đợt cuối,
   cap 100, cộng chu kỳ tháng/2 tuần/tuần).
3. **Repository** — CRUD installments (`watchInstallments(loanId)`,
   `replaceInstallments(loanId, list)` trong 1 `writeTransaction` — sửa lịch
   là thay cả cụm, đơn giản và không bao giờ lệch seq).
4. **Form** (`loan_form_sheet.dart`) — thêm chọn dạng 2 chip
   Trả tự do / Trả theo đợt (mặc định: tự do; khi **sửa** loan thì ẩn — đổi
   dạng làm ở Detail). Chọn "theo đợt" → sau khi bấm Lưu mở tiếp màn lịch (5).
5. **Màn sửa lịch** — mới, vd
   `presentation/screens/installment_schedule_screen.dart` (full-screen, list
   dài — không nhét sheet): generator ở trên + list đợt edit/xoá/thêm + dòng
   tổng + cảnh báo lệch (2.4). Lưu = `replaceInstallments`. Dùng lại
   `AmountInputController` cho ô tiền.

   ```
   [Chia đều | Theo số tiền]     Số đợt [ 12 ]
   Đợt đầu [ 15/10/2026 ▾ ]      Chu kỳ [ Hàng tháng ▾ ]
   ──────────────────────────────────────
   Đợt 1   15/10/2026   3.333.333   ✎ 🗑
   Đợt 2   15/11/2026   3.333.333   ✎ 🗑
   …                        [ + Thêm đợt ]
   ──────────────────────────────────────
   Tổng 12 đợt   10.000.000   = gốc ✓
   [        Lưu lịch trả        ]
   ```
6. **Detail** (`loan_detail_screen.dart`) — loan `installment`: section
   **Lịch trả** trên lịch sử thanh toán (tiến độ X/N đợt + progress bar theo
   allocatable/tổng-lịch, 2-3 đợt sắp tới với trạng thái waterfall + nút Trả,
   "Xem tất cả ▾", nút Sửa lịch / Xoá lịch). Loan `free`: giữ nguyên + nút
   "Tạo lịch trả góp" (generator seed bằng **số còn lại**, 2.1).
7. **Payment sheet** (`add_payment_sheet.dart`) — loan installment: prefill
   số tiền = phần còn thiếu của đợt chưa-đủ sớm nhất, kèm dòng "Đợt k/N ·
   hạn dd/MM" (user sửa thoải mái — waterfall lo phần còn lại).
8. **List** (`loan_list_screen.dart`) — row loan installment: phụ đề dạng
   "Đợt 5/12 · 15/10" thay cho due_date đơn (nếu đang có); overdue badge lấy
   theo đợt quá hạn sớm nhất thay vì `loans.due_date`.
   Lưu ý: `Loan.status` hiện tính theo `loans.due_date` — với installment,
   due_date "hiệu dụng" = hạn của đợt chưa-đủ kế tiếp; cân nhắc expose qua
   provider (join installments) chứ đừng nhét query vào widget.

### Nghiệm thu GĐ1

- Tạo loan theo đợt: chia đều 10tr/3 → 3.333.000 ×2 + 3.334.000 (dồn lẻ);
  theo số tiền 10tr @ 3tr → 4 đợt (3+3+3+1).
- Sửa 1 đợt cho lệch tổng → cảnh báo + "Dồn vào đợt cuối" hoạt động; lưu khi
  lệch vẫn được.
- Trả 5tr một cục → waterfall: đợt 1 Đã trả, đợt 2 Trả thiếu, đợt 3 Chưa.
- Loan free cũ: mọi thứ y nguyên; "Tạo lịch trả góp" từ remaining chạy đúng
  (offset test 2.3).
- Xoá lịch → về free, payments còn nguyên, remaining không đổi.
- Backup → xoá app data → restore: installments về đủ.
- `flutter analyze` + `flutter test` (244 + tests mới) + build APK sạch.

Tests tối thiểu: unit generator (lẻ, cap, chu kỳ, cuối tháng 31→30/28) ·
unit waterfall (đủ/thiếu/dư/offset/quá hạn) · widget màn lịch (sinh + sửa +
cảnh báo) · widget detail section · repository replaceInstallments.

---

## 5. GĐ2 — Liên kết ví & danh mục

### Phạm vi

1. **Resolver 4 danh mục** (2.7) + 4 entry mới trong `category_icons.dart`.
2. **Payment sheet**: thêm picker ví (tái dùng widget/provider chọn ví của
   `add_transaction_sheet.dart`) → `addPayment` mở rộng: tạo transaction
   (chiều + danh mục theo 2.6, `source='loan'`, note = ghi chú payment hoặc
   tự sinh "Trả nợ: «title»"), lưu `transaction_id` vào payment — tất cả
   trong 1 `writeTransaction`.
3. **Xoá payment** → xoá transaction kèm theo. **Xoá loan**
   (`loan_repository.delete`) → gom mọi transaction_id (payments + funding)
   xoá cùng, 1 `writeTransaction`.
4. **Form loan**: toggle "Ghi vào ví" + picker ví (2.8) → tạo funding
   transaction khi lưu. Detail hiện dòng liên kết GD gốc (nếu có).
5. **Guard** ở `transaction_detail_sheet.dart` + `delete_transaction_action.dart`
   (2.9).
6. Kiểm tra Thống kê/Ví hiển thị các giao dịch mới tự nhiên (không sửa gì
   thêm — chúng là transactions thường).

### Nghiệm thu GĐ2

- Ghi payment 2tr từ ví A → ví A giảm 2tr, Thống kê chi có "Trả nợ" 2tr,
  danh mục tự sinh đúng 1 lần (ghi tiếp không nhân đôi danh mục).
- Xoá payment → transaction biến mất, ví hồi 2tr.
- Tạo loan đi vay 10tr toggle bật ví A → ví A +10tr, thu "Đi vay" 10tr; xoá
  loan → sạch cả funding lẫn payment transactions.
- Mở GD source='loan' ở màn Giao dịch → không sửa/xoá được, dẫn về đúng loan.
- 4 danh mục không xoá được ở màn quản lý danh mục ("Mặc định").
- Restore backup mất prefs → resolver adopt lại theo icon_name, không tạo
  danh mục trùng.
- analyze/test/build sạch.

---

## 6. GĐ3 — Nhắc đợt đến hạn

### Phạm vi

1. `LoanNotificationService` (mới, cạnh `reminder_notification_service.dart`,
   cùng style): schedule/cancel theo mục 2.10, channel riêng
   (`spendo_loan_due`), title kiểu "💸 Đợt 5/12 — «title»", body số tiền
   còn thiếu của đợt.
2. Payload + route deep-link `/loan-pay` (2.10) trong `notification_service.dart`
   `_handlePayload` + `app_router.dart` — làm đúng pattern `/add`
   (HANDOFF-STATE 2.2: route sống chỉ vì deep-link, mọi lối trong-app gọi
   thẳng helper).
3. Hook reschedule: `main.dart` bước 4 (cạnh scheduleAll reminders, cùng
   kiểu try/timeout 5s) + sau save/xoá lịch + sau add/delete payment.
4. Giới hạn: chỉ schedule **K đợt sắp tới mỗi loan** (vd 3) — đợt sau được
  schedule dần qua hook (a) mỗi lần mở app; tránh xếp hàng trăm notification.

### Nghiệm thu GĐ3

- Loan 3 đợt, đợt 1 hạn ngày mai → có notification pending 09:00 hôm nay
  (kiểm bằng `pendingNotificationRequests` trong test/debug panel).
- Trả đủ đợt 1 → notif của nó bị cancel, đợt 2 lên lịch.
- Tap notification (app killed) → mở đúng loan + sheet điền sẵn.
- Xoá loan / xoá lịch → không còn notif mồ côi.
- Không đụng dải id của daily (0) / reminders (1000+) / test (99, 9999).
- analyze/test/build sạch.

---

## 7. Backlog (KHÔNG làm trong 3 GĐ này)

- Lãi suất (nhập %/năm, tính dư nợ giảm dần vs lãi phẳng).
- Tuỳ chọn loại trừ nhóm danh mục nợ khỏi biểu đồ Thống kê ("dòng tiền" vs
  "thu nhập thật").
- Sửa payment (hiện chỉ có xoá + ghi lại).
- Backfill ghi-vào-ví cho loan cũ.
- Nhiều lịch nhắc / tuỳ chỉnh giờ nhắc đợt.
