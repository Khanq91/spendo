# 03 — Component tái sử dụng (AS-IS)

> Chỉ liệt kê widget **được dùng ở ≥2 vị trí** hoặc là primitive chung. Widget public dùng 1 nơi và widget private được mô tả trong file màn hình tương ứng. Phần cuối liệt kê các pattern **bị cài đặt lặp** (không có component chung).

---

## 1. `PressableScale`
- **File**: `lib/shared/widgets/motion/pressable_scale.dart`
- **Mô tả**: Bọc child, thu nhỏ khi nhấn; tuỳ chọn tự xử lý tap hoặc chỉ quan sát pointer.
- **Props**: `child` (bắt buộc), `onTap` (null), `enabled` (true), `scale` (0.96), `borderRadius` (null → không clip), `behavior` (`HitTestBehavior.opaque`), `haptic` (false → `selectionClick`), `deferTapToChild` (false).
- **Anatomy**: `MouseRegion(cursor)` → [`ClipRRect(borderRadius)`] → `GestureDetector` **hoặc** `Listener` (khi defer) → `AnimatedScale(scale)` → child.
- **States**: default (scale 1) · pressed (scale 0.96, 100ms `tapDownDuration`) · released (1, 140ms) · disabled (`enabled=false` hoặc không onTap và không defer → không scale, cursor defer) · reduce-motion (không scale, duration 0).
- **Kích thước**: theo child.
- **Dùng ở**: `feature_grid.dart:51`, `transaction_list_item.dart:27`, `transactions_screen.dart:245` (_FilterChip), `wallet_detail_screen.dart:466` (_FilterChip), `add_transaction_sheet.dart:467` (ChoiceChip defer), `:1037` (_TypeToggle), `reminders_screen.dart:642, 240`, `app_bottom_nav.dart:71, 86` (FAB defer), `visual_mode_picker.dart:122, 136`.

## 2. `AnimatedMoneyText`
- **File**: `lib/shared/widgets/motion/animated_money_text.dart`
- **Mô tả**: Text số tiền tween từ giá trị cũ → mới, tabular figures; hỗ trợ mask riêng tư.
- **Props**: `value` (num), `formatter` (num→String), `style` (null → DefaultTextStyle), `privacyMask` (null), `animate` (true), `textAlign`, `overflow`.
- **Anatomy**: `TweenAnimationBuilder<double>(Tween(end: value), 360ms, easeOutCubic)` → `Text(formatter(v), style + FontFeature.tabularFigures)`. Nếu `!animate || masked || reduceMotion` → `Text` tĩnh.
- **States**: animating · masked (hiện `privacyMask`, không animate) · static.
- **Dùng ở**: `summary_card.dart:79, 333`, `transactions_screen.dart:303, 313`, `stats_screen.dart:225, 327`, `wallets_screen.dart:201, 338`, `wallet_detail_screen.dart:312`, `add_transaction_sheet.dart:415`.
- **Không dùng ở** (Text thường): `_DayHeader`, `TransactionListItem`, `TransactionDetailSheet`, `LoanDetail`, `BudgetScreen`, `WalletFormSheet`, `LoanFormSheet`, `_AddPaymentSheet`, `_SetCategoryBudgetSheet`.

## 3. `AnimatedProgressBar`
- **File**: `lib/shared/widgets/motion/animated_progress_bar.dart`
- **Mô tả**: `LinearProgressIndicator` tween giá trị, bo góc, có semantics.
- **Props**: `value` (0..1, clamp), `height` (8), `trackColor` (null → `surfaceContainerHighest`), `valueColor` (null → `primary`), `borderRadius` (999), `semanticLabel` (null).
- **Anatomy**: `Semantics(label, value '%')` → `ClipRRect` → `SizedBox(height)` → `TweenAnimationBuilder` → `LinearProgressIndicator(minHeight)`.
- **States**: animating 360ms · reduce-motion (0ms).
- **Dùng ở**: `category_budget_screen.dart:270` (h4), `add_transaction_sheet.dart:872` (h3, 48 wide), `loan_detail_screen.dart:485` (h6), `wallet_detail_screen.dart:369` (h6), `budget_card.dart:232, 331` (dead).
- **Không dùng ở**: `summary_card._WalletProgressBar` (Stack+FractionallySizedBox tự vẽ), `wallets_screen._DarkProgressBar` (tự vẽ), `splash._ProgressBar`.

