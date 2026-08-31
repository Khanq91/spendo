# 00 — Tổng quan hiện trạng UI (AS-IS)

> Nguồn: đọc trực tiếp toàn bộ `lib/` (114 file Dart, 22.478 LOC — `find lib -name "*.dart" | wc -l`), `android/app/src/main/res/layout/*.xml`, `pubspec.yaml`. Phiên bản app: `1.7.26+31` (`pubspec.yaml:19`).
> Screenshot trong `screenshots/0x_*.png` **đã lỗi thời**: ảnh cho thấy 4 tab (Tổng quan/Giao dịch/Thống kê/Cài đặt) nhưng code hiện tại chỉ có 3 tab (`lib/shared/widgets/app_bottom_nav.dart:25-29`). Tài liệu này lấy code làm chuẩn.

## 1. Stack UI

| Hạng mục | Giá trị | Nguồn |
|---|---|---|
| Framework | Flutter, SDK `^3.7.2` | `pubspec.yaml:22` |
| Design system | Material 3 (`useMaterial3: true`) + `ColorScheme.fromSeed` với 5 seed chọn được | `lib/core/theme/app_theme.dart:58-69`, `:7-40` |
| Lớp hiệu ứng tuỳ chọn | `liquid_glass_widgets ^0.21.3` (chế độ "Xịn xò": GlassTabBar, GlassButton, GlassContainer, nền Aurora) | `pubspec.yaml:53`, `app_bottom_nav.dart:170-211`, `aurora_theme_background.dart` |
| State | `flutter_riverpod ^2.5.1` (StreamProvider/StateProvider, không dùng codegen ở tầng UI) | `pubspec.yaml:46` |
| Điều hướng | `go_router ^14.2.7` (10 route phẳng, không ShellRoute) + `Navigator.push` cho 2 màn + `showModalBottomSheet` cho ~18 sheet | `lib/core/router/app_router.dart:17-59` |
| Icon | `lucide_icons_flutter` (68 icon khác nhau) **lẫn** Material `Icons.*` (≈38 icon) | grep toàn `lib/` |
| Chart | `fl_chart ^0.68.0` (PieChart, BarChart) | `stats_screen.dart:404,588,714` |
| Font | **Không có custom font**. Chỉ `fontFamily: 'serif'` ở logo splash và `'monospace'` ở debug panel | `splash_screen.dart:288`, `reminders_screen.dart:538` |
| Localization | **Không có `.arb`/`l10n.yaml`**. Toàn bộ chuỗi UI hard-code tiếng Việt trong widget. `MaterialApp.router` ép `locale: vi_VN` (delegates chỉ cho widget Material) | `lib/app.dart:40-49` |
| Asset | Duy nhất `assets/icons/app_logo.jpg` (+ `assets/images/.gitkeep` rỗng) | `pubspec.yaml:143-145` |
| Motion | Bộ primitive tự viết `lib/shared/widgets/motion/` (MotionSpec, PressableScale, AnimatedMoneyText, AnimatedProgressBar, SkeletonBlock, MotionListItem) — có respect `disableAnimations` | `motion_spec.dart:29-37` |
| Theme mode | System / Light / Dark (SharedPreferences `theme_mode`) + 5 màu chủ đạo (`theme_color_scheme`) + 2 chế độ đồ hoạ Normal/Fancy (`app_visual_mode`) | `theme_provider.dart:37-38`, `visual_mode_provider.dart:16` |

### Điểm cấu trúc đặc biệt
- **Hai `MaterialApp` lồng nhau**: `main.dart:66-73` tạo `MaterialApp(theme: colorSchemeSeed 0xFFF06292, home: SplashScreen)`; SplashScreen → StartupGate → `SpendoApp` (`app.dart:33`) lại là một `MaterialApp.router` khác với theme thật của user. Hệ quả: Splash & Welcome dùng theme hồng cố định, không phải theme user chọn.
- **Tab shell không nằm trong router**: `AppShell` (`app_bottom_nav.dart:15`) là 1 route `/` chứa `IndexedStack` 3 màn. Các route `/transactions`, `/settings` là bản **push riêng** của cùng widget, mất bottom nav khi vào từ Home grid.
- **Route `/add` là "route giả"**: `_AddTransactionPage` (`app_router.dart:65-107`) render `AppShell` rồi mở sheet trong `postFrameCallback`, đóng sheet thì `context.go('/')`.

