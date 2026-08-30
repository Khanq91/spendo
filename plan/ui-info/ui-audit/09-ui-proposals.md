# 09 — Đề xuất UI (TO-BE)

> Direction đã chốt: **Material 3 tonal (B) làm nền + điểm nhấn "ledger" (A)**: bề mặt tonal thay viền, component M3 chuẩn thay component tự vẽ, ít màu, số tiền tabular là nhân vật chính, danh sách dày và thẳng hàng. Giữ: logo `#F06292` + tagline, 5 scheme, chế độ Fancy (liquid glass) như một "skin" bật/tắt trên cùng bộ token.
> Mọi mục gắn **[GIỮ]/[SỬA]/[MỚI]/[BỎ]** + lý do neo vào AS-IS. Mục Tầng 2 luôn có **Cũ / Mới** để bạn chọn.

---

## Tầng 1 — Không đổi logic (layout / style / spacing / typography)

| Màn hình | Vấn đề (AS-IS) | Đề xuất | Nhãn | Ảnh hưởng | Effort |
|---|---|---|---|---|---|
| Toàn app | 16 cỡ chữ, inline `TextStyle` (02 §2) | Dùng `textTheme` (Tầng 3 §T2); cấm `fontSize` < 11 | [SỬA] — 1 thang chữ để thứ bậc nhất quán | mọi file UI | L |
| Toàn app | 15 radius, viền 0.5/0.8 (02 §4-5) | Radius 4/8/12/16/28; bỏ viền mảnh, dùng tonal surface + divider 1px `outlineVariant` | [SỬA] — B tonal thay border | mọi card/chip | L |
| Toàn app | 2 màu đỏ cho "chi" (06 B1) | 1 `expense`, 1 `income` (Tầng 3 §T1.2) | [SỬA] | `app_theme.dart`, 8 file | S |
| Toàn app | `#6C63FF`, `#1E88E5`, `grey.shade*` cứng (06 B2/B3) | Thay bằng role: budget/backup → `primary`; SePay/tự động → `tertiary`; grey → `onSurfaceVariant`/`outline` | [SỬA] — phá dark mode | 12 file | M |
| Toàn app | Lucide + Material Icons lẫn (02 §6) | Chỉ Lucide (24/20/16); `Icons.add`→`LucideIcons.plus`, `chevron_right`→`chevronRight`… | [SỬA] | ~38 chỗ | S |
| Toàn app | 15 drag handle inline, 2 sheet thiếu (06 C2) | `showModalBottomSheet(showDragHandle: true)` M3 | [SỬA] | 18 sheet | S |
| Toàn app | Nút submit 3 style (03 §16.9) | `FilledButton` M3 mặc định, h48, full width, `labelLarge` | [SỬA] | 9 sheet | S |
| Toàn app | Section header 11/12/13 (03 §16.3) | `labelMedium` 12 w600 `onSurfaceVariant`, pad (16,20,16,8) | [SỬA] | 6 file | S |
| Toàn app | Leading icon box 32/36/40/44, r8/10/12/circle (03 §16.8) | Danh mục: `CategoryIconWidget` tròn 40/20 mọi nơi; icon chức năng: 40 circle `secondaryContainer` | [SỬA] | 10 file | M |
| Splash | Palette tím-hồng riêng, text Anh (04-01 §L) | Nền `surface` theme thật, logo `#F06292` giữ, message tiếng Việt, bỏ 0.8s delay cứng | [SỬA] | `splash_screen.dart`, `main.dart` | S |
| Welcome | Nền sáng cố định (06 B5) | Render trong theme thật; glass card giữ | [SỬA] | `welcome_screen.dart` | S |
| Home | Card gradient + 2 mini card viền + 3 mắt (04-05 §L) | Header tonal `surfaceContainerLow` không gradient; 1 nút mắt duy nhất, lưu prefs; thu/chi là 2 cột text không card | [SỬA] — giảm 3 lớp viền, 1 toggle | `summary_card.dart` | M |
| Home | Feature grid 8 màu Tailwind (06 B9) | Icon `onSecondaryContainer` trên nền `secondaryContainer` (1 màu) | [SỬA] | `home_feature_actions.dart` | S |
| Home | Wallet carousel auto-play 3s không indicator (04-05 §L) | Hàng chip ví cuộn ngang tay, không auto-play | [SỬA] — auto-play gây mất tập trung, vi phạm reduce-motion | `wallet_card_home.dart` | S |
| Transactions | Day header filled `surfaceContainerHighest` vs plain (03 §9) | 1 style: `labelMedium` + net, nền `surface`, không divider dày | [SỬA] | `grouped_transaction_sliver.dart` | S |
| Transactions | Không loading (06 A4) | Skeleton 4 hàng như Home | [SỬA] | `transactions_screen.dart` | S |
| AddTransaction | "₫ ₫" (06 A2) | Bỏ `Text('₫')` | [SỬA] | 1 dòng | S |
| AddTransaction | Chip danh mục không icon/màu (04-07 §L) | Chip có `CategoryIconWidget` 24 + tên, màu danh mục khi chọn | [SỬA] | `add_transaction_sheet.dart` | M |
| AddTransaction | Numpad key border 0.5 (03 §10) | Key phẳng nền `surfaceContainerLow`, ripple, chữ `headlineSmall` | [SỬA] | `numpad.dart` | S |
| TransactionDetail | `grey.shade*` (06 B3), note overflow (04-08 §J) | Role màu; `_DetailRow` value `Expanded` + `maxLines 3` | [SỬA] | 1 file | S |
| Stats | Summary 12px trong box (04-10 §L) | 3 số `titleMedium` tabular, nhãn `labelSmall`, không box | [SỬA] | `stats_screen.dart` | S |
| Wallets | Icon lỗi (06 A1); card `[primary,primary]` (06 C13) | Map `WalletType→LucideIcons` (wallet/landmark/smartphone/creditCard/trendingUp/ellipsis); card tổng dùng cùng widget Home | [SỬA] | `wallet.dart`, `wallets_screen.dart` | S |
| LoanList/Detail | Emoji badge 🔴/⚠️ (06 F7) | `Badge`/chip M3 màu `error`/`warning` + icon Lucide | [SỬA] | 2 file | S |
| Reminders | 2 kiểu gợi ý (04-18 §L) | 1 hàng `ActionChip` ✨ thống nhất | [SỬA] | `reminders_screen.dart` | S |
| Settings | Block trắng không bo, không margin (04-20 §E) | Nhóm dạng card `surfaceContainerLow` r12 margin H16 gap 24 (M3 grouped list) | [SỬA] | `settings_screen.dart` | M |
| Settings | 4 màu icon (06 B2) | Tất cả icon `onSecondaryContainer`/`secondaryContainer`; trừ nút Google giữ màu Google theo brand guideline | [SỬA] | 3 section | S |
| SePay form | Style lạc (06 C14) | Token chung | [SỬA] | 1 file | S |
| Mọi tap-target < 44 (06 F1) | | `IconButton` chuẩn 48 hoặc `Padding` ≥ 12; x slot widget → nút "Bỏ ghim" trong sheet | [SỬA] | 8 chỗ | S |
| Mọi sheet không cuộn (06 F8) | | `DraggableScrollableSheet` / `SingleChildScrollView` + `SafeArea(bottom)` | [SỬA] | 3 sheet | S |
| Dead code (06 C15) | `AuthScreen`, `GlobalFab`, `LoanMiniCard`, `LoanSettingsTile`, `QuickActionsBar`, `WalletProgressBar` | Xoá (BudgetCard giữ để hồi sinh ở Tầng 2) | [BỎ] — giảm nhiễu khi redesign | 6 file | S |

