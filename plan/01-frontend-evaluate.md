# Audit UI/Motion Spendo - Giữ Liquid Glass

## 1. Phạm vi và nguồn audit

Reading this as: audit UI/motion cho Flutter personal finance app, audience là developer sẽ refactor UI sau audit, platform Android/iOS, visual direction là smooth premium finance UI nhưng giữ Liquid Glass như một phần design system hiện có.

Audit này chỉ đọc code và screenshot hiện có, không sửa UI runtime. Nguồn chính:

- Dependencies: `pubspec.yaml` có `flutter_riverpod`, `go_router`, `powersync`, `supabase_flutter`, `fl_chart`, `lucide_icons_flutter`, `liquid_glass_widgets`.
- Bootstrap: `lib/main.dart:57-62` gọi `LiquidGlassWidgets.initialize()`, `LiquidGlassWidgets.wrap(...)`, `GlassThemeData.simple(quality: GlassQuality.premium)`.
- App/router: `lib/app.dart`, `lib/core/router/app_router.dart:17-52`.
- Shell/nav: `lib/shared/widgets/app_bottom_nav.dart:74-116`, `lib/shared/widgets/app_bottom_nav.dart:211-214`.
- Theme/visual mode: `lib/core/theme/app_theme.dart`, `lib/core/theme/visual_mode_provider.dart`, `lib/shared/widgets/visual_mode_picker.dart`.
- Screenshots đã xem: `screenshots/01_home.png`, `02_transactions.png`, `03_stats.png`, `04_add_transaction.png`, `05_settings.png`.
- Liquid Glass reference theo skill không có trong `.skill/flutter-taste`; file tương tự tồn tại ở `old-plan/ui_plan/LIQUID_GLASS_UI_PLAN-package_liquid_glass_widgets.md`, nhưng bị mojibake. Audit ưu tiên implementation thật trong repo.

## 2. Tổng quan UI hiện tại

Spendo đã có nền tảng UI tốt hơn Flutter mặc định: finance hierarchy rõ, icon/category màu hóa, Material 3 theme, bottom nav tùy biến, feature grid, chart bằng `fl_chart`, và một mode `fancy` dùng Aurora + Liquid Glass. Các màn core đều có empty state cơ bản.

Vấn đề chính không phải thiếu hiệu ứng, mà là motion/data transition chưa có hệ thống. Tiền, progress, chart, filter, list item phần lớn đổi tức thời. Một số list build toàn bộ child sau khi group nên không nên thêm animation/glass dày trước khi tối ưu lazy rendering/key. Settings dài và nhiều section, hợp để polish hierarchy hơn là motion nặng.

Điểm cần chú ý:

- Home/Transactions đang có text/copy trong source bị mojibake ở nhiều file, nhưng screenshot hiển thị đúng. Đây là rủi ro bảo trì, không sửa trong audit.
- `normal/fancy` visual mode đã có, nhưng quality setting `standard/minimal/premium` chưa thấy trong codebase. Not found in codebase.
- Reduce motion/accessibility motion toggle chưa thấy trong codebase. Not found in codebase.
- Glass đang dùng `GlassQuality.premium` ở root/nav/FAB/onboarding; cần giới hạn surface và test thiết bị yếu trước khi mở rộng.

## 3. Inventory màn hình và flow

