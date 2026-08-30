# 02 — Design tokens trích từ code (AS-IS)

> Không có file token tập trung. Nguồn "token" thực tế = `ThemeData` trong `lib/core/theme/app_theme.dart` + các hằng rải rác. Tần suất đếm bằng `grep -rhoE` trên `lib/` (đã gộp cả code dead).

## 1. Màu

### 1.1 Seed & ColorScheme (`app_theme.dart:7-40`)

| Enum `AppColorScheme` | Label hiển thị | Seed = swatch | Ghi chú |
|---|---|---|---|
| `roseDefault` | "Rose (Mặc định)" | `#AD6E7F` | mặc định (`theme_provider.dart:14`) |
| `indigoMidnight` | "Indigo Midnight" | `#5C6BC0` | |
| `emeraldWealth` | "Emerald Wealth" | `#00897B` | |
| `slatePremium` | "Slate Premium" | `#78909C` | |
| `amberWarm` | "Amber Warm" | `#FFB300` | |

`ColorScheme.fromSeed(seedColor, brightness)` sinh toàn bộ `primary/primaryContainer/secondary/tertiary/…`. Chỉ các slot sau bị ghi đè:

| Slot | Light (`:60-66`) | Dark (`:159-169`) |
|---|---|---|
| `surface` | `Colors.white` | `#1E1E1E` |
| `surfaceContainerHighest` | `#F0F0F0` | `#2A2A2A` |
| `onSurface` | (fromSeed) | `#EEEEEE` |
| `onSurfaceVariant` | (fromSeed) | `#AAAAAA` |
| `outline` | (fromSeed) | `#444444` |
| `outlineVariant` | (fromSeed) | `#333333` |
| `scaffoldBackgroundColor` | `#F5F5F5` (`:71`) | `#111111` (`:174`) |

**Hệ quả**: `cs.primary`, `cs.primaryContainer`, `cs.secondary`, `cs.tertiary` (dùng cho Aurora) không có giá trị hex cố định — phụ thuộc seed. `[UNKNOWN: giá trị hex thực của primary/primaryContainer cho từng seed — do Material tính runtime]`.

### 1.2 Màu ngữ nghĩa cố định (`app_theme.dart:51-53`)

| Tên | Hex | Dùng ở |
|---|---|---|
| `AppTheme.incomeColor` | `#43A047` | số tiền thu (list item, summary, stats, mini summary, day header) |
| `AppTheme.expenseColor` | `#F06292` | số tiền chi trong `TransactionListItem:25`, `TransactionDetailSheet:27,130-133,179`; **không** dùng cho summary |
| `AppTheme.expenseAltColor` | `#E53935` | "destructive" + **cũng** là màu chi ở `SummaryCards:155`, `_MiniSummaryRow:319`, `_DayHeader:124`, Stats `:140,637,759` → 2 màu đỏ cho cùng 1 nghĩa |

### 1.3 Hex hard-code ngoài theme (≥2 lần)