---

## Tầng 2 — Đổi cấu trúc màn hình (mỗi mục: Cũ / Mới, bạn chọn)

### T2.1 Shell điều hướng
**AS-IS**: 3 tab Giao dịch | Trang chủ | Cài đặt, mặc định ở giữa; 5 khu vực chỉ tới được qua grid Home (04-04 §L, 06 E1/E6).

```
CŨ (3 tab, tự vẽ, pill 90×62)            MỚI-A (4 tab M3 NavigationBar + FAB)      MỚI-B (3 tab, đổi thứ tự)
┌─────────────────────────┐              ┌─────────────────────────┐              ┌─────────────────────────┐
│                         │              │                         │              │                         │
│                    (+)  │              │                    (+)  │              │                    (+)  │
├─────────────────────────┤              ├─────────────────────────┤              ├─────────────────────────┤
│ [🧾] [▐🏠▌] [⚙]         │              │ [🏠] [🧾] [◔] [⚙]        │              │ [▐🏠▌] [🧾] [⚙]         │
│      Trang chủ          │              │ Trang chủ Giao dịch Thống kê Cài đặt │  │ Trang chủ               │
└─────────────────────────┘              └─────────────────────────┘              └─────────────────────────┘
```
- **MỚI-A [SỬA]**: 4 tab `NavigationBar` M3 (Trang chủ · Giao dịch · Thống kê · Cài đặt), label luôn hiện, mặc định tab 0; FAB `+` trên tab 0–2. Lý do: Stats là khu vực đọc thường xuyên nhưng đang ở 2 tap; khớp với screenshot cũ (đã từng có 4 tab); `navigationBarTheme` hiện là dead config sẽ được dùng. Fancy: `GlassTabBar` 4 tab.
- **MỚI-B [SỬA nhẹ]**: giữ 3 tab, Home ở trái, dùng `NavigationBar` M3.
- Ràng buộc: bỏ route push riêng `/transactions`, `/settings` (Home grid & AllFeatures → `goToTab(i)`); các route con giữ nguyên.
- **Khuyến nghị: MỚI-A.** → **ĐÃ CHỐT: MỚI-A (4 tab)**. Hệ quả: `AllFeaturesScreen` [BỎ]; Home grid rút còn 4 ô (T2.2).

### T2.2 Home
**AS-IS**: ~460px khối tĩnh trước list; "Số dư" ≠ progress ví; 8 ô grid; carousel ví (04-05).

