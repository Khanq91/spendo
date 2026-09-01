# HANDOFF-STATE — đọc file này TRƯỚC khi làm phase tiếp theo

> File này ghi **trạng thái thực tế của code** và **các quyết định lệch khỏi
> spec gốc**. Spec (`README.md`, `01-tokens.md`…) mô tả đích đến; file này mô
> tả đang đứng ở đâu và những chỗ đã cố ý làm khác. Khi hai bên mâu thuẫn về
> một điểm được liệt kê ở mục "Quyết định đã chốt" bên dưới → **file này thắng**.
>
> Cập nhật file này mỗi khi xong một phase.

## 0. Đọc gì trước khi bắt đầu

Mọi đường dẫn dưới đây tính từ `plan/ui-info/ui-audit/design_handoff_spendo_redesign/`.

| Thứ tự | File | Để làm gì |
|---|---|---|
| 1 | **file này** | đang ở đâu, đã chốt khác spec chỗ nào |
| 2 | `01-tokens.md` | bảng màu light+dark, thang chữ, bo góc, spacing |
| 3 | `02-components.md` | spec từng component dùng chung |
| 4 | `03-screens.md` | bảng 26 màn: mockup nào ↔ audit nào ↔ đổi gì |
| 5 | `04-phases.md` | mục của phase sắp làm + tiêu chí Nghiệm thu |
| 6 | `README.md` | bối cảnh chung (đọc lướt, đã tóm ở đây) |

Khi làm một màn cụ thể thì đọc thêm:
- `audit/<nn>-*.md` — hiện trạng code màn đó, có ref `file:line`
- `mockups/*.dc.html` — thiết kế TO-BE, style nằm inline; **reference, không
  copy HTML vào app**
- `../screenshots/<nn>-*.png` — ảnh render các màn, đã đặt tên theo số màn

Nguyên tắc chung: giữ nguyên logic nghiệp vụ / provider / database — đây là
redesign UI. Icon chỉ dùng Lucide (stroke 2.25). Số tiền luôn tabular figures.
Cấm rải hex trong widget, mọi màu lấy qua `ColorScheme` + `context.spendo`.

---

## 1. Tiến độ

| Phase | Trạng thái | Commit |
|---|---|---|
| 0 — Nền theme & hạ tầng | ✅ xong | `ae1b508` |
| 1 — Shell & component dùng chung | ✅ xong | `be499de` |
| 2 — Home + Add (màn 01, 02, 02b) | ✅ xong | `1e9322f` |
| 3 — Giao dịch & PeriodPicker | ✅ xong | `0bd474a` |
| 4 — Ví & Hạn mức | ✅ xong | `37ee086` |
| 5 — Thống kê, Vay, Nhắc nhở | ✅ xong | `eb30303` + `583d7d0` |
| 6 — Cài đặt & trang con | ✅ xong | `da955a9` |
| 7 — Khởi động + Dark pass + QA | ✅ xong | `adf1bf1` |

Baseline hiện tại: `flutter analyze` sạch · **244 test pass** · debug APK build được.

> **Toàn bộ 8 phase đã xong.** Redesign khép lại ở `adf1bf1`.

> Sau Phase 3 có 1 commit sửa lỗi UI phát hiện khi chạy thật (`6eb95fa`) —
> xem mục 2.9.

---

## 2. Quyết định đã chốt trong lúc làm (KHÁC spec gốc)

### 2.1 Font — KHÔNG dùng Figtree/Caprasimo

Spec ghi Figtree (UI) + Caprasimo (tiêu đề). **Cả hai đều không có glyph tiếng
Việt.** Đã verify bằng `fontTools` trên binary upstream + metadata Google Fonts:

- Figtree thiếu **92/98** codepoint tiếng Việt (gồm `ơ ư ạ ả`)
- Caprasimo thiếu **82**

App hard-code 100% tiếng Việt → chữ có dấu sẽ rơi sang font hệ thống **giữa
từ** ("Số dư" = S,d một font, dấu móc một font khác). Spec chỉ dự phòng cho
Caprasimo, bỏ sót Figtree — mà Figtree mới là font dùng cho toàn UI.

**Đã thay** (user duyệt) bằng cặp phủ tiếng Việt 100% + có `tnum`:

| Vai trò | Spec gốc | Đang dùng |
|---|---|---|
| UI toàn app | Figtree | **Plus Jakarta Sans** (400/500/600/700/800) |
| Tiêu đề màn, brand | Caprasimo | **Baloo 2** (700/800, đã subset) |

- Bundle trong `assets/fonts/` (484 KB) — app offline-first, **không** dùng
  `google_fonts` fetch runtime.
- Thang chữ / weight / letter-spacing **giữ nguyên theo spec**.
- Khai báo ở `lib/core/theme/app_typography.dart`. Đổi font = sửa 2 hằng
  `fontFamily` / `displayFamily` ở đó, không màn nào hard-code tên font.

⚠️ **Đừng cài lại Figtree/Caprasimo.** Nếu cần đổi, chọn font có subset
`vietnamese` trên Google Fonts và kiểm `tnum` trước (số tiền có
`AnimatedMoneyText`, digit không đều sẽ nhảy).

### 2.2 Route `/add` — giữ lại, KHÔNG xoá

Spec Phase 1 ghi "bỏ route giả `/add`". Nhưng `/add` **không phải route giả**:
`lib/core/notifications/notification_service.dart:74` deep-link vào
`/add?category_id=…&note=…&amount=…` khi user tap thông báo nhắc nhở. Khi app
bị kill hoàn toàn, notification khởi động app từ đầu — lúc đó chưa có context
nào để mở bottom sheet.

**Đang làm:**
- Mọi lối vào trong app (FAB, shortcut Home, nút Chỉnh sửa ở detail sheet) gọi
  thẳng `showAddTransactionSheet(context, …)` trong
  `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`.
- `/add` giữ lại **chỉ cho deep-link**, và cũng gọi vào đúng helper đó.

Kết quả: chỉ còn 1 nơi định nghĩa cách present sheet (trước có 3 nơi khai báo
`showModalBottomSheet` với `backgroundColor`/`shape` khác nhau).

Muốn xoá hẳn `/add` thì phải đổi cơ chế notification trước (ví dụ lưu pending
intent vào provider rồi Home tự mở sheet) — chưa làm.

### 2.3 5 màu chủ đạo — swap brand + primary, giữ nền cream

Theo `01-tokens.md`: không sinh lại scheme bằng `fromSeed`. `AppColorScheme`
trong `app_theme.dart` giờ khai báo tường minh `brandColor` / `onBrandColor` /
ramp primary cho từng lựa chọn; **bộ surface cream/nâu dùng chung cho cả 5**.
Có test khoá hành vi này (`test/core/theme/app_theme_test.dart`).

### 2.4 Chọn kỳ — ĐÃ XONG ở Phase 3

Mockup 01 bỏ 2 nút `‹ ›` và chip "Hôm nay", chỉ còn `Tháng 8/2026 ▾`.

Phase 3 đã dựng `PeriodPickerSheet` và **thay hết**: Home, Giao dịch, Thống kê
và `MonthSelector` đều gọi nó. `MonthPickerSheet` + `DateRangePickerSheet` đã
xoá.

`month_selector.dart` **đã xoá** ở Phase 4 (Chi tiết ví là call-site cuối).

### 2.4b Phase 3 — model kỳ chung `Period`

`StatsDateRange` (trong `features/stats/`) chuyển ra
**`lib/shared/domain/period.dart`** thành `Period` — 4 màn cùng hỏi "kỳ nào".

