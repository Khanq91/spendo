# Spendo UI/Motion Refactor Master Plan

## 1. Pham vi va cach doc

File nay tong hop tu:

- `plan/01-frontend-evaluate.md`: audit UI/motion theo code va screenshot hien co.
- `plan/02-UI-refactor.md`: brief/refactor spec cho "smooth premium finance UI".
- Code that trong repo Spendo, doc theo thu tu AGENTS: dependency, bootstrap, router, core/theme, feature screens, PowerSync schema, CI va screenshot pipeline.

Muc tieu cua file 03 khong phai tao them mot prompt UI chung, ma bien 01 + 02 thanh ke hoach refactor co thu tu, co guardrail ky thuat, va co the giao cho dev thuc hien theo phase.

## 2. Danh gia tong the project

### 2.1. Nen tang ky thuat

Spendo la Flutter app ca nhan ve tai chinh, dung stack kha ro va phu hop:

- Flutter/Dart SDK constraint o `pubspec.yaml`.
- Riverpod cho state: `flutter_riverpod` o `pubspec.yaml:47`.
- Go Router cho route: `go_router` o `pubspec.yaml:51`, config chinh o `lib/core/router/app_router.dart:17-53`.
- PowerSync + Supabase cho local-first/sync: `powersync` o `pubspec.yaml:44`, `supabase_flutter` o `pubspec.yaml:61`, schema o `lib/core/db/schema.dart:4-70`.
- Chart/visual: `fl_chart` o `pubspec.yaml:41`, `lucide_icons_flutter` o `pubspec.yaml:63`, `liquid_glass_widgets` o `pubspec.yaml:64`.
- External services: Google Drive backup, home widget, notification/workmanager o `pubspec.yaml:72-81`.

Kien truc hien tai theo feature folder tuong doi de refactor UI: `transactions`, `home`, `stats`, `wallets`, `budget`, `loan`, `reminders`, `settings`, `categories`, `onboarding`, `auth`.

### 2.2. Bootstrap va runtime risk

Startup hien tai la diem can can trong khi refactor UI:

- `main()` init Liquid Glass va Workmanager truoc khi run app o `lib/main.dart:55-63`.
- Splash init Supabase, PowerSync DB, notifications, reminder scheduling, widget sync, cleanup o `lib/main.dart:83-128`.
- Startup gate quyet dinh vao `SpendoApp` hay onboarding o `lib/features/onboarding/presentation/startup_gate.dart:9-35`.
- `SpendoApp` moi la app router chinh, gan theme, locale `vi_VN`, va `routerConfig: appRouter` o `lib/app.dart:34-42`.

Danh gia: UI refactor nen tranh dung vao startup/service init trong cac phase dau. Bat ky motion/skeleton nao cho splash phai duoc coi la polish rieng, khong tron voi core money/list motion.

### 2.3. Routing va app shell

Router chinh khai bao cac route:

- `/` -> `AppShell`
- `/features`
- `/transactions`
- `/stats`
- `/settings`
- `/add`
- `/reminders`
- `/wallets`
- `/wallets/:id`
- `/loans`

Nguon: `lib/core/router/app_router.dart:17-53`.

`AppShell` thuc te chi co 3 tab trong `IndexedStack`: Transactions, Home, Settings o `lib/shared/widgets/app_bottom_nav.dart:74-78`. Stats, Wallets, Loans, Reminders di qua route/action rieng, khong nam trong bottom nav.

Danh gia: refactor motion can phan biet:

- Shell/tab motion: anh huong 3 tab chinh.
- Feature-route motion: anh huong man hinh phu.
- Modal/sheet motion: anh huong add/edit/picker.

### 2.4. Theme, visual mode va Liquid Glass

Theme co san:

- `AppColorScheme` voi 5 seed colors o `lib/core/theme/app_theme.dart:7-38`.
- Semantic finance colors `incomeColor`, `expenseColor`, `expenseAltColor` o `lib/core/theme/app_theme.dart:51-53`.
- Light/dark theme Material 3 o `lib/core/theme/app_theme.dart:58-235`.
- `ThemeNotifier`/`themeProvider` luu theme mode + color scheme o `lib/core/theme/theme_provider.dart:32-94`.
- `AppVisualMode.normal/fancy` luu qua SharedPreferences o `lib/core/theme/visual_mode_provider.dart:4-36`.