```
CŨ                                         MỚI
┌───────────────────────────────┐          ┌───────────────────────────────┐
│  ‹ [Tháng 8/2026 ▾] ›   [🔔] │          │ Tháng 8/2026 ▾            [🔔]│ AppBar lớn, tiêu đề = tháng (tap → picker), ‹ › ẩn (swipe ngang header)
├───────────────────────────────┤          ├───────────────────────────────┤
│ ╔═ Số dư ••••••        [👁] ═╗│          │ Còn lại tháng này        [👁] │ labelMedium
│ ║ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬          ║│          │ 4.250.000 ₫                   │ displaySmall tabular (thu−chi), 1 mắt, lưu prefs
│ ╚═══════════════════════════╝│          │ Thu 18.000.000  ·  Chi 13.750.000│ bodyMedium 2 cột, màu income/expense
│ ┌↓ Thu nhập 👁┐┌↑ Chi tiêu 👁┐│          │ ┌ Ngân sách tháng  68% ▬▬▬▬▬─ ┐│ [MỚI] BudgetCard hồi sinh (ẩn nếu chưa đặt → 1 dòng "Đặt hạn mức")
│ └────────────┘└────────────┘  │          │ └──────────────────────────────┘│
│ ┌[👛] ● Ví A  30.000.000 › ┐  │          │ Ví  (● Tiền mặt 500k)(● MB 29.5tr)(+)│ chip cuộn tay, tap → detail; (+) → tạo ví
│ └──────────────────────────┘  │          │                               │
│ (⊕)(🧾)(👛)(◎)                │          │ (👛 Ví)(🤝 Vay)(🔔 Nhắc)(◎ Hạn mức)│ 1 hàng 4 ô nhỏ 64px, "Thêm/Giao dịch/Thống kê/Xem thêm" [BỎ] vì đã có FAB/tab
│ Thêm Giao dịch Ví Hạn mức     │          ├───────────────────────────────┤
│ (🤝)(🔔)(◔)(…)                │          │ Gần đây               Xem tất cả│ titleSmall + TextButton → tab Giao dịch
│ Vay nợ Nhắc nhở Thống kê Xem thêm│       │ Hôm nay              −85.000 ₫│
│ Hôm nay              −85.000 ₫│          │ (◯) Ăn uống   An trua −85.000 ₫│ list 8 giao dịch gần nhất
│ (◯) Ăn uống        −85.000 ₫  │          │ …                             │
└───────────────────────────────┘          └───────────────────────────────┘
```
- [SỬA] header: "Còn lại tháng này" đặt tên đúng bản chất (thu−chi), bỏ progress ví khỏi header (chuyển về chip ví) — giải quyết A3.
- [MỚI] BudgetCard hiển thị (A6). [BỎ] 4 ô grid trùng tab/FAB. [SỬA] carousel → chip tay.
- Trên màn 640px: header ≈ 150 + budget 56 + ví 48 + ô 64 ≈ **320px** (cũ ~460) → list lên trên fold.
- **Tuỳ chọn Cũ**: giữ grid 8 ô nhưng chuyển xuống dưới list "Gần đây" (ít xáo trộn hơn).

### T2.3 AddTransactionSheet
**AS-IS**: 04-07. Xem luồng ở 08 F2 PA1.

```
CŨ                                         MỚI (sheet 92%, cuộn, DraggableScrollableSheet)
╭───────────────────────────────╮          ╭───────────────────────────────╮
│           ━━━━                │          │           ━━━━                │ showDragHandle
│ [Chi] [Thu]        1.234.567 ₫│          │ Huỷ     [ Chi | Thu ]      Lưu│ TextButton · SegmentedButton · FilledButton.tonal (disabled khi 0)
│ (Ăn uống ✨)(Di chuyển•)(…)→  │          │                               │
│ Ghi chú (tuỳ chọn)...     [🔍]│          │        1.234.567 ₫            │ displaySmall tabular màu expense/income, center
│ ☐ Ghi vào nguồn tiền  (Ví ▾)  │          │ (◯)  (◯)  (◯)  (◯)            │ grid danh mục 4 cột × 2 hàng, icon tròn 40 + tên labelSmall
│ ─────────────────────────────  │          │ Ăn   Đi    Mua  Học           │ chọn = vòng primary + nền primaryContainer; ✨ khi auto
│   1      2      3             │          │ (◯)  (◯)  (◯)  (＋)            │ hàng 2 cuộn ngang nếu >7; ô "＋" → CategoryFormSheet [MỚI]
│   4      5      6             │          │ ┌ Ghi chú… ┐  (Ăn sáng)(Cà phê)(Trà sữa)│ chip gợi ý inline top-6 [MỚI], [BỎ] NotePicker
│   7      8      9             │          │ [📅 Hôm nay 12:30] [👛 Tiền mặt] [🔁]│ hàng meta chip: ngày/giờ [MỚI], ví (mặc định ví gần nhất), lặp lại (tạo reminder)
│  00      0      ⌫             │          ├───────────────────────────────┤
│ [     Chi 1.234.567 ₫     ]   │          │   1      2      3             │ numpad phẳng cố định đáy; khi focus ghi chú → thu thành thanh "Xong"
╰───────────────────────────────╯          │   4      5      6             │
                                           │   7      8      9             │
                                           │  000     0      ⌫             │ "000" thay "00" (VND thường 3 số 0) — [SỬA] tuỳ chọn
                                           ╰───────────────────────────────╯
```
- Nút Lưu chuyển lên góc phải để không bị keyboard/numpad che; label ngắn "Lưu" (số tiền đã lớn ở giữa).
- **Tuỳ chọn Cũ**: giữ chip ngang danh mục + nút lớn dưới; chỉ thêm hàng meta và sửa lỗi.