- Biên **nửa mở**: `start` inclusive, `end` exclusive → query
  `created_at >= start AND < end`, không phải cộng trừ cuối ngày ở từng chỗ.
- `PeriodPreset` (Tháng này / Tháng trước / 3 tháng gần nhất / Năm nay) tự
  resolve theo lịch.
- Màn chỉ chạy theo tháng truyền `allowCustomRange: false` → picker ẩn **cả**
  khoảng tuỳ chọn **lẫn** preset nhiều tháng (Home, và Hạn mức ở Phase 4).
- `features/stats` giữ `typedef StatsDateRange = Period;` để màn Thống kê
  (Phase 5) chưa phải sửa.

### 2.4c Phase 3 — xoá giao dịch dùng Hoàn tác, bỏ dialog

Mockup 03 (vuốt) + 04 (xoá → undo). Cả hai đường xoá gọi chung
`deleteTransactionWithUndo` (`transactions/presentation/widgets/`):
xoá ngay → snackbar "Hoàn tác" 5s → `TransactionRepository.restore()` chèn lại
đúng id + createdAt.

Dialog xác nhận cũ đã bỏ: dialog hỏi trước **mọi** lần xoá kể cả lần cố ý,
còn undo chỉ tốn chú ý khi xoá nhầm.

Phase 4–5 khi làm màn có xoá (ví, khoản vay, nhắc nhở) nên dùng cùng kiểu này.

### 2.4d Phase 3 — Giao dịch có kỳ + bộ lọc riêng

- `transactionsPeriodProvider` (kỳ của màn Giao dịch) tách khỏi
  `selectedMonthProvider` (tháng của Home). Audit ghi: dùng chung state toàn
  cục → lọc ở bản push `/transactions` còn dính lại khi về tab.
- `TransactionFilter` (`transactions/domain/transaction_filter.dart`) gom:
  loại (Tất cả|Chi|Thu) · **nhiều** danh mục · **nhiều** ví · từ khoá.
  Chip strip cũ chỉ giữ được 1 danh mục và trộn thu/chi cùng hàng.
- `activeCount` = số bộ lọc đang áp (badge trên nút phễu). Từ khoá **không**
  tính vì ô tìm kiếm đã tự hiện chữ đang gõ.

### 2.9 Chip — CHỈ MỘT kiểu: nền đặc

Spec `02-components.md` cho phép chip gợi ý dùng "viền 1px **HOẶC** nền
surfaceContainer" → tôi đã chọn lệch nhau ở mỗi màn, ra 3 kiểu cho cùng một
thứ. Trên nền tối chip viền gần như biến mất.

**Đã chốt:** mọi `SpendoChip` đều **nền đặc**, cao 34 (meta 36), không viền.
Chỉ `selected` phân biệt (primaryContainer). `SpendoChipKind.suggestion` giờ
là alias của `filter`, giữ lại để call-site nói rõ ý.

Có test khoá ở `test/shared/widgets/spendo/spendo_chip_test.dart` (chạy cả
light + dark).

⚠️ **Đừng dùng màu thô của danh mục/ví cho nền hay chữ chip.** Màu riêng chỉ
đặt ở **icon** (`SpendoIconTile`, `SpendoCategoryTile`). Lý do: danh mục màu
đỏ (`#FF6B6B`) làm chip đang chọn đọc thành báo lỗi ở dark mode.

**Đã hết chip riêng.** `wallet_detail_screen.dart:_FilterChip` xoá ở Phase 4,
`loan_detail_screen.dart:_MetaChip` ở Phase 5, `settings_screen.dart:_TabChip`
ở Phase 6 (đều thay bằng `SpendoSegmented` / `SpendoChip.meta`).

### 2.10 `SpendoSheet.showModal` tự bọc nền

`showModal` đặt `backgroundColor: Colors.transparent` vì `SpendoSheet` tự vẽ
nền bo góc. Hệ quả: truyền vào widget **không phải** `SpendoSheet` → sheet
trong suốt, nhìn xuyên xuống sheet phía dưới (đúng lỗi `ReminderFormSheet` khi
bấm "Lặp lại").

`showModal` giờ tự bọc `_SheetSurface` cho content chưa phải `SpendoSheet` →
màn chưa tới lượt redesign vẫn có nền đúng. Khi tới lượt thì dựng hẳn trên
`SpendoSheet` để có luôn drag handle + padding bàn phím.

### 2.11 Phase 4 — `/budget` là TRANG, 3 sheet cũ xoá hẳn

Spec màn 09 ghi "gộp 3 sheet cũ → 1 trang". Đã làm đúng:

- **Xoá**: `budget_type_sheet.dart` (bước chọn loại), `category_budget_screen.dart`
  (list + sheet con). `budget_screen.dart` **viết lại** thành trang thật.
- **Route mới `/budget`** trong `app_router.dart`. Mọi lối vào (ô tắt "Hạn mức"
  ở Home, card ngân sách Home cả 2 trạng thái) giờ `context.push('/budget')`.
- `showBudgetTypeSheet` **không còn** — đừng gọi lại (mục 3.4 cũ đã bỏ dòng đó).

Trang gồm: card Tổng tháng (tiến độ + Sửa + xoá) · danh sách danh mục có hạn
mức (progress + % / "Vượt +X") · chip danh mục chưa đặt · dòng gợi ý.

### 2.12 Phase 4 — Hạn mức có KỲ RIÊNG (`budgetPeriodProvider`)

Sheet cũ đọc thẳng `selectedMonthProvider` → mở từ đâu cũng ghi vào tháng Home
đang xem, chỉ báo bằng 1 dòng phụ 12px (`23-budget-screen.md` §J).

`budget_page_provider.dart` thêm:

| Provider | Trả về |
|---|---|
| `budgetPeriodProvider` | kỳ của trang (khởi tạo từ `selectedMonthProvider`, sau đó độc lập) |
| `budgetPageBudgetProvider` | hạn mức tháng **theo kỳ của trang** |
| `budgetPeriodTransactionsProvider` | giao dịch trong kỳ |
| `budgetSpentTotalProvider` / `budgetSpentByCategoryProvider` | đã chi (tổng / theo danh mục) |
| `budgetPageCategoryProgressProvider` | tiến độ từng danh mục trong kỳ |

`budgetProgressProvider` + `categoryBudgetProgressProvider` cũ **giữ nguyên** —
Home và sheet Thêm giao dịch vẫn dùng, chúng đúng là "theo tháng Home".

⚠️ Hạn mức danh mục **không có cột tháng** trong DB (`CategoryBudget` chỉ có
`category_id` + `amount`) → áp dụng mọi tháng, chỉ tiến độ mới theo kỳ. Đây là
model có sẵn, Phase 4 **không** đổi schema; trang nói rõ điều đó ở dòng gợi ý.

### 2.13 Phase 4 — xoá hạn mức + lưu trữ ví dùng Hoàn tác

Theo mục 2.4c. Cả ba đường xoá/lưu trữ mới đều snackbar 5s + Hoàn tác:

- hạn mức tháng (nút thùng rác trên card) → `BudgetRepository.set` lại
- hạn mức danh mục (**vuốt trái**) → `CategoryBudgetRepository.set` lại
- **lưu trữ ví** → `unarchive`

Riêng **xoá ví** vẫn giữ dialog xác nhận: ví không còn giao dịch thì không có
gì để khôi phục lại từ đó. Xoá ví còn giao dịch vẫn bị chặn như cũ.

### 2.14 Phase 4 — `walletTypeIcon` thay `categoryIcon` cho ví