Liquid Glass hien dang dung that:

- Root wrap voi `GlassThemeData.simple(quality: GlassQuality.premium)` o `lib/main.dart:57-63`.
- Fancy FAB va `GlassTabBar.bottom` o `lib/shared/widgets/app_bottom_nav.dart:85-116` va `lib/shared/widgets/app_bottom_nav.dart:201-214`.
- Visual mode picker co glass branch o `lib/shared/widgets/visual_mode_picker.dart:7-115`.

Quality setting `standard/minimal/premium`: Not found in codebase.

Reduce motion/accessibility motion toggle: Not found in codebase.

Danh gia: giu Liquid Glass la dung voi huong san pham, nhung khong mo rong thanh material mac dinh cho list/chart/settings dai. Can tao policy noi bo truoc khi them glass vao surface moi.

### 2.5. Data layer va sync

PowerSync schema gom:

- Sync tables: `transactions`, `categories`, `budgets`, `recurring_reminders`.
- Local-only tables: `category_budgets`, `detected_habits`, `wallets`, `loans`, `loan_payments`.

Nguon: `lib/core/db/schema.dart:4-70`.

Database open path:

- `openDatabase({String databaseName = 'spendo.db'})` o `lib/core/db/powersync_db.dart:10-15`.
- Manual migrations cho `transactions.wallet_id` va `transactions.source` o `lib/core/db/powersync_db.dart:32-42`.
- Sync connect/disconnect theo Supabase auth o `lib/core/db/powersync_db.dart:60-77`.
- Upload CRUD sang Supabase qua `SupabasePowerSyncConnector.uploadData` o `lib/core/db/powersync_connector.dart:29-58`.

Supabase URL, anon key, PowerSync URL dang hardcode trong `lib/core/config.dart:1-4`. `.env` hoac env loader: Not found in codebase.

SQL migration folder/files: Not found in codebase.

Danh gia: UI/motion refactor khong can sua data layer, nhung can ton trong local-first stream model. Tat ca animation list/money phai dua tren provider data hien co, khong chen business logic vao animation widget.

### 2.6. State management hien tai

Pattern chinh la repository + Riverpod provider:

- Transactions dung `transactionsProvider`, `summaryProvider`, `filteredTransactionsProvider` o `lib/features/transactions/presentation/providers/transaction_provider.dart:6-47`.
- Stats dung `statsDateRangeProvider`, `statsTransactionsProvider`, `statsExpensesByCategoryProvider`, `statsDailyTotalsProvider`, `statsSummaryProvider` o `lib/features/stats/presentation/providers/stats_provider.dart:57-114`.
- Wallets dung `walletsProvider`, `walletBalanceProvider`, `totalNetWorthProvider`, `walletTxByMonthProvider` o `lib/features/wallets/presentation/providers/wallet_provider.dart:7-93`.
- Budget/category budgets dua vao summary va expenses provider o `lib/features/budget/presentation/providers/budget_provider.dart` va `lib/features/budget/presentation/providers/category_budget_provider.dart`.

Danh gia: co the refactor UI bang shared widgets ma khong can doi provider. Tuy nhien, mot so list hien tai build eager nen phai sua render strategy truoc khi them list motion nang.

### 2.7. UI hien tai theo man hinh

Home:

- Dashboard dung `SummaryCards`, wallet card, feature grid, grouped transaction list o `lib/features/home/presentation/screens/home_screen.dart:17-130`.
- Grouped list hien build ra list widget roi dua vao `SliverChildListDelegate` o `lib/features/home/presentation/screens/home_screen.dart:125-126`.
- Summary amount/progress hien doi truc tiep, visibility toggle bang `setState` o `lib/features/home/presentation/widgets/summary_card.dart:19-120`.

Transactions:

- Search/month title switch bang ternary, filter bar, summary row, grouped list o `lib/features/transactions/presentation/screens/transactions_screen.dart:33-112`.
- List hien dung `ListView(children: [...])` o `lib/features/transactions/presentation/screens/transactions_screen.dart:111-116`.
- Filter chip da co `AnimatedContainer` nhe o `lib/features/transactions/presentation/screens/transactions_screen.dart:241-279`.

Stats:

- `TabBarView` hai tab Category/Daily o `lib/features/stats/presentation/screens/stats_screen.dart:35-53`.
- Pie chart touch dung `setState` thay radius o `lib/features/stats/presentation/screens/stats_screen.dart:66-126`.
- Bar chart build truc tiep tu `fl_chart` o `lib/features/stats/presentation/screens/stats_screen.dart:211-476`.

Wallets:

- `WalletsScreen` dung `ListView` voi net worth, breakdown, active/archived wallet o `lib/features/wallets/presentation/screens/wallets_screen.dart:14-50`.
- Archived section da co `AnimatedRotation` va `AnimatedCrossFade` o `lib/features/wallets/presentation/screens/wallets_screen.dart:291-346`.

Wallet detail:

- Dung `CustomScrollView` + `SliverList`/`SliverChildBuilderDelegate` cho transaction list o `lib/features/wallets/presentation/screens/wallet_detail_screen.dart:94-140`.
- Filter chip co `AnimatedContainer` o `lib/features/wallets/presentation/screens/wallet_detail_screen.dart:523-559`.

Add transaction:

- Sheet la core input surface: amount, type toggle, wallet, category list, note, submit o `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:19-613`.
- Category list dung `ListView.separated` ngang va `_chipKeys` de auto-scroll o `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:427-439`.
- Type toggle da co `AnimatedContainer` o `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:980-1014`.

Budget/Loan/Reminder/Settings:

- Budget progress dung `LinearProgressIndicator` o `lib/features/budget/presentation/widgets/budget_card.dart:175-242`.
- Category budget list/progress o `lib/features/budget/presentation/screens/category_budget_screen.dart:15-123` va `:157-242`.
- Loan detail progress/payment list o `lib/features/loan/presentation/screens/loan_detail_screen.dart:78-139` va `:395-441`.
- Reminders dung `ListView`, suggestion, debug panel, preset list o `lib/features/reminders/presentation/screens/reminders_screen.dart:16-88`, `:581-760`.
- Settings la `ListView` dai, gom backup/import/export/theme/visual mode/category o `lib/features/settings/presentation/screens/settings_screen.dart:25-45` va `:1025-1433`.

### 2.8. Test, screenshot va CI

Repo co san pipeline screenshot:

- `integration_test/screenshot_test.dart` mo DB rieng `spendo_screenshot.db` o line 59, chup PNG va ghi `meta.json` o line 76-101.
- `scripts/run_screenshots.ps1` chay screenshot target.
- `scripts/generate_report.dart` doc `screenshots/` + `meta.json` de tao `report.html`.
- Screenshot hien co: `screenshots/01_home.png` den `05_settings.png`.

CI:

- `.github/workflows/flutter-build.yml` setup Flutter `3.44.0` o line 27.
- Build APK release o line 56.
- Decode keystore tu secret o line 49 va upload release latest o line 64-66.

Danh gia: screenshot pipeline la loi the lon cho UI refactor. Moi phase UI nen co screenshot normal/fancy cho Home, Transactions, Stats, Add Transaction, Settings.

## 3. Danh gia tong the file 01

### 3.1. Diem manh

`plan/01-frontend-evaluate.md` la audit co gia tri, vi no:

- Doc dung stack va source chinh: dependencies, bootstrap Liquid Glass, router, shell/nav, theme, visual mode, screenshots o `plan/01-frontend-evaluate.md:3-15`.
- Nhan dien dung van de lon: app da co UI nen tang tot nhung motion/data transition chua thanh system o `plan/01-frontend-evaluate.md:17-24`.
- Ghi ro missing capability thay vi doan: quality setting va reduce motion deu "Not found in codebase" o `plan/01-frontend-evaluate.md:26-27`.
- Dat guardrail dung cho Liquid Glass: khong glass hoa transaction list, stats chart, settings list dai o `plan/01-frontend-evaluate.md:53-75`.
- Chia priority theo risk/benefit va dua Home/Transactions/Add/Stats len priority A o `plan/01-frontend-evaluate.md:76-95`.
- De xuat component motion system kha sat code: `AnimatedMoneyText`, `PressableScale`, `MotionListItem`, `SkeletonTransactionItem`, `AnimatedProgressBar`, `GlassSafeSheet` o `plan/01-frontend-evaluate.md:150-161`.
- Roadmap 3 phase hop ly o `plan/01-frontend-evaluate.md:165-202`.

### 3.2. Diem can chinh lai

File 01 dung huong, nhung can bo sung/lam chat cac diem sau:

1. Can tach "quick win" va "nen tang bat buoc" ro hon.
   - Them `PressableScale` la quick win, nhung list motion khong nen lam truoc khi grouped transaction list co key/lazy render.

2. Can co motion/accessibility policy som hon.
   - File 01 noi reduce motion not found, nhung dat vao Phase 2 nhu optional. Nen dua thanh phase 0/1 guardrail de moi widget motion doc chung mot policy.

3. Can co acceptance criteria bang file/test.
   - File 01 co test checklist, nhung chua gan voi screenshot pipeline san co (`integration_test/screenshot_test.dart`, `scripts/run_screenshots.ps1`, `report.html`).

4. Can noi ro khong nen dung package moi truoc khi co ly do.
   - File 02 co goi y package, nhung voi repo nay nen uu tien Flutter built-in truoc: `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedScale`, `SliverList`, `RepaintBoundary`.

5. Can danh dau risk copy/mojibake thanh issue rieng.
   - Source hien co co nhieu chuoi mojibake trong output PowerShell va trong code display string. Screenshot co the dang dung/khac encoding tuy moi truong, nhung day la maintenance risk. Nen xu ly nhu copy/encoding pass rieng, khong tron voi motion.

6. Can bo sung rui ro config.
   - `AppConfig` hardcode Supabase/PowerSync endpoint o `lib/core/config.dart:1-4`. Khong phai UI task, nhung la technical debt can ghi trong tong quan project.

### 3.3. Ket luan ve file 01

Co the dung file 01 lam baseline refactor. File 03 nay se giu cac quyet dinh dung cua 01, nhung doi thu tu uu tien thanh:

1. Guardrail va component primitives.
2. Money/progress motion.
3. Core input sheet.
4. Transaction list lazy/key refactor.
5. Stats chart/data transition.
6. Secondary screens polish.
7. Liquid Glass quality policy va fancy-mode hardening.

## 4. Ket hop file 01 va 02 thanh ke hoach tong the

### 4.1. Nguyen tac san pham

Huong UI:

- Smooth premium finance UI: sach, it mau, nhieu khoang tho, nhan vao data tai chinh.
- Motion phuc vu nhan thuc: tien, progress, filter, list, chart phai chuyen trang thai co y nghia.
- Liquid Glass la layer cho shell/picker/onboarding/floating/sheet, khong phai material mac dinh cho moi card.

Huong ky thuat:

- Khong thay doi business logic Riverpod/PowerSync trong UI refactor.
- Khong animate list dai neu item chua co key on dinh va render strategy chua lazy.
- Khong them package motion trong phase 1 tru khi built-in Flutter khong du.
- Blur/glass phai nho, co `RepaintBoundary` khi can, va khong nam trong list dai.
- Tat ca text/money motion phai giu width/baseline on dinh de tranh layout shift.

### 4.2. Motion tokens

Dung chung trong `lib/shared/widgets/motion/` hoac file tokens rieng:

| Token | Gia tri | Dung cho |
|---|---:|---|
| `tapDownDuration` | 90-120ms | press feedback |
| `tapUpDuration` | 120-160ms | release feedback |
| `valueDuration` | 280-420ms | money/progress |
| `listDuration` | 220-300ms | item enter/exit |
| `chartDuration` | 300-450ms | chart value transition |
| `screenDuration` | 350-500ms | route/sheet inner transition |
| `staggerShort` | 20-40ms | digit/item small stagger |
| `curveStandard` | `Curves.easeOutCubic` | default |
| `curveLayout` | `Curves.easeInOutCubic` | layout morph |
| `curveMaterial` | `Curves.fastOutSlowIn` | Material-like transition |

### 4.3. Shared components can tao

Phase dau nen tao nho, thu nghiem tren 1-2 man truoc:

1. `MotionSettings` / `MotionSpec`
   - Noi tap trung duration/curve.
   - Co flag reduce motion.
   - Ban dau co the doc `MediaQuery.disableAnimations` va/hoac `MediaQuery.accessibleNavigation`.

2. `PressableScale`
   - Wrap tile/button/list item.
   - API: `child`, `onTap`, `enabled`, `scale`, `duration`, optional `haptic`.
   - Khong tu doc provider.

