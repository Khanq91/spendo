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
| 2 — Home + Add (màn 01, 02, 02b) | ⬜ tiếp theo | |
| 3 — Giao dịch & PeriodPicker | ⬜ | |
| 4 — Ví & Hạn mức | ⬜ | |
| 5 — Thống kê, Vay, Nhắc nhở | ⬜ | |
| 6 — Cài đặt & trang con | ⬜ | |
| 7 — Khởi động + Dark pass + QA | ⬜ | |

Baseline hiện tại: `flutter analyze` sạch · **63 test pass** · debug APK build được.

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

### 2.4 `AppTheme.incomeColor/expenseColor/expenseAltColor` — còn nợ

Phase 0 giữ 3 hằng static này (đã trỏ sang giá trị token mới) vì có **53
call-site / 16 file** dùng chúng ngoài widget tree. Cách đúng là
`context.spendo.income` / `.expense` (resolve được cả dark mode).

**Việc còn tồn:** mỗi phase 2–6 khi động vào màn nào thì chuyển call-site của
màn đó sang `context.spendo`. Phase 7 quét nốt phần còn lại rồi xoá 3 hằng.

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
`SpendoExtendedFab`.

> ⚠️ **Component đã dựng nhưng CHƯA lắp vào màn nào** (trừ shell). Đây chính là
> việc của phase 2–6: thay widget private trong từng màn bằng các component
> này. Nếu thấy màn nào còn tự vẽ drag-handle / chip / empty state → thay.

### 3.3 Motion — giữ nguyên, chỉ đổi màu

`lib/shared/widgets/motion/`: `appMotion` (instance, **không** phải static),
`PressableScale`, `AnimatedMoneyText`, `AnimatedProgressBar`, `MotionListItem`,
`SkeletonBlock`. Dùng `appMotion.whenMotionAllowed(context, appMotion.xxx)` để
tôn trọng reduce-motion.

---

## 4. Nợ kỹ thuật còn lại (phần lớn thuộc Phase 7)

| Việc | Quy mô hiện tại |
|---|---|
| Hex hard-code ngoài `core/theme/` | **55** chỗ / 9 file (nặng nhất: `home_feature_actions.dart` 26 — màn này Phase 2 xoá) |
| `Colors.white/grey/red/orange/…` cố định (không đổi theo dark) | ~100 chỗ |
| `AppTheme.incomeColor/…` → `context.spendo` | 53 chỗ / 16 file |
| Splash | Phase 0 mới đổi màu sang token; redesign thật ở Phase 7 |
| 2 widget Android native `widget_layout_*.xml` | chưa đổi màu — Phase 7 |
| Route `/features` (AllFeatures) + `/stats` `/settings` | AllFeatures bị xoá ở Phase 2; lúc đó rà lại route thừa |

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