## 4. `SkeletonBlock` / `SkeletonTransactionItem`
- **File**: `motion/skeleton_block.dart`, `motion/skeleton_transaction_item.dart`
- **Mô tả**: Khối placeholder pulse (không shimmer).
- **Props** `SkeletonBlock`: `width` (null), `height` (14), `borderRadius` (8). `SkeletonTransactionItem`: không props.
- **Anatomy**: `AnimationController 1100ms repeat(reverse)` → `DecoratedBox(color lerp surfaceContainerHighest α.55↔.9)` → `SizedBox`. Transaction item: `Padding(H16 V10) Row[Block 42×42, 12, Column[120×14, 8, 72×12], 86×14]`.
- **States**: pulsing · reduce-motion (tĩnh α.55).
- **Dùng ở**: `home_screen.dart:180` (4 item), `wallets_screen.dart:99-141` (card 126 + 3 tile), `stats_screen.dart:109-113, 898-906`.
- **Không dùng ở**: Transactions (không loading), Reminders/LoanList/LoanDetail/WalletDetail (spinner).

## 5. `MotionListItem`
- **File**: `motion/motion_list_item.dart`
- **Props**: `child`, `index` (0), `enabled` (true), `offset` (0,10).
- **Anatomy**: `TweenAnimationBuilder(0→1, listDuration 260ms + 30ms×min(index,6))` → `Opacity` → `Transform.translate(offset×(1−v))`.
- **Dùng ở**: chỉ `grouped_transaction_sliver.dart:53`.

## 6. `MotionSpec` / `appMotion`
- **File**: `motion/motion_spec.dart` — bộ token duration/curve (xem 02 §8) + `shouldReduceMotion(context)` (`disableAnimations || accessibleNavigation`).
- **Dùng ở**: 14 file. Không dùng ở: `app_bottom_nav._NavButton`, `aurora_theme_background`, `splash_screen`, `welcome_screen`, `month_picker_sheet`, `month_selector`, `note_picker_screen`, mọi form sheet (150ms cứng).

## 7. `CategoryIconWidget`
- **File**: `lib/shared/widgets/category_icon.dart`
- **Props**: `category` (Category?, bắt buộc), `size` (40), `iconSize` (18).
- **Anatomy**: `Container(size, circle, color α.15)` → `Icon(categoryIcon(iconName), iconSize, color)`. Null category → `Colors.grey` + `circleEllipsis`.
- **Dùng ở**: `transaction_list_item.dart:49` (40/18), `transaction_detail_sheet.dart:53` (56/26).
- **Không dùng ở** (tự vẽ box vuông r8/r10 thay vì tròn): `settings_screen._CategoryTile` (36 r8), `category_budget_screen` (40 r10 / 32 r8), `widget_pin_section` (36 r8; slot card), `note_picker._CategoryChip`, `reminder_form_sheet` chip, `stats._LegendRow` (dot 12), `budget_card`.

## 8. `MonthSelector` + `MonthPickerSheet`
- **File**: `lib/features/home/presentation/widgets/month_selector.dart`, `month_picker_sheet.dart`
- **Props** `MonthSelector`: `month` (DateTime), `onPrev`, `onNext`, `onMonthPicked` — tất cả bắt buộc. `MonthPickerSheet`: `selected`.
- **Anatomy**: `Row(min, center)[IconButton ‹ (compact), GestureDetector(Container pad H8 V4 r8 bg primary α.06 [Text 'Tháng M/YYYY' 15 w600, 2, arrow_drop_down 18]), IconButton › (disabled tháng hiện tại, màu grey.shade300), AnimatedSwitcher(chip 'Hôm nay' 11 w600 primary bg α.1 border α.3 r20 | shrink)]`.
- **States**: current month (› disabled, không chip) · past month (› enabled, chip hiện) · **future month**: không chặn ở `onNext` (chỉ disable ở tháng hiện tại) nhưng Home không thể tới tương lai vì disable; WalletDetail cũng vậy.
- **Dùng ở**: `home_screen.dart:35` (AppBar title), `transactions_screen.dart:76` (AppBar title), `wallet_detail_screen.dart:437` (trong body, dưới filter chip).
- **Tương đương nhưng khác**: `StatsTimeSelector` (`stats_time_selector.dart`) — cùng anatomy nhưng có mode custom, dùng `DateRangePickerSheet` thay `MonthPickerSheet`, dùng `appMotion` (MonthSelector dùng 200ms cứng).