## 2. Số lượng

| Loại | Số lượng | Ghi chú |
|---|---|---|
| Màn hình có `Scaffold` (full page) | 16 | trong đó `AuthScreen` **không được tham chiếu** ở đâu (dead code) |
| Bottom sheet | 18 | 6 là class công khai, 12 là class private trong file màn hình |
| AlertDialog | 17 vị trí | xoá/xác nhận/cảnh báo ngân sách/ví âm/chọn màu/restore |
| Component công khai tái sử dụng (dùng ≥2 nơi) | 14 | xem `03-components.md` |
| Widget công khai **không được dùng** (dead) | 6 | `AuthScreen`, `GlobalFab`+`showAddTransactionSheet`, `BudgetCard`, `LoanMiniCard`, `LoanSettingsTile`, `QuickActionsBar` (grep không có import ngoài file định nghĩa) |
| Component private trùng chức năng | ≥5 nhóm | pill-chip ×7 bản, drag-handle ×15 bản inline, section header ×3, empty state ×6, progress bar ×5 — chi tiết ở `06-inconsistencies.md` |
| Android home widget (native) | 2 | `widget_layout_small.xml`, `widget_layout_medium.xml` |

## 3. Cây thư mục phần UI

```
lib/
├── main.dart                      # MaterialApp #1 (splash host), LiquidGlassWidgets.wrap, Workmanager
├── app.dart                       # SpendoApp = MaterialApp.router (#2), theme thật, locale vi_VN
├── core/
│   ├── router/app_router.dart     # GoRouter 10 route + _AddTransactionPage
│   ├── theme/
│   │   ├── app_theme.dart         # AppColorScheme enum (5 seed), AppTheme.light/dark
│   │   ├── app_colors.dart        # palette 15 hex cho category/wallet/loan picker
│   │   ├── app_glass_policy.dart  # GlassQuality policy cho liquid glass
│   │   ├── theme_provider.dart    # ThemeMode + scheme (SharedPreferences)
│   │   └── visual_mode_provider.dart # normal | fancy
│   ├── utils/
│   │   ├── category_icons.dart    # iconName → LucideIcons (16 case)
│   │   ├── currency_formatter.dart# formatVND → "1.234.567 ₫"
│   │   └── date_helpers.dart      # "Tháng M/YYYY", "Hôm nay/Hôm qua/d/M/yyyy", "HH:mm"
│   └── notifications/notification_service.dart # điều hướng từ notification → /add?…
├── shared/widgets/
│   ├── app_bottom_nav.dart        # AppShell + _SpendoNavBar + _FancySpendoNavBar + FAB
│   ├── aurora_theme_background.dart # nền blob động (fancy)
│   ├── category_icon.dart         # CategoryIconWidget (vòng tròn màu 15%)
│   ├── global_fab.dart            # [DEAD]
│   ├── splash_screen.dart         # Splash + progress + retry
│   ├── visual_mode_picker.dart    # 2 tile chọn Normal/Fancy
│   └── motion/                    # motion_spec, pressable_scale, animated_money_text,
│                                  # animated_progress_bar, motion_list_item, skeleton_block,
│                                  # skeleton_transaction_item, motion.dart (barrel)
└── features/
    ├── auth/presentation/screens/auth_screen.dart            # [DEAD]
    ├── onboarding/presentation/{startup_gate,welcome_screen}.dart
    ├── home/presentation/
    │   ├── screens/{home_screen,all_features_screen}.dart
    │   └── widgets/{summary_card,wallet…(ở wallets),feature_grid,home_feature_actions,
    │               month_selector,month_picker_sheet}.dart
    ├── transactions/presentation/
    │   ├── screens/{transactions_screen,note_picker_screen}.dart
    │   └── widgets/{add_transaction_sheet,transaction_detail_sheet,transaction_list_item,
    │               grouped_transaction_sliver,numpad,amount_input_controller}.dart
    ├── categories/presentation/widgets/category_form_sheet.dart
    ├── stats/presentation/{screens/stats_screen,widgets/{stats_time_selector,date_range_picker_sheet}}.dart
    ├── budget/presentation/
    │   ├── screens/{budget_screen,category_budget_screen}.dart   # thực chất là bottom sheet
    │   └── widgets/{budget_card[DEAD],budget_type_sheet}.dart
    ├── wallets/presentation/
    │   ├── screens/{wallets_screen,wallet_detail_screen}.dart
    │   └── widgets/{wallet_card_home,wallet_form_sheet}.dart
    ├── loan/presentation/
    │   ├── screens/{loan_list_screen,loan_detail_screen}.dart
    │   └── widgets/{loan_form_sheet,loan_mini_card[DEAD],loan_settings_tile[DEAD],quick_actions_bar[DEAD]}.dart
    ├── reminders/presentation/{screens/reminders_screen,widgets/reminder_form_sheet}.dart
    ├── habits/presentation/providers/habit_provider.dart      # chỉ provider, UI nằm trong reminders_screen
    └── settings/presentation/
        ├── screens/settings_screen.dart
        └── widgets/{gdrive_backup_section,sepay_connection_section,widget_pin_section}.dart
android/app/src/main/res/layout/widget_layout_{small,medium}.xml   # home widget native
```