| Flow | Entry thật | Mục đích | Data động | List/data dense | Glass fit |
|---|---|---:|---:|---:|---:|
| App startup/splash | `lib/main.dart:75`, `lib/shared/widgets/splash_screen.dart` | Init Supabase, PowerSync, notification, widget sync | Cao | Không | 2 |
| Onboarding | `lib/features/onboarding/presentation/welcome_screen.dart:93-109` | Chọn visual mode, GDrive opt-in | Thấp | Không | 5 |
| Shell/Home/Transactions/Settings tabs | `lib/shared/widgets/app_bottom_nav.dart:74-116` | Daily navigation | Trung bình | Không | 5 |
| Home | `lib/features/home/presentation/screens/home_screen.dart:22-126` | Dashboard tháng, summary, ví, feature grid, giao dịch gần đây | Cao | Có | 3 |
| Transactions | `lib/features/transactions/presentation/screens/transactions_screen.dart:33-112` | Search/filter/list giao dịch | Cao | Có | 1 |
| Add Transaction | `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:399-613` | Nhập số tiền/category/note/wallet | Cao | Chip list ngắn | 4 |
| Transaction Detail | `lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart` | Xem/sửa/xóa giao dịch | Trung bình | Không | 4 |
| Note Picker | `lib/features/transactions/presentation/screens/note_picker_screen.dart` | Gợi ý note theo history/category | Trung bình | Wrap chips | 4 |
| Stats | `lib/features/stats/presentation/screens/stats_screen.dart:49-149`, `:220-263` | Chart category/day | Cao | Có | 2 |
| Wallets | `lib/features/wallets/presentation/screens/wallets_screen.dart:19-50` | Net worth và danh sách ví | Cao | Có | 3 |
| Wallet Detail | `lib/features/wallets/presentation/screens/wallet_detail_screen.dart:34-133` | Số dư ví + giao dịch theo ví | Cao | Có | 2 |
| Budget month | `lib/features/budget/presentation/screens/budget_screen.dart` | Đặt hạn mức tháng | Trung bình | Không | 4 |
| Category Budget | `lib/features/budget/presentation/screens/category_budget_screen.dart:31-123` | Hạn mức theo danh mục | Cao | Có | 3 |
| Reminders | `lib/features/reminders/presentation/screens/reminders_screen.dart:22-65` | Nhắc chi tiêu, habit suggestion | Trung bình | Có | 3 |
| Loans | `lib/features/loan/presentation/screens/loan_list_screen.dart` | Theo dõi vay/cho vay | Trung bình | Có | 3 |
| Loan Detail | `lib/features/loan/presentation/screens/loan_detail_screen.dart:26-139` | Khoản vay + lịch sử thanh toán | Cao | Có | 3 |
| Settings | `lib/features/settings/presentation/screens/settings_screen.dart:45-472` | Export, backup, SePay, GDrive, theme, reminders, widget, categories | Trung bình | Dài | 2 |
| All Features | `lib/features/home/presentation/screens/all_features_screen.dart` | Grid tính năng đầy đủ | Thấp | Không | 3 |

## 4. Liquid Glass evaluation

Giữ Liquid Glass, nhưng không mở rộng tràn lan.

Đang hợp lý:

- App bootstrap dùng `LiquidGlassWidgets.initialize()` và `LiquidGlassWidgets.wrap()` ở `lib/main.dart:57-62`.
- Fancy shell dùng `AuroraThemeBackground`, `GlassButton` cho FAB và `GlassTabBar.bottom` cho bottom nav ở `lib/shared/widgets/app_bottom_nav.dart:91-116`, `:211-214`.
- Onboarding dùng `GlassContainer`, `GlassButton.custom`, `LiquidRoundedSuperellipse` ở `lib/features/onboarding/presentation/welcome_screen.dart:157-159`, `:231-235`, `:300-304`.
- Visual mode picker có nhánh glass với `GlassContainer` ở `lib/shared/widgets/visual_mode_picker.dart`.

Không nên mở rộng glass:

- Transaction list dài trong Home/Transactions/Wallet Detail. Home đang dùng `SliverChildListDelegate` từ list widget đã build sẵn ở `lib/features/home/presentation/screens/home_screen.dart:126`; Transactions dùng `ListView(children: [...])` ở `lib/features/transactions/presentation/screens/transactions_screen.dart:111-112`.
- Stats chart area lớn. `PieChart` và `BarChart` ở `lib/features/stats/presentation/screens/stats_screen.dart:115-149`, `:290-337`, `:406-448` nên ưu tiên chart readability.
- Settings dài. `SettingsScreen` là một `ListView` nhiều section ở `lib/features/settings/presentation/screens/settings_screen.dart:45-472`; glass toàn màn sẽ giảm scanability.