## 9. `GroupedTransactionSliver` + `TransactionListItem`
- **File**: `lib/features/transactions/presentation/widgets/grouped_transaction_sliver.dart`, `transaction_list_item.dart`
- **Props** Sliver: `transactions` (List), `categoryMap` (Map<String,Category>), `style` (`plain` | `filledHeader`, mặc định plain), `animateItems` (true). Item: `transaction`, `category` (nullable).
- **Anatomy**: `SliverList(SliverChildBuilderDelegate)` với rows phẳng: `_DayHeader` (Padding [Text ngày 12 w600 onSurfaceVariant, Spacer, Text net 12 w500 income/expenseAlt] + `Divider(indent 16)` (plain) hoặc `ColoredBox(surfaceContainerHighest)` (filled)) và `KeyedSubtree(MotionListItem(Column[TransactionListItem, Divider(indent 68) nếu filled]))`.
  `TransactionListItem`: `PressableScale(onTap → TransactionDetailSheet)` → `Padding(H16 V10) Row[Stack[CategoryIconWidget 40, badge SePay 14 #1E88E5 bolt 8], 12, Expanded Column[name 14 w500, note 12 grey500 ellipsis | time 12 grey400], Text amount 14 w600 #F06292/#43A047]`.
- **States**: plain / filledHeader; item automatic badge; category null → 'Không rõ'.
- **Kích thước**: row ≈ 60px; header plain ≈ 33, filled ≈ 29.
- **Dùng ở**: `home_screen.dart:129` (plain), `transactions_screen.dart:142` (filledHeader), `wallet_detail_screen.dart:137` (plain).

## 10. `Numpad` + `AmountInputController`
- **File**: `lib/features/transactions/presentation/widgets/numpad.dart`, `amount_input_controller.dart`
- **Props** Numpad: `onKey(String)`. Controller: `raw`, `value` (int), `hasValue` (>0), `formatted` ("1.234.567" | "0"), `press(key)`, `prefill`, `reset`.
- **Anatomy**: `GridView.count(3 cột, aspect 1.6, shrinkWrap, no scroll)` 12 ô `InkWell > Container(border dividerColor α.15 w.5) > Center(Text 22 w400 | Icon backspace_outlined 20)`. Không có phím "." / "," / "=" / "xoá hết" / "xong".
- **Logic**: max 10 chữ số; không leading 0; `00` chỉ khi đã có số và ≤8 chữ số.
- **Kích thước**: cao = 4 × (W/3 ÷ 1.6) ≈ 4×75 = 300 @ W=360; 4×100 = 400 @ W=480.
- **Dùng ở**: `add_transaction_sheet.dart:619`, `budget_screen.dart:153`, `category_budget_screen.dart:477`, `wallet_form_sheet.dart:438`, `loan_form_sheet.dart:336`, `loan_detail_screen.dart:653` (_AddPaymentSheet).
- **Không dùng ở**: `reminder_form_sheet` (TextField number), `sepay _AddMappingSheet`.

## 11. `FeatureGrid` / `FeatureGridAction`
- **File**: `lib/features/home/presentation/widgets/feature_grid.dart`
- **Props**: `actions` (List<FeatureGridAction{label, icon, color, onTap}>).
- **Anatomy**: `GridView.builder(4 cột, mainAxisExtent 102, spacing 10/6, shrinkWrap)` → `_FeatureTile`: `PressableScale(r12) > SizedBox(102) Column(center)[Container 56 circle color α.12 (Icon 26 color), 10, Text label 12 w600 h1.15 center 2 dòng ellipsis]`.
- **States**: pressed; không disabled/badge.
- **Dùng ở**: `home_screen.dart:87`, `all_features_screen.dart:42`.