| Hex | Số lần | Nơi | Ý nghĩa |
|---|---|---|---|
| `#6C63FF` | 16 | `budget_screen.dart:135,165`, `budget_type_sheet.dart:48`, `budget_card.dart:170,197`, `settings_screen.dart:81,87,111,117,727,743,781,835`, `home_feature_actions.dart:168`, `auth_screen.dart:161,223` | tím "budget/backup" — không nằm trong scheme |
| `#F06292` | 7 | `main.dart:68` (seed MaterialApp#1), `splash_screen.dart:421,427,433,484,488,568`, `app_theme.dart:52` | hồng brand cũ, chỉ còn ở splash |
| `#43A047` | 6 | `app_theme.dart:51`, `add_transaction_sheet.dart:362,408`, `sepay_connection_section.dart:170,179,189` | xanh thu |
| `#E53935` | 5 | `app_theme.dart:53`, `add_transaction_sheet.dart:362,401`, `budget_screen.dart:111`, `auth_screen.dart:149` | đỏ chi |
| `#1E88E5` | 4 | `transaction_list_item.dart:58`, `transaction_detail_sheet.dart:108`, `sepay_connection_section.dart:33,37` | xanh "SePay/tự động" |
| `#4285F4` | 4 | `gdrive_backup_section.dart:51,58,92,98,202` | Google blue |
| `#4ECDC4` | 2 | `settings_screen.dart:768,788`, `app_colors.dart:13` | teal |
| Bộ 18 màu Tailwind-like (`#16A34A #2563EB #0EA5E9 #F59E0B #DC2626 #DB2777 #7C3AED #7A869A #8B5CF6 #EC4899 #EA580C #0891B2 #475569 #64748B #0284C7 #0F766E #9333EA #CA8A04 #059669`) | 1–2 | `home_feature_actions.dart:25-198` | màu icon feature grid, không nằm trong palette nào |
| Bộ splash (`#FAF5FF #0F0A12 #7B5F8A #B89AB0 #9E7DB0 #8A7090 #B09ABF #5A4560 #E8D8F5 #2A1A2E #1A0A2E #F48FB1 #CE93D8 #7B1FA2`) | 1–2 | `splash_screen.dart:233-242,421,484,549,568,583` | palette riêng tím-hồng, không liên quan theme |

### 1.4 `Colors.*` Material dùng trực tiếp (không qua scheme)

| Màu | Số lần | Vai trò điển hình |
|---|---|---|
| `Colors.white` | 48 | text trên gradient card, spinner trong FilledButton, check trên swatch |
| `Colors.orange` (+`.shade700`) | 36 | cảnh báo ≥80% hạn mức, loan upcoming, debug panel |
| `Colors.red` (+`.shade400/.shade600`, `redAccent`) | 30 | vượt hạn, overdue, ví âm, loan borrowed |
| `Colors.green` (+`.shade400/.shade500`) | 11 | loan lent, budget <50%, trả xong |
| `Colors.amber` | 4 | budget 50–80% |
| `Colors.grey.shade50/100/200/300/400/500/600/800` | 17 | text phụ trong `transaction_list_item:91,101`, `transaction_detail_sheet:47,226,230,238`, `month_selector:80`, `stats_time_selector:113`, `auth_screen` — **không đổi theo dark mode** |
| `Colors.purple` | 1 | debug seed button |

### 1.5 Palette người dùng chọn (`app_colors.dart:7-23`)
15 hex: `#FF6B6B #FF8E53 #FFA726 #FFEAA7 #96CEB4 #4ECDC4 #45B7D1 #42A5F5 #6C63FF #9C8FFF #DDA0DD #EC407A #66BB6A #B0BEC5 #FFD3B6` — dùng cho màu category (`category_form_sheet.dart:168`), wallet (`wallet_form_sheet.dart:119`; mặc định `palette[4]` xanh mint `:46`), loan (`loan_form_sheet.dart:50-51`: borrowed = `palette[0]`, lent = `palette[12]`).

### 1.6 Alpha overlay thường dùng
`withValues(alpha: 0.15)` ×24 (nền icon danh mục/chip chọn), `0.12` ×23 (chip/pill chọn), `0.10` ×20 (nền icon settings), `0.08` ×7, `0.06` ×6 (nền label tháng), `0.05`/`0.04` (card nhạt), `0.5/0.4/0.3/0.25/0.2` (border theo màu).

## 2. Typography

**Font family**: mặc định hệ thống (Roboto trên Android). Không có `fontFamily` trong `ThemeData`. Ngoại lệ: `'serif'` (`splash_screen.dart:288`), `'monospace'` (`reminders_screen.dart:538`). Không dùng `textTheme` Material (không có `Theme.of(context).textTheme.*` trong UI — mọi Text đặt `TextStyle` inline).

### 2.1 Theme-level
| Slot | Giá trị | Nguồn |
|---|---|---|
| `appBarTheme.titleTextStyle` | 16 / w600 / `#1A1A1A` (light) – `white` (dark), `centerTitle: true` | `app_theme.dart:77-81, 180-184` |
| `navigationBarTheme.labelTextStyle` | 11 / w600 (selected) – 11 / `#9E9E9E` | `:93-102` (thực tế **không dùng** NavigationBar; nav tự vẽ) |
| `chipTheme.labelStyle` | 12 | `:124` |
| `inputDecorationTheme.hintStyle` | 13 / `grey.shade400` (light) – `#666666` (dark) | `:135, 237` |

### 2.2 Thang cỡ chữ thực tế (tần suất `fontSize:`)

| Size | Số lần | Vai trò quan sát được | Weight đi kèm |
|---|---|---|---|
| 48 | 1 | emoji 💸 AuthScreen (dead) | — |
| 44 | 1 | "Spendo" splash (serif, letterSpacing −1.5, height 1) | w700 |
| 40 | 1 | "Spendo" welcome | w700 |
| 32 | 5 | số tiền đang nhập (AddTransaction, Budget, CategoryBudget), "Spendo" auth | w600, letterSpacing −1 |
| 28 | 5 | số tiền nhập (WalletForm, LoanForm, AddPayment), số tiền TransactionDetail | w600/w700, ls −1/−0.5 |
| 24 | 4 | số dư card Home, tổng số dư Wallets, principal LoanDetail | w700, ls −0.5 |
| 22 | 2 | phím numpad; số dư WalletDetail | w400 / w700 |
| 18 | 1 | năm trong MonthPicker | w700 |
| 16 | 18 | tiêu đề AppBar & tiêu đề sheet lớn (WalletForm/LoanForm/AddMapping/VisualMode/ThemeColor/Restore), mô tả welcome | w600 |
| 15 | 22 | tiêu đề sheet nhỏ, label tháng, tiêu đề tile visual mode, input note picker, giờ reminder, nút submit | w600/w700/w500 |
| 14 | 57 | title ListTile, tên category ở list, số tiền row, body mặc định | w400/w500/w600 |
| 13 | 56 | body phụ, chip, label form, nút text | w400/w500/w600 |
| 12 | 102 | **phổ biến nhất** — subtitle, day header, legend, label mini card, chip | w400/w500/w600 |
| 11 | 36 | caption, nav label, section label uppercase-ish (letterSpacing 0.5), meta chip | w600/w400 |
| 10 | 10 | "Đã dùng x / y" progress label, tên slot widget, badge | w400/w600 |
| 9 | 4 | % mini progress, trục bar chart, badge số | w600/w400 |

`FontWeight`: w600 ×108, w500 ×37, w700 ×23, w400 ×14 (explicit). `height`: 1 (nav label, brand), 1.15 (feature tile), 1.25 (visual mode subtitle), 1.35 (welcome desc), 1.6 (debug), còn lại mặc định. `letterSpacing`: 0.5 ×8 (section header), −1 ×7, −0.5 ×6, 0.4 ×3, 0.3, −1.5.

**Kết luận**: không có thang chữ; 16 cỡ khác nhau (9→48), 12/13/14 dùng gần như thay thế nhau cho cùng vai trò (vd tiêu đề sheet: 15 ở 9 nơi, 16 ở 6 nơi).

## 3. Spacing

### 3.1 Giá trị xuất hiện (px logic)

| Giá trị | `SizedBox(height)` | `SizedBox(width)` | `horizontal:` | `vertical:` | `EdgeInsets.all` |
|---|---|---|---|---|---|
| 1 | | | | 1 | |
| 2 | 7 | 2 | 2 | 5 | |
| 3 | 2 | 2 | | 5 | |
| 4 | 22 | 14 | 4 | 14 | 3 |
| 5 | | 1 | | | |
| 6 | 6 | 8 | 1 | 13 | 2 |
| 7 | | | | 1 | |
| 8 | **55** | **29** | 10 | 9 | 1 |
| 10 | 10 | 16 | 10 | **25** | |
| 12 | 38 | 12 | 19 | 16 | 1 |
| 14 | 2 | 1 | 6 | 5 | |
| 16 | 23 | 1 | **39** | 2 | 5 |
| 18 | 3 | | | | |
| 20 | 9 | | 3 | | |
| 22 | | | | 1 | |
| 24 | 6 | 1 | 1 | 2 | 2 |
| 28 | 1 | | | | |
| 32 | 2 | | 1 | | 1 |
| 36 | 1 | | | | |
| 40 | | 1 | | 1 | |
| 48 | | | | 2 | |
| 80 | 5 | | | | (bottom spacer cho FAB) |
| 88 | | 1 | | | (placeholder nút Bỏ qua) |

**Nhận xét**: có "xương sống" 4/8/12/16 nhưng lẫn 2, 3, 6, 10, 14, 18, 20, 22 thường xuyên (10 xuất hiện 61 lần, 6 xuất hiện 30 lần, 14 xuất hiện 14 lần). Padding ngang màn hình nhất quán = **16** (39 lần). Padding sheet: `fromLTRB(16,12,16,32)` ×4, `(16,8,16,16)` ×3, `(16,4,16,12)` ×3 — 30 tổ hợp `fromLTRB` khác nhau.

### 3.2 Chiều cao cố định đáng chú ý
| Element | Giá trị | Nguồn |
|---|---|---|
| Bottom nav (normal) | 80 + SafeArea | `app_bottom_nav.dart:151` |
| Bottom nav (fancy) | 64 | `:186` |
| Nav pill | 90 × 44→62 | `:265-266, 310` |
| FAB | 56 | `:80-81` (fancy), theme (normal) |
| Feature tile | 102 (mainAxisExtent), icon circle 56, icon 26 | `feature_grid.dart:33, 60-66` |
| Category filter bar / filter chip | 48 | `transactions_screen.dart:199, 248` |
| Category chip strip (AddTransaction) | 36 hoặc 48 khi có budget | `add_transaction_sheet.dart:439-443` |
| Preset chip strip (Reminders) | 44 | `reminders_screen.dart:634` |
| Wallet carousel | 38 | `wallet_card_home.dart:140` |
| Stats summary row | 76 | `stats_screen.dart:97` |
| Pie chart box | 220 (radius 60→72 touch, center 48) | `:308, 393, 407` |
| Bar chart box | 200 | `:536` |
| Widget slot card | 72 | `widget_pin_section.dart:113` |
| Numpad key | aspect 1.6 (GridView 3 cột) | `numpad.dart:14` |
| Submit button | minHeight 48 (`minimumSize`) hoặc padding v12 | `add_transaction_sheet.dart:636`, `wallet_form_sheet.dart:450` |
| Drag handle | 36×4, radius 2 (×14); 40×4 ở SePay sheet | `sepay_connection_section.dart:272` |
| Icon leading ListTile | 36×36 radius 8 (Settings), 40×40 radius 10 (Wallets/Loans/CategoryBudget), 44×44 radius 12 (BudgetType, WalletDetail info) | |

## 4. Border radius

| Giá trị | Số lần | Dùng cho |
|---|---|---|
| 2 | 20 | drag handle, progress mini |
| 3 | 4 | bar chart rod, mini progress |
| 4 | 6 | progress bar wallet |
| 6 | 3 | meta chip loan, day-of-week, payload box |
| 8 | 26 | nền icon settings 36×36, label tháng, type toggle, month cell, text field debug |
| 9 | 1 | habit icon |
| 10 | 38 | **phổ biến nhất** — `OutlineInputBorder`, nút submit form (Category/Wallet/Loan/Reminder/AddPayment), leading icon 40×40, date field |
| 12 | 27 | card viền (WalletCardHome, BudgetCard, habit tile, info banner), nút submit AddTransaction/Budget, feature tile clip, widget slot |
| 14 | 2 | option card BudgetType |
| 16 | 9 | `cardTheme` (theme), balance card, net worth card, info card Wallet/Loan detail, dialog chọn màu |
| 20 | 25 | pill chip/filter chip, bottom sheet top, nav pill, badge, `chipTheme` |
| 22 | 1 | GlassContainer visual mode |
| 24 | 2 | date range picker dialog, tab chip ink |
| 28 | 1 | GlassContainer welcome, skeleton pie |
| 999 | 1 | `AnimatedProgressBar` mặc định |
| circle | — | icon danh mục (`CategoryIconWidget`), FAB, swatch, dot |

→ 15 giá trị radius. Cùng vai trò "nút submit" dùng 10 (5 sheet) và 12 (3 sheet); "leading icon box" dùng 8/10/12.

## 5. Border, elevation, shadow, opacity

| Thuộc tính | Giá trị | Nơi |
|---|---|---|
| Border mảnh | `width: 0.8` ×13 (viền chip/card), `0.5` ×5 (card theme, divider, mini card, numpad key), `1` (widget slot, debug), `1.5` (icon picker selected, badge border), `2` (swatch selected), `3` (swatch selected category form) | |
| `dividerTheme` | thickness 0.5, space 1, `grey.shade100` / `#2A2A2A` | `app_theme.dart:128-132, 230-234` |
| Elevation | `appBarTheme` 0, `scrolledUnderElevation` 0; `cardTheme` 0; `navigationBarTheme` 0; FAB **2** | `app_theme.dart:74-75,109,103,118` |
| BoxShadow | chỉ ở splash logo glow (blur 24–44 / 60), splash progress (blur 6), swatch selected (blur 6 / 4), pulse badge dead code | `splash_screen.dart:424-437`, `category_form_sheet.dart:187-191` |
| Gradient | balance card `[darken(primary,0.22) → primary]` topLeft→bottomRight (`summary_card.dart:48-52`); net worth card `[primary, primary]` (gradient đồng màu, `wallets_screen.dart:167-171`); ShaderMask trắng→trắng 75% trên số dư (`:69-78`); splash progress `[#F06292 → #CE93D8]` | |
| Opacity text trên nền tối | `Colors.white70` (label), `white60` (caption), `white.withValues(0.2)` track | `summary_card.dart:66,105,187,191,235` |
| Glass (fancy) | `GlassQuality.standard` (theme/interactive), `premium` (focal: nav bar, welcome card); `LiquidRoundedSuperellipse(borderRadius 18/22/28)` | `app_glass_policy.dart:8-13`, `welcome_screen.dart:163,241,309` |

## 6. Icon

| Bộ | Số icon khác nhau | Kích thước phổ biến |
|---|---|---|
| `LucideIcons.*` | 68 | 18 (×54 — leading Settings, action AppBar), 16 (×28 — inline, trash/pencil), 20 (×24), 14 (×11), 13, 48 (×8 — empty state), 22, 26, 12, 10, 8 |
| `Icons.*` Material | ~38 | `add` 28 (FAB), 14–18 (inline); nav icon 26; `chevron_right` 18; `visibility_*` 20/16 |

Ánh xạ category `iconName → LucideIcons` (`category_icons.dart:4-23`): 15 case + default `circleEllipsis`. **Lỗi**: `WalletType.iconName` trả `'wallet'|'landmark'|'smartphone'|'credit_card'|'trending_up'|'more_horiz'` (`wallet.dart:21-28`) — **không có case nào** trong `categoryIcon()` → mọi ví hiển thị icon `circleEllipsis` (dùng ở `wallets_screen.dart:314,451`, `wallet_detail_screen.dart:269`, `wallet_form_sheet.dart:277`, `add_transaction_sheet.dart:737,808`).

Emoji dùng làm icon: `⚠️` (dialog icon, "Vượt hạn", "Âm"), `🔴`, `✅ ❌ 🔔 💸 ⏰` (snackbar/notification), `💸` (AuthScreen).

## 7. Theme mode & cách switch

| Mode | Cách chọn | Lưu | Ảnh hưởng |
|---|---|---|---|
| `ThemeMode.system/light/dark` | Settings › Giao diện › 3 `_ThemeTile` (`settings_screen.dart:161-187`) | `theme_mode` (int index) `theme_provider.dart:37` | `MaterialApp.router.themeMode` (`app.dart:38`). Splash tự resolve bằng `themeModeProvider` + `platformBrightness` (`splash_screen.dart:52-58`) |
| Màu chủ đạo (5 seed) | Settings › Màu chủ đạo → `_ThemeColorSheet` ListTile (`:1339-1360`) | `theme_color_scheme` (enum name) | rebuild `lightThemeProvider/darkThemeProvider` |
| Đồ hoạ Normal / Fancy | Welcome trang 2 (`welcome_screen.dart:108-116`) và Settings › Đồ hoạ → `_VisualModeSheet` (`:1269-1310`) | `app_visual_mode` | `AppShell`: nền `AuroraThemeBackground` + `GlassTabBar` + `GlassButton` FAB + `extendBody` + scaffold trong suốt (`app_bottom_nav.dart:35-97`); Settings thêm bottom padding (`settings_screen.dart:36-37`). **Welcome luôn dùng Aurora + glass** bất kể mode (`welcome_screen.dart:94`) |
| Glass quality | tự động adaptive `minimal…premium`, lưu `spendo_adaptive_glass_quality` | `main.dart:31-56` | |

**Dark mode coverage**: các nơi dùng `Colors.grey.shadeXXX`/`Colors.white` cố định (mục 1.4) và bảng màu splash không đổi theo scheme; `MonthPickerSheet` chọn tháng dùng `textColor = Colors.white` trên `cs.primary` (`month_picker_sheet.dart:124`).

## 8. Motion tokens (`lib/shared/widgets/motion/motion_spec.dart:6-15`)

| Token | Giá trị | Dùng ở |
|---|---|---|
| `tapDownDuration` | 100ms | PressableScale nhấn |
| `tapUpDuration` | 140ms | PressableScale thả, chip AnimatedContainer, icon switch |
| `valueDuration` | 360ms | AnimatedMoneyText, AnimatedProgressBar, stats summary |
| `listDuration` | 260ms | MotionListItem, expand/collapse, reminder tile |
| `chartDuration` | 380ms | fl_chart swap, stats state transition |
| `screenDuration` | 420ms | AnimatedSwitcher title search / list ↔ empty |
| `staggerShort` | 30ms × index (max 6) | MotionListItem |
| curve | `easeOutCubic` (standard), `easeInOutCubic` (layout), `fastOutSlowIn` (material) | |
| `PressableScale.scale` | 0.96 | |

**Ngoài spec** (hard-code): 150ms ×9 (chip form, tab btn), 120ms (month cell), 200ms (Hôm nay btn), 280ms (nav pill, easeOutBack icon 1.0→1.22), 300ms (ensureVisible chip, splash switcher), 360/420ms (welcome), 400ms (wallet carousel autoplay 3s), 1100/1800/450/350ms (splash), 1200ms (pulse badge dead), 24s (aurora loop).