Nên tinh chỉnh:

- Thêm quality policy: `normal`, `fancy standard`, `fancy premium` hoặc ít nhất internal token để không hardcode `GlassQuality.premium` ở mọi nơi.
- Với fancy mode, chỉ glass shell/nav/FAB/modal chọn mode/onboarding; sheet nhập liệu chỉ dùng glass nếu backdrop contrast ổn và không gây lag bàn phím.
- Nếu có glass modal, bọc vùng glass nặng bằng `RepaintBoundary` và tránh nhiều `useOwnLayer: true` trong list.

## 5. Scoring và priority

Thang điểm 1-5: `Data Dynamism`, `Interaction Density`, `Visual Priority`, `Motion Benefit`, `Implementation Risk`, `Glass Fit`. `Risk` cao nghĩa là dễ đụng logic/data/perf.

| Screen/Component | Data | Interaction | Visual | Motion Benefit | Risk | Glass Fit | Priority | Refactor level | Ghi chú |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| Home summary cards | 5 | 3 | 5 | 5 | 3 | 3 | A | Level 3 | Tiền/progress đổi tức thời; nên `AnimatedMoneyText` + progress tween. |
| Home transaction section | 5 | 3 | 5 | 4 | 4 | 1 | A | Level 4 | Đổi list/group theo tháng; cần lazy grouped list/key trước khi animation. |
| Transactions filter/list | 5 | 5 | 5 | 5 | 4 | 1 | A | Level 4 | Search/filter/category chip/list là core daily flow. |
| Add Transaction Sheet | 5 | 5 | 5 | 4 | 3 | 4 | A | Level 3 | Amount, type toggle, category auto-select, budget warning nên mượt hơn. |
| Stats | 5 | 3 | 4 | 4 | 3 | 2 | A | Level 3 | Chart/tab/date range cần transition có kiểm soát, không glass chart. |
| Wallets | 5 | 3 | 4 | 4 | 3 | 3 | B | Level 3 | Net worth, wallet balance, archived expand đã có motion nhẹ. |
| Wallet Detail | 5 | 4 | 4 | 4 | 4 | 2 | B | Level 4 | Dùng `SliverChildBuilderDelegate` nhưng vẫn prebuild grouped widgets. |
| Category Budget | 5 | 4 | 4 | 4 | 3 | 3 | B | Level 3 | Progress bar và budget status rất hợp data motion. |
| Loan Detail | 5 | 4 | 4 | 4 | 3 | 3 | B | Level 3 | Paid/remaining/progress nên animate; payment list ít hơn transaction. |
| Reminders | 3 | 4 | 3 | 3 | 2 | 3 | B | Level 2 | Suggestion/toggle/delete cần feedback, không cần redesign. |
| Onboarding | 2 | 3 | 4 | 4 | 2 | 5 | B | Level 2 | Glass đúng chỗ; polish copy/contrast/mode transition. |
| Settings | 3 | 4 | 4 | 2 | 3 | 2 | C | Level 1 | Dài và utilitarian; ưu tiên spacing/section/states. |
| All Features grid | 1 | 3 | 3 | 2 | 1 | 3 | C | Level 1 | Chỉ cần press feedback/stagger nhẹ nếu vào màn. |
| Startup/Splash/Auth | 3 | 1 | 3 | 2 | 3 | 2 | C | Level 1 | Skeleton/progress messaging; auth detail không thấy route trong router. |

## 6. Audit chi tiết theo màn hình/component