Bug `12-wallets.md` §L: `categoryIcon` không có key nào của `WalletType`
(`wallet` `landmark` `smartphone` `credit_card` `trending_up` `more_horiz`) →
**cả 6 loại ví** rơi vào fallback `circleEllipsis`.

`lib/core/utils/wallet_icons.dart` → `walletTypeIcon(WalletType)`. Có test
khoá cả hai chiều (`test/core/utils/wallet_icons_test.dart`).

⚠️ Đừng "sửa" bằng cách nhồi key ví vào `categoryIcon` — hai bảng khác miền,
trộn vào là danh mục tên `landmark` sẽ ăn nhầm icon ví.

### 2.15 Phase 4 — `SpendoScreenHeader` + `SpendoPeriodStepper`

Mockup cho màn push (06/07/09) một hàng 52px: mũi tên back + tên màn **font
display 23px** + action. `AppBar` không cho title cỡ đó mà không lặp lại
`TextStyle` ở từng màn → tách thành widget trong
`shared/widgets/spendo/spendo_screen_header.dart`:

- `SpendoScreenHeader(title:, actions:)` — title co lại trước, action giữ nguyên
- `SpendoHeaderIconButton` — tap target 44
- `SpendoPeriodStepper(period:, onChanged:, showArrows:, maxLabelWidth:)` —
  `‹ Tháng 8 ›`, tap label mở `PeriodPickerSheet`

`showArrows: false` cho hàng chật (Chi tiết ví có segmented cùng dòng): trên
360dp segmented + stepper đủ mũi tên **tràn**. Bỏ mũi tên không mất chức năng —
picker tới được mọi tháng mà mũi tên tới được.

⚠️ Row của stepper là `mainAxisSize.min`; con `Flexible` trong đó **vẫn** lấy
đủ chiều rộng tự nhiên → phải `ConstrainedBox` + `FittedBox` (đã làm). Cùng lý
do, segmented ở Chi tiết ví để `expand: true` trong `Flexible`.

### 2.16 Phase 4 — sheet Thêm giao dịch nhận ví đặt sẵn

`showAddTransactionSheet(context, preselectedWalletId: …)` — FAB "Thêm giao
dịch" ở Chi tiết ví ghi thẳng vào ví đang xem (`13-wallet-detail.md` §G: màn
cũ không có cách nào thêm giao dịch cho chính ví đang mở). Khi **sửa** giao
dịch thì ví của giao dịch thắng.

### 2.17 Phase 5 — Thống kê có toggle Chi|Thu, `statsPeriodProvider`

Màn cũ hard-wire vào **chi**: pie bỏ qua thu, bar chỉ vẽ expense → tháng chỉ có
lương báo "Chưa có dữ liệu" (`10-stats.md` §L).

- `StatsSide` (enum `expense` | `income`) + `statsSideProvider` — segmented
  Chi|Thu quyết định cả pie lẫn bar.
- `statsDateRangeProvider` → **`statsPeriodProvider`**; header dùng
  `SpendoPeriodStepper(allowCustomRange: true)`.
- **Xoá**: `stats_time_selector.dart` và `typedef StatsDateRange = Period`
  (nợ ở mục 2.4b đã trả).
- `statsExpensesByCategoryProvider` → `statsByCategoryProvider` trả
  `List<StatsSlice>` (`categoryId` + `amount` + `share`) đã sort giảm dần.

AppBar + TabBar cũ chiếm 104px trước khi thấy số; giờ header 52 + segmented 30.

### 2.18 Phase 5 — legend tap → tab Giao dịch đã lọc (drill-down)

Theo mục 2.5 (`shellTabProvider`). Tap hàng legend **hoặc** múi pie:

```
transactionsPeriodProvider = kỳ của Stats
transactionFilterProvider  = TransactionFilter(type: Chi|Thu, categoryIds: {id})
shellTabProvider           = ShellTab.transactions
```

Đây là lý do `shellTabProvider` tồn tại — đừng push route `/transactions`.

### 2.19 Phase 5 — `formatVND(amount, withSymbol: false)`

Hàng summary Thống kê có 3 số cùng dòng; 3 chữ ₫ không vừa 360dp. Thêm tham số
**có default `true`** nên mọi call-site cũ không đổi.

### 2.20 Phase 5 — Khoản vay hiện SỐ CÒN LẠI + `loanFilterProvider`

`15-loan-list.md` §L: tile hiện **principal** (số gốc) nên muốn biết còn nợ bao
nhiêu phải vào chi tiết.

- `LoanRepository.watchPaidByLoan()` — 1 query gom `SUM(amount)` theo `loan_id`,
  không phải stream/dòng.
- `paidByLoanProvider` + hàm `remainingOf(loan, paidByLoan)` (clamp 0..principal,
  nên trả dư không ra số âm).
- `LoanFilter` (Tất cả | Đang vay | Cho vay) + `loanFilterProvider` — segmented
  **trong màn**. Query param `?type=` chỉ còn để seed giá trị ban đầu.
- Header card tổng **Đang nợ / Được nợ** (tính trên remaining, bỏ loan closed).
- Chip **"Trả"** ngay trên tile → `showAddPaymentSheet` (không cần vào chi tiết).

⚠️ Progress bar khoản vay dùng **`cs.primary` cố định**, không dùng ngưỡng
85%/vượt của `SpendoProgressBar`. Trả nợ càng nhiều càng tốt — màu cảnh báo ở
đây đọc ngược nghĩa.

### 2.21 Phase 5 — `/loans/:id` là route thật

`LoanDetailScreen` cũ nhận **object `Loan`** qua `Navigator.push` → không URL,
không deep-link, và loan bị xoá nơi khác vẫn render như còn sống.

Giờ nhận `loanId`, tự tìm trong `loansProvider`; không thấy → báo "Khoản vay
không còn tồn tại" (không spinner vô hạn).

`loanPaymentsProvider(loanId)` khai báo **trong `loan_detail_screen.dart`**
(family autoDispose) — nơi duy nhất dùng.

### 2.22 Phase 5 — badge M3 thay emoji · ghi chú thanh toán hiện ra

- `'🔴 Quá hạn'` / `'⚠️ Còn N ngày'` → `_StatusBadge` icon Lucide +
  `context.spendo.warning`. Emoji không đổi theo dark mode và screen reader đọc
  ra tên emoji.
- `loanStatusLabel(loan)` (public trong `loan_list_screen.dart`) — list và
  detail dùng chung, thêm mốc `'Đến hạn hôm nay'` (trước ra "Còn 0 ngày").
- Ghi chú payment **hiện ở subtitle** (`ngày · ghi chú`) — model có, form nhập,
  nhưng chưa bao giờ hiển thị.
- Trả hết → nút đổi thành **"Đánh dấu tất toán"** (trước để loan mở, không gợi ý).
- Tất toán có **Hoàn tác**; xoá loan **giữ dialog** (xoá kéo theo cả lịch sử
  thanh toán, không undo được từ đâu).
- Xoá payment = **vuốt trái** + Hoàn tác (`addPayment` lại nguyên `paidAt`/note).

### 2.23 Phase 5 — `AddPaymentSheet` tách file, chọn được ngày

Sheet cũ nằm trong `loan_detail_screen.dart`, `paidAt = DateTime.now()` cố định
→ ghi bù hôm sau là sai ngày. Giờ:

`loan/…/widgets/add_payment_sheet.dart` · `showAddPaymentSheet(context, loan:,
remaining:)` — chip ngày, chip **"Trả hết"**, cảnh báo khi nhập quá số còn lại
(cảnh báo, **không chặn** — trả dư là chuyện có thật).

### 2.24 Phase 5 — Nhắc nhở: 1 hàng gợi ý, tile đủ thông tin, xoá có Hoàn tác