## 4. Bảng màn hình

Độ phức tạp: **thấp** (<250 LOC, ≤2 state), **TB** (250–600 LOC hoặc nhiều state async), **cao** (>600 LOC hoặc ≥3 luồng async/dialog).

### 4.1 Màn hình full-page (có `Scaffold`)

| # | Screen | Route / cách vào | File | LOC | Độ phức tạp |
|---|---|---|---|---|---|
| 01 | Splash | `MaterialApp.home` (không route) | `lib/shared/widgets/splash_screen.dart` | 595 | TB |
| 02 | StartupGate | `pushReplacement` từ Splash | `lib/features/onboarding/presentation/startup_gate.dart` | 39 | thấp |
| 03 | Welcome (onboarding 3 trang) | từ StartupGate khi chưa hoàn tất | `lib/features/onboarding/presentation/welcome_screen.dart` | 320 | TB |
| 04 | AppShell (bottom nav + FAB) | `/` | `lib/shared/widgets/app_bottom_nav.dart` | 368 | TB |
| 05 | Home | tab index 1 trong AppShell (mặc định) | `lib/features/home/presentation/screens/home_screen.dart` (+ `summary_card.dart` 365, `wallet_card_home.dart` 259, `feature_grid.dart` 89, `home_feature_actions.dart` 228, `month_selector.dart` 133) | 185 (+1074) | cao |
| 06 | Transactions | tab index 0 **và** route `/transactions` | `lib/features/transactions/presentation/screens/transactions_screen.dart` | 364 | TB |
| 07 | Settings | tab index 2 **và** route `/settings` | `lib/features/settings/presentation/screens/settings_screen.dart` (+ 3 section widget 1098 LOC) | 1366 | cao |
| 08 | AllFeatures | `/features` | `lib/features/home/presentation/screens/all_features_screen.dart` | 49 | thấp |
| 09 | Stats | `/stats` | `lib/features/stats/presentation/screens/stats_screen.dart` | 964 | cao |
| 10 | Reminders | `/reminders` | `lib/features/reminders/presentation/screens/reminders_screen.dart` | 830 | cao |
| 11 | Wallets | `/wallets` | `lib/features/wallets/presentation/screens/wallets_screen.dart` | 509 | TB |
| 12 | WalletDetail | `/wallets/:id` | `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` | 568 | TB |
| 13 | LoanList | `/loans?type=borrowed\|lent` | `lib/features/loan/presentation/screens/loan_list_screen.dart` | 272 | thấp |
| 14 | LoanDetail | `Navigator.push(MaterialPageRoute)` từ LoanList | `lib/features/loan/presentation/screens/loan_detail_screen.dart` | 704 | cao |
| 15 | NotePicker | `Navigator.push(MaterialPageRoute)` từ AddTransactionSheet | `lib/features/transactions/presentation/screens/note_picker_screen.dart` | 375 | TB |
| 16 | Auth | **KHÔNG có route, không được gọi** | `lib/features/auth/presentation/screens/auth_screen.dart` | 237 | thấp (dead) |

### 4.2 Bottom sheet