### T2.4 Transactions
```
CŨ                                         MỚI
┌───────────────────────────────┐          ┌───────────────────────────────┐
│   ‹ [Tháng 8/2026 ▾] ›   [🔍]│          │ Giao dịch                     │ AppBar lớn
│ (Tất cả)(Ăn uống)(Di chuyển)…→│          │ ┌ 🔍 Tìm ghi chú, số tiền… ┐  │ SearchBar M3 [SỬA]
│ 3 giao dịch  +18.0M  −130K    │          │ ‹ Tháng 8/2026 ›  [Tất cả|Chi|Thu] [Lọc•2]│ tháng + SegmentedButton + nút lọc badge [MỚI]
│▓ Hôm nay            −85.000 ₫▓│          │ 3 giao dịch · +18.000.000 · −130.000│ bodySmall
│ (◯) Ăn uống       −85.000 ₫   │          │ Hôm nay              −85.000 ₫│ day header phẳng
│…                              │          │ (◯) Ăn uống   An trua −85.000 ₫│ swipe trái → Xoá + Hoàn tác [MỚI]
└───────────────────────────────┘          │ …                             │
                                           └───────────────────────────────┘
```
- Sheet "Lọc": danh mục nhóm Chi/Thu (chip), ví, khoảng ngày; chip "Đang lọc: Ăn uống, MB ×" dưới thanh khi có filter; filter reset khi đổi tab (state cục bộ) — [SỬA] 06 E7.
- **Tuỳ chọn Cũ**: giữ hàng chip danh mục ngang nhưng tách Chi/Thu bằng SegmentedButton phía trên.

### T2.5 Settings → hub + 5 trang con
```
CŨ (1 list 9 nhóm, ~2000px)               MỚI (hub)
┌───────────────────────────────┐          ┌───────────────────────────────┐
│ Xuất báo cáo … Tháng này …    │          │ Cài đặt                       │
│ Sao lưu & khôi phục …         │          │ ┌ [🏷] Danh mục         12 › ┐│ → /settings/categories (T2 F13)
│ Kết nối ngân hàng …           │          │ │ [👛] Nguồn tiền         3 › ││ → /wallets
│ Sao lưu Google Drive …        │          │ │ [🤝] Khoản vay          2 › ││ → /loans
│ Giao diện … Thông báo …       │          │ │ [🔔] Nhắc nhở           4 › ││ → /reminders
│ Nhắc chi tiêu định kỳ …       │          │ └───────────────────────────┘│
│ Widget màn hình chính …       │          │ ┌ [☁] Sao lưu & đồng bộ  Drive · 2h trước › ┐│ → /settings/backup (JSON + Drive + CSV)
│ Danh mục ▾ …                  │          │ │ [🏛] Ngân hàng tự động   1 tài khoản › ││ → /settings/bank
└───────────────────────────────┘          │ │ [📱] Widget              2/4 › ││ → /settings/widget (preview)
                                           │ └───────────────────────────┘│
                                           │ ┌ [🎨] Giao diện   Tối · Rose › ┐│ → /settings/appearance (preview live)
                                           │ │ [🔔] Thông báo     20:00 › ││ → /settings/notifications
                                           │ └───────────────────────────┘│
                                           │ Spendo v1.7.26 · Your money, clearly.│
                                           └───────────────────────────────┘
```
- [SỬA] AllFeatures 8 ô → `/settings/*` đúng trang (06 E4). AllFeatures `[BỎ]` nếu chọn T2.1 MỚI-A + hub này (mọi thứ ≤2 tap); hoặc `[GIỮ]` như "Xem thêm".
- **Tuỳ chọn Cũ**: giữ 1 list nhưng dùng card nhóm + anchor scroll từ AllFeatures. → **ĐÃ CHỐT: Hub + trang con.**

### T2.6 Hạn mức → 1 trang `/budget`
```
CŨ: Home grid → BudgetTypeSheet → BudgetScreen | CategoryBudgetScreen → _SetCategoryBudgetSheet (3–4 lớp sheet)
MỚI:
┌───────────────────────────────┐
│ ‹  Hạn mức · Tháng 8/2026     │
│ Tổng tháng      9.300.000 / 12.000.000│ header + progress 8px; "Đặt" nếu chưa
│ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬─────  78%│
│ Theo danh mục          (＋ Đặt)│
│ (◯) Ăn uống   850k/1tr ▬▬▬▬▬▬▬▬▬─ 85%│ tile + progress, tap → numpad sheet, swipe xoá + undo
│ (◯) Di chuyển 300k/500k ▬▬▬▬▬───  60%│
│ Chưa đặt: (Mua sắm)(Học tập)(Giải trí)…│ chip → numpad sheet
└───────────────────────────────┘
```
- [BỎ] `BudgetTypeSheet`; [SỬA] 2 "Screen" sheet gộp; [MỚI] card trên Home (T2.2). → **ĐÃ CHỐT** (theo khuyến nghị).

### T2.7 LoanList
```
MỚI
┌───────────────────────────────┐
│ ‹  Khoản vay            [＋]  │
│ Đang nợ 3.000.000  ·  Được nợ 2.000.000│ header 2 số
│ [Tất cả | Đang vay | Cho vay] │ SegmentedButton [SỬA] thay 3 ô AllFeatures
│ (↙) Vay mua xe   còn 4.000.000 ₫│ trailing = còn lại [SỬA]; dòng phụ: Anh A · Hạn 30/8 (Còn 3 ngày)
│      ▬▬▬▬▬─────────── 20%  [Trả]│ progress + nút "Trả" mở AddPayment [MỚI]
│ Đã tất toán (1) ▾             │ collapsed
└───────────────────────────────┘
```

