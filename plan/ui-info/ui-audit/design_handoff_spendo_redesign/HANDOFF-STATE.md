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
| 4 — Ví & Hạn mức | ⬜ tiếp theo | |
| 5 — Thống kê, Vay, Nhắc nhở | ⬜ | |
| 6 — Cài đặt & trang con | ⬜ | |
| 7 — Khởi động + Dark pass + QA | ⬜ | |

Baseline hiện tại: `flutter analyze` sạch · **131 test pass** · debug APK build được.

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

`month_selector.dart` **vẫn còn** — chỉ Chi tiết ví (Phase 4) dùng; Phase 4
thay nốt rồi xoá file.

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

Phase 4–6 còn 3 bản chip riêng phải thay khi động tới màn:
`loan_detail_screen.dart:_MetaChip` · `settings_screen.dart:_TabChip` ·
`wallet_detail_screen.dart:_FilterChip`.

### 2.10 `SpendoSheet.showModal` tự bọc nền

`showModal` đặt `backgroundColor: Colors.transparent` vì `SpendoSheet` tự vẽ
nền bo góc. Hệ quả: truyền vào widget **không phải** `SpendoSheet` → sheet
trong suốt, nhìn xuyên xuống sheet phía dưới (đúng lỗi `ReminderFormSheet` khi
bấm "Lặp lại").

`showModal` giờ tự bọc `_SheetSurface` cho content chưa phải `SpendoSheet` →
màn chưa tới lượt redesign vẫn có nền đúng. Khi tới lượt thì dựng hẳn trên
`SpendoSheet` để có luôn drag handle + padding bàn phím.

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

`numpad.dart` cũ còn **5 màn** dùng (budget ×2, loan ×2, wallet form) thuộc
Phase 4–5. Không xoá; đổi thành wrapper 1 dòng gọi `SpendoNumpad`, nên 5 màn đó
có bàn phím theo token ngay mà không phải redesign sớm. Phase 4–5 khi động vào
thì đổi call-site sang `SpendoNumpad` rồi xoá file.

### 2.8 `AppTheme.incomeColor/expenseColor/expenseAltColor` — còn nợ

Phase 0 giữ 3 hằng static này (đã trỏ sang giá trị token mới) vì có **53
call-site / 16 file** dùng chúng ngoài widget tree. Cách đúng là
`context.spendo.income` / `.expense` (resolve được cả dark mode).

**Việc còn tồn:** mỗi phase 2–6 khi động vào màn nào thì chuyển call-site của
màn đó sang `context.spendo`. Phase 7 quét nốt phần còn lại rồi xoá 3 hằng.

Sau Phase 3: **39 chỗ / 9 file** (từ 53/16). Các file còn lại đều thuộc màn
của Phase 4–6.

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
ô "+" thêm ví).

> Phase 2 đã lắp bộ này vào màn 01/02/02b. Phase 3–6 làm tương tự cho màn của
> mình: thấy màn nào còn tự vẽ drag-handle / chip / empty state → thay.

### 3.4 Thứ khác Phase 2 dựng, phase sau dùng lại

| Thứ | Ở đâu | Dùng khi |
|---|---|---|
| `shellTabProvider` / `ShellTab` | `lib/shared/providers/shell_tab_provider.dart` | cần chuyển **tab** thay vì push route (mục 2.5) |
| `showBudgetTypeSheet(context)` | `budget/…/widgets/budget_type_sheet.dart` | mở sheet hạn mức — 1 nơi duy nhất |
| `loadNoteHistory` / `mergeNoteSuggestions` / `kDefaultNotes` | `transactions/domain/note_suggestions.dart` | gợi ý ghi chú (sheet Thêm + màn 02b dùng chung) |
| `SpendoSheet.showModal` | `spendo_sheet.dart` | mở bottom sheet đã có token sẵn |
| `Period` / `PeriodPreset` | `shared/domain/period.dart` | mọi chỗ cần khoảng thời gian (mục 2.4b) |
| `PeriodPickerSheet.show()` | `shared/widgets/spendo/` | chọn kỳ — 1 picker cho 4 màn |
| `deleteTransactionWithUndo` | `transactions/…/widgets/` | xoá + Hoàn tác (mục 2.4c) |
| `TransactionFilter` | `transactions/domain/` | lọc danh sách giao dịch (mục 2.4d) |
| `SpendoSegmented(height:, horizontalPadding:)` | `spendo_chip.dart` | segmented gọn khi hàng chật |
| `GroupedTransactionSliver(dismissible: true)` | `transactions/…/widgets/` | bật vuốt-xoá cho list |

### 3.3 Motion — giữ nguyên, chỉ đổi màu

`lib/shared/widgets/motion/`: `appMotion` (instance, **không** phải static),
`PressableScale`, `AnimatedMoneyText`, `AnimatedProgressBar`, `MotionListItem`,
`SkeletonBlock`. Dùng `appMotion.whenMotionAllowed(context, appMotion.xxx)` để
tôn trọng reduce-motion.

---

## 4. Nợ kỹ thuật còn lại (phần lớn thuộc Phase 7)

| Việc | Quy mô hiện tại |
|---|---|
| Hex hard-code ngoài `core/theme/` | **25** chỗ (từ 55 — `home_feature_actions.dart` đã xoá ở Phase 2) |
| `Colors.white/grey/red/orange/…` cố định (không đổi theo dark) | ~100 chỗ |
| `AppTheme.incomeColor/…` → `context.spendo` | **45** chỗ / 11 file (từ 53/16) |
| `numpad.dart` (alias) → gọi thẳng `SpendoNumpad` rồi xoá | 5 call-site, Phase 4–5 (mục 2.7) |
| `month_selector.dart` → xoá | còn **1** call-site (Chi tiết ví), Phase 4 |
| `typedef StatsDateRange = Period` → dùng thẳng `Period` rồi xoá alias | Phase 5 (mục 2.4b) |
| Splash | Phase 0 mới đổi màu sang token; redesign thật ở Phase 7 |
| 2 widget Android native `widget_layout_*.xml` | chưa đổi màu — Phase 7 |
| Route `/stats` `/settings` trùng tab của shell | rà khi Phase 6 làm Cài đặt (`/features` + AllFeatures đã xoá ở Phase 2) |

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