| # | Sheet | Mở từ | File | LOC | Độ phức tạp |
|---|---|---|---|---|---|
| 17 | AddTransactionSheet | FAB, Home grid "Thêm", route `/add`, notification, widget, edit từ detail | `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart` | 1061 | cao |
| 18 | TransactionDetailSheet | tap row giao dịch | `…/widgets/transaction_detail_sheet.dart` | 245 | thấp |
| 19 | _WalletPickerSheet | chip ví trong AddTransactionSheet | trong `add_transaction_sheet.dart:757-828` | 72 | thấp |
| 20 | CategoryFormSheet | Settings › Danh mục › Thêm/sửa | `lib/features/categories/presentation/widgets/category_form_sheet.dart` | 292 | TB |
| 21 | WalletFormSheet | Wallets +, WalletDetail ✎, Home wallet CTA | `lib/features/wallets/presentation/widgets/wallet_form_sheet.dart` | 480 | TB |
| 22 | LoanFormSheet | LoanList +, LoanDetail ✎ | `lib/features/loan/presentation/widgets/loan_form_sheet.dart` | 382 | TB |
| 23 | _AddPaymentSheet | LoanDetail "Ghi nhận thanh toán" | trong `loan_detail_screen.dart:543-704` | 162 | thấp |
| 24 | ReminderFormSheet | Reminders +, preset, habit, edit | `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart` | 519 | TB |
| 25 | BudgetTypeSheet | Home grid "Hạn mức" | `lib/features/budget/presentation/widgets/budget_type_sheet.dart` | 149 | thấp |
| 26 | BudgetScreen (hạn mức tháng) | BudgetTypeSheet opt 1, AllFeatures | `lib/features/budget/presentation/screens/budget_screen.dart` | 205 | thấp |
| 27 | CategoryBudgetScreen | BudgetTypeSheet opt 2, AllFeatures | `lib/features/budget/presentation/screens/category_budget_screen.dart` | 529 | TB |
| 28 | _SetCategoryBudgetSheet | CategoryBudgetScreen "Đặt"/✎ | trong `category_budget_screen.dart:339-529` | 191 | thấp |
| 29 | MonthPickerSheet | tap label tháng (Home/Transactions/WalletDetail) | `lib/features/home/presentation/widgets/month_picker_sheet.dart` | 163 | thấp |
| 30 | DateRangePickerSheet | tap label thời gian ở Stats | `lib/features/stats/presentation/widgets/date_range_picker_sheet.dart` | 266 | thấp |
| 31 | _VisualModeSheet | Settings › Đồ hoạ | trong `settings_screen.dart:1269-1310` | 42 | thấp |
| 32 | _ThemeColorSheet | Settings › Màu chủ đạo | trong `settings_screen.dart:1312-1366` | 55 | thấp |
| 33 | _AddMappingSheet (SePay) | Settings › Thêm tài khoản ngân hàng | trong `sepay_connection_section.dart:215-420` | 206 | TB |
| 34 | _CategoryPickerSheet (widget pin) | Settings › Widget slot | trong `widget_pin_section.dart:180-268` | 89 | thấp |

### 4.3 Native

| # | Screen | File | Ghi chú |
|---|---|---|---|
| 35 | Android widget small (2×1) | `android/app/src/main/res/layout/widget_layout_small.xml` | 1 nút "+ Thêm chi tiêu" |
| 36 | Android widget medium (2×2) | `android/app/src/main/res/layout/widget_layout_medium.xml` | 4 ô danh mục (emoji + tên) |
| — | iOS widget | `[UNKNOWN: không tìm thấy target widget iOS trong repo]` | |

## 5. Component tái sử dụng (đếm nhanh; chi tiết ở 03)

**Dùng ≥2 màn hình (14):** `PressableScale`, `AnimatedMoneyText`, `AnimatedProgressBar`, `SkeletonBlock`, `SkeletonTransactionItem`, `MotionListItem`, `CategoryIconWidget`, `MonthSelector` (+`MonthPickerSheet`), `GroupedTransactionSliver` (+`TransactionListItem`), `Numpad` (+`AmountInputController`), `FeatureGrid`, `VisualModePicker`, `AuroraThemeBackground`, `BudgetTypeSheet`.

**Dùng 1 nơi nhưng public (10):** `SummaryCards`, `WalletProgressBar` (export nhưng **không ai import** — grep chỉ thấy định nghĩa), `WalletCardHome`, `StatsTimeSelector`, `DateRangePickerSheet`, `GDriveBackupSection`, `SepayConnectionSection`, `WidgetPinSection`, `TransactionDetailSheet`, `SplashScreen`.

**Dead (6):** `AuthScreen`, `GlobalFab`/`showAddTransactionSheet`, `BudgetCard`, `LoanMiniCard`, `LoanSettingsTile`, `QuickActionsBar`.