### T2.8 Bảng ánh xạ component tự vẽ → M3 chuẩn
| AS-IS (private) | TO-BE | Nhãn |
|---|---|---|
| `_SpendoNavBar`/`_NavButton` | `NavigationBar` + `NavigationDestination` | [SỬA] |
| 14 pill chip (03 §16.2) | `FilterChip` / `ChoiceChip` / `SegmentedButton` theo ngữ nghĩa | [SỬA] |
| `_TypeToggle`, loan type, frequency, `_FilterChip` Theo tháng/Tất cả | `SegmentedButton<T>` | [SỬA] |
| `_SectionHeader` ×3 | `SectionHeader` shared (`labelMedium`) | [SỬA] |
| `_EmptyState` ×6 | `EmptyState(icon, title, subtitle?, action?)` shared | [SỬA] |
| `Text('Lỗi: $e')` ×5 | `ErrorState(onRetry)` shared | [SỬA] |
| 5 progress bar | `AnimatedProgressBar` duy nhất (thêm `labels`) | [SỬA] |
| `_InfoCard` ×2 | `TonalCard` (surfaceContainerLow, r12, pad 16) | [SỬA] |
| Icon box 4 kích thước | `CategoryIconWidget` (danh mục) / `IconTile` (chức năng) | [SỬA] |
| 6 dialog xoá + 5 xoá tức thì | `UndoableAction` (SnackBar 5s) — **ĐÃ CHỐT**; dialog chỉ còn cho xoá ví có giao dịch, xoá loan kèm payment, ngắt Drive, restore | [SỬA] |
| `AlertDialog` cảnh báo budget/ví | giữ, dùng icon Lucide thay emoji | [GIỮ] |
| `Numpad` | giữ, restyle | [GIỮ] — nhanh hơn keyboard hệ thống cho VND |
| `MonthSelector` + `StatsTimeSelector` | 1 `PeriodSelector(mode: month\|range)` | [SỬA] |
| `MonthPickerSheet` + `DateRangePickerSheet` | 1 `PeriodPickerSheet` (grid tháng + preset + tuỳ chọn) | [SỬA] |
| Liquid glass (`GlassTabBar`, `GlassButton`, `GlassContainer`, Aurora) | giữ, bọc trong `FancySurface(child)` để mọi surface có bản glass | [GIỮ] |

---

## Tầng 3 — Design direction đã chốt: token đầy đủ

### T3.1 Màu — role M3 (giá trị thật xuất từ `ColorScheme.fromSeed`, Flutter 3.44)

Nguyên tắc: **không hard-code hex trong widget**; chỉ dùng role. Giá trị dưới là kết quả thực tế cho từng seed để công cụ thiết kế dùng.

**Rose (mặc định) — seed `#F06292` (ĐÃ CHỐT: đổi từ `#AD6E7F` sang mã logo)**