- Tile cũ chỉ hiện quy tắc lặp; `nextTrigger` và `amountHint` có trong model mà
  ẩn. Giờ: `Lần tới: Thứ 5, 5/9 · 20:00 · ~300.000 ₫`, tắt thì `Đã tắt · <lịch>`.
- Chip **"Ghi ngay"** → `showAddTransactionSheet(preselectedCategoryId:,
  prefillNote:, prefillAmount:)`.
- **Preset + habit gộp 1 hàng chip** (trước là chip strip + list card = 2 hình
  dạng cho cùng một việc). Habit dùng `SpendoChip(selected: true)` + icon
  sparkles + `onDeleted` để bỏ qua.
- **Xoá = vuốt trái + Hoàn tác** — trước là nơi duy nhất trong app xoá ngay
  không hỏi, không undo.
- Tiêu đề màn đổi `Nhắc chi tiêu định kỳ` → **`Nhắc nhở`**, khớp mọi lối vào.
- `_DebugPanel` (~310 dòng, chỉ `kDebugMode`) tách ra
  `widgets/debug_reminder_panel.dart`. Sửa luôn `id.substring(0, 8)` ném lỗi khi
  id ngắn hơn 8 ký tự.

### 2.25 Phase 5 — Form nhắc nhở: numpad + `warnBeforeHours` có UI

- Số tiền gợi ý chuyển từ keyboard hệ thống (không format nghìn) sang
  **`SpendoNumpad`**; tap ô số mới hiện numpad, nên numpad và keyboard không
  chồng nhau.
- **`WarnBefore`** (Tắt | 6 giờ | 1 ngày | 2 ngày) — model có
  `warnBeforeHours`, preset có `defaultWarnBeforeHours`, nhưng form **không có
  UI** nên giá trị preset bị bỏ. `WarnBefore.nearest(hours)` làm tròn xuống.
- Tần suất + thứ trong tuần + nhắc trước đều dùng `SpendoSegmented` (trước là 4
  kiểu chọn khác nhau trong 1 form).