## 12. `VisualModePicker`
- **File**: `lib/shared/widgets/visual_mode_picker.dart`
- **Props**: `selectedMode`, `onChanged`, `useGlass` (false).
- **Anatomy**: `Column(min)[_VisualModeTile normal, 12, _VisualModeTile fancy]`; tile = `PressableScale(r22|r12) > GlassContainer(superellipse 22) | AnimatedContainer(260ms, bg primaryContainer α.5 | surface)` → `Padding(H16 V14) Row[Icon 22, 12, Column[title 15 w700, 4, subtitle 12 h1.25], 12, AnimatedSwitcher(circleCheck|circle 20)]`.
- **Dùng ở**: `welcome_screen.dart:110` (glass), `settings_screen.dart:1298` (non-glass).

## 13. `AuroraThemeBackground`
- **File**: `lib/shared/widgets/aurora_theme_background.dart`
- **Props**: không.
- **Anatomy**: `LayoutBuilder > MouseRegion > Listener > RepaintBoundary > AnimatedBuilder > CustomPaint(_AuroraMeshPainter)`: nền `scaffoldBackgroundColor` + 4 blob radial (`cs.primary/secondary/tertiary/primary`, radius 0.46–0.70 × shortest, α .38 light / .55 dark, `BlendMode.plus` dark) + overlay LinearGradient trắng α.10/.03. Controller 24s loop; parallax lerp 0.06 theo accelerometer (`maxTilt 4.0`) hoặc pointer.
- **States**: light / dark; không reduce-motion.
- **Dùng ở**: `app_bottom_nav.dart:42` (fancy), `welcome_screen.dart:94` (luôn).

## 14. `BudgetTypeSheet`
- Xem `04-screens/22`. Dùng ở `home_feature_actions.dart:210` (+ 2 dead).

## 15. Widget public dùng 1 nơi (tham chiếu)
| Widget | File | Dùng ở |
|---|---|---|
| `SummaryCards` | `home/widgets/summary_card.dart` | Home |
| `WalletProgressBar` (export) | cùng file `:257-278` | **không ai dùng** |
| `WalletCardHome` | `wallets/widgets/wallet_card_home.dart` | Home |
| `StatsTimeSelector`, `DateRangePickerSheet` | `stats/widgets/` | Stats |
| `TransactionDetailSheet` | `transactions/widgets/` | qua TransactionListItem |
| `GDriveBackupSection`, `SepayConnectionSection`, `WidgetPinSection` | `settings/widgets/` | Settings |
| `SplashScreen` | `shared/widgets/` | main |
| `CategoryFormSheet`, `WalletFormSheet`, `LoanFormSheet`, `ReminderFormSheet`, `AddTransactionSheet` | | form |

---

## 16. Pattern bị cài đặt lặp (không có component chung)

### 16.1 Drag handle (15 bản inline)
`Container(width 36, height 4, color cs.outlineVariant, r2)` với margin khác nhau: `margin V10` (add_transaction, budget, category_budget ×2, wallet_picker, widget_pin picker), `margin B16` (month_picker, budget_type, transaction_detail — dùng **grey.shade300**), `margin B12` (date_range), `SizedBox(16)` sau (category_form, wallet_form, loan_form, reminder_form, add_payment), **40×4** (sepay). Thiếu ở `_VisualModeSheet`, `_ThemeColorSheet`.