> Kết quả thực tế: `fromSeed(#F06292)` cho bảng gần **y hệt** `fromSeed(#AD6E7F)` (chỉ khác `primary #8C4A5E` vs `#8C4A5D`, `tertiaryContainer #FFDCC0/#613F1F`) vì Material chuẩn hoá tone/chroma của seed. Đổi seed = đồng nhất mã nguồn với logo, **không** làm primary hồng như logo. Hồng `#F06292` trên nền trắng chỉ đạt contrast ≈2.9:1 → không được dùng làm màu chữ/nút có chữ trắng. Để hồng brand "thấy được" trong app có 2 cách (quyết định mở #4 ở 07): (a) FAB & nav indicator dùng `brand` với icon `#551D30` (contrast ≈5.4:1) — chỉ điểm nhấn; (b) giữ nguyên, brand chỉ ở logo/splash. Bảng dưới là giá trị thật của seed `#F06292`.

| Role | Light | Dark | Dùng cho |
|---|---|---|---|
| primary | `#8C4A5E` | `#FFB1C5` | FAB, nút chính, chọn, link |
| onPrimary | `#FFFFFF` | `#551D30` | chữ trên primary |
| primaryContainer | `#FFD9E1` | `#703346` | nav indicator, chip chọn, ô danh mục chọn |
| onPrimaryContainer | `#703346` | `#FFD9E1` | |
| secondaryContainer | `#FFD9E1` | `#5B3F46` | icon tile chức năng, FilledButton.tonal |
| onSecondaryContainer | `#5B3F46` | `#FFD9E1` | |
| tertiary | `#7B5734` | `#EEBD92` | "tự động/SePay", Aurora blob 3 |
| tertiaryContainer | `#FFDCC0` | `#613F1F` | badge "tự động" |
| error | `#BA1A1A` | `#FFB4AB` | lỗi form, vượt hạn |
| surface (nền trang) | `#FFF8F8` | `#191113` | scaffold |
| surfaceContainerLowest | `#FFFFFF` | `#140C0E` | sheet, dialog |
| surfaceContainerLow | `#FFF0F2` | `#22191B` | card, nhóm settings, numpad key |
| surfaceContainer | `#FBEAEC` | `#261D1F` | search bar, chip chưa chọn |
| surfaceContainerHigh | `#F5E4E6` | `#31282A` | nav bar, app bar khi scroll |
| surfaceContainerHighest | `#EFDFE1` | `#3C3234` | skeleton, track progress |
| onSurface | `#22191B` | `#EFDFE1` | text chính |
| onSurfaceVariant | `#514346` | `#D6C2C5` | text phụ, icon phụ |
| outline | `#847376` | `#9E8C90` | viền input focus-less |
| outlineVariant | `#D6C2C5` | `#514346` | divider 1px |
| inverseSurface | `#382E30` | `#EFDFE1` | SnackBar, tooltip |

**4 seed còn lại — role chính (light / dark)**
| Seed | primary | primaryContainer | secondaryContainer | surface | surfaceContainerLow | onSurface | onSurfaceVariant | outlineVariant |
|---|---|---|---|---|---|---|---|---|
| Indigo `#5C6BC0` | `#515B92` / `#BAC3FF` | `#DEE0FF` / `#394379` | `#DFE1F9` / `#434659` | `#FBF8FF` / `#121318` | `#F5F2FA` / `#1B1B21` | `#1B1B21` / `#E4E1E9` | `#46464F` / `#C6C5D0` | `#C6C5D0` / `#46464F` |
| Emerald `#00897B` | `#006B5F` / `#82D5C7` | `#9EF2E3` / `#005048` | `#CCE8E2` / `#334B47` | `#F4FBF8` / `#0E1513` | `#EFF5F2` / `#161D1B` | `#161D1B` / `#DDE4E1` | `#3F4946` / `#BEC9C5` | `#BEC9C5` / `#3F4946` |
| Slate `#78909C` | `#106681` / `#8AD0EF` | `#BCE9FF` / `#004D63` | `#D0E6F2` / `#354A53` | `#F6FAFD` / `#0F1417` | `#F0F4F8` / `#171C1F` | `#171C1F` / `#DFE3E6` | `#40484C` / `#C0C8CD` | `#C0C8CD` / `#40484C` |
| Amber `#FFB300` | `#7D570D` / `#F0BE6D` | `#FFDEAC` / `#604100` | `#F8DFBB` / `#55442A` | `#FFF8F3` / `#17130B` | `#FEF2E5` / `#201B13` | `#201B13` / `#ECE1D4` | `#4E4539` / `#D2C4B4` | `#D2C4B4` / `#4E4539` |

Ghi chú: các override hiện tại (`surface: Colors.white`, `#1E1E1E`, `#111111`… `app_theme.dart:60-66,159-174`) **[BỎ]** để tonal hoạt động.

**Tuỳ chọn nền trung tính** — `DynamicSchemeVariant.neutral` với cùng seed `#F06292` (giá trị thật, Flutter 3.44): light `primary #6F585E`, `primaryContainer #FADBE1`, `secondaryContainer #F3DDE1`, `surface #FFF8F8`, `surfaceContainerLow #FAF2F2`, `surfaceContainer #F4ECEC`, `onSurface #1E1B1B`, `onSurfaceVariant #4A4646`, `outlineVariant #CCC5C5`; dark `primary #DCBFC5`, `surface #151313`, `surfaceContainerLow #1E1B1B`, `surfaceContainer #221F1F`, `onSurface #E8E1E1`. Nền bớt ám hồng, hợp tinh thần "ledger" (A) hơn, nhưng primary xám-hồng nhạt (ít "nút bấm"). Khuyến nghị: **tonalSpot** (mặc định) để primary còn sắc độ; neutral là quyết định mở #4b ở 07.

### T3.2 Màu ngữ nghĩa cố định (thêm vào `ThemeExtension<AppSemanticColors>`)
| Token | Light | Dark | Contrast trên surface | Thay cho |
|---|---|---|---|---|
| `income` | `#2E7D32` | `#81C784` | ≥4.5:1 | `#43A047` |
| `expense` | `#C62828` | `#EF9A9A` | ≥4.5:1 | `#F06292` **và** `#E53935` (06 B1) |
| `warning` | `#B26A00` | `#FFB74D` | ≥4.5:1 | `Colors.orange` (35 lần) |
| `automatic` | = `tertiary` | | | `#1E88E5` |
| `brand` | `#F06292` | `#F06292` | logo/splash/về app **+ FAB nền và chỉ báo tab đang chọn** (đã chốt); chữ/icon trên brand = `onBrand #551D30` (≈5.4:1); không dùng brand làm nền chữ trắng | giữ theo yêu cầu |
| `onBrand` | `#551D30` | `#551D30` | icon FAB, icon/label tab đang chọn trên nền brand | mới |
| `googleBlue` | `#4285F4` | `#4285F4` | chỉ nút Google | brand guideline |

Palette danh mục/ví (`AppColors.palette` 15 màu) **[GIỮ]** nhưng chỉ dùng cho icon/dot; text tên ví dùng `onSurface` (06 F4).

### T3.3 Typography (`textTheme`, font hệ thống — Roboto/SF; số dùng `FontFeature.tabularFigures`)
| Role | Size/Height | Weight | Dùng cho | Thay cho |
|---|---|---|---|---|
| displaySmall | 36/44 | 700 | số dư Home | 24 w700 |
| headlineSmall | 24/32 | 700 | số tiền trong sheet, tổng ví, principal | 32/28 w600 |
| titleLarge | 22/28 | 600 | tiêu đề AppBar lớn (Home tháng, Giao dịch) | 16 w600 |
| titleMedium | 16/24 | 600 | tiêu đề sheet, tên nhóm settings, số summary Stats | 15/16 |
| titleSmall | 14/20 | 600 | tên danh mục trong row, tiêu đề card | 14 w500 |
| bodyLarge | 16/24 | 400 | input text, mô tả onboarding | 15/16 |
| bodyMedium | 14/20 | 400 | nội dung, subtitle ListTile | 13/14 |
| bodySmall | 12/16 | 400 | ghi chú row, caption có nội dung | 12/11 |
| labelLarge | 14/20 | 600 | nút | 14/15 |
| labelMedium | 12/16 | 600 | section header, chip, day header, nav label | 11/12/13 |
| labelSmall | 11/16 | 500 | tên dưới icon danh mục, badge | 9/10 |
Cấm: `fontSize` < 11; `letterSpacing` âm ngoài display/headline (−0.5); `height: 1` (trừ logo).

### T3.4 Spacing (lưới 4)
| Token | px | Dùng |
|---|---|---|
| `s1` | 4 | icon↔text nhỏ, badge |
| `s2` | 8 | trong chip, giữa chip, giữa dòng text |
| `s3` | 12 | icon↔text trong row, gap card nội bộ |
| `s4` | 16 | padding ngang màn/card, gap giữa card |
| `s5` | 20 | padding sheet top sau handle |
| `s6` | 24 | gap giữa section |
| `s8` | 32 | padding empty state |
| `s10` | 40 | đáy list chừa FAB (thay 80 cứng → dùng `MediaQuery.padding` + 56+16) |
Loại bỏ: 2, 3, 6, 10, 14, 18, 22 (02 §3.1).

### T3.5 Radius / border / elevation
| Token | Giá trị | Dùng |
|---|---|---|
| `r-xs` | 4 | progress bar, skeleton nhỏ |
| `r-sm` | 8 | chip vuông (SegmentedButton M3 dùng pill), input, numpad key |
| `r-md` | 12 | card, tile nhóm, FilledButton (M3 mặc định pill → đặt 12 để hợp A) |
| `r-lg` | 16 | card nổi bật (header Home khi có nền) |
| `r-xl` | 28 | bottom sheet top, dialog (M3) |
| `r-full` | 999 | FilterChip, FAB, CategoryIcon, badge |
| Border | chỉ `Divider` 1px `outlineVariant`; input `OutlineInputBorder` 1px `outline`, focus 2px `primary` | thay 0.5/0.8 |
| Elevation | 0 mọi surface (tonal); FAB level 3 (M3); sheet/dialog level 1 (shadow nhẹ); AppBar scrolledUnder `surfaceContainerHigh` | |
| Fancy | cùng token, `FancySurface` thay nền tonal bằng `GlassContainer(superellipse r-xl)`, Aurora nền; giữ `AppGlassPolicy` | |

### T3.6 Icon & motion
- Bộ: **Lucide** duy nhất; 24 (AppBar/nav/list leading), 20 (trong chip/ListTile trailing), 16 (inline text). Stroke mặc định.
- Motion: giữ `MotionSpec` (02 §8); mọi 150ms cứng → `tapUpDuration`; nav/Aurora/Welcome respect `shouldReduceMotion`; sheet dùng M3 mặc định.

### T3.7 Áp lên 3 màn hình đại diện

**(1) Home** — xem wireframe T2.2 MỚI. Vùng:
- AppBar: `titleLarge` "Tháng 8/2026 ▾" trái, nền `surface`, action 🔔 24. Swipe ngang trên header đổi tháng; tap → PeriodPickerSheet.
- Header số: pad 16/20; "Còn lại tháng này" `labelMedium onSurfaceVariant` + mắt 48; số `displaySmall` `onSurface` (âm → `expense`); dòng thu/chi `bodyMedium` với dot 8 `income`/`expense`.
- BudgetCard: `surfaceContainerLow` r12 pad 16; `titleSmall` + `labelMedium` %; progress 8px `primary`/`warning`/`error`.
- Ví: hàng `FilterChip`-style (avatar dot màu ví + tên `labelMedium` + số `labelMedium` tabular) nền `surfaceContainer`, cuộn tay, chip cuối "＋".
- 4 ô tắt: 64px, icon 24 `onSecondaryContainer` trên circle 40 `secondaryContainer`, label `labelSmall`.
- "Gần đây": `titleSmall` + `TextButton` "Xem tất cả"; list 8 row: `CategoryIconWidget` 40, tên `titleSmall`, phụ `bodySmall onSurfaceVariant`, số `titleSmall` tabular `expense`/`income`; row 56px; divider 1px indent 68; day header `labelMedium` + net.

**(2) AddTransactionSheet** — wireframe T2.3 MỚI. Vùng:
- Sheet `surfaceContainerLowest` r-xl top, drag handle M3, `DraggableScrollableSheet` initial .92.
- Hàng 1: `TextButton` Huỷ · `SegmentedButton` Chi|Thu (selected `secondaryContainer`) · `FilledButton` Lưu (disabled khi 0).
- Số: `headlineSmall`→ dùng `displaySmall` tabular center, màu `expense`/`income`; "0 ₫" khi rỗng.
- Grid danh mục: 4 cột, ô 72×80: `CategoryIconWidget` 40 (chọn: ring 2px `primary` + nền `primaryContainer`), tên `labelSmall` 2 dòng; ô "＋" outline dashed.
- Ghi chú: `TextField` filled `surfaceContainer` r-sm, `bodyLarge`; dưới là `Wrap` `SuggestionChip` `labelMedium` (top-6 history + default).
- Meta: 3 `AssistChip` (📅 ngày/giờ → `showDatePicker`+`showTimePicker` theme chung; 👛 ví → sheet chọn; 🔁 lặp lại → ReminderFormSheet prefill).
- Numpad: 4×3, key 64px nền `surfaceContainerLow` r-sm, chữ `headlineSmall` 400; hàng cuối `000 · 0 · ⌫`; dính đáy sheet + `SafeArea`.
- Trạng thái: lưu → `SnackBar` "Đã thêm 50.000 ₫ · Hoàn tác"; lỗi → SnackBar `errorContainer`.

**(3) Transactions** — wireframe T2.4 MỚI. Vùng:
- AppBar `titleLarge` "Giao dịch"; `SearchBar` M3 nền `surfaceContainer` r-full, pad H16.
- Thanh điều khiển: `PeriodSelector` (‹ tháng ›) trái; `SegmentedButton` Tất cả|Chi|Thu; `IconButton.filledTonal` "Lọc" + `Badge` số.
- Chip filter đang áp: `InputChip` có ×.
- Tổng dòng: `bodySmall onSurfaceVariant` "3 giao dịch · +… · −…".
- List: như Home; swipe trái nền `errorContainer` icon trash 24; SnackBar hoàn tác.
- States: skeleton 4 row; empty (icon 48 `outlineVariant`, `titleSmall`, `bodySmall`, `FilledButton.tonal` "Thêm giao dịch"); error (`ErrorState` retry).

### T3.8 Quy tắc áp cho các màn còn lại
1. **Trang danh sách** (Wallets, Loans, Reminders, Categories, Budget): AppBar `titleLarge` + 1 hành động; header tổng (nếu có) `headlineSmall` tabular trên `surfaceContainerLow`; `SegmentedButton` cho lọc ≤3 lựa chọn; list row 56/72 M3; FAB hoặc AppBar `＋` — **chỉ một**; empty/error/loading dùng 3 widget chung; swipe xoá + undo.
2. **Trang chi tiết** (WalletDetail, LoanDetail): header `TonalCard` r12 (icon 40 + tên + loại), số chính `headlineSmall`, meta là `AssistChip`; hành động phụ trong `MenuAnchor` (M3) thay `PopupMenuButton`; hành động chính là FAB (Thêm giao dịch / Trả).
3. **Form sheet** (Category/Wallet/Loan/Reminder/SePay/Payment): drag handle M3; tiêu đề `titleMedium` + nút Huỷ/Lưu ở hàng đầu; `TextField` filled r-sm, label nổi, lỗi inline (`errorText`); chọn 1-trong-n ≤4 → `SegmentedButton`, >4 → `ChoiceChip` Wrap có icon; màu → hàng 15 swatch 32 inline (cùng cho danh mục & ví); số tiền → 1 dòng `headlineSmall` + numpad; cuộn được; `SafeArea` đáy.
4. **Picker thời gian**: 1 `PeriodPickerSheet` dùng chung Home/Transactions/WalletDetail/Stats (grid tháng + preset + tuỳ chọn); `showDatePicker/showTimePicker/showDateRangePicker` dùng `datePickerTheme`/`timePickerTheme` khai báo 1 lần trong `ThemeData` (xoá override cục bộ 50 dòng ở `date_range_picker_sheet.dart:142-198`).
5. **Dialog**: chỉ cho quyết định không thể hoàn tác thật (xoá ví có giao dịch, ngắt Drive, restore) — `AlertDialog` M3 r-xl, icon Lucide 24 `secondary`, không emoji.
6. **Stats**: chart giữ fl_chart; màu rod/section từ `category.color`; tooltip `inverseSurface`; summary 3 số `titleMedium` tabular không box; legend row = list row tap được.
7. **Splash/Welcome**: nền `surface` theme; logo tròn 96 `brand`; tagline `bodyLarge onSurfaceVariant`; progress 4px `primary`; Welcome dùng `FancySurface` cho card (giữ glass).
8. **Fancy mode** (đã chốt): mọi `TonalCard`/nav/FAB/sheet header → glass (FAB glass tint `brand`); list và chart giữ đặc; Aurora chỉ ở Home/Welcome/Settings hub (tránh dưới list dài).
8b. **Brand accent** (đã chốt): FAB nền `brand #F06292` + icon `onBrand #551D30`; `NavigationBar` indicator `brand` + icon/label `onBrand`; mọi nút khác `primary`. Áp cho cả 5 scheme (brand là hằng, không đổi theo seed).
8c. **Tên scheme** (đã chốt): Hồng · Chàm · Ngọc lục · Xám xanh · Hổ phách.
8d. **Numpad** (đã chốt): `000` thay `00`, long-press ⌫ xoá hết, tối đa 12 chữ số.
8e. **Roadmap mockup**: 1 sheet "Chuyển tiền giữa ví" (Từ ví → Đến ví, số tiền, ngày) vẽ kèm bộ thiết kế, nhãn "Roadmap", không nằm trong phạm vi code.
9. **Dark mode**: chỉ role; kiểm tra `income/expense/warning` bản dark; `Colors.white` chỉ cho `onPrimary` khi seed đảm bảo.
10. **Accessibility**: tap-target ≥48; `Semantics` label cho mọi `IconButton`; text ≥11; contrast ≥4.5:1 cho text, ≥3:1 cho icon/viền.