3. `AnimatedMoneyText`
   - API: `value`, `formatter`, `style`, `privacyMask`, `animate`, `textAlign`.
   - Phase 1 co the dung `TweenAnimationBuilder<int>` + tabular figures.
   - Phase 2 moi nang len rolling digit/odometer neu can.

4. `AnimatedProgressBar`
   - API: `value`, `trackColor`, `valueColor`, `height`, `borderRadius`, `label`.
   - Dung cho wallet/budget/loan.

5. `MotionListItem`
   - Fade + translate + optional press scale.
   - Yeu cau caller truyen `Key` on dinh.
   - Khong tu xu ly reorder phuc tap luc dau.

6. `SkeletonTransactionItem` / `SkeletonBlock`
   - Skeleton nhe, shimmer-free neu chua can package.
   - Dung thay spinner giua man cho list-shaped loading.

7. `GlassSafeSheet`
   - Chon normal `Container` hoac `GlassContainer` theo `AppVisualMode`.
   - Co guardrail ve blur/quality.
   - Chi dung cho picker/sheet quan trong, khong dung trong transaction list.

8. `SmoothFilterChip`
   - Hop nhat chip animation cho Transactions, Wallet Detail, Note Picker, Settings category tabs.

## 5. Roadmap thuc thi

### Phase 0 - Audit hardening va guardrail

Muc tieu: chuan bi nen truoc khi sua UI rong.

Viec lam:

1. Tao `lib/shared/widgets/motion/` va motion tokens.
2. Tao reduce-motion helper dua tren `MediaQuery.disableAnimations`/`accessibleNavigation`.
3. Them guideline noi bo cho Liquid Glass:
   - `normal`: no glass.
   - `fancy`: glass chi o shell/nav/FAB/onboarding/picker/sheet chon loc.
   - `premium quality`: khong mac dinh cho data-heavy surface.
4. Ghi danh sach chuoi mojibake UI-facing can sua rieng.
5. Chot screenshot baseline tu `screenshots/` va `report.html`.

Acceptance:

- `flutter analyze` pass.
- Khong thay doi flow/data.
- Co screenshot baseline 5 man chinh.

### Phase 1 - Low-risk premium polish

Muc tieu: tang cam giac phan hoi ma khong doi data/render strategy lon.

Viec lam:

1. Ap dung `PressableScale` cho:
   - Feature grid tile o `lib/features/home/presentation/widgets/feature_grid.dart:23-73`.
   - FAB normal/fancy o `lib/shared/widgets/app_bottom_nav.dart:101-128`.
   - Transaction row tap o `lib/features/transactions/presentation/widgets/transaction_list_item.dart:11-40`.
   - Filter chip o Transactions va Wallet Detail.
2. Them `AnimatedSwitcher` cho search/month title trong `TransactionsScreen`.
3. Them `AnimatedSwitcher` cho empty/list/loading state o Home/Transactions.
4. Doi spinner list-shaped thanh skeleton nhe o Home/Transactions/Wallets khi phu hop.
5. Sua padding bottom neu FAB/nav che item trong Home/Transactions.

Khong lam:

- Chua them odometer phuc tap.
- Chua lam FLIP/reorder.
- Chua glass hoa card/list.

Acceptance:

- Search/filter/add transaction van dung.
- Screenshot Home, Transactions, Add Transaction, Settings khong layout shift.
- No jank obvious tren list 100+ giao dich.

### Phase 2 - Money va progress motion

Muc tieu: finance UI co cam giac cao cap ro nhat qua amount/progress.

Viec lam:

1. Tao `AnimatedMoneyText`.
2. Tao `AnimatedProgressBar`.
3. Ap dung cho:
   - `SummaryCards` balance/income/expense o `lib/features/home/presentation/widgets/summary_card.dart:19-134`.
   - `TransactionsScreen` mini summary o `lib/features/transactions/presentation/screens/transactions_screen.dart:286-330`.
   - Wallet net worth/tile balance o `lib/features/wallets/presentation/screens/wallets_screen.dart:91-261`.
   - Wallet detail info cards/progress o `lib/features/wallets/presentation/screens/wallet_detail_screen.dart:290-441`.
   - Budget progress o `lib/features/budget/presentation/widgets/budget_card.dart:175-242`.
   - Category budget progress o `lib/features/budget/presentation/screens/category_budget_screen.dart:157-242`.
   - Loan paid/remaining/progress o `lib/features/loan/presentation/screens/loan_detail_screen.dart:395-441`.