### 16.2 Pill chip chọn (7 cài đặt riêng)
| Class | File | Pad | Radius | Font | Có icon | Animation |
|---|---|---|---|---|---|---|
| `_FilterChip` | transactions_screen | H12 V4 (trong box 48) | 20 | 12 | không | 140ms |
| `_FilterChip` | wallet_detail_screen | H12 V6 | 20 | 12 | không | 140ms |
| `_TabChip` | settings_screen | H10 V4 (InkWell 48) | 20 | 12 | không | 140ms |
| `_TypeToggle` | add_transaction_sheet | H14 V6 | **8** | 13 w600 | không | 140ms |
| `_CategoryChip` | note_picker_screen | H10 V6 | 20 | 12 | icon 13 | 150ms |
| category chip | reminder_form_sheet | H10 V6 | 20 | 12 | icon 14 | 150ms |
| type chip | wallet_form_sheet | H10 V6 | 20 | 12 | icon 13 | 150ms |
| freq chip | reminder_form_sheet | V8 Expanded | 8 | 12 | không | 150ms |
| loan type | loan_form_sheet | V10 Expanded | 10 | 13 w600 | không | 150ms |
| `ChoiceChip` | add_transaction_sheet | H4 | theme 20 | 12 | không | Material |
| preset chip | reminders_screen | H12 V8 | 20 | 13 | add 14 | PressableScale |
| `_SuggestionChip` | note_picker | H12 V7 | 20 | 13 | không | không |
| `_MetaChip` | loan_detail | H8 V4 | 6 | 11 | không | không |
| `_SelectedWalletChip` | add_transaction | H10 V4 | 20 | 12 w600 | icon 12 | không |

### 16.3 Section header (3 bản)
`settings._SectionHeader` (12 w600 ls.5, pad (16,16,8,4)), `loan_list._SectionHeader` (12 w600 ls.4, pad (16,16,16,6), có `muted`), `category_budget._SectionLabel` (**11** w600 ls.5, pad (16,16,16,6)), inline ở reminders (12 w600 ls.5 pad (16,16,16,8)), wallets archived (12 w600 ls.5), all_features (13 w700 pad L2 B8), stats (13 w600).

### 16.4 Empty state (6 bản)
Home (SliverFillRemaining, icon 48 + 2 text), Transactions (`_EmptyState` hasFilter), Wallets (`_EmptyState` + FilledButton), WalletDetail (`_EmptyTx` icon 40), LoanList (`_EmptyState` + button), Reminders (`_EmptyState` ListView + preset), Stats (`_EmptyStats`), NotePicker (text only), LoanDetail payments (text only). Chung: icon 48 outlineVariant, title onSurfaceVariant, sub 12; khác: có/không CTA, padding.

### 16.5 Error state (2 kiểu)
Kiểu A có retry: Home (`_HomeTransactionLoadError`), Transactions, Stats, WalletCardHome. Kiểu B `Center(Text('Lỗi: $e'))` thô: Wallets, WalletDetail (tx), LoanList, LoanDetail, Reminders.

### 16.6 Progress bar (5 bản)
`AnimatedProgressBar` (shared), `summary_card._WalletProgressBar` (Stack, isOnDarkBg), `wallets_screen._DarkProgressBar` (Stack), `wallet_detail._LightProgressBar` (bọc AnimatedProgressBar), `add_transaction._MiniProgressBar` (bọc AnimatedProgressBar + %), `splash._ProgressBar`.

### 16.7 Info card viền màu (2 bản giống nhau)
`wallet_detail._InfoCard` và `loan_detail._InfoCard`: margin (16,16,16,12), pad 16, bg color α.05, border α.3 .8, r16.

### 16.8 Leading icon box (3 kích thước)
36 r8 (Settings, SePay, GDrive, widget picker, category tile), 40 r10 (Wallets, LoanList, CategoryBudget, Reminders), 44 r12 (BudgetType, WalletDetail info), 32 r8 (SetCategoryBudget), 36 r9 (habit), 36 circle (payment), 40 circle (`CategoryIconWidget`), 56 circle (feature tile, detail sheet).

### 16.9 Nút submit sheet (3 style)
`minimumSize(∞,48) r12` (AddTransaction, Budget, SetCategoryBudget); `padding V12 r10` (CategoryForm, WalletForm, LoanForm, ReminderForm, AddPayment); theme mặc định M3 (SePay AddMapping, empty-state `FilledButton.icon`).

### 16.10 Dialog xác nhận xoá (6 bản)
`AlertDialog(title 'Xoá …?', content?, TextButton Huỷ, TextButton Xoá fg expenseColor|expenseAlt)` ở TransactionDetail, WalletDetail, LoanDetail ×2, Settings category, SePay. Không dùng ở: Reminders delete, CategoryBudget delete, Budget delete, Loan close/reopen, Wallet archive.

### 16.11 Loading dialog
`showDialog(barrierDismissible false, Center(CircularProgressIndicator))` ×6 trong Settings/GDrive (không nền, không text).