| Screen/Component | Current UX issue | Suggested level | Motion technique | Expected benefit | Difficulty | Risk | Priority | Notes |
|---|---|---|---|---|---|---|---|---|
| `SummaryCards` | Số dư/thu/chi đổi tức thời, toggle ẩn/hiện đổi text trực tiếp | Level 3 | `AnimatedMoneyText`, `AnimatedSwitcher`, progress tween | Cảm giác finance premium rõ nhất | Medium | Medium | A | `lib/features/home/presentation/widgets/summary_card.dart`; đang `setState` nội bộ cho visibility. |
| `HomeScreen` list | Grouped list build bằng `SliverChildListDelegate`, item thiếu key explicit | Level 4 | Lazy grouped sliver + `MotionListItem` keyed by `transaction.id` | Filter/tháng/list update dễ hiểu, ít jank hơn | Medium | Medium | A | `home_screen.dart:126`, item ở `:196`. |
| `TransactionsScreen` filter/list | Search toggle snap, filter chip chỉ animate màu, list rebuild toàn bộ children | Level 4 | `AnimatedSwitcher` search/month title, `SliverList`, keyed item enter/fade | Core flow mượt khi tìm/lọc | Medium | Medium | A | `transactions_screen.dart:49-112`, chip `:260`. |
| `AddTransactionSheet` | Amount lớn đổi tức thời; chip height đổi 36/48 có thể shift; submit/loading cơ bản | Level 3 | Rolling amount, `AnimatedSize` chip row, press scale, button state transition | Nhập giao dịch có cảm giác phản hồi tốt | Medium | Medium | A | `add_transaction_sheet.dart:399-613`; auto-scroll category `:264`. |
| `TransactionListItem` | Tap mở detail nhưng không có shared continuity; amount/item không keyed | Level 2/4 | `PressableScale`, optional `Hero` category icon/amount, stable `ValueKey` | Tap rõ hơn, detail sheet cảm giác liên tục | Medium | Medium | A | `transaction_list_item.dart`; tránh glass item. |
| `StatsScreen` | Chart đổi range/tab snap; pie touched radius dùng setState toàn chart | Level 3 | Chart tween, tab shared-axis, value crossfade | Hiểu thay đổi dữ liệu tốt hơn | Medium | Low | A | `stats_screen.dart:122` setState touch; chart refs ở `:115`, `:290`, `:406`. |
| `WalletsScreen` | Net worth và từng wallet balance load bằng spinner nhỏ | Level 3 | `AnimatedMoneyText`, skeleton balance, progress tween | Số dư ví cập nhật mượt | Medium | Low | B | `wallets_screen.dart:91-261`. |
| `WalletDetailScreen` | Filter/month đổi snap; grouped tx list precomputed | Level 4 | Same transaction list system as Transactions | Consistency giữa money views | Medium | Medium | B | `wallet_detail_screen.dart:131-212`. |
| `CategoryBudgetScreen` | Progress và over-budget state đổi tức thời | Level 3 | `TweenAnimationBuilder<double>` progress, status badge switcher | Hạn mức rõ và ít giật | Low | Low | B | `category_budget_screen.dart:242`, sheet `:311-448`. |
| `LoanDetailScreen` | Paid/remaining/progress đổi tức thời; payment add/delete list snap | Level 3 | Animated progress + keyed payment rows | Dễ hiểu tiến độ trả nợ | Low | Low | B | `loan_detail_screen.dart:395-441`, payment list `:139`. |
| `RemindersScreen` | Suggestion/toggle/delete thiếu transition; debug panel chỉ debug | Level 2 | `AnimatedSwitcher`, switch row feedback, dismiss animation | Flow reminder bớt cứng | Low | Low | B | `reminders_screen.dart:49-65`, switch `:714`. |
| `SettingsScreen` | Rất dài, nhiều section scan khó; motion hiện có chỉ expansion category | Level 1 | Section spacing, sticky/anchor optional, no glass broad | Giảm cognitive load | Medium | Low | C | `settings_screen.dart:45-472`, categories `:1195-1283`. |
| `VisualModePicker` | Đúng hướng nhưng đổi mode không có preview/restart policy | Level 2 | Selected tile transition, optional restart/quality copy | Người dùng hiểu normal/fancy rõ hơn | Low | Low | B | Quality setting Not found in codebase. |
| Onboarding | Glass đẹp, nhưng premium everywhere; page action motion chỉ nút next | Level 2 | Page indicator, selected mode feedback, quality guard | First-run premium hơn | Low | Low | B | `welcome_screen.dart:157-304`. |