- Ngày trong tháng: `_DayOfMonthSheet` lưới 1–28 thay `DropdownButtonFormField`.
- Có dòng đọc lại bằng tiếng Việt ("Nhắc … ngày 5 hàng tháng lúc 20:00, báo
  trước 6 giờ").
- `showReminderFormSheet(...)` là lối mở duy nhất (kể cả chip "Lặp lại" ở sheet
  Thêm giao dịch).

### 2.26 Phase 5 — form khoản vay: nút Lưu bám cả tên lẫn số

`17-loan-form-sheet.md` §L: nút disable theo `_titleCtrl` nhưng **không
addListener** → gõ tên xong nút vẫn xám.

- `_titleCtrl.addListener` + nút Lưu bọc `ListenableBuilder(_amountCtrl)`.
- Tên rỗng → lỗi inline (trước return im lặng).
- **Ngày bắt đầu chọn được** (trước cố định lúc tạo).
- `showDatePicker(firstDate: now)` cũ **ném lỗi** khi sửa loan có hạn quá khứ
  (`initialDate < firstDate`) → `firstDate` lùi về `now.year - 10`.

### 2.27 Phase 6 — Cài đặt là HUB, mỗi nhóm một trang có route

Màn cũ 1366 dòng, 9 nhóm không liên quan trong 1 list phẳng ~2000px, không có
điều hướng cấp 2 (`20-settings.md` §L).

Giờ là hub 3 card — **DỮ LIỆU / KẾT NỐI / ỨNG DỤNG** — 9 dòng, mỗi dòng 1
trang. Route mới:

| Route | Màn | Thay cho |
|---|---|---|
| `/settings/categories` | 14 | expansion tile cuối trang |
| `/settings/appearance` | 20 | 3 ListTile + `_VisualModeSheet` + `_ThemeColorSheet` |
| `/settings/backup` | 21 | 3 section (Drive / JSON / CSV) |
| `/settings/bank` | 22 | `SepayConnectionSection` |
| `/settings/widget` | 23 | `WidgetPinSection` |
| `/settings/notifications` | — | section Thông báo |

`Nguồn tiền` / `Khoản vay` / `Nhắc nhở` trỏ vào route đã có (`/wallets`,
`/loans`, `/reminders`) — hub không dựng lại màn nào.

**Xoá hẳn:** `gdrive_backup_section.dart` · `sepay_connection_section.dart` ·
`widget_pin_section.dart` (nội dung viết lại trong trang tương ứng).

⚠️ Mỗi dòng hub hiện **số đếm lấy từ đúng provider trang đích dùng** — đừng
đếm lại bằng query riêng, sẽ lệch.

Có test khoá: hub vừa 1 màn 360×640 (kể cả footer), và **mọi dòng điều hướng
đúng route** (`settings_screen_test.dart`).

### 2.28 Phase 6 — `CategoryRepository` thêm `reorder()` + `restore()`

Cột `sort_order` đã có trong DB nhưng **chỉ được ghi lúc tạo** → lưới danh mục
ở sheet Thêm giao dịch kẹt theo thứ tự chèn.

- `reorder(orderedIds)` — ghi lại `sort_order` 1 transaction, gọi từ
  `ReorderableListView` ở trang Danh mục (user duyệt phương án này).
- `restore(category)` — chèn lại **đúng id + sortOrder**, backing cho Hoàn tác.
  `add()` sinh `uuid()` mới nên không dùng để khôi phục được.
- `watchTransactionCounts()` + `categoryTransactionCountsProvider` — số giao
  dịch từng danh mục, hiện ngay trên dòng.

⚠️ **Vuốt xoá chỉ bật khi `!isDefault && count == 0`.** Danh mục còn giao dịch
bị repo chặn xoá; arm gesture rồi báo lỗi sau là để user vuốt hụt.

### 2.29 Phase 6 — Sao lưu: 1 pattern tiến trình inline

Luồng restore cũ xếp **3 dialog loading toàn màn không nền** + 2 dialog xác
nhận (`20-settings.md` §L). Trang `/settings/backup` giờ có **1 dải progress
inline** (`_ProgressStrip`) cho mọi thao tác dài, và preview khôi phục là
`SpendoSheet` chứ không phải `AlertDialog` text thuần.

Card trạng thái ở đầu trang trả lời "dữ liệu của tôi có an toàn không" bằng 3
trạng thái: chưa bật · đã kết nối nhưng chưa sao lưu · đã sao lưu (kèm thời
gian tương đối).

### 2.30 Phase 6 — tên 5 màu GIỮ tiếng Anh

`27-*.md` §L và mockup 20 đề xuất đổi sang tiếng Việt (Hồng / Chàm / Ngọc lục
/ Xám xanh / Hổ phách). **User chốt giữ nguyên** `Rose (Mặc định)` /
`Indigo Midnight` / … → `AppColorScheme.label` và
`test/core/theme/app_theme_test.dart` không đổi. Đây là chỗ mockup thua
HANDOFF-STATE, đừng "sửa lại cho khớp mockup".

### 2.31 Phase 6 — `SpendoSettingsRow` nhận subtitle / enabled / showChevron

Trang Sao lưu và Ngân hàng cần dòng 2 (`Toàn bộ dữ liệu, khôi phục được`,
`Đang đồng bộ`), cần làm mờ khi đang bận, và có dòng **hành động tại chỗ**
(toggle, chọn giá trị) không nên có chevron.

| Tham số | Mặc định | Dùng khi |
|---|---|---|
| `subtitle` / `subtitleColor` | null | dòng 2; màu riêng cho trạng thái đồng bộ |
| `enabled` | true | làm mờ + bỏ tap, **giữ nguyên chỗ** trong group |
| `showChevron` | `onTap != null` | đặt `false` cho hành động tại chỗ |

`minHeight` 49 → **52** cho vừa 2 dòng. `_DashedCircle` đổi tên thành
**`SpendoDashedCircle`** (public) vì hàng slot widget cần nó ở cỡ 32.

### 2.32 Phase 7 — `StartupGate` XOÁ, splash tự quyết đích đến

Gate cũ render `Scaffold` trắng + spinner giữa 2 màn đều có nền riêng → khởi
động ở dark mode chớp trắng (`02-startup-gate.md` §J).

`SplashScreen` giờ nhận **`nextScreenBuilder(context, onboardingCompleted)`**
thay `nextScreen`. Nó tự đọc cờ onboarding **song song với init**, nên tới lúc
fade là đã có câu trả lời — không còn frame trung gian nào.

- Key `onboardingCompletedPrefsKey` chuyển sang
  **`onboarding/presentation/onboarding_prefs.dart`** (splash và welcome dùng
  chung, không bên nào phải import bên kia).
- Đọc prefs lỗi → coi như chưa onboarding (xấu nhất là xem lại 2 trang welcome),
  **không** để user kẹt ở splash.
- Message tiến độ đổi sang tiếng Việt (`Đang mở dữ liệu…`…) — trước tiếng Anh
  giữa app thuần Việt (`01-splash.md` §L).

⚠️ Đừng dựng lại màn trung gian nào giữa splash và app.

### 2.33 Phase 7 — Welcome 2 trang, dots + Bỏ qua mọi nơi

Trang 0 cũ chỉ có 1 câu, nửa dưới trống; đồ hoạ và Drive mỗi thứ 1 trang
(`03-welcome.md` §L).

| Trang | Nội dung |
|---|---|
| 1 | Brand card + **3 dòng tính năng** (Ghi 5 giây · Hạn mức & nhắc nhở · Dữ liệu của bạn) |
| 2 | Đồ hoạ (2 card) + Google Drive (tuỳ chọn) — gộp 2 trang cũ |

- **Dots** ở cả 2 trang (trước không có, không biết còn mấy bước).
- **`Bỏ qua` ở mọi trang** (trước chỉ trang cuối), nút cuối ghi **`Bắt đầu`**
  thay `Tiếp theo`.
- `_finish()` **luôn lưu `visualModeProvider`** — kể cả khi thoát bằng Bỏ qua.
  Bản cũ chỉ lưu khi bấm Tiếp theo rời trang đó.
- Bỏ `GlassContainer` premium + `AuroraThemeBackground` chạy full ngay cả với
  user sắp chọn "Bình thường"; brand card giờ là `surfaceContainerLowest`
  alpha .82, đọc được trên aurora mà không cần glass layer.
- `WelcomeScreen({destinationBuilder})` — inject đích đến để test khỏi phải
  mount `SpendoApp` (nó chạm plugin notification, widget test không có binding).

**Xoá:** `shared/widgets/visual_mode_picker.dart` (+test) — Giao diện (Phase 6)
và Welcome đều có card riêng · `shared/widgets/category_icon.dart` (0 call-site,
`SpendoIconTile` đã thay).

### 2.34 Phase 7 — Widget: LUÔN 4 ô, không bỏ ghim, tap để đổi

**User chốt lệch mockup 23.** Mockup ghi "ghim bao nhiêu dùng bấy nhiêu, slot
trống hiện +"; phương án đang dùng là **4 ô luôn có danh mục, tap 1 ô để đổi
sang danh mục khác**. Trang Widget bỏ nút "Bỏ ghim".

Sửa luôn bug thật: Kotlin cũ `if (cats.size >= 4) cats else defaults` — **vứt
dữ liệu thật đi** dùng 4 tên hard-code khi có ít hơn 4 danh mục; và
`widget_sync.dart` tự fill cho đủ 4 nên lời hứa "ghim bao nhiêu dùng bấy nhiêu"
chưa từng đúng.

**`resolveWidgetSlots(pinnedIds, expenseCategories)`** trong
`core/utils/widget_sync.dart` là **định nghĩa duy nhất**, dùng chung cho sync và
cho preview ở trang Cài đặt → hai bên không thể lệch nhau:

- id đã ghim giữ đúng slot; id không còn tồn tại → rơi xuống fallback
- fallback lấy danh mục **chưa dùng** theo thứ tự, không lặp
- ít hơn 4 danh mục → slot thừa để `null`, **giữ nguyên vị trí** (lưới 2×2 là
  positional), widget vẽ `+` / `Ghi nhanh` và mở `/add` không kèm danh mục

Có 8 test khoá ở `test/core/utils/widget_slots_test.dart`.

### 2.35 Phase 7 — màu native ra `values/` + `values-night/`

2 widget và launch screen hard-code màu sáng (`#FFFFFF`, `#F06292`, `#666666`,
`#FFF0F5`) → đặt widget lên home screen nền tối thì chói.

Giờ mọi màu native đi qua `@color/...`, khai báo 2 bộ:
`android/app/src/main/res/values/colors.xml` (light) và `values-night/`
(dark, theo quy tắc §01-tokens: brand giữ hue + `#551D30` đè lên, primary sáng
lên `#E9A4B5`, phân tầng bằng surface chứ không bằng shadow).

⚠️ Sửa màu widget thì sửa **cả hai file**, đừng nhét hex vào layout/drawable —
`grep -roE '#[0-9A-Fa-f]{6,8}' res/layout res/drawable` phải ra **0**.

`launch_bg_*` **không** override trong `values-night/`: `values-night/styles.xml`
đã tự trỏ vào `launch_bg_dark` rồi.

### 2.36 Phase 7 — bug: `VisualModeNotifier._load()` đè lên `setMode()`

Phát hiện khi viết test Welcome. `_load()` đọc prefs **bất đồng bộ** rồi gán
`state`; nếu user chọn đồ hoạ trong vài khoảnh khắc đầu sau khi mở app (đúng
kịch bản trang Welcome), lựa chọn bị **âm thầm revert** khi `_load()` xong.

Thêm cờ `_chosen`: `_load()` bỏ qua nếu user đã chọn rồi (và nếu notifier đã
dispose). Test khoá ở `test/core/theme/visual_mode_provider_test.dart`.

⚠️ Notifier nào vừa `_load()` async vừa có setter đều dính kiểu bug này — kiểm
lại nếu thêm cái mới.

### 2.37 Phase 7 — dark pass là TEST, không phải rà tay

`test/core/theme/dark_mode_pass_test.dart` render **8 màn × 2 theme** (bắt
exception + tràn layout) và khoá quy tắc token: surface dark là nâu ấm chứ
không đen thuần; brand dùng chung 2 theme, còn primary / income / expense phải
khác nhau.

Bộ component chung (Phase 1) **đã** tôn trọng quy tắc "dark không bóng"
(`SpendoFab` bỏ shadow khi dark) và alpha tile 0.16→0.24, nên phase này không
phải sửa gì ở đó. Mấy `BoxShadow` còn lại là **vòng chọn** (swatch màu), không
phải shadow tạo độ sâu — giữ nguyên.

### 2.5 Phase 2 — `shellTabProvider` thay `setState` trong AppShell

Nút "Xem tất cả" ở Home phải chuyển sang **tab** Giao dịch, không push route
thứ hai. Tab index của `AppShell` giờ nằm ở
`lib/shared/providers/shell_tab_provider.dart` (`ShellTab` enum + StateProvider)
thay vì state nội bộ.

Phase 5 dùng lại chỗ này cho "legend tap → tab Giao dịch đã lọc".

### 2.6 Phase 2 — sửa 2 file ngoài phạm vi màn

Cần thiết để đạt tiêu chí nghiệm thu, không đụng logic:

- `TransactionRepository.update()` giờ lưu cả `created_at` (trước không lưu) —
  để chip ngày trong sheet có nghĩa khi **sửa** giao dịch. Phase 3 (màn Chi
  tiết, "Ngày sửa được") dùng lại.
- `ReminderFormSheet` nhận thêm `prefillTitle` / `prefillAmount` — cho chip
  "Lặp lại" mở form đã điền sẵn theo giao dịch đang nhập.

### 2.7 Phase 2 — `Numpad` thành alias mỏng của `SpendoNumpad`

`numpad.dart` cũ là wrapper 1 dòng gọi `SpendoNumpad`, để màn chưa tới lượt có
bàn phím theo token ngay. Phase 4 dọn 3/5 call-site, Phase 5 dọn 2 cái cuối
(loan). **File đã xoá** — dùng thẳng `SpendoNumpad`.

### 2.8 `AppTheme.incomeColor/expenseColor/expenseAltColor` — ĐÃ XOÁ ở Phase 6

Phase 0 giữ 3 hằng static này (đã trỏ sang giá trị token mới) vì có **53
call-site / 16 file** dùng chúng ngoài widget tree. Cách đúng là
`context.spendo.income` / `.expense` (resolve được cả dark mode).

**Việc còn tồn:** mỗi phase 2–6 khi động vào màn nào thì chuyển call-site của
màn đó sang `context.spendo`. Phase 7 quét nốt phần còn lại rồi xoá 3 hằng.

**✅ ĐÃ TRẢ XONG ở Phase 6.** 3 file cuối (`settings_screen`,
`gdrive_backup_section`, `sepay_connection_section`) đều được viết lại hoặc
xoá, nên 14 call-site cuối biến mất cùng lúc.

**3 hằng `AppTheme.incomeColor/expenseColor/expenseAltColor` đã xoá khỏi
`app_theme.dart`.** Dùng `context.spendo.income` / `.expense`; màu hành động
phá huỷ dùng `cs.error` / `cs.errorContainer`. Đừng thêm lại hằng màu tĩnh —
chúng chỉ đúng ở light mode.

---

## 3. Cái gì đã có sẵn để dùng (đừng dựng lại)

### 3.1 Token

| Thứ | Ở đâu | Dùng thế nào |
|---|---|---|
| ColorScheme light/dark tường minh | `lib/core/theme/app_theme.dart` | `Theme.of(context).colorScheme` |
| brand / onBrand / income / expense / warning / dashedOutline | `lib/core/theme/spendo_colors.dart` | `context.spendo.income` |
| Thang chữ + `tnum` | `lib/core/theme/app_typography.dart` | `Theme.of(context).textTheme.*` |
| Bo góc | `AppTheme.radiusCard/CardFeature/Sheet/Input/Pill` | |

### 3.2 Component dùng chung — `lib/shared/widgets/spendo/`

Import 1 dòng: `import '<...>/shared/widgets/spendo/spendo.dart';`

`SpendoButton` (primary/secondary/outline) · `SpendoChip` (filter/suggestion/
meta) · `SpendoSegmented` (Chi|Thu) · `SpendoCard` · `SpendoSectionHeader` ·
`SpendoEmptyState` · `SpendoProgressBar` (tự đổi màu 85%/vượt) ·
`SpendoSearchBar` · `SpendoSheet` + `SpendoSheetHeader` + `SpendoDragHandle` ·
`SpendoNumpad` · `SpendoIconTile` / `SpendoCategoryTile` (có biến thể
`.add` nét đứt) · `SpendoTransactionRow` / `SpendoDayHeader` ·
`SpendoSettingsGroup` / `SpendoSettingsRow` · `SpendoBottomNav` · `SpendoFab` /
`SpendoExtendedFab` · `DottedBorderBox` (viền nét đứt bo góc — CTA hạn mức,
ô "+" thêm ví) · `SpendoScreenHeader` / `SpendoHeaderIconButton` /
`SpendoPeriodStepper` (hàng tiêu đề màn push — mục 2.15) ·
`SpendoDashedCircle` (vòng nét đứt, mục 2.31).

> Phase 2–6 đã lắp bộ này vào **toàn bộ 24 màn** trong phạm vi. Phase 7 chỉ còn
> Splash + Welcome; thấy màn nào còn tự vẽ drag-handle / chip / empty state /
> AppBar → thay.

### 3.4 Thứ khác Phase 2 dựng, phase sau dùng lại

| Thứ | Ở đâu | Dùng khi |
|---|---|---|
| `shellTabProvider` / `ShellTab` | `lib/shared/providers/shell_tab_provider.dart` | cần chuyển **tab** thay vì push route (mục 2.5) |
| ~~`showBudgetTypeSheet`~~ | — | **đã xoá ở Phase 4** → `context.push('/budget')` (mục 2.11) |
| `loadNoteHistory` / `mergeNoteSuggestions` / `kDefaultNotes` | `transactions/domain/note_suggestions.dart` | gợi ý ghi chú (sheet Thêm + màn 02b dùng chung) |
| `SpendoSheet.showModal` | `spendo_sheet.dart` | mở bottom sheet đã có token sẵn |
| `Period` / `PeriodPreset` | `shared/domain/period.dart` | mọi chỗ cần khoảng thời gian (mục 2.4b) |
| `PeriodPickerSheet.show()` | `shared/widgets/spendo/` | chọn kỳ — 1 picker cho 4 màn |
| `deleteTransactionWithUndo` | `transactions/…/widgets/` | xoá + Hoàn tác (mục 2.4c) |
| `TransactionFilter` | `transactions/domain/` | lọc danh sách giao dịch (mục 2.4d) |
| `SpendoSegmented(height:, horizontalPadding:)` | `spendo_chip.dart` | segmented gọn khi hàng chật |
| `GroupedTransactionSliver(dismissible: true)` | `transactions/…/widgets/` | bật vuốt-xoá cho list |
| `SpendoScreenHeader` / `SpendoPeriodStepper` | `shared/widgets/spendo/` | hàng tiêu đề màn push (mục 2.15) |
| `walletTypeIcon(type)` | `core/utils/wallet_icons.dart` | icon loại ví (mục 2.14) |
| `showWalletFormSheet(context, existing:)` | `wallets/…/widgets/` | mở form ví — 1 nơi duy nhất |
| `SetBudgetSheet.show(...)` | `budget/…/widgets/` | sheet numpad nhập hạn mức (tháng + danh mục) |
| `budgetPeriodProvider` + họ | `budget/…/providers/budget_page_provider.dart` | kỳ + số liệu của trang `/budget` (mục 2.12) |
| `showAddTransactionSheet(preselectedWalletId:)` | `transactions/…/widgets/` | thêm giao dịch vào 1 ví cụ thể (mục 2.16) |
| `formatVND(x, withSymbol: false)` | `core/utils/currency_formatter.dart` | bỏ ₫ khi 1 hàng có nhiều số (mục 2.19) |
| `StatsSide` / `statsPeriodProvider` / `statsByCategoryProvider` | `stats/…/providers/` | Chi\|Thu + kỳ của Thống kê (mục 2.17) |
| `paidByLoanProvider` + `remainingOf(loan, paid)` | `loan/…/providers/` | số còn lại của khoản vay (mục 2.20) |
| `loanStatusLabel(loan)` | `loan/…/screens/loan_list_screen.dart` | `Quá hạn` / `Còn N ngày` — list + detail dùng chung |
| `showAddPaymentSheet(context, loan:, remaining:)` | `loan/…/widgets/` | ghi nhận thanh toán (mục 2.23) |
| `showLoanFormSheet(context, existing:, initialType:)` | `loan/…/widgets/` | mở form khoản vay — 1 nơi duy nhất |
| `showReminderFormSheet(context, ...)` | `reminders/…/widgets/` | mở form nhắc nhở — 1 nơi duy nhất (mục 2.25) |
| `WarnBefore` | `reminders/…/widgets/reminder_form_sheet.dart` | mức nhắc trước (mục 2.25) |
| `showCategoryFormSheet(context, existing:, isIncome:)` | `categories/…/widgets/` | mở form danh mục — 1 nơi duy nhất |
| `deleteCategoryWithUndo(context, ref, cat)` | `categories/…/screens/categories_screen.dart` | xoá danh mục + Hoàn tác |
| `categoryTransactionCountsProvider` | `categories/…/providers/` | số giao dịch từng danh mục (mục 2.28) |
| `CategoryRepository.reorder / restore` | `categories/data/` | đổi thứ tự · khôi phục sau xoá (mục 2.28) |
| `showSepayMappingSheet(context)` | `settings/…/widgets/` | form liên kết tài khoản SePay (mục 2.27) |
| `SpendoSettingsRow(subtitle:, enabled:, showChevron:)` | `spendo_tiles.dart` | dòng cài đặt 2 dòng / bận / hành động tại chỗ (mục 2.31) |
| `SpendoDashedCircle` | `spendo_tiles.dart` | vòng nét đứt cỡ tuỳ ý (mục 2.31) |

### 3.3 Motion — giữ nguyên, chỉ đổi màu

`lib/shared/widgets/motion/`: `appMotion` (instance, **không** phải static),
`PressableScale`, `AnimatedMoneyText`, `AnimatedProgressBar`, `MotionListItem`,
`SkeletonBlock`. Dùng `appMotion.whenMotionAllowed(context, appMotion.xxx)` để
tôn trọng reduce-motion.

---

## 4. Nợ kỹ thuật còn lại (phần lớn thuộc Phase 7)

Redesign đã xong; bảng dưới là những gì **cố ý để lại**, không phải việc dở.

| Việc | Trạng thái |
|---|---|
| ~~Hex hard-code ngoài `core/theme/`~~ | ✅ **0** (từ 55) — hết ở Phase 6 |
| ~~`AppTheme.incomeColor/…` → `context.spendo`~~ | ✅ **0** (từ 53/16) — 3 hằng đã xoá, mục 2.8 |
| ~~Hex trong `res/layout` + `res/drawable`~~ | ✅ **0** — ra `values/` + `values-night/` (mục 2.35) |
| `Colors.white` cố định | **6** chỗ / 2 file (từ ~100) — **cố ý giữ**: highlight trên logo splash + shimmer progress + gloss aurora. Đều là lớp phủ trắng thật và **đã** đổi alpha theo `isDark`; thay bằng token là sai nghĩa. |
| ~~`numpad.dart` · `month_selector.dart` · `typedef StatsDateRange`~~ | ✅ xoá ở Phase 4–5 |
| ~~`visual_mode_picker.dart` · `category_icon.dart`~~ | ✅ xoá ở Phase 7 (mục 2.33) |
| ~~Splash / Welcome redesign~~ | ✅ Phase 7 (mục 2.32, 2.33) |
| ~~2 widget Android native~~ | ✅ Phase 7 (mục 2.34, 2.35) |
| Route `/stats` `/settings` trùng tab của shell | **còn lại** — hub push `/wallets` `/loans` `/reminders` ra ngoài shell (mất bottom nav ở màn con). Đổi sang `StatefulShellRoute` là việc riêng, không thuộc redesign. |
| `debug_reminder_panel` (~310 dòng) | chỉ `kDebugMode`, không ship. Đã chuyển sang token ở Phase 7. |

---

## 4b. Phase 2 đã đụng file nào

**Thêm:** `home/…/widgets/home_balance_header.dart`, `home_budget_card.dart`,
`home_shortcuts.dart`, `home_wallet_strip.dart` ·
`transactions/domain/note_suggestions.dart` ·
`shared/providers/shell_tab_provider.dart`

**Viết lại:** `home/…/screens/home_screen.dart` ·
`transactions/…/widgets/add_transaction_sheet.dart` ·
`transactions/…/screens/note_picker_screen.dart` ·
`transactions/…/widgets/transaction_list_item.dart`

**Sửa:** `app_router.dart` (bỏ `/features`) · `app_bottom_nav.dart` (dùng
`shellTabProvider`) · `spendo_tiles.dart` (thêm `DottedBorderBox`, sửa tràn ở
`SpendoTransactionRow` + `SpendoDayHeader`) · `grouped_transaction_sliver.dart` ·
`budget_type_sheet.dart` (thêm `showBudgetTypeSheet`) · `reminder_form_sheet.dart`
(2 tham số prefill) · `transaction_repository.dart` (`update` lưu `created_at`) ·
`numpad.dart` (thành alias)

**Xoá:** `all_features_screen.dart` · `summary_card.dart` · `feature_grid.dart` ·
`home_feature_actions.dart` · `wallet_card_home.dart` (+ test carousel của nó —
hành vi carousel đã bị thay)

---

## 4c. Phase 3 đã đụng file nào

**Thêm:** `shared/domain/period.dart` ·
`shared/widgets/spendo/period_picker_sheet.dart` ·
`transactions/domain/transaction_filter.dart` ·
`transactions/…/widgets/delete_transaction_action.dart` ·
`transactions/…/widgets/transaction_filter_sheet.dart`

**Viết lại:** `transactions/…/screens/transactions_screen.dart` ·
`transactions/…/widgets/transaction_detail_sheet.dart` ·
`transactions/…/providers/transaction_provider.dart` ·
`stats/…/widgets/stats_time_selector.dart`

**Sửa:** `home_screen.dart` + `month_selector.dart` (dùng `PeriodPickerSheet`) ·
`stats_provider.dart` (dùng `Period` + alias) · `grouped_transaction_sliver.dart`
(thêm `dismissible`) · `transaction_list_item.dart` · `spendo_chip.dart`
(`SpendoSegmented` nhận height/padding) · `transaction_repository.dart`
(thêm `restore`)

**Xoá:** `month_picker_sheet.dart` · `stats/…/widgets/date_range_picker_sheet.dart`

---

## 4d. Phase 4 đã đụng file nào

**Thêm:** `core/utils/wallet_icons.dart` ·
`shared/widgets/spendo/spendo_screen_header.dart` ·
`budget/…/providers/budget_page_provider.dart` ·
`budget/…/widgets/set_budget_sheet.dart`

**Viết lại:** `wallets/…/screens/wallets_screen.dart` ·
`wallets/…/screens/wallet_detail_screen.dart` ·
`wallets/…/widgets/wallet_form_sheet.dart` (thêm `showWalletFormSheet`) ·
`budget/…/screens/budget_screen.dart` (sheet → trang)

**Sửa:** `app_router.dart` (thêm `/budget`) · `home_shortcuts.dart` +
`home_budget_card.dart` (push `/budget` thay sheet) · `home_wallet_strip.dart`
(dùng `showWalletFormSheet`) · `add_transaction_sheet.dart`
(`preselectedWalletId`) · `spendo.dart` (export header) ·
`integration_test/screenshot_test.dart` (2 bước sheet → 1 bước `/budget`)

**Xoá:** `budget/…/widgets/budget_type_sheet.dart` ·
`budget/…/screens/category_budget_screen.dart` ·
`home/…/widgets/month_selector.dart`

**Test mới:** `test/core/utils/wallet_icons_test.dart` ·
`test/features/wallets/…/wallets_screen_test.dart` ·
`…/wallet_detail_screen_test.dart` · `…/wallet_form_sheet_test.dart` ·
`test/features/budget/…/budget_screen_test.dart` (131 → 150 test)

---

## 4e. Phase 5 đã đụng file nào

Làm 2 commit: `eb30303` (Thống kê) + `583d7d0` (Vay + Nhắc nhở).

**Thêm:** `loan/…/widgets/add_payment_sheet.dart` ·
`reminders/…/widgets/debug_reminder_panel.dart`

**Viết lại:** `stats/…/screens/stats_screen.dart` ·
`stats/…/providers/stats_provider.dart` ·
`loan/…/screens/loan_list_screen.dart` · `loan/…/screens/loan_detail_screen.dart` ·
`loan/…/widgets/loan_form_sheet.dart` ·
`reminders/…/screens/reminders_screen.dart` ·
`reminders/…/widgets/reminder_form_sheet.dart`

**Sửa:** `app_router.dart` (thêm `/loans/:id`) ·
`core/utils/currency_formatter.dart` (`withSymbol`) ·
`loan/data/loan_repository.dart` (`watchPaidByLoan`) ·
`loan/…/providers/loan_provider.dart` (`LoanFilter`, `paidByLoanProvider`,
`remainingOf`) · `add_transaction_sheet.dart` (gọi `showReminderFormSheet`)

**Xoá:** `stats/…/widgets/stats_time_selector.dart` ·
`transactions/…/widgets/numpad.dart`

**Test mới:** `stats_screen_test.dart` (viết lại, 6 test) ·
`loan_list_screen_test.dart` · `loan_detail_screen_test.dart` ·
`loan_form_sheet_test.dart` (viết lại) · `reminders_screen_test.dart` ·
`reminder_form_sheet_test.dart` (+2) — 150 → 177 test

## 4f. Phase 6 đã đụng file nào

1 commit: `da955a9`.

**Thêm:** `categories/…/screens/categories_screen.dart` ·
`settings/…/screens/appearance_screen.dart` · `…/backup_screen.dart` ·
`…/bank_screen.dart` · `…/widget_screen.dart` · `…/notifications_screen.dart` ·
`settings/…/widgets/sepay_mapping_sheet.dart`

**Viết lại:** `settings/…/screens/settings_screen.dart` (1366 → ~250 dòng) ·
`categories/…/widgets/category_form_sheet.dart`

**Sửa:** `app_router.dart` (6 route `/settings/*`) ·
`categories/data/category_repository.dart` (`reorder`, `restore`,
`watchTransactionCounts`) · `categories/…/providers/category_provider.dart`
(`categoryTransactionCountsProvider`) · `shared/widgets/spendo/spendo_tiles.dart`
(`SpendoSettingsRow` +subtitle/enabled/showChevron, `SpendoDashedCircle` public) ·
`core/theme/app_theme.dart` (xoá 3 hằng màu) ·
`integration_test/screenshot_test.dart` (bước 19 cuộn → 4 bước mở trang con)

**Xoá:** `settings/…/widgets/gdrive_backup_section.dart` ·
`…/sepay_connection_section.dart` · `…/widget_pin_section.dart`

**Test mới:** `settings_screen_test.dart` (viết lại, 3 test) ·
`appearance_screen_test.dart` · `backup_screen_test.dart` ·
`bank_screen_test.dart` · `widget_screen_test.dart` ·
`categories_screen_test.dart` · `category_form_sheet_test.dart`
— 177 → **207 test**

---

## 4g. Phase 7 đã đụng file nào

1 commit: `adf1bf1`.

**Thêm:** `onboarding/presentation/onboarding_prefs.dart`

**Viết lại:** `onboarding/presentation/welcome_screen.dart` (3 trang → 2)

**Sửa:** `shared/widgets/splash_screen.dart` (`nextScreenBuilder`, đọc cờ
onboarding, message tiếng Việt) · `main.dart` (bỏ gate, message tiếng Việt) ·
`core/utils/widget_sync.dart` (`resolveWidgetSlots`) ·
`core/theme/visual_mode_provider.dart` (cờ `_chosen`, mục 2.36) ·
`settings/…/screens/widget_screen.dart` (4 ô luôn đầy, bỏ "Bỏ ghim") ·
`reminders/…/widgets/debug_reminder_panel.dart` (sang token) ·
`SpendoWidgetMedium.kt` (nhận 1–4 slot) · 2 `widget_layout_*.xml` +
3 `drawable/widget_*.xml` (dùng `@color/`) · `values/colors.xml` +
`values-night/colors.xml`

**Xoá:** `onboarding/presentation/startup_gate.dart` ·
`shared/widgets/visual_mode_picker.dart` (+test) ·
`shared/widgets/category_icon.dart`

**Test mới:** `test/core/theme/dark_mode_pass_test.dart` (18 test — 8 màn × 2
theme + quy tắc token) · `test/core/theme/visual_mode_provider_test.dart` ·
`test/core/utils/widget_slots_test.dart` (8 test) ·
`test/features/onboarding/…/welcome_screen_test.dart` ·
`splash_screen_test.dart` (+3) · `widget_screen_test.dart` (viết lại)
— 207 → **244 test**

---

## 5. Quy trình mỗi phase

1. Đọc mục phase đó trong `04-phases.md` → biết làm màn nào, lưu ý gì.
2. Với **mỗi màn**: đọc audit AS-IS tương ứng **trước khi sửa**, rồi mở mockup
   + ảnh (xem mục 0 để biết file nào).
3. Dựng lại bằng component + token đã có (mục 3). Màn nào động tới thì tiện tay
   chuyển `AppTheme.incomeColor/…` của màn đó sang `context.spendo` (mục 2.4).
4. Xong: `flutter analyze` → `flutter test` → `flutter build apk --debug`.
   Cả ba phải sạch mới tính là xong.
5. Tự kiểm mục "Nghiệm thu" của phase trong `04-phases.md`, liệt kê file đã sửa.
6. **Commit** (mỗi phase / giai đoạn nhỏ 1 commit, giữ `git status` sạch).
7. **Cập nhật file này**: bảng tiến độ mục 1 (trạng thái + hash commit), baseline
   số test, và mục 2 nếu phát sinh quyết định mới lệch spec. Rồi dừng chờ duyệt.

Làm đúng 1 phase mỗi lượt, không lấn phase sau. Điều gì không rõ → hỏi, kèm
phương án đề xuất.

> **Hết phase rồi.** Quy trình trên giữ lại cho việc sau: sửa/thêm màn thì vẫn
> đọc mục 2 trước, dùng component ở mục 3, và chạy đủ `analyze` → `test` →
> `build apk` trước khi commit. Nợ cố ý còn lại nằm ở mục 4.

Ưu tiên khi mâu thuẫn: **HANDOFF-STATE (mục 2) > tokens > mockup > audit**.
(Audit là AS-IS — mô tả cái đang có, không phải cái cần làm.)

---

## 6. Lệnh hay dùng

```bash
flutter analyze
flutter test
flutter build apk --debug

# kiểm không còn Material Icons (phải ra 0)
grep -rhoE "(^|[^a-zA-Z])Icons\.[a-zA-Z_]+" lib/ | wc -l

# kiểm hex rải rác ngoài theme
grep -rE "0xFF[0-9A-Fa-f]{6}" lib/ --include=*.dart | grep -v "^lib/core/theme/"
```