4. Dam bao privacy mask cua `SummaryCards` khong animate thanh so khi dang an.

Acceptance:

- Amount thay doi khong lam card/list nhay kich thuoc.
- Co fallback reduce motion.
- Khong rebuild toan screen chi de animate mot amount.

### Phase 3 - Add Transaction Sheet refactor

Muc tieu: core input flow muot va chac, vi day la hanh dong lap lai nhieu nhat.

Viec lam:

1. Amount display:
   - Scale/fade nhe khi amount update.
   - Optional rolling digit sau khi `AnimatedMoneyText` on dinh.
2. Type toggle:
   - Dung chung timing voi `SmoothFilterChip`.
   - Giu height co dinh de tranh layout shift.
3. Category list:
   - Giu `ListView.separated` ngang, them stable key/press feedback.
   - Auto-scroll hien co qua `_chipKeys` can giu.
4. Wallet picker:
   - Can nhac `GlassSafeSheet` neu fancy mode active.
5. Budget warning:
   - Dung hierarchy ro, progress tween, CTA state transition.
6. Submit button:
   - Animated loading state, disable state ro, khong double submit.

Acceptance:

- Keyboard inset khong che field/button.
- Add income/expense voi category/wallet/note/prefill `/add` van dung.
- Budget warning van hien dung khi over budget.

### Phase 4 - Transaction list lazy/key refactor

Muc tieu: mo khoa list motion ma khong gay jank.

Viec lam:

1. Tao shared grouped transaction sliver/list component:
   - Dung cho Home, Transactions, Wallet Detail.
   - Input: `transactions`, `categoryMap`, display mode, divider/header style.
   - Header key: `ValueKey('day_${yyyyMMdd}')`.
   - Item key: `ValueKey(transaction.id)`.
2. Thay:
   - Home `SliverChildListDelegate(_buildGroupedList(...))` o `home_screen.dart:125-126`.
   - Transactions `ListView(children: [...])` o `transactions_screen.dart:111-116`.
   - Wallet Detail grouped list neu dang precompute.
3. Dung lazy rendering:
   - `SliverList.builder`/`SliverChildBuilderDelegate`.
   - Flatten grouped model thanh lightweight row descriptors neu can.
4. Sau khi key/lazy on dinh, them `MotionListItem` fade/slide 220-300ms cho enter/filter.
5. Chua lam FLIP full reorder neu chua co nhu cau ro; uu tien add/delete/filter transition.

Acceptance:

- Test 200-1000 transactions.
- Search/filter/month switch khong tao hang tram widget upfront neu khong can.
- Scroll position va FAB/nav padding on dinh.
- Transaction detail sheet van mo dung item.

### Phase 5 - Stats chart transition

Muc tieu: chart thay doi range/tab co ngu canh, khong snap.

Viec lam:

1. Them summary row/value transition cho `StatsScreen`.
2. Pie chart:
   - Tween amount/percent/radius khi data doi.
   - Touch radius change phai nhe, tranh setState rebuild thua toan bo neu co the.
3. Bar chart:
   - Tween `toY` khi date range doi.
   - Giữ tooltip, axis label contrast.
4. Empty/loading state:
   - Fade + slide nhe.
5. Khong dung glass quanh chart.

Acceptance:

- Month/custom range doi khong snap manh.
- Chart readable o light/dark/fancy.
- Performance on dinh voi range <= 90 ngay.

### Phase 6 - Secondary screens polish

Muc tieu: dong bo UI ma khong over-engineer.

Wallets:

- Money/progress da lam tu Phase 2.
- Archived section hien da co `AnimatedRotation`/`AnimatedCrossFade`; chi can refine duration/token.

Budget:

- Progress motion + status badge.
- Sheet set budget loading/CTA state.

Loan:

- Payment add/delete list transition nhe.
- Paid/remaining/progress dung chung motion.

Reminders:

- Suggestion/toggle/delete feedback.
- Debug panel neu chi dung dev thi khong polish qua muc.

Settings:

- Uu tien hierarchy, section spacing, states.
- Khong glass hoa toan bo settings list.
- Visual mode sheet co preview/selected transition va copy ro ve normal/fancy.

### Phase 7 - Liquid Glass quality policy

Muc tieu: giu ban sac Liquid Glass nhung co kiem soat.

Viec lam:

1. Tao abstraction noi bo cho glass quality thay vi hardcode `GlassQuality.premium`.
2. Dinh nghia surface duoc glass:
   - App shell/nav/FAB.
   - Onboarding.
   - Visual mode picker.
   - Mot so bottom sheet/picker co backdrop ngan.
3. Dinh nghia surface cam glass:
   - Transaction list.
   - Stats chart.
   - Settings list dai.
   - Long scroll data-heavy cards.
4. Neu co `fancy standard/premium`, luu preference rieng hoac derive tu visual mode + device policy.
5. Dung `RepaintBoundary` quanh glass/blur nang.

Acceptance:

- Fancy mode dep hon normal nhung data van doc duoc.
- Khong co jank ro khi scroll Home/Transactions/Settings.
- Quality setting neu them phai co fallback mac dinh.

## 6. Component-to-screen matrix

| Component | Home | Transactions | Add Sheet | Stats | Wallets | Budget | Loan | Settings |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `PressableScale` | Feature tile, FAB | row, chip, FAB | chip, CTA | tabs optional | wallet tile | tiles | payment/action | theme/mode tiles |
| `AnimatedMoneyText` | balance/income/expense | mini summary/day net optional | amount | summary/legend optional | net worth/balance | spent/budget | paid/remaining | no broad use |
| `AnimatedProgressBar` | wallet breakdown | no | budget warning | no | wallet progress | budget progress | loan progress | no |
| `MotionListItem` | tx rows | tx rows | no | daily rows optional | tx rows | category rows optional | payment rows | no |
| `SkeletonBlock` | tx/wallet load | tx load | no | chart load optional | wallet load | budget load | loan load | no |
| `GlassSafeSheet` | no | no | wallet/category/budget sheet | date range sheet optional | wallet form optional | budget sheet optional | payment sheet optional | visual mode sheet |

## 7. Do-not-do list

- Khong glass hoa transaction list, stats chart, settings list dai.
- Khong animate toan man khi chi mot amount thay doi.
- Khong dung `AnimatedSize` nang trong list dai.
- Khong them list animation khi item chua co `ValueKey`.
- Khong them package motion truoc khi Flutter built-ins khong du.
- Khong dua business logic vao animation widget.
- Khong hardcode them color/radius ngoai theme/tokens.
- Khong mac dinh `GlassQuality.premium` cho moi surface moi.
- Khong sua Supabase/PowerSync config trong UI phase tru khi co task rieng.

## 8. Validation checklist

Moi phase UI nen chay:

1. `flutter analyze`
2. Smoke flows:
   - doi visual mode normal/fancy
   - add expense/income
   - search/filter transaction
   - doi month
   - vao stats/wallet/budget/loan/settings
3. Screenshot:
   - `scripts/run_screenshots.ps1`
   - `dart scripts/generate_report.dart --dir=screenshots --out=report.html`
4. Performance:
   - list 200-1000 transactions
   - scroll Home/Transactions/Settings
   - add/delete transaction
   - switch filter/date range
5. Accessibility:
   - text scale basic
   - reduce motion fallback
   - light/dark/fancy contrast
6. App version:
   - Moi luot hoan tat implementation co thay doi code theo plan phai tang version trong pubspec.yaml truoc khi ban giao.
   - Mac dinh tang ca patch version va build number (vi du 1.7.5+10 -> 1.7.6+11) de Android/iOS deu nhan dien day la build moi.
   - Ghi version cu -> moi trong plan/memory/PROGRESS.md; luot chi sua tai lieu/quy trinh thi khong bump version.

## 9. Uu tien thuc te

Neu chi lam 5 viec co impact cao nhat:

1. Motion tokens + `PressableScale` + reduce-motion guardrail.
2. `AnimatedMoneyText` va `AnimatedProgressBar` cho Home/Wallet/Budget/Loan.
3. Add Transaction Sheet amount/chip/CTA polish.
4. Shared lazy/keyed transaction grouped list cho Home/Transactions/Wallet Detail.
5. Stats chart/value transition khong glass.

Thu tu nay dung vi no giai quyet cam giac "premium finance" bang data motion va list stability truoc, sau do moi mo rong Liquid Glass. File 01 dung khi noi giu Liquid Glass, nhung file 03 dat glass sau cac nen tang render/motion de tranh bien effect thanh nguon jank.