## 7. Motion recommendation cụ thể

### Data motion

- `AnimatedMoneyText`: dùng cho `SummaryCards`, `_MiniSummaryRow`, `_NetWorthCard`, `_WalletTile`, `_InfoCard`, `_PaidSummaryRow`.
- Duration: 280-420ms, `Curves.easeOutCubic`.
- Trigger: amount thay đổi do provider emits, filter/month đổi, add/delete transaction/payment.
- Không animate mỗi frame input quá nặng; ở amount đang nhập trong `AddTransactionSheet`, rolling digit chỉ chạy khi `_amountCtrl.formatted` đổi và phải nhẹ.

### List motion

- Transaction list: trước tiên đổi sang grouped sliver lazy. Header ngày và item dùng key ổn định:
  - Header: `ValueKey('day_${yyyyMMdd}')`
  - Item: `ValueKey(transaction.id)`
- Sau khi key/lazy ổn, thêm `MotionListItem` fade/slide 220-280ms. Không dùng glass item.
- Filter/search: dùng `AnimatedSwitcher` cho empty/list/skeleton, tránh rebuild toàn màn nếu chỉ query đổi.

### Interaction motion

- `PressableScale`: áp dụng cho FAB, feature tile, transaction item, filter chip, visual mode tile, button quan trọng.
- Duration: down 90-120ms, up 120-160ms, `Curves.easeOut`.
- Haptic: hiện shell tab có `HapticFeedback.lightImpact()` ở `app_bottom_nav.dart:141`; mở rộng có chọn lọc cho submit transaction/delete confirm, không dùng mọi tap.

### Chart motion

- Stats pie/bar: dùng tween cho section radius/value khi filter/date range đổi. Không blur/glass quanh chart.
- Tab transition: `TabBarView` hiện có ở `stats_screen.dart:49`; có thể giữ native swipe, thêm `AnimatedSwitcher` cho summary label.

### Sheet/modal motion

- Add transaction, budget, wallet picker, visual mode picker: sheet là nơi glass fit tốt nếu fancy mode active.
- Không hand-roll `BackdropFilter` nếu package glass đang là hệ thống chính; nếu dùng blur fallback thì isolate bằng `RepaintBoundary`.
- Bottom sheet duration mặc định của Flutter đủ ổn; motion bên trong nên tập trung amount/chip/CTA.

## 8. Component motion system nên tạo

Đề xuất tạo trong `lib/shared/widgets/motion/` hoặc `lib/shared/widgets/` nếu repo muốn giữ phẳng:

- `AnimatedMoneyText`: `TweenAnimationBuilder<int>` hoặc custom digit rolling, nhận `value`, `formatter`, `style`, `privacyMask`.
- `PressableScale`: wrapper `GestureDetector`/`Listener` + `AnimatedScale`, có `onTap`, `enabled`, optional haptic.
- `MotionListItem`: fade + translate + stable key, không tự đọc provider.
- `SkeletonTransactionItem`: shimmer-free/skeleton nhẹ bằng `AnimatedContainer` opacity, tránh thêm package nếu chưa cần.
- `AnimatedStatCard`: card tiền/progress dùng `AnimatedMoneyText` + `TweenAnimationBuilder<double>`.
- `AnimatedProgressBar`: thống nhất progress wallet/budget/loan.
- `GlassSafeSheet`: helper chọn normal surface hoặc `GlassContainer` theo `AppVisualMode`, chỉ dùng cho modal/picker quan trọng.
- `SmoothFilterChip`: hợp nhất chip ở Transactions, Wallet Detail, Note Picker, Settings category tabs.

Không thêm package ở phase audit. Nếu refactor sau này cần package list animation, cân nhắc sau khi lazy/key đã xong.

## 9. Roadmap 3 phase

### Phase 1 - Quick Wins

Mục tiêu: ít rủi ro, không đổi data flow.

1. Sửa/polish copy mojibake ở UI-facing text nếu source thật đang lưu sai encoding.
2. Thêm `PressableScale` cho `FeatureGrid`, FAB normal/fancy, transaction item, filter chip.
3. Thêm `AnimatedSwitcher` cho search title/month title trong `TransactionsScreen`.
4. Thêm skeleton nhẹ cho Home/Transactions/Wallets thay vì spinner giữa màn ở các list-shaped loading.
5. Tinh chỉnh layout: padding bottom của Home/Transactions để FAB không che item; kiểm tra nav height trên màn nhỏ.
6. Glass: giữ nguyên placement, chỉ chỉnh contrast/tint nếu fancy mode bị khó đọc.

Test: `flutter analyze`, screenshot Home/Transactions/Add/Settings ở normal và fancy, thao tác add transaction, search/filter, đổi visual mode.

### Phase 2 - Core Motion Components

Mục tiêu: tạo motion system tái dùng.

1. Tạo `AnimatedMoneyText`, `AnimatedProgressBar`, `PressableScale`, `MotionListItem`, `SkeletonTransactionItem`, `GlassSafeSheet`.
2. Áp dụng `AnimatedMoneyText` cho `SummaryCards`, `WalletsScreen`, `WalletDetailScreen`, `LoanDetailScreen`.
3. Áp dụng progress tween cho wallet/budget/loan progress bars.
4. Hợp nhất chip animation trong Transactions/Add/WalletDetail/NotePicker để timing và shape đồng bộ.
5. Thêm reduce-motion hook nếu quyết định hỗ trợ accessibility. Hiện Not found in codebase.

Test: verify không rebuild toàn màn khi một amount đổi; dùng DevTools/Performance overlay với list dài; screenshot diff trên Pixel 9 Pro pipeline nếu có emulator.

### Phase 3 - High Impact Refactor

Mục tiêu: core flow có cảm giác premium rõ nhất.

1. Refactor transaction grouped list thành lazy sliver keyed shared component dùng cho Home, Transactions, Wallet Detail.
2. Refactor Add Transaction Sheet: amount rolling, category auto-select transition, wallet picker sheet style, budget warning hierarchy.
3. Refactor Stats: chart transition, summary values, empty/loading states.
4. Refactor fancy mode: quality policy `normal/fancy standard/fancy premium`, performance advisor hoặc ít nhất guardrail không premium trên data-heavy areas.
5. Optional: shared element từ transaction row sang detail sheet nếu không làm phức tạp navigation.

Test: tạo data 200-1000 transactions, scroll/filter/search, add/delete, kiểm tra jank; test normal/fancy; kiểm tra keyboard insets ở Add/Budget/Loan sheets.

## 10. Việc không nên làm

- Không glass hóa transaction list, stats chart, settings list dài.
- Không animate toàn bộ màn khi chỉ một số tiền đổi.
- Không thêm animation list khi item chưa có key ổn định.
- Không dùng `AnimatedSize`/height animation dày trong list dài.
- Không thêm package motion trước khi tận dụng `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer`, `AnimatedScale`, `SliverList`.
- Không thay đổi business logic Riverpod/PowerSync khi refactor visual.
- Không hardcode thêm màu/radius mới ngoài theme/tokens.
- Không dùng `GlassQuality.premium` mặc định cho mọi surface mới.

## 11. Kết luận ưu tiên

Làm trước để tạo cảm giác "premium smooth" rõ nhất với ít rủi ro nhất:

1. `SummaryCards` + money/progress animation.
2. Add Transaction Sheet amount/chip/CTA micro motion.
3. Transactions filter/search/list skeleton, sau đó mới đến lazy keyed grouped list.
4. Wallet/Budget/Loan progress + money animation.
5. Stats chart transition.

Liquid Glass nên được giữ như lớp shell/picker/onboarding/floating action, không phải vật liệu mặc định cho mọi card. Giá trị lớn nhất của Spendo nằm ở money motion, list stability, và feedback khi nhập giao dịch; glass chỉ nên giúp phân lớp ở những điểm nổi, không cạnh tranh với dữ liệu tài chính.
