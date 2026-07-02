# Spendo Clone Blueprint

Source constraint: this document uses only `audit/context_bundle.md`. Anything not present there is marked `Not found`.

## 1. Tech Stack & Dependencies

Project metadata found in `pubspec.yaml`:

- App name: `spendo`
- Description: `Spend your money`
- Version: `1.5.0+10`
- Dart SDK: `^3.7.2`
- Flutter assets: `assets/images/`, `assets/icons/`
- Material icons: enabled with `uses-material-design: true`

| Package | Version | Role | Setup Complexity |
| --- | --- | --- | --- |
| flutter | sdk: flutter | Flutter application framework | Native platform setup required for Android/iOS builds. |
| flutter_localizations | sdk: flutter | Flutter localization support | Low. |
| cupertino_icons | ^1.0.8 | iOS-style icon font | Low. |
| collection | ^1.18.0 | Dart collection utilities | Low. |
| fl_chart | ^0.68.0 | Charts for stats UI | Low. |
| powersync | ^1.5.0 | Local database and offline sync | High: requires PowerSync backend endpoint and Supabase auth token integration. |
| flutter_riverpod | ^2.5.1 | State management | Low. |
| riverpod_annotation | ^2.3.5 | Riverpod code generation annotations | Medium: requires build runner workflow. |
| go_router | ^14.2.7 | Declarative navigation | Low. |
| uuid | ^4.4.2 | UUID generation | Low. |
| intl | ^0.20.2 | Formatting/localization utilities | Low. |
| csv | ^6.0.0 | CSV import/export support | Low. |
| share_plus | ^9.0.0 | Native share sheet | Medium: native platform plugin. |
| file_picker | ^8.0.0 | Native file picker | Medium: native platform plugin and permissions may be needed. |
| path_provider | ^2.1.4 | Native app document/cache paths | Medium: native platform plugin. |
| supabase_flutter | ^2.5.0 | Supabase auth/client initialization | High: requires Supabase URL and anon key. |
| lucide_icons_flutter | ^3.1.14+1 | Icon set | Low. |
| flutter_local_notifications | ^18.0.0 | Local notifications | High: native notification permissions/channels required. |
| timezone | ^0.9.4 | Timezone data for notifications | Medium: paired with notification scheduling. |
| flutter_timezone | ^3.0.0 | Device timezone lookup | Medium: native platform plugin. |
| home_widget | ^0.7.0 | Android/iOS home screen widget integration | High: native widget setup required. |
| flutter_launcher_icons | ^0.14.4 | Launcher icon generation | Medium: build-time asset generation. |
| google_sign_in | ^6.2.1 | Google sign-in for Drive backup | High: OAuth client configuration required. |
| googleapis | ^13.2.0 | Google API client, used for Drive backup | High: Google API/OAuth configuration required. |
| http | ^1.2.2 | HTTP client | Low. |
| shared_preferences | ^2.3.0 | Local key-value settings storage | Medium: native platform plugin. |
| workmanager | ^0.9.0+3 | Background periodic backup task | High: native background execution setup required. |
| package_info_plus | ^9.0.1 | App package/version info | Medium: native platform plugin. |
| path | ^1.9.1 | Path utilities | Low. |
| url_launcher | ^6.3.0 | Launch external URLs | Medium: native URL scheme/platform setup may be required. |
| integration_test | sdk: flutter | Flutter integration testing | Medium: test device/emulator setup. |
| flutter_test | sdk: flutter | Flutter unit/widget testing | Low. |
| flutter_lints | ^5.0.0 | Recommended lint rules | Low. |
| build_runner | ^2.4.11 | Code generation runner | Medium: required for generated code workflows. |
| riverpod_generator | ^2.4.3 | Riverpod provider generator | Medium: used with build_runner. |

Launcher icon config found:

- Android icon name: `launcher_icon`
- iOS generation: enabled
- Image path: `assets/icons/app_logo.jpg`
- Android min SDK for icon config: `21`
- Web, Windows, macOS generation: enabled
- Web `background_color` and `theme_color`: `#hexcode`

## 2. Project Structure

The `FILE TREE (lib/)` section is empty in the bundle. The following structure is visible only from file section headers and imports:

| Folder/File Pattern | Layer | Evidence / Role |
| --- | --- | --- |
| `lib/main.dart` | App bootstrap | Initializes Flutter bindings, Workmanager, Supabase, PowerSync DB, notifications, reminders, widgets, cleanup, and starts `SpendoApp` inside `ProviderScope`. |
| `lib/app.dart` | App shell/root | Imported by `main.dart`; contents not found. |
| `lib/core/config.dart` | Core configuration | Provides `AppConfig.supabaseUrl`, `AppConfig.supabaseAnonKey`, and `AppConfig.powerSyncUrl`; file contents not found. |
| `lib/core/db/` | Data/infrastructure core | Contains `powersync_db.dart`, `powersync_connector.dart`, `schema.dart`; owns PowerSync setup, schema, migrations, and Supabase upload connector. |
| `lib/core/router/` | Core navigation | Contains `app_router.dart` with Go Router routes. |
| `lib/core/theme/` | Core design system | Contains `app_colors.dart`, `app_theme.dart`, `theme_provider.dart`. |
| `lib/core/notifications/` | Core service/state | Contains notification providers/services by import/header. Service implementation partly referenced but not fully included. |
| `lib/core/services/` | Core integrations | Google Drive auth/backup services imported by `main.dart` and providers; contents not found. |
| `lib/core/utils/` | Core utilities | `widget_sync.dart` imported by `main.dart`; contents not found. |
| `lib/shared/widgets/` | Shared presentation | Contains `splash_screen.dart` and `app_bottom_nav.dart` by imports; contents not found. |
| `lib/features/*/presentation/` | Presentation layer | Screens and Riverpod providers are visible for auth, budget, categories, habits, loan, reminders, settings, stats, transactions, wallets. |
| `lib/features/*/domain/` | Domain layer | Domain classes are imported, but domain files are not included in the bundle. |
| `lib/features/*/data/` | Data layer | Repositories/services are imported, but repository implementations are not included in the bundle. |

Feature folders visible from imports/provider sections:

- `features/auth`
- `features/budget`
- `features/categories`
- `features/habits`
- `features/home`
- `features/loan`
- `features/reminders`
- `features/settings`
- `features/stats`
- `features/transactions`
- `features/wallets`

## 3. Data Models

The explicit `DATA MODELS` section in the bundle is empty. Domain model files are referenced by imports but their definitions are not included.

Persisted/domain models referenced but not defined:

| Model Class | Fields / Types | Serialization Method | DB Table Mapping |
| --- | --- | --- | --- |
| `Budget` | Not found | Not found | Likely `budgets` by provider/repository naming, but exact mapping not found. |
| `CategoryBudget` | Not found | Not found | Likely `category_budgets` by provider/repository naming, but exact mapping not found. |
| `Category` | Not found | Not found | Likely `categories` by provider/repository naming, but exact mapping not found. |
| `DetectedHabit` | Not found | Not found | Likely `detected_habits` by provider/repository naming, but exact mapping not found. |
| `Loan` | Not found | Not found | Likely `loans` by provider/repository naming, but exact mapping not found. |
| `RecurringReminder` | Not found | Not found | Likely `recurring_reminders` by provider/repository naming, but exact mapping not found. |
| `SepayBankAccount` | Not found in class definition. Used with `SepayBankAccount.fromJson(e as Map<String, dynamic>)`. | `fromJson` is called; implementation not found. | Supabase table `sepay_bank_accounts`. |
| `Transaction` | Not found | Not found | Likely `transactions` by provider/repository naming, but exact mapping not found. |
| `Wallet` | Not found | Not found | Likely `wallets` by provider/repository naming, but exact mapping not found. |

Non-persisted state/helper classes found:

| Class | Fields / Types | Serialization Method | DB Table Mapping |
| --- | --- | --- | --- |
| `ThemeState` | `ThemeMode mode`, `AppColorScheme colorScheme` | `copyWith`; persisted manually to SharedPreferences keys `theme_mode`, `theme_color_scheme`. | None. |
| `LoanSummary` | `int count`, `int remainingBorrowed`, `int remainingLent`, `bool hasOverdue`, `bool hasUpcoming`, `int overdueCount`, `int upcomingCount` | None found. Computed summary from loan repository stream. | None. |
| `GDriveState` | `bool isSignedIn`, `String? email`, `DateTime? lastBackupTime`, `BackupFrequency frequency`, `bool isLoading`, `String? error`, `String? successMessage` | `copyWith`; frequency and backup time persisted manually to SharedPreferences keys `gdrive_backup_frequency`, `gdrive_last_backup_time`. | None. |
| `StatsDateRange` | `StatsTimeMode mode`, `DateTime start`, `DateTime end` | Factory constructors `fromMonth`, `custom`; no JSON/DB serialization found. | None. |

Enums found:

- `BackupFrequency`: `none`, `daily`, `weekly`, `monthly`; exposes `label` and `interval`.
- `StatsTimeMode`: `month`, `custom`.
- `AppColorScheme`: `roseDefault`, `indigoMidnight`, `emeraldWealth`, `slatePremium`, `amberWarm`; exposes `label`, `seedColor`, `swatch`.

## 4. PowerSync Schema

Schema source found in `lib/core/db/schema.dart`.

PowerSync initialization found in `lib/core/db/powersync_db.dart`:

- Database path: app documents directory + `spendo.db`
- Database variable: `late final PowerSyncDatabase db`
- Created with `PowerSyncDatabase(schema: schema, path: dbPath)`
- Initialized with `await db.initialize()`
- Sync setup connects only when Supabase current session exists and user id is not empty.

Tables:

| Table | Sync Mode | Columns |
| --- | --- | --- |
| `transactions` | Synced table | `amount` text; `type` text; `category_id` text; `note` text; `created_at` text; `wallet_id` text; `source` text |
| `categories` | Synced table | `name` text; `color_hex` text; `icon_name` text; `is_default` integer; `is_income` integer; `sort_order` integer |
| `budgets` | Synced table | `amount` text; `month` text |
| `category_budgets` | Local-only table | `category_id` text; `amount` text |
| `recurring_reminders` | Synced table | `title` text; `category_id` text; `amount_hint` text; `frequency` text; `day_of_week` integer; `day_of_month` integer; `hour` integer; `minute` integer; `is_active` integer; `next_trigger` text; `warn_before_hours` integer |
| `detected_habits` | Local-only table | `keyword` text; `category_id` text; `median_gap_days` integer; `last_occurrence` text; `occurrence_count` integer; `is_dismissed` integer; `analyzed_at` text |
| `wallets` | Local-only table | `name` text; `type` text; `initial_balance` text; `note` text; `color_hex` text; `sort_order` integer; `is_archived` integer |
| `loans` | Local-only table | `title` text; `type` text; `principal` text; `contact_name` text; `start_date` text; `due_date` text; `note` text; `color_hex` text; `is_closed` integer |
| `loan_payments` | Local-only table | `loan_id` text; `amount` text; `paid_at` text; `note` text |

PowerSync local migrations found:

- `_migrateWalletId()`: `ALTER TABLE transactions ADD COLUMN wallet_id TEXT`
- `_migrateSource()`: `ALTER TABLE transactions ADD COLUMN source TEXT DEFAULT 'manual'`
- `_deduplicateCategories()`: deletes duplicate categories, keeping `MIN(id)` grouped by `name, is_income`.

Seed data found:

- Expense categories are inserted into `categories` with `is_default = 1`, `is_income = 0`.
- Income categories are inserted into `categories` with `is_default = 1`, `is_income = 1`.
- Seed sentinel checks for `icon_name = 'restaurant' AND is_default = 1`.

Sync rules:

- PowerSync server-side sync rules: Not found.
- Client upload behavior in `SupabasePowerSyncConnector.uploadData()`:
  - Reads `database.getNextCrudTransaction()`.
  - Requires `Supabase.instance.client.auth.currentUser?.id`.
  - Removes `updated_at` from uploaded data.
  - `UpdateType.put`: `client.from(table).upsert({'id': op.id, 'user_id': userId, ...data})`
  - `UpdateType.patch`: `client.from(table).update(data).eq('id', op.id)`
  - `UpdateType.delete`: `client.from(table).delete().eq('id', op.id)`
  - Calls `tx.complete()` both on success and in catch before rethrow.

## 5. Supabase Integration

Initialization found in `lib/main.dart`:

- `Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey)`
- `AppConfig` values are referenced but not shown in the bundle.

PowerSync credential integration found in `lib/core/db/powersync_connector.dart`:

- Calls `Supabase.instance.client.auth.refreshSession()`.
- Uses `response.session`.
- Uses `session.user.id`; returns `null` if missing/empty.
- Builds `PowerSyncCredentials` with:
  - `endpoint: AppConfig.powerSyncUrl`
  - `token: session.accessToken`
  - `expiresAt` converted from `session.expiresAt`.

Supabase auth methods/state found:

- `Supabase.instance.client.auth.currentSession`
- `Supabase.instance.client.auth.onAuthStateChange`
- `AuthChangeEvent.signedIn`
- `AuthChangeEvent.signedOut`
- `AuthChangeEvent.tokenRefreshed`
- `Supabase.instance.client.auth.currentUser?.id`
- `authStateProvider`: streams `AuthState`.
- `currentUserProvider`: streams `User?` from auth state.
- `isLoggedInProvider`: true when current user is not null.

Supabase tables directly queried:

| Table | Operations Found | File Section |
| --- | --- | --- |
| `sepay_bank_accounts` | `select().eq('user_id', userId).order('created_at', ascending: false)` | `lib/features/settings/presentation/providers/sepay_provider.dart` |
| `sepay_bank_accounts` | `update({'is_active': isActive}).eq('id', id)` | `lib/features/settings/presentation/providers/sepay_provider.dart` |
| `sepay_bank_accounts` | `upsert({...}, onConflict: 'user_id, account_number')` | `lib/features/settings/presentation/providers/sepay_provider.dart` |
| `sepay_bank_accounts` | `delete().eq('id', id)` | `lib/features/settings/presentation/providers/sepay_provider.dart` |
| Dynamic `op.table` from PowerSync CRUD | `upsert`, `update`, `delete` | `lib/core/db/powersync_connector.dart` |

Tables uploaded through PowerSync dynamic `op.table` may include synced PowerSync tables:

- `transactions`
- `categories`
- `budgets`
- `recurring_reminders`

RLS assumptions:

- Not found as SQL policies or migrations.
- The connector adds `user_id` on upsert for PowerSync writes.
- SePay account reads filter by `user_id`.
- SePay update/delete operations shown only filter by `id`; whether RLS protects ownership is not shown.

Supabase schema/migrations:

- Not found.

## 6. Navigation Map (Go Router)

Router source found in `lib/core/router/app_router.dart`.

Global navigation:

- Navigator key: `_routerNavigatorKey = GlobalKey<NavigatorState>()`
- Router: `appRouter = GoRouter(...)`
- Initial location: `/`
- Notification navigator bridge: `initNotificationNavigatorKey()` assigns `NotificationService.navigatorKey = _routerNavigatorKey`.
- Guards/redirects: Not found.

Routes:

| Path | Screen / Builder | Params | Guard |
| --- | --- | --- | --- |
| `/` | `AppShell()` | None | Not found |
| `/features` | `AllFeaturesScreen()` | None | Not found |
| `/transactions` | `TransactionsScreen()` | None | Not found |
| `/stats` | `StatsScreen()` | None | Not found |
| `/settings` | `SettingsScreen()` | None | Not found |
| `/add` | `_AddTransactionPage(...)`, which opens `AddTransactionSheet` as a modal bottom sheet and then `context.go('/')` | Query params: `category_id`, `note`, `amount`; `amount` parsed with `int.tryParse` | Not found |
| `/reminders` | `RemindersScreen()` | None | Not found |
| `/wallets` | `WalletsScreen()` | None | Not found |
| `/wallets/:id` | `WalletDetailScreen(walletId: state.pathParameters['id']!)` | Path param: `id` | Not found |
| `/loans` | `LoanListScreen(filterType: filterType)` | Query param: `type`; comment says `'borrowed' \| 'lent' \| null (all)` | Not found |

ASCII navigation tree:

```text
/
├── features
├── transactions
├── stats
├── settings
├── add
│   └── AddTransactionSheet modal
│       ├── query: category_id
│       ├── query: note
│       └── query: amount
├── reminders
├── wallets
│   └── :id
└── loans
    └── query: type=borrowed|lent|null
```

## 7. Theme & Design System

Theme sources found:

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/theme_provider.dart`

Primary/seed colors:

| Scheme | Seed / Swatch Hex | Label |
| --- | --- | --- |
| `roseDefault` | `#AD6E7F` | `Rose (Mặc định)` as encoded in bundle text |
| `indigoMidnight` | `#5C6BC0` | `Indigo Midnight` |
| `emeraldWealth` | `#00897B` | `Emerald Wealth` |
| `slatePremium` | `#78909C` | `Slate Premium` |
| `amberWarm` | `#FFB300` | `Amber Warm` |

Bootstrap theme in `main.dart`:

- `_AppRoot` uses `ThemeData(colorSchemeSeed: const Color(0xFFF06292))` for the splash/root `MaterialApp`.

Semantic colors:

- `incomeColor = Color(0xFF43A047)`
- `expenseColor = Color(0xFFF06292)`
- `expenseAltColor = Color(0xFFE53935)`

Shared palette in `AppColors.palette`:

- `#FF6B6B`
- `#FF8E53`
- `#FFA726`
- `#FFEAA7`
- `#96CEB4`
- `#4ECDC4`
- `#45B7D1`
- `#42A5F5`
- `#6C63FF`
- `#9C8FFF`
- `#DDA0DD`
- `#EC407A`
- `#66BB6A`
- `#B0BEC5`
- `#FFD3B6`

Color helpers:

- `AppColors.fromHex(String hex)` returns `Color(int.parse('FF$cleaned', radix: 16))`.
- `AppColors.toHex(Color color)` returns uppercase `#RRGGBB`.

Typography scale found:

- AppBar title: `fontSize: 16`, `fontWeight: FontWeight.w600`
- Navigation selected label: `fontSize: 11`, `fontWeight: FontWeight.w600`
- Navigation unselected label: `fontSize: 11`
- Chip label: `fontSize: 12`
- Input hint: `fontSize: 13`
- Other typography scale: Not found.

Light theme key settings:

- `useMaterial3: true`
- `ColorScheme.fromSeed(seedColor: scheme.seedColor, brightness: Brightness.light)`
- `surface: Colors.white`
- `surfaceContainerHighest: #F0F0F0`
- `scaffoldBackgroundColor: #F5F5F5`
- AppBar background: `#F5F5F5`; elevation `0`; centered title; title/icon color `#1A1A1A`
- NavigationBar background: white; selected icon color `cs.primary`; unselected icon color `#9E9E9E`; selected indicator `cs.primaryContainer`; elevation `0`
- Card background: white; elevation `0`; radius `16`; border `Colors.grey.shade100`, width `0.5`
- FAB: background `cs.primary`; foreground `cs.onPrimary`; circle shape; elevation `2`
- Chip: transparent background; grey border; radius `20`
- Divider: grey shade 100; thickness `0.5`; space `1`
- InputDecoration: no border; dense; vertical content padding `4`
- ListTile: white tile; horizontal padding `16`; vertical padding `2`
- BottomSheet: white background; top radius `20`

Dark theme key settings:

- `useMaterial3: true`
- `ColorScheme.fromSeed(seedColor: scheme.seedColor, brightness: Brightness.dark)`
- `surface: #1E1E1E`
- `surfaceContainerHighest: #2A2A2A`
- `onSurface: #EEEEEE`
- `onSurfaceVariant: #AAAAAA`
- `outline: #444444`
- `outlineVariant: #333333`
- `scaffoldBackgroundColor: #111111`
- AppBar background: `#111111`; elevation `0`; centered title; title/icon color white
- NavigationBar background: `#1E1E1E`; selected icon color `cs.primary`; unselected icon color `#757575`; selected indicator `cs.primaryContainer`
- Card background: `#1E1E1E`; elevation `0`; radius `16`; border `#2A2A2A`, width `0.5`
- FAB: background `cs.primary`; foreground `cs.onPrimary`; circle shape; elevation `2`
- Chip: transparent background; border `#333333`; radius `20`
- Divider: `#2A2A2A`; thickness `0.5`; space `1`
- InputDecoration: no border; hint `#666666`; dense; vertical content padding `4`
- ListTile: tile `#1E1E1E`; horizontal padding `16`; vertical padding `2`
- BottomSheet: `#1E1E1E`; top radius `20`

Theme persistence:

- `ThemeState` defaults to `ThemeMode.system` and `AppColorScheme.roseDefault`.
- SharedPreferences keys:
  - `theme_mode`
  - `theme_color_scheme`

## 8. CI/CD Summary

Workflow found: `.github/workflows/flutter-build.yml`

Trigger:

- On push to branch `main`

Concurrency:

- Group: `flutter-build`
- `cancel-in-progress: true`

Permissions:

- `contents: write`

Runner:

- `ubuntu-latest`

Build steps:

1. Checkout source with `actions/checkout@v4`.
2. Setup Java with `actions/setup-java@v4`.
   - Distribution: `temurin`
   - Java version: `17`
3. Setup Flutter with `subosito/flutter-action@v2`.
   - Flutter version: `3.44.0`
   - Cache: `true`
4. Cache pub dependencies with `actions/cache@v4`.
   - Path: `~/.pub-cache`
   - Key uses `hashFiles('**/pubspec.lock')`
5. Install dependencies: `flutter pub get`.
6. Get app version:
   - Reads `version:` from `pubspec.yaml`
   - Strips build number after `+`
   - Adds timestamp `date +'%Y%m%d_%H%M'`
   - Outputs name like `spendo_v${VERSION}_${BUILD_TIME}`
7. Decode keystore:
   - Secret: `KEYSTORE_BASE64`
   - Output path: `android/app/spendo.jks`
8. Build APK:
   - Command: `flutter build apk --release`
   - Env secrets:
     - `KEY_ALIAS`
     - `KEY_PASSWORD`
     - `STORE_PASSWORD`
9. Rename APK:
   - From `build/app/outputs/flutter-apk/app-release.apk`
   - To `build/app/outputs/flutter-apk/${{ steps.version.outputs.name }}.apk`
10. Upload APK to GitHub Release using `softprops/action-gh-release@v2`.
    - `tag_name: latest`
    - `name: Latest Build`
    - `make_latest: true`

Signing:

- Android release signing uses decoded keystore from `KEYSTORE_BASE64`.
- Signing credentials are injected through GitHub secrets.
- `android/key.properties` or Gradle signing config details: Not found.

Deploy targets:

- GitHub Release with tag `latest`.
- Android APK artifact.
- Google Play/App Store/TestFlight/Firebase deploy: Not found.

## Feature: auth

### Files Involved
- `lib/features/auth/presentation/providers/auth_provider.dart` - Defines Riverpod providers that expose Supabase auth state, current user, and logged-in status.
- `lib/features/auth/presentation/screens/auth_screen.dart` - Implements the login/sign-up UI and calls Supabase Auth APIs.

### What It Does
Provides a user-facing authentication screen where users can enter an email and password to either sign in or create an account. The screen also allows users to dismiss authentication and continue without an account. Auth state is exposed to the rest of the app through Riverpod providers.

### Screens & Widgets
- `AuthScreen` - `lib/features/auth/presentation/screens/auth_screen.dart:4-201`; stateful screen for login/sign-up form, error display, loading state, and offline skip action.
- `_TabBtn` - `lib/features/auth/presentation/screens/auth_screen.dart:203-238`; private tab-style button used to switch between login and registration modes.

### Riverpod Providers
- `authStateProvider` - `StreamProvider<AuthState>`; streams raw Supabase auth state changes from `Supabase.instance.client.auth.onAuthStateChange` (`lib/features/auth/presentation/providers/auth_provider.dart:4-6`).
- `currentUserProvider` - `StreamProvider<User?>`; maps Supabase auth state changes to the current session user, or `null` when no session exists (`lib/features/auth/presentation/providers/auth_provider.dart:8-11`).
- `isLoggedInProvider` - `Provider<bool>`; derives a boolean login status from `currentUserProvider.valueOrNull != null` (`lib/features/auth/presentation/providers/auth_provider.dart:13-15`).

### Data Flow
User enters email/password in `AuthScreen` text fields (`auth_screen.dart:35-38`) -> `_submit()` validates both values are non-empty and sets local `_loading`/`_error` state (`auth_screen.dart:40-43`) -> the screen gets `Supabase.instance.client` (`auth_screen.dart:46`) -> login mode calls `client.auth.signInWithPassword(email: email, password: pass)` (`auth_screen.dart:47-48`) or sign-up mode calls `client.auth.signUp(email: email, password: pass)` (`auth_screen.dart:49-50`) -> `AuthException` messages are shown in `_error` (`auth_screen.dart:52-53`), other exceptions show a generic error string (`auth_screen.dart:54-55`) -> loading state is cleared when mounted (`auth_screen.dart:56-58`). Separately, `initState()` listens for Supabase `AuthChangeEvent.signedIn` and closes the screen with `Navigator.of(context).pop()` (`auth_screen.dart:18-26`). The skip action also exits with `Navigator.of(context).pop()` (`auth_screen.dart:184-189`).

### PowerSync / Supabase Tables Touched
Not found in codebase. This feature references Supabase Auth only and does not reference database table names.

### Navigation
Routes used: Not found in codebase. Inside this feature, navigation only exits the current screen via `Navigator.of(context).pop()` after sign-in (`auth_screen.dart:21-24`) or when the user chooses to continue without an account (`auth_screen.dart:184-189`). How the user enters this feature is not found in codebase within `lib/features/auth`.

### Complexity Rating
Low - the feature consists of a single auth form and three small derived auth-state providers with direct Supabase Auth calls and no local database or cross-feature logic.

### TODOs / Known Issues
Not found in codebase.

---

## Feature: budget

### Files Involved
- `lib/features/budget/domain/budget.dart` � Defines the `Budget` model, parses PowerSync rows, and formats month keys as `yyyy-MM` (`Budget`, `Budget.fromMap`, `Budget.monthKey`; lines 1-21).
- `lib/features/budget/domain/category_budget.dart` � Defines the `CategoryBudget` model for per-category spending limits (`CategoryBudget`, `CategoryBudget.fromMap`; lines 1-18).
- `lib/features/budget/data/budget_repository.dart` � Reads, watches, upserts, and deletes monthly budget rows in the `budgets` table (`BudgetRepository`; lines 7-38).
- `lib/features/budget/data/category_budget_repository.dart` � Reads, watches, upserts, and deletes per-category budget rows in the `category_budgets` table (`CategoryBudgetRepository`; lines 4-51).
- `lib/features/budget/presentation/providers/budget_provider.dart` � Riverpod providers for the current selected month budget and monthly budget progress (lines 6-32).
- `lib/features/budget/presentation/providers/category_budget_provider.dart` � Riverpod providers for category budget lists, maps, progress, and near-limit alerts (lines 7-72).
- `lib/features/budget/presentation/widgets/budget_card.dart` � Home/summary budget card UI showing monthly progress and expandable category alerts (`BudgetCard`; lines 12-329).
- `lib/features/budget/presentation/widgets/budget_type_sheet.dart` � Bottom sheet for choosing monthly budget versus category budget setup (`BudgetTypeSheet`; lines 9-137).
- `lib/features/budget/presentation/screens/budget_screen.dart` � Bottom-sheet screen for creating, updating, or deleting the selected month budget (`BudgetScreen`; lines 11-159).
- `lib/features/budget/presentation/screens/category_budget_screen.dart` � Draggable bottom-sheet screen for managing per-category budgets (`CategoryBudgetScreen`; lines 15-443).

### What It Does
The budget feature lets users set a total spending limit for the currently selected month and optional spending limits for individual expense categories. It shows progress against the monthly limit, warns when category budgets reach at least 70%, highlights over-budget states, and allows users to add, edit, or delete limits from modal bottom sheets.

### Screens & Widgets
- `BudgetCard` � `lib/features/budget/presentation/widgets/budget_card.dart:12`; compact summary/CTA card for monthly budget and category alerts.
- `_BudgetCardState` � `lib/features/budget/presentation/widgets/budget_card.dart:19`; local UI expansion state for category alerts.
- `_MonthlyBudgetRow` � `lib/features/budget/presentation/widgets/budget_card.dart:175`; monthly budget progress row with label, percentage, progress bar, and spent/budget amounts.
- `_CategoryAlertList` � `lib/features/budget/presentation/widgets/budget_card.dart:256`; expandable list of near-limit or over-limit category budgets.
- `BudgetTypeSheet` � `lib/features/budget/presentation/widgets/budget_type_sheet.dart:9`; modal selector for budget type.
- `_OptionCard` � `lib/features/budget/presentation/widgets/budget_type_sheet.dart:85`; tappable option row used inside the budget type selector.
- `BudgetScreen` � `lib/features/budget/presentation/screens/budget_screen.dart:11`; bottom-sheet editor for the monthly budget.
- `_BudgetScreenState` � `lib/features/budget/presentation/screens/budget_screen.dart:18`; owns amount input controller, loading state, save, and delete actions.
- `CategoryBudgetScreen` � `lib/features/budget/presentation/screens/category_budget_screen.dart:15`; draggable bottom sheet listing categories with and without budgets.
- `_SectionLabel` � `lib/features/budget/presentation/screens/category_budget_screen.dart:133`; section header label for the category budget list.
- `_CategoryBudgetTile` � `lib/features/budget/presentation/screens/category_budget_screen.dart:157`; row for a category that already has a budget, including edit/delete and progress bar.
- `_CategoryNobudgetTile` � `lib/features/budget/presentation/screens/category_budget_screen.dart:258`; row for a category without a budget, with an add action.
- `_SetCategoryBudgetSheet` � `lib/features/budget/presentation/screens/category_budget_screen.dart:311`; modal amount-entry sheet for one category budget.
- `_SetCategoryBudgetSheetState` � `lib/features/budget/presentation/screens/category_budget_screen.dart:325`; owns category budget amount input, loading state, and save action.

### Riverpod Providers
- `budgetRepoProvider` � `Provider<BudgetRepository>` in `lib/features/budget/presentation/providers/budget_provider.dart:6`; exposes the monthly budget repository.
- `currentBudgetProvider` � `StreamProvider.autoDispose<Budget?>` in `lib/features/budget/presentation/providers/budget_provider.dart:8`; watches the `budgets` row for `selectedMonthProvider` using `Budget.monthKey`.
- `budgetProgressProvider` � `Provider.autoDispose<({int budget, int spent, double percent, bool isOver})?>` in `lib/features/budget/presentation/providers/budget_provider.dart:15`; combines `currentBudgetProvider` with `summaryProvider.expense` to calculate monthly usage and over-budget status.
- `categoryBudgetRepoProvider` � `Provider<CategoryBudgetRepository>` in `lib/features/budget/presentation/providers/category_budget_provider.dart:7`; exposes the category budget repository.
- `categoryBudgetsProvider` � `StreamProvider<List<CategoryBudget>>` in `lib/features/budget/presentation/providers/category_budget_provider.dart:11`; watches all rows from `category_budgets`.
- `categoryBudgetMapProvider` � `Provider.autoDispose<Map<String, CategoryBudget>>` in `lib/features/budget/presentation/providers/category_budget_provider.dart:16`; converts the watched category budget list into an O(1) lookup by `categoryId`.
- `categoryBudgetProgressProvider` � `Provider.autoDispose<Map<String, ({int budget, int spent, double percent, bool isOver})>>` in `lib/features/budget/presentation/providers/category_budget_provider.dart:24`; combines category budgets with `expensesByCategoryProvider` to calculate per-category progress.
- `nearLimitCategoriesProvider` � `Provider.autoDispose<List<({String categoryId, int budget, int spent, double percent, bool isOver})>>` in `lib/features/budget/presentation/providers/category_budget_provider.dart:56`; filters category progress to existing categories at or above 70% usage and sorts descending by percent.

### Data Flow
Monthly budget:
Input: user opens `BudgetCard`, chooses monthly budget in `BudgetTypeSheet`, enters an amount in `BudgetScreen` through `AmountInputController` and `Numpad`.
Processing: `BudgetScreen._save` reads `selectedMonthProvider`, formats it via `Budget.monthKey`, then calls `BudgetRepository.set` (`budget_screen.dart:39-47`). `BudgetRepository.set` checks whether a `budgets` row exists for the month, then updates or inserts (`budget_repository.dart:17-33`).
Output/side-effects: PowerSync local database table `budgets` is changed; `currentBudgetProvider` streams the updated row; `budgetProgressProvider` recomputes against `summaryProvider.expense`; `BudgetCard` displays CTA/progress/over-limit state and the sheet closes via `Navigator.of(context).pop()`.

Category budget:
Input: user opens `BudgetCard`, chooses category budget in `BudgetTypeSheet`, selects a category in `CategoryBudgetScreen`, and enters an amount in `_SetCategoryBudgetSheet`.
Processing: `CategoryBudgetScreen` splits `expenseCategoriesProvider` into categories with and without existing budget entries using `categoryBudgetMapProvider` (`category_budget_screen.dart:20-27`). `_SetCategoryBudgetSheetState._save` calls `CategoryBudgetRepository.set` with the category id and amount (`category_budget_screen.dart:343-347`). The repository checks `category_budgets` by `category_id`, then updates or inserts (`category_budget_repository.dart:26-42`). Delete actions call `CategoryBudgetRepository.delete` (`category_budget_screen.dart:79-81`, `category_budget_repository.dart:45-50`).
Output/side-effects: PowerSync local database table `category_budgets` is changed; `categoryBudgetsProvider` streams updated rows; `categoryBudgetProgressProvider` combines them with `expensesByCategoryProvider`; `nearLimitCategoriesProvider` feeds `BudgetCard` category alerts.

### PowerSync / Supabase Tables Touched
- `budgets` � selected, inserted, updated, and deleted by `BudgetRepository` (`lib/features/budget/data/budget_repository.dart:10-37`).
- `category_budgets` � selected, inserted, updated, and deleted by `CategoryBudgetRepository` (`lib/features/budget/data/category_budget_repository.dart:8-48`).

### Navigation
No GoRouter route definitions were found inside `lib/features/budget`; route files outside this feature were intentionally not read. Within the feature, entry is modal-driven: `BudgetCard._openBudgetTypeSheet` opens `BudgetTypeSheet` with `showModalBottomSheet` (`budget_card.dart:164-169`). `BudgetTypeSheet` closes itself and opens either `BudgetScreen` for monthly budgets (`budget_type_sheet.dart:53-58`) or `CategoryBudgetScreen` for category budgets (`budget_type_sheet.dart:71-76`). Save/delete flows exit by calling `Navigator.of(context).pop()` in `BudgetScreen` and `_SetCategoryBudgetSheetState` (`budget_screen.dart:47`, `budget_screen.dart:54`, `category_budget_screen.dart:347`).

### Complexity Rating
Medium � the UI is mostly modal forms and progress displays, but the feature coordinates realtime PowerSync streams, selected-month transaction summaries, category expense aggregation, and derived alert providers.

### TODOs / Known Issues
- No `TODO` or `FIXME` comments found in `lib/features/budget`.
- `lib/features/budget/data/budget_repository.dart:1` imports `package:uuid/uuid.dart` and `budget_repository.dart:5` defines `const _uuid = Uuid();`, but inserts use SQL `uuid()` directly, so `_uuid` appears unused.

## Feature: categories

### Files Involved
- `lib/features/categories/data/category_repository.dart` - PowerSync-backed repository for watching, querying, creating, updating, and deleting categories.
- `lib/features/categories/domain/category.dart` - Immutable `Category` domain model with database mapping and color parsing.
- `lib/features/categories/presentation/providers/category_provider.dart` - Riverpod providers exposing the repository, all categories, expense categories, and income categories.
- `lib/features/categories/presentation/widgets/category_form_sheet.dart` - Modal bottom-sheet form for adding or editing a category name, color, and icon.

### What It Does
The categories feature manages income and expense categories used by transactions. Users can create or edit categories with a name, color, and icon through `CategoryFormSheet`; repository methods expose all categories, categories filtered by income/expense type, lookup by name/type, update, and guarded deletion. Deletes are blocked when the category is still referenced by transactions.

### Screens & Widgets
- `CategoryFormSheet` - `lib/features/categories/presentation/widgets/category_form_sheet.dart:26`; stateful bottom-sheet UI for add/edit category flows.
- `_CategoryFormSheetState` - `lib/features/categories/presentation/widgets/category_form_sheet.dart:36`; private state handling text input, selected color/icon, loading state, and submit behavior.

### Riverpod Providers
- `categoryRepoProvider` - `Provider<CategoryRepository>`; creates the feature repository used to access category persistence operations. Defined in `lib/features/categories/presentation/providers/category_provider.dart:5`.
- `categoriesProvider` - `StreamProvider<List<Category>>`; watches all categories from PowerSync ordered by income flag and sort order. Defined in `lib/features/categories/presentation/providers/category_provider.dart:7`.
- `expenseCategoriesProvider` - `Provider.autoDispose<List<Category>>`; derives non-income categories from `categoriesProvider` for expense selection. Defined in `lib/features/categories/presentation/providers/category_provider.dart:11`.
- `incomeCategoriesProvider` - `Provider.autoDispose<List<Category>>`; derives income categories from `categoriesProvider` for income selection. Defined in `lib/features/categories/presentation/providers/category_provider.dart:15`.

### Data Flow
- Read all categories: UI/provider watches `categoriesProvider` -> `categoryRepoProvider.watchAll()` -> `CategoryRepository.watchAll()` runs `SELECT * FROM categories ORDER BY is_income ASC, sort_order ASC` through `db.watch()` -> rows are mapped with `Category.fromMap()` -> `StreamProvider<List<Category>>` emits lists to consumers.
- Read by type: caller invokes `CategoryRepository.getByType(isIncome: ...)` -> SQL filters `categories.is_income` -> rows become `Category` objects.
- Add category: `CategoryFormSheet._submit()` trims `_nameCtrl.text` and ignores empty names -> creates `CategoryRepository` -> `add()` reads max `sort_order` for the selected `is_income` group -> inserts a new row into `categories` with `uuid()`, selected name/color/icon, `is_default = 0`, income flag, and next sort order -> calls `WidgetSync.syncCategories()` -> bottom sheet closes with `Navigator.of(context).pop()`.
- Edit category: `CategoryFormSheet` receives `existing` -> initializes form fields from it -> `_submit()` builds an updated `Category` preserving `id`, `isDefault`, `isIncome`, and `sortOrder` -> `CategoryRepository.update()` updates `name`, `color_hex`, and `icon_name` in `categories` -> calls `WidgetSync.syncCategories()` -> bottom sheet closes.
- Delete category: caller invokes `CategoryRepository.delete(id)` -> repository counts matching rows in `transactions` by `category_id` -> if count is greater than zero, throws an exception -> otherwise deletes from `categories` -> calls `WidgetSync.syncCategories()`.

### PowerSync / Supabase Tables Touched
- `categories` - watched, queried, inserted, updated, and deleted by `CategoryRepository`.
- `transactions` - checked before deletion to prevent removing a category that is still used by transactions.

No direct Supabase client usage found in codebase for this feature.

### Navigation
- No GoRouter route declarations found in codebase for this feature.
- `CategoryFormSheet` exits by calling `Navigator.of(context).pop()` after a successful add or edit (`lib/features/categories/presentation/widgets/category_form_sheet.dart:89`).
- How users enter this bottom sheet is not found in codebase within `lib/features/categories`.

### Complexity Rating
Medium - the UI is small, but the feature spans derived Riverpod state, live PowerSync streams, insert ordering, guarded deletion against transaction usage, and widget sync side effects.

### TODOs / Known Issues
- No `TODO` or `FIXME` comments found in `lib/features/categories`.
- `const _uuid = Uuid();` is declared but not used in `lib/features/categories/data/category_repository.dart:6`; inserts use SQL `uuid()` instead.
- `CategoryFormSheet` instantiates `CategoryRepository()` directly instead of using `categoryRepoProvider`, so submit operations bypass Riverpod dependency injection (`lib/features/categories/presentation/widgets/category_form_sheet.dart:69`).

## Feature: habits

### Files Involved
- `lib/features/habits/data/habit_detector.dart` - Implements `HabitDetector`, which analyzes expense transaction notes and upserts recurring purchase patterns into `detected_habits`.
- `lib/features/habits/data/habit_repository.dart` - Implements `HabitRepository`, which watches pending detected habits and dismisses habits.
- `lib/features/habits/domain/detected_habit.dart` - Defines the `DetectedHabit` domain model plus due-date helper getters and map deserialization.
- `lib/features/habits/presentation/providers/habit_provider.dart` - Defines Riverpod providers for the repository, detected habit stream, due suggestions, and analysis trigger.

### What It Does
The habits feature detects repeated expense patterns from transaction history. It groups expense transactions by normalized note text, checks whether a note appears often enough and at a stable interval, stores detected recurring habits, streams non-dismissed habits, filters due suggestions, and allows detected habits to be dismissed.

### Screens & Widgets
Not found in codebase.

### Riverpod Providers
- `habitRepoProvider` - `Provider<HabitRepository>`; exposes a `HabitRepository` instance for data access.
- `detectedHabitsProvider` - `StreamProvider<List<DetectedHabit>>`; streams non-dismissed detected habits from PowerSync, ordered by `analyzed_at` descending.
- `pendingHabitSuggestionsProvider` - `Provider.autoDispose<List<DetectedHabit>>`; derives the subset of detected habits whose `DetectedHabit.isDue` getter returns true.
- `habitAnalysisProvider` - `FutureProvider.autoDispose<void>`; triggers `HabitDetector.analyze()` to run throttled habit analysis.

### Data Flow
Input: expense rows from the `transactions` table with non-empty `note` values.

Processing steps:
1. `HabitDetector.analyze()` checks `_analyzedRecently()` and skips work if any `detected_habits.analyzed_at` value is less than 24 hours old.
2. `_runAnalysis()` queries `transactions` for expense rows with notes, ordered by `created_at`.
3. Each transaction note is normalized with lowercase + trim and grouped by keyword.
4. Groups with fewer than 3 occurrences are ignored.
5. The dominant category is selected by most frequent `category_id` in the group.
6. Date gaps between occurrences are calculated; groups with median gap under 3 days are ignored.
7. Coefficient of variation is calculated; groups above `0.6` are ignored as too irregular.
8. Passing groups are upserted into `detected_habits` with keyword, category, median gap, last occurrence, occurrence count, dismissal state, and analysis timestamp.
9. `HabitRepository.watchPending()` streams non-dismissed rows from `detected_habits` and maps them to `DetectedHabit`.
10. `pendingHabitSuggestionsProvider` filters streamed habits to only those due at or after 80% of the median gap.

Output/side effects: inserts or updates rows in `detected_habits`, updates `is_dismissed` when a habit is dismissed, and emits `DetectedHabit` lists through Riverpod providers.

### PowerSync / Supabase Tables Touched
- `transactions`
- `detected_habits`

### Navigation
Not found in codebase.

### Complexity Rating
Medium - the feature has no UI surface in this folder, but the detection logic includes throttling, grouping, median gap calculation, coefficient-of-variation filtering, database upserts, and derived provider state.

### TODOs / Known Issues
Not found in codebase.

---

## Feature: home

### Files Involved
- `lib/features/home/presentation/screens/home_screen.dart` - Main home dashboard screen that shows month selection, summary cards, wallet card, feature shortcuts, and grouped transactions.
- `lib/features/home/presentation/screens/all_features_screen.dart` - Screen that displays all shortcut features grouped into sections.
- `lib/features/home/presentation/widgets/feature_grid.dart` - Reusable 4-column feature shortcut grid and action model.
- `lib/features/home/presentation/widgets/home_feature_actions.dart` - Builds home/all-feature shortcut actions and opens budget-related bottom sheets.
- `lib/features/home/presentation/widgets/month_picker_sheet.dart` - Bottom sheet for selecting a month/year, limited to non-future months and the last 3 years.
- `lib/features/home/presentation/widgets/month_selector.dart` - App-bar month selector with previous/next controls, bottom-sheet picker, and Today shortcut.
- `lib/features/home/presentation/widgets/summary_card.dart` - Balance, income, expense, and wallet-spend progress summary widgets.

### What It Does
The home feature is the app dashboard. It lets the user switch the active month, view balance/income/expense summaries, inspect wallet usage progress, jump to major finance modules, and see transactions grouped by day for the selected data stream.

### Screens & Widgets
- `HomeScreen` - `lib/features/home/presentation/screens/home_screen.dart:17`
- `AllFeaturesScreen` - `lib/features/home/presentation/screens/all_features_screen.dart:6`
- `FeatureSection` - `lib/features/home/presentation/widgets/home_feature_actions.dart:10`
- `FeatureGridAction` - `lib/features/home/presentation/widgets/feature_grid.dart:3`
- `FeatureGrid` - `lib/features/home/presentation/widgets/feature_grid.dart:17`
- `_FeatureTile` - `lib/features/home/presentation/widgets/feature_grid.dart:43`
- `MonthSelector` - `lib/features/home/presentation/widgets/month_selector.dart:6`
- `MonthPickerSheet` - `lib/features/home/presentation/widgets/month_picker_sheet.dart:6`
- `_MonthPickerSheetState` - `lib/features/home/presentation/widgets/month_picker_sheet.dart:15`
- `SummaryCards` - `lib/features/home/presentation/widgets/summary_card.dart:8`
- `_SummaryCardsState` - `lib/features/home/presentation/widgets/summary_card.dart:24`
- `_WalletProgressBar` - `lib/features/home/presentation/widgets/summary_card.dart:164`
- `WalletProgressBar` - `lib/features/home/presentation/widgets/summary_card.dart:257`
- `_MiniCard` - `lib/features/home/presentation/widgets/summary_card.dart:282`
- `_MiniCardState` - `lib/features/home/presentation/widgets/summary_card.dart:299`

### Riverpod Providers
- `selectedMonthProvider` - Type: Not found in codebase within `lib/features/home`; used like a `StateProvider<DateTime>` because `HomeScreen` watches it and writes through `.notifier.state` at `lib/features/home/presentation/screens/home_screen.dart:22` and `lib/features/home/presentation/screens/home_screen.dart:40`. Manages the currently selected month for the dashboard.
- `transactionsProvider` - Type: Not found in codebase within `lib/features/home`; watched as an async value at `lib/features/home/presentation/screens/home_screen.dart:23` and consumed with `.when` at `lib/features/home/presentation/screens/home_screen.dart:61`. Manages the transaction list displayed on the home screen.
- `summaryProvider` - Type: Not found in codebase within `lib/features/home`; watched synchronously at `lib/features/home/presentation/screens/home_screen.dart:24`. Manages aggregate `income`, `expense`, and `balance` values passed into `SummaryCards`.
- `categoriesProvider` - Type: Not found in codebase within `lib/features/home`; watched as an async value at `lib/features/home/presentation/screens/home_screen.dart:25`. Provides categories used to map `Transaction.categoryId` to `Category` for transaction list rows.
- `totalWalletBreakdownProvider` - Type: Not found in codebase within `lib/features/home`; watched as an async value at `lib/features/home/presentation/widgets/summary_card.dart:37`. Provides wallet progress values `x1` and `x2` for `_WalletProgressBar`.

### Data Flow
Input -> User changes month through `MonthSelector` previous/next buttons or `MonthPickerSheet`; `HomeScreen` writes the selected `DateTime` into `selectedMonthProvider`.
Processing -> `HomeScreen` watches `transactionsProvider`, `summaryProvider`, and `categoriesProvider`; it builds a category lookup map, renders loading/error/data states, and groups transactions by `createdAt` year/month/day in `_buildGroupedList`.
Output/side-effects -> The screen renders `SummaryCards`, `WalletCardHome`, `FeatureGrid`, empty-state messaging, and `TransactionListItem` rows; shortcut taps push routes through GoRouter or open budget bottom sheets.
Input -> User toggles visibility in `SummaryCards` or `_MiniCard`.
Processing -> Local widget state flips `_balanceVisible` or `_visible`.
Output/side-effects -> Amounts are shown with `formatVND` or hidden behind bullet placeholders; no persistent side-effect is performed in this feature.

### PowerSync / Supabase Tables Touched
Not found in codebase. No exact PowerSync or Supabase table names are referenced inside `lib/features/home`.

### Navigation
- User entry route to `HomeScreen`: Not found in codebase within `lib/features/home`.
- User entry route to `AllFeaturesScreen`: Not found in codebase within `lib/features/home`.
- `buildHomeFeatureActions` pushes `/add`, `/transactions`, `/wallets`, `/loans`, `/reminders`, `/stats`, and `/features` from `lib/features/home/presentation/widgets/home_feature_actions.dart:20`.
- `buildAllFeatureSections` pushes `/add`, `/transactions`, `/wallets`, `/loans`, `/loans?type=borrowed`, `/loans?type=lent`, `/stats`, `/reminders`, and `/settings` from `lib/features/home/presentation/widgets/home_feature_actions.dart:73`.
- Budget actions open modal bottom sheets for `BudgetTypeSheet`, `BudgetScreen`, and `CategoryBudgetScreen` at `lib/features/home/presentation/widgets/home_feature_actions.dart:206`.
- `MonthSelector` opens `MonthPickerSheet` with `showModalBottomSheet<DateTime>` at `lib/features/home/presentation/widgets/month_selector.dart:25`; `MonthPickerSheet` exits by `Navigator.pop(context, DateTime(_year, m))` at `lib/features/home/presentation/widgets/month_picker_sheet.dart:139`.

### Complexity Rating
Medium - The feature is mostly presentation composition, but it coordinates multiple external Riverpod data sources, local visibility state, transaction grouping, route shortcuts, and modal bottom sheets.

### TODOs / Known Issues
- Not found in codebase. No TODO or FIXME comments were found in `lib/features/home`.

## Feature: loan

### Files Involved
- `lib/features/loan/data/loan_repository.dart` - PowerSync-backed repository for loan CRUD, payment CRUD, and remaining-balance summary queries.
- `lib/features/loan/domain/loan.dart` - Domain enums and models for `LoanType`, `LoanStatus`, `Loan`, and `LoanPayment`.
- `lib/features/loan/presentation/providers/loan_provider.dart` - Riverpod providers exposing repository, loan streams, active-loan filtering, and home/settings summary state.
- `lib/features/loan/presentation/screens/loan_detail_screen.dart` - Detail screen for one loan, including edit, close/reopen, delete, payment history, and add/delete payment flows.
- `lib/features/loan/presentation/screens/loan_list_screen.dart` - Loan list screen with optional borrowed/lent filtering, active/closed sections, empty state, and add form entry.
- `lib/features/loan/presentation/widgets/loan_form_sheet.dart` - Bottom-sheet form for creating or editing a loan, including type, title, contact, due date, note, amount, and color defaults.
- `lib/features/loan/presentation/widgets/loan_mini_card.dart` - Home summary card that shows active loan totals and overdue/upcoming status, linking to `/loans`.
- `lib/features/loan/presentation/widgets/loan_settings_tile.dart` - Settings list tile that summarizes loan count/alerts and links to `/loans`.
- `lib/features/loan/presentation/widgets/quick_actions_bar.dart` - Home quick actions row with budget, borrowed, lent, disabled placeholder, and all-loans shortcuts.

### What It Does
The loan feature lets users track money they borrowed and money they lent. Users can create/edit loans, set an optional due date, attach contact/name and notes, mark loans as settled or reopen them, delete loans, record partial payments, delete payment records, and view active/closed loans. Summary widgets surface remaining borrowed/lent balances and overdue/upcoming due-date alerts on home/settings entry points.

### Screens & Widgets
- `LoanListScreen` - `lib/features/loan/presentation/screens/loan_list_screen.dart:11`; main list screen with optional `filterType` for all, borrowed, or lent loans.
- `_SectionHeader` - `lib/features/loan/presentation/screens/loan_list_screen.dart:114`; private section label for active/closed groups.
- `_LoanTile` - `lib/features/loan/presentation/screens/loan_list_screen.dart:140`; private tappable loan row that opens loan detail.
- `_EmptyState` - `lib/features/loan/presentation/screens/loan_list_screen.dart:230`; private empty state for no loans in the current filter.
- `LoanDetailScreen` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:14`; loan detail and payment history screen.
- `_LoanDetailScreenState` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:22`; private state handling live loan refresh, menu actions, and payment operations.
- `_InfoCard` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:233`; private loan summary/info card.
- `_MetaChip` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:366`; private date metadata chip.
- `_PaidSummaryRow` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:395`; private principal/paid/remaining progress row.
- `_PaymentTile` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:458`; private payment history row with delete action.
- `_AddPaymentSheet` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:500`; private bottom sheet for recording a payment.
- `_AddPaymentSheetState` - `lib/features/loan/presentation/screens/loan_detail_screen.dart:508`; private amount/note submission state for payments.
- `LoanFormSheet` - `lib/features/loan/presentation/widgets/loan_form_sheet.dart:9`; create/edit loan bottom sheet.
- `_LoanFormSheetState` - `lib/features/loan/presentation/widgets/loan_form_sheet.dart:20`; private form state for loan input, due-date picker, and repository submission.
- `LoanMiniCard` - `lib/features/loan/presentation/widgets/loan_mini_card.dart:11`; compact home summary card.
- `LoanSettingsTile` - `lib/features/loan/presentation/widgets/loan_settings_tile.dart:10`; settings entry tile.
- `QuickActionsBar` - `lib/features/loan/presentation/widgets/quick_actions_bar.dart:10`; quick shortcut row.
- `_BadgeData` - `lib/features/loan/presentation/widgets/quick_actions_bar.dart:134`; private badge state holder.
- `_ActionChip` - `lib/features/loan/presentation/widgets/quick_actions_bar.dart:148`; private reusable quick action chip.
- `_ActionChipState` - `lib/features/loan/presentation/widgets/quick_actions_bar.dart:165`; private pulse animation state for alert badges.
- `_PulseBadge` - `lib/features/loan/presentation/widgets/quick_actions_bar.dart:258`; private animated badge renderer.
- Domain classes/enums: `LoanType` (`lib/features/loan/domain/loan.dart:4`), `LoanStatus` (`lib/features/loan/domain/loan.dart:14`), `Loan` (`lib/features/loan/domain/loan.dart:21`), `LoanPayment` (`lib/features/loan/domain/loan.dart:81`).

### Riverpod Providers
- `loanRepoProvider` - `Provider` at `lib/features/loan/presentation/providers/loan_provider.dart:5`; creates `LoanRepository`.
- `loansProvider` - `StreamProvider<List<Loan>>` at `lib/features/loan/presentation/providers/loan_provider.dart:7`; streams all loans from `LoanRepository.watchAll()`.
- `activeLoansProvider` - `Provider.autoDispose<List<Loan>>` at `lib/features/loan/presentation/providers/loan_provider.dart:12`; derives non-closed loans from `loansProvider`.
- `loanSummaryProvider` - `StreamProvider.autoDispose<LoanSummary>` at `lib/features/loan/presentation/providers/loan_provider.dart:52`; streams aggregate remaining borrowed/lent balances and due-date alert counts from `LoanRepository.watchSummaryWithRemaining()`.
- `loanSummaryDataProvider` - `Provider.autoDispose<LoanSummary>` at `lib/features/loan/presentation/providers/loan_provider.dart:60`; exposes a non-async fallback summary for UI widgets while summary loading/errors occur.
- `_paymentsProvider` - `StreamProvider.autoDispose.family<List<LoanPayment>, String>` at `lib/features/loan/presentation/screens/loan_detail_screen.dart:227`; streams payments for a single loan id via `LoanRepository.watchPayments(loanId)`.
- `budgetProgressProvider` - referenced in `lib/features/loan/presentation/widgets/quick_actions_bar.dart:16` but defined outside `lib/features/loan`; not audited per scope, so state details are Not found in codebase.

### Data Flow
- Loan list: `LoanListScreen` watches `loansProvider` (`loan_list_screen.dart:19`), `loansProvider` calls `LoanRepository.watchAll()` (`loan_provider.dart:7`), repository watches `SELECT * FROM loans ORDER BY is_closed ASC, start_date DESC` (`loan_repository.dart:8-11`), UI filters by `filterType` (`loan_list_screen.dart:87-93`), then renders active and closed sections.
- Create/edit loan: user opens `LoanFormSheet` from the list (`loan_list_screen.dart:97-107`) or detail edit action (`loan_detail_screen.dart:51-54`), enters fields and amount, `_submit()` builds a `Loan` (`loan_form_sheet.dart:76-93`), then calls `LoanRepository.add()` or `LoanRepository.update()` (`loan_form_sheet.dart:95-99`). Side effect: inserts/updates `loans`, then closes the sheet (`loan_form_sheet.dart:100`).
- Loan detail: list tile pushes `LoanDetailScreen` (`loan_list_screen.dart:162-163`); detail screen refreshes the passed loan from `loansProvider` and watches `_paymentsProvider(loan.id)` (`loan_detail_screen.dart:26-34`). It computes `totalPaid` and `remaining` from streamed payments (`loan_detail_screen.dart:86-88`) and renders progress/history.
- Close/reopen/delete loan: detail overflow menu calls `_handleMenu()` (`loan_detail_screen.dart:155-187`), which calls `LoanRepository.close()`, `reopen()`, or `delete()`. Delete first removes `loan_payments` for the loan and then the `loans` row (`loan_repository.dart:73-75`), then exits the detail screen (`loan_detail_screen.dart:185-186`).
- Payment flow: user opens `_AddPaymentSheet` (`loan_detail_screen.dart:191-195`), enters amount/note, `_submit()` calls `LoanRepository.addPayment()` with `DateTime.now()` (`loan_detail_screen.dart:526-536`). Deleting a payment confirms, then calls `LoanRepository.deletePayment()` (`loan_detail_screen.dart:199-219`). Side effects insert/delete rows in `loan_payments`.
- Summary widgets: `LoanMiniCard`, `LoanSettingsTile`, and `QuickActionsBar` watch `loanSummaryDataProvider` (`loan_mini_card.dart:16`, `loan_settings_tile.dart:15`, `quick_actions_bar.dart:15`). `loanSummaryProvider` delegates to `watchSummaryWithRemaining()` (`loan_provider.dart:52-55`), which left-joins `loans` and `loan_payments`, groups by loan, clamps remaining balance to `0..principal`, and counts overdue/upcoming due dates (`loan_repository.dart:121-189`). Output is UI badge/totals and navigation shortcuts.

### PowerSync / Supabase Tables Touched
- `loans` - selected, inserted, updated, marked closed/reopened, deleted, and joined in summary queries (`lib/features/loan/data/loan_repository.dart:10`, `:16`, `:23`, `:41`, `:61`, `:68`, `:75`, `:133`).
- `loan_payments` - selected, summed, inserted, deleted individually, deleted by loan, and left-joined for summaries (`lib/features/loan/data/loan_repository.dart:74`, `:83`, `:91`, `:104`, `:112`, `:134`).
- Supabase-specific API calls: Not found in codebase for this feature; this feature accesses local PowerSync `db` only from `LoanRepository`.

### Navigation
- Home mini card enters the feature with `context.push('/loans')` (`lib/features/loan/presentation/widgets/loan_mini_card.dart:42`).
- Settings tile enters the feature with `context.push('/loans')` (`lib/features/loan/presentation/widgets/loan_settings_tile.dart:73`).
- Quick actions enter filtered/all views with `context.push('/loans?type=borrowed')`, `context.push('/loans?type=lent')`, and `context.push('/loans')` (`lib/features/loan/presentation/widgets/quick_actions_bar.dart:95`, `:104`, `:123`).
- `LoanListScreen` opens `LoanFormSheet` via `showModalBottomSheet()` (`lib/features/loan/presentation/screens/loan_list_screen.dart:97-107`).
- `LoanListScreen` opens detail with `Navigator.of(context).push(MaterialPageRoute(... LoanDetailScreen ...))` (`lib/features/loan/presentation/screens/loan_list_screen.dart:162-163`).
- `LoanDetailScreen` opens edit and add-payment sheets via `showModalBottomSheet()` (`lib/features/loan/presentation/screens/loan_detail_screen.dart:51-54`, `:191-195`).
- Exits happen through `Navigator.of(context).pop()` after form/payment submit, delete confirmation dialogs, or deleting a loan (`loan_form_sheet.dart:100`, `loan_detail_screen.dart:172`, `:176`, `:185-186`, `:206`, `:210`, `:536`).

### Complexity Rating
Medium - the feature is mostly straightforward CRUD, but complexity rises because it combines live PowerSync streams, derived summary aggregation, due-date alert logic, multiple entry widgets, modal forms, and nested payment management.

### TODOs / Known Issues
- TODO/FIXME comments: Not found in codebase.
- Known issue from audited code: the user-facing Vietnamese text appears mojibake/encoding-corrupted in the source files, for example labels like `Khoáº£n vay` in multiple widgets; exact intended strings are not recoverable from the audited feature files alone.

## Feature: reminders

### Files Involved
- `lib/features/reminders/data/reminder_repository.dart` - PowerSync repository for CRUD and watching `recurring_reminders` records.
- `lib/features/reminders/domain/recurring_reminder.dart` - Domain model, frequency enum/labels, next-trigger calculation, warning-trigger helper, and built-in reminder presets.
- `lib/features/reminders/presentation/providers/reminder_provider.dart` - Riverpod providers and action facade that coordinate repository writes with local notification scheduling/cancellation.
- `lib/features/reminders/presentation/screens/reminders_screen.dart` - Main reminders UI, quick presets, habit-based suggestions, reminder list items, empty state, and debug notification/test-data panel.
- `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart` - Modal bottom sheet form for creating or editing recurring reminders.

### What It Does
The reminders feature lets users create recurring expense reminders for daily, weekly, or monthly spending events, optionally with a suggested amount and category. Users can add reminders from scratch, use quick presets, accept suggestions derived from detected spending habits, edit existing reminders, toggle them active/inactive, delete them, and schedule local notifications for active reminders.

### Screens & Widgets
- `RemindersScreen` - main feature screen; watches reminders and renders loading/error/empty/list states (`lib/features/reminders/presentation/screens/reminders_screen.dart:16`).
- `_HabitSuggestionSection` - shows habit-derived reminder suggestions not already represented by existing reminder titles (`lib/features/reminders/presentation/screens/reminders_screen.dart:88`).
- `_HabitSuggestionTile` - renders one detected-habit suggestion with create and dismiss actions (`lib/features/reminders/presentation/screens/reminders_screen.dart:136`).
- `_DebugPanel` - debug-only panel for scheduling a test notification and seeding habit test transaction data (`lib/features/reminders/presentation/screens/reminders_screen.dart:267`).
- `_PresetSection` - horizontal quick-create preset chips, excluding presets already used by title (`lib/features/reminders/presentation/screens/reminders_screen.dart:581`).
- `_ReminderTile` - list tile for an existing reminder with active switch, edit action, and delete action (`lib/features/reminders/presentation/screens/reminders_screen.dart:657`).
- `_EmptyState` - empty reminder state with add button, presets, and habit suggestions (`lib/features/reminders/presentation/screens/reminders_screen.dart:753`).
- `ReminderFormSheet` - create/edit modal form for title, category, suggested amount, frequency, schedule day/time, and submit action (`lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:9`).
- `_ReminderFormSheetState` - mutable form state and submit logic for `ReminderFormSheet` (`lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:27`).

### Riverpod Providers
- `reminderRepoProvider` - `Provider<ReminderRepository>`; constructs the repository used for PowerSync reminder access (`lib/features/reminders/presentation/providers/reminder_provider.dart:6`).
- `remindersProvider` - `StreamProvider<List<RecurringReminder>>`; watches all reminders ordered by title and exposes live reminder list state to the UI (`lib/features/reminders/presentation/providers/reminder_provider.dart:8`).
- `reminderActionsProvider` - `Provider<ReminderActions>`; exposes add/update/toggle/delete commands that combine database writes with notification scheduling/cancellation (`lib/features/reminders/presentation/providers/reminder_provider.dart:12`).
- External providers consumed but not defined in this feature: `habitAnalysisProvider`, `pendingHabitSuggestionsProvider`, `habitRepoProvider`, and `expenseCategoriesProvider` (`lib/features/reminders/presentation/screens/reminders_screen.dart:22`, `lib/features/reminders/presentation/screens/reminders_screen.dart:95`, `lib/features/reminders/presentation/screens/reminders_screen.dart:146`, `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:134`).

### Data Flow
Input -> processing steps -> output/side-effects:
- Opening `RemindersScreen` watches `habitAnalysisProvider` and `remindersProvider`; `remindersProvider` streams rows from `ReminderRepository.watchAll()`; rows are mapped through `RecurringReminder.fromMap`; UI renders empty state, preset suggestions, habit suggestions, reminder tiles, and debug controls (`lib/features/reminders/presentation/screens/reminders_screen.dart:22`, `lib/features/reminders/presentation/screens/reminders_screen.dart:24`, `lib/features/reminders/data/reminder_repository.dart:5`).
- Add reminder: user opens `ReminderFormSheet`, enters title/category/amount/frequency/time; `_submit()` computes `nextTrigger` using `RecurringReminder.calcNextTrigger`; `ReminderActions.add()` inserts a row through `ReminderRepository.add()`, re-reads all reminders to find the DB-generated id, then calls `ReminderNotificationService.schedule(saved)` (`lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:78`, `lib/features/reminders/presentation/providers/reminder_provider.dart:20`, `lib/features/reminders/data/reminder_repository.dart:26`).
- Edit reminder: user opens `ReminderFormSheet(existing: reminder)` from the reminder tile; `_submit()` builds an updated `RecurringReminder`; `ReminderActions.update()` writes changes and either schedules or cancels notification based on `isActive` (`lib/features/reminders/presentation/screens/reminders_screen.dart:723`, `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:91`, `lib/features/reminders/presentation/providers/reminder_provider.dart:28`).
- Toggle active: `_ReminderTile` switch calls `ReminderActions.toggleActive()`; repository updates `is_active`; enabling recalculates `nextTrigger` and schedules notification, disabling cancels notification (`lib/features/reminders/presentation/screens/reminders_screen.dart:709`, `lib/features/reminders/presentation/providers/reminder_provider.dart:37`).
- Delete reminder: popup delete action calls `ReminderActions.delete()`; notification is cancelled first, then repository deletes the row (`lib/features/reminders/presentation/screens/reminders_screen.dart:727`, `lib/features/reminders/presentation/providers/reminder_provider.dart:67`).
- Habit suggestion: suggestions from `pendingHabitSuggestionsProvider` are filtered against existing reminder titles; create opens `ReminderFormSheet` with a generated `ReminderPreset` and `preselectedCategoryId`; dismiss calls `habitRepoProvider.dismiss(habit.id)` (`lib/features/reminders/presentation/screens/reminders_screen.dart:95`, `lib/features/reminders/presentation/screens/reminders_screen.dart:101`, `lib/features/reminders/presentation/screens/reminders_screen.dart:235`, `lib/features/reminders/presentation/screens/reminders_screen.dart:146`).
- Debug test notification: `_DebugPanel` builds a temporary reminder with a near-future `nextTrigger` and calls `ReminderNotificationService.scheduleTest(testReminder)`; seed action inserts sample rows into `transactions` after selecting one expense category (`lib/features/reminders/presentation/screens/reminders_screen.dart:299`, `lib/features/reminders/presentation/screens/reminders_screen.dart:334`).

### PowerSync / Supabase Tables Touched
- `recurring_reminders` - watched, read by id, inserted, updated, activated/deactivated, and deleted by `ReminderRepository` (`lib/features/reminders/data/reminder_repository.dart:7`, `lib/features/reminders/data/reminder_repository.dart:13`, `lib/features/reminders/data/reminder_repository.dart:20`, `lib/features/reminders/data/reminder_repository.dart:28`, `lib/features/reminders/data/reminder_repository.dart:50`, `lib/features/reminders/data/reminder_repository.dart:74`, `lib/features/reminders/data/reminder_repository.dart:81`).
- `categories` - debug panel selects one expense category id for seeding test habit data (`lib/features/reminders/presentation/screens/reminders_screen.dart:337`).
- `transactions` - debug panel inserts sample expense transactions for habit-analysis testing (`lib/features/reminders/presentation/screens/reminders_screen.dart:347`, `lib/features/reminders/presentation/screens/reminders_screen.dart:356`, `lib/features/reminders/presentation/screens/reminders_screen.dart:365`).
- Direct Supabase API usage: Not found in codebase for this feature.

### Navigation
No GoRouter route declarations or route names are defined inside `lib/features/reminders`. Entry into the feature is via `RemindersScreen` when another part of the app routes to or embeds it; that route definition is not found in codebase within this feature. In-feature navigation is modal-based: add/preset/habit/edit actions call `showModalBottomSheet(...)` with `ReminderFormSheet`, and successful submit exits the sheet with `Navigator.of(context).pop()` (`lib/features/reminders/presentation/screens/reminders_screen.dart:78`, `lib/features/reminders/presentation/screens/reminders_screen.dart:250`, `lib/features/reminders/presentation/screens/reminders_screen.dart:623`, `lib/features/reminders/presentation/screens/reminders_screen.dart:723`, `lib/features/reminders/presentation/widgets/reminder_form_sheet.dart:125`).

### Complexity Rating
Medium - the feature has a small file count and straightforward CRUD UI, but complexity increases because reminder persistence is coupled to local notification scheduling and habit-derived suggestions, plus debug-only database seeding.

### TODOs / Known Issues
- No TODO or FIXME comments found in `lib/features/reminders`.

---

## Feature: settings

### Files Involved
- `lib/features/settings/domain/sepay_bank_account.dart` - Domain model for a SePay-linked bank account, including JSON mapping and display-name formatting.
- `lib/features/settings/presentation/providers/gdrive_provider.dart` - Riverpod state/notifier for Google Drive sign-in, backup timing, manual backup, and Workmanager auto-backup scheduling.
- `lib/features/settings/presentation/providers/sepay_provider.dart` - Riverpod async notifier for loading and mutating SePay bank-account mappings in Supabase.
- `lib/features/settings/presentation/providers/widget_pin_provider.dart` - Riverpod state notifier for four home-widget pinned category IDs stored in SharedPreferences.
- `lib/features/settings/presentation/screens/settings_screen.dart` - Main settings screen with export, backup/restore, SePay, Google Drive, theme, notification, reminders, widget-pin, and category-management sections.
- `lib/features/settings/presentation/widgets/gdrive_backup_section.dart` - Google Drive backup UI for sign-in/out, auto-backup frequency, manual backup, and Drive restore dialogs.
- `lib/features/settings/presentation/widgets/sepay_connection_section.dart` - SePay settings UI for opening SePay dashboard, listing mappings, adding mappings, toggling sync, and deleting mappings.
- `lib/features/settings/presentation/widgets/widget_pin_section.dart` - Home-widget pinning UI for selecting up to four expense categories and syncing them to the native widget.

### What It Does
The settings feature is a central configuration and maintenance screen. Users can export transaction CSVs, export or restore full JSON backups, configure SePay bank-account mappings for automatic bank import, connect Google Drive for cloud backup/restore, change theme mode/color, configure daily expense-entry notifications, open recurring reminders, choose home-widget category shortcuts, and manage income/expense categories.

### Screens & Widgets
- `SettingsScreen` - `lib/features/settings/presentation/screens/settings_screen.dart:23`
- `_RestorePreviewDialog` - `lib/features/settings/presentation/screens/settings_screen.dart:731`
- `_ImportPreviewDialog` - `lib/features/settings/presentation/screens/settings_screen.dart:849`
- `_PreviewRow` - `lib/features/settings/presentation/screens/settings_screen.dart:936`
- `_SectionHeader` - `lib/features/settings/presentation/screens/settings_screen.dart:964`
- `_ExportTile` - `lib/features/settings/presentation/screens/settings_screen.dart:986`
- `_CategoryTile` - `lib/features/settings/presentation/screens/settings_screen.dart:1025`
- `_ThemeTile` - `lib/features/settings/presentation/screens/settings_screen.dart:1089`
- `_CategoriesExpansionTile` - `lib/features/settings/presentation/screens/settings_screen.dart:1123`
- `_CategoriesExpansionTileState` - `lib/features/settings/presentation/screens/settings_screen.dart:1145`
- `_TabChip` - `lib/features/settings/presentation/screens/settings_screen.dart:1271`
- `_ThemeColorSheet` - `lib/features/settings/presentation/screens/settings_screen.dart:1314`
- `GDriveBackupSection` - `lib/features/settings/presentation/widgets/gdrive_backup_section.dart:10`
- `SepayConnectionSection` - `lib/features/settings/presentation/widgets/sepay_connection_section.dart:13`
- `_AccountTile` - `lib/features/settings/presentation/widgets/sepay_connection_section.dart:149`
- `_AddMappingSheet` - `lib/features/settings/presentation/widgets/sepay_connection_section.dart:215`
- `_AddMappingSheetState` - `lib/features/settings/presentation/widgets/sepay_connection_section.dart:223`
- `WidgetPinSection` - `lib/features/settings/presentation/widgets/widget_pin_section.dart:10`
- `_SlotCard` - `lib/features/settings/presentation/widgets/widget_pin_section.dart:90`
- `_CategoryPickerSheet` - `lib/features/settings/presentation/widgets/widget_pin_section.dart:178`

### Riverpod Providers
- `gdriveProvider` - `StateNotifierProvider<GDriveNotifier, GDriveState>`; manages Google Drive connection state, signed-in email, last backup time, selected `BackupFrequency`, loading/error/success UI state, and auto-backup scheduling (`lib/features/settings/presentation/providers/gdrive_provider.dart:81`).
- `sepayAccountsProvider` - `AsyncNotifierProvider<SepayAccountsNotifier, List<SepayBankAccount>>`; loads the current user's SePay bank-account mappings and supports active toggle, add/upsert, and delete mutations (`lib/features/settings/presentation/providers/sepay_provider.dart:9`).
- `widgetPinnedIdsProvider` - `StateNotifierProvider<WidgetPinnedNotifier, List<String>>`; manages four pinned category IDs for the home-screen widget and persists them as JSON in SharedPreferences (`lib/features/settings/presentation/providers/widget_pin_provider.dart:7`).
- External providers referenced but defined outside `lib/features/settings`: `categoriesProvider`, `expenseCategoriesProvider`, `themeModeProvider`, `themeProvider`, `notificationEnabledProvider`, `notificationHourProvider`, `notificationMinuteProvider`, and `transactionsProvider`. Their provider types are not found in codebase within this feature because definitions are outside the allowed audit path.

### Data Flow
- CSV export: user taps an export range in `SettingsScreen`; `_export()` calls `ExportService.exportCSV(range)`; errors are surfaced by SnackBar (`lib/features/settings/presentation/screens/settings_screen.dart:47`, `lib/features/settings/presentation/screens/settings_screen.dart:491`).
- Local JSON backup export: user taps full backup export; `_exportBackup()` shows a loading dialog, calls `BackupService.exportBackup()`, then reports exported counts in a SnackBar (`lib/features/settings/presentation/screens/settings_screen.dart:123`, `lib/features/settings/presentation/screens/settings_screen.dart:505`).
- Local JSON restore: user taps restore; `_restore()` picks a backup file, previews it, shows `_RestorePreviewDialog`, calls `BackupService.restore(filePath)`, invalidates `transactionsProvider` and `categoriesProvider`, then shows restore counts (`lib/features/settings/presentation/screens/settings_screen.dart:153`, `lib/features/settings/presentation/screens/settings_screen.dart:548`, `lib/features/settings/presentation/screens/settings_screen.dart:605`).
- SePay mapping: `SepayConnectionSection` watches `sepayAccountsProvider`; the notifier reads rows for the current Supabase user from `sepay_bank_accounts`; add/toggle/delete actions write to the same table and invalidate the provider (`lib/features/settings/presentation/widgets/sepay_connection_section.dart:21`, `lib/features/settings/presentation/providers/sepay_provider.dart:18`, `lib/features/settings/presentation/providers/sepay_provider.dart:34`, `lib/features/settings/presentation/providers/sepay_provider.dart:43`, `lib/features/settings/presentation/providers/sepay_provider.dart:68`).
- Google Drive backup: `GDriveBackupSection` watches `gdriveProvider`; sign-in delegates to `GDriveAuthService`, backup/restore delegates to `GDriveBackupService`, frequency is saved in SharedPreferences, and periodic auto-backup is registered/cancelled through Workmanager (`lib/features/settings/presentation/widgets/gdrive_backup_section.dart:15`, `lib/features/settings/presentation/providers/gdrive_provider.dart:93`, `lib/features/settings/presentation/providers/gdrive_provider.dart:117`, `lib/features/settings/presentation/providers/gdrive_provider.dart:147`, `lib/features/settings/presentation/providers/gdrive_provider.dart:169`).
- Theme settings: `SettingsScreen` watches theme providers, calls `themeProvider.notifier.setMode(...)` for system/light/dark, and opens `_ThemeColorSheet` to call `setColorScheme(...)` (`lib/features/settings/presentation/screens/settings_screen.dart:175`, `lib/features/settings/presentation/screens/settings_screen.dart:185`, `lib/features/settings/presentation/screens/settings_screen.dart:231`, `lib/features/settings/presentation/screens/settings_screen.dart:1357`).
- Notifications: `SettingsScreen` watches notification enabled/hour/minute providers, requests permission before enabling reminders, schedules daily reminders after time changes, and can send a test notification (`lib/features/settings/presentation/screens/settings_screen.dart:248`, `lib/features/settings/presentation/screens/settings_screen.dart:277`, `lib/features/settings/presentation/screens/settings_screen.dart:309`, `lib/features/settings/presentation/screens/settings_screen.dart:351`).
- Widget pins: `WidgetPinSection` reads expense categories and pinned IDs, lets the user choose a category in `_CategoryPickerSheet`, persists the selected slot via `widgetPinnedIdsProvider`, and calls `WidgetSync.syncCategories()` after set/clear (`lib/features/settings/presentation/widgets/widget_pin_section.dart:15`, `lib/features/settings/presentation/widgets/widget_pin_section.dart:64`, `lib/features/settings/presentation/widgets/widget_pin_section.dart:81`, `lib/features/settings/presentation/widgets/widget_pin_section.dart:46`).
- Category management: `SettingsScreen` reads categories, splits them into expense/income, opens `CategoryFormSheet` for add/edit, and calls `CategoryRepository().delete(cat.id)` after confirmation (`lib/features/settings/presentation/screens/settings_screen.dart:28`, `lib/features/settings/presentation/screens/settings_screen.dart:417`, `lib/features/settings/presentation/screens/settings_screen.dart:434`, `lib/features/settings/presentation/screens/settings_screen.dart:450`).

### PowerSync / Supabase Tables Touched
- `sepay_bank_accounts` - selected, updated, upserted, and deleted directly through `Supabase.instance.client.from('sepay_bank_accounts')` (`lib/features/settings/presentation/providers/sepay_provider.dart:23`, `lib/features/settings/presentation/providers/sepay_provider.dart:36`, `lib/features/settings/presentation/providers/sepay_provider.dart:53`, `lib/features/settings/presentation/providers/sepay_provider.dart:70`).
- Direct PowerSync table references in `lib/features/settings`: Not found in codebase.
- Other tables may be touched by imported services/repositories such as `BackupService`, `ImportService`, `ExportService`, `CategoryRepository`, `WalletRepository`, or `GDriveBackupService`, but their implementations are outside `lib/features/settings` and were not read per the audit restriction.

### Navigation
Entry route into `SettingsScreen` is not defined inside `lib/features/settings`; route definition is not found in codebase within this feature. Inside the feature, the only explicit GoRouter navigation is `context.push('/reminders')` from the recurring reminders tile (`lib/features/settings/presentation/screens/settings_screen.dart:399`). Most interactions use modal UI: category forms and theme color picker use `showModalBottomSheet(...)`, SePay add mapping uses `showModalBottomSheet(...)`, backup/restore flows use `showDialog(...)`, and SePay dashboard opens the external URL `https://my.sepay.vn` with `launchUrl(..., LaunchMode.externalApplication)` (`lib/features/settings/presentation/screens/settings_screen.dart:231`, `lib/features/settings/presentation/screens/settings_screen.dart:435`, `lib/features/settings/presentation/widgets/sepay_connection_section.dart:16`, `lib/features/settings/presentation/widgets/sepay_connection_section.dart:95`, `lib/features/settings/presentation/widgets/gdrive_backup_section.dart:121`).

### Complexity Rating
High - the settings screen itself is broad and coordinates local preferences, Supabase mutations, file import/export, Google Drive auth/backup/restore, Workmanager scheduling, notifications, widget sync, category editing, and cross-feature provider invalidation.

### TODOs / Known Issues
- No TODO or FIXME comments found in `lib/features/settings`.

## Feature: stats

### Files Involved
- `lib/features/stats/presentation/providers/stats_provider.dart` - Defines the stats date-range model and Riverpod providers that load and aggregate transaction stats.
- `lib/features/stats/presentation/screens/stats_screen.dart` - Main stats screen with two tabs: category pie chart and daily/weekly spending chart.
- `lib/features/stats/presentation/widgets/date_range_picker_sheet.dart` - Bottom sheet for selecting preset or custom stats date ranges.
- `lib/features/stats/presentation/widgets/stats_time_selector.dart` - AppBar date selector with previous/next month, reset, and bottom-sheet launcher controls.

### What It Does
The stats feature lets users view transaction analytics for a selected month or custom date range. It shows expense distribution by category in a pie chart, daily or weekly expense bars for shorter ranges, and per-day income/expense/net totals. Date selection supports current month, previous month, last 3 months, current year, and a custom date range.

### Screens & Widgets
- `StatsScreen` - `lib/features/stats/presentation/screens/stats_screen.dart:14`; top-level stats screen with AppBar date selector and two tabs.
- `_StatsScreenState` - `lib/features/stats/presentation/screens/stats_screen.dart:21`; owns the two-tab `TabController`.
- `_CategoryTab` - `lib/features/stats/presentation/screens/stats_screen.dart:59`; category analytics tab.
- `_CategoryTabState` - `lib/features/stats/presentation/screens/stats_screen.dart:66`; builds the pie chart, handles touched pie section state, and renders category legend rows.
- `_LegendRow` - `lib/features/stats/presentation/screens/stats_screen.dart:161`; displays one category legend item with color, name, percent, and amount.
- `_DailyTab` - `lib/features/stats/presentation/screens/stats_screen.dart:211`; daily/weekly spending chart tab plus per-day detail rows.
- `_DailyRow` - `lib/features/stats/presentation/screens/stats_screen.dart:478`; displays one day of income, expense, and net total.
- `_EmptyStats` - `lib/features/stats/presentation/screens/stats_screen.dart:546`; empty state shown when no stats data is available.
- `DateRangePickerSheet` - `lib/features/stats/presentation/widgets/date_range_picker_sheet.dart:6`; bottom sheet for preset and custom date range selection.
- `_PresetTile` - `lib/features/stats/presentation/widgets/date_range_picker_sheet.dart:224`; reusable preset row for the date-range picker.
- `StatsTimeSelector` - `lib/features/stats/presentation/widgets/stats_time_selector.dart:8`; compact AppBar control for changing the active stats date range.
- `StatsDateRange` - `lib/features/stats/presentation/providers/stats_provider.dart:9`; value model for month/custom ranges with label and day-span helpers.

### Riverpod Providers
- `statsDateRangeProvider` - `StateProvider<StatsDateRange>` at `lib/features/stats/presentation/providers/stats_provider.dart:59`; stores the active stats date range, defaulting to the current month.
- `statsTransactionsProvider` - `StreamProvider.autoDispose<List<Transaction>>` at `lib/features/stats/presentation/providers/stats_provider.dart:66`; watches transactions for the active range by calling `transactionRepoProvider.watchByDateRange(range.start, range.end)`.
- `statsExpensesByCategoryProvider` - `Provider.autoDispose<Map<String, int>>` at `lib/features/stats/presentation/providers/stats_provider.dart:74`; aggregates expense transaction amounts by `categoryId` for the category pie chart.
- `statsDailyTotalsProvider` - `Provider.autoDispose<Map<DateTime, ({int income, int expense})>>` at `lib/features/stats/presentation/providers/stats_provider.dart:85`; groups transactions by calendar day and totals income/expense for each date.
- `statsSummaryProvider` - `Provider.autoDispose<({int income, int expense, int balance})>` at `lib/features/stats/presentation/providers/stats_provider.dart:101`; computes total income, total expense, and balance for the active range. Not referenced by widgets inside this feature folder.

### Data Flow
1. User changes the active range through `StatsTimeSelector` previous/next/reset controls or `DateRangePickerSheet` presets/custom picker (`stats_time_selector.dart:30`, `stats_time_selector.dart:86`, `stats_time_selector.dart:119`, `date_range_picker_sheet.dart:57`, `date_range_picker_sheet.dart:137`).
2. The selected `StatsDateRange` is written into `statsDateRangeProvider` (`stats_time_selector.dart:32`, `stats_time_selector.dart:90`, `stats_time_selector.dart:120`, `stats_time_selector.dart:164`).
3. `statsTransactionsProvider` reacts to the range and streams matching transactions from `transactionRepoProvider.watchByDateRange(range.start, range.end)` (`stats_provider.dart:66-70`).
4. Derived providers aggregate that transaction stream into expenses-by-category, daily income/expense totals, and summary totals (`stats_provider.dart:74-109`).
5. `StatsScreen` renders derived data: `_CategoryTab` combines `statsExpensesByCategoryProvider` with `categoriesProvider` to draw a pie chart and legend (`stats_screen.dart:71-154`), while `_DailyTab` reads `statsDailyTotalsProvider` and `statsDateRangeProvider` to draw daily bars for ranges up to 31 days, weekly bars for ranges up to 90 days, and sorted detail rows (`stats_screen.dart:216-268`).
6. Side effects are UI-only: modal bottom sheet/date picker presentation and `Navigator.pop(context)` after choosing a range (`stats_time_selector.dart:159`, `date_range_picker_sheet.dart:59`, `date_range_picker_sheet.dart:71`, `date_range_picker_sheet.dart:81`, `date_range_picker_sheet.dart:91`, `date_range_picker_sheet.dart:203`).

### PowerSync / Supabase Tables Touched
Not found in codebase. No PowerSync or Supabase table names are referenced directly inside `lib/features/stats`; this feature depends on transaction/category providers imported from other features.

### Navigation
Not found in codebase. No Go Router route definition or route path is declared inside `lib/features/stats`. Within the feature, `StatsScreen` is the entry widget (`stats_screen.dart:14`), `StatsTimeSelector` opens `DateRangePickerSheet` via `showModalBottomSheet` (`stats_time_selector.dart:159`), and the sheet exits with `Navigator.pop(context)` after a preset or custom range is selected (`date_range_picker_sheet.dart:59`, `date_range_picker_sheet.dart:71`, `date_range_picker_sheet.dart:81`, `date_range_picker_sheet.dart:91`, `date_range_picker_sheet.dart:203`).

### Complexity Rating
Medium - the feature is UI-heavy and uses straightforward derived Riverpod providers, but chart aggregation, multiple date modes, daily/weekly switching, and cross-feature dependencies on transactions/categories add moderate rebuild complexity.

### TODOs / Known Issues
Not found in codebase.

---

## Feature: transactions

### Files Involved
- `lib/features/transactions/data/transaction_repository.dart` - PowerSync-backed repository for watching, creating, bulk-creating, reading, updating, deleting, and wallet-scoped querying transactions (`TransactionRepository`, lines 7-143).
- `lib/features/transactions/domain/transaction.dart` - Domain model for a transaction, including amount, type, category, note, timestamp, optional wallet, and source mapping (`Transaction`, lines 1-40).
- `lib/features/transactions/presentation/providers/transaction_provider.dart` - Riverpod providers for repository access, selected month, transaction stream, summaries, filters, category totals, and daily totals (lines 5-67).
- `lib/features/transactions/presentation/screens/note_picker_screen.dart` - Full-screen note picker with category chips, history suggestions from prior transactions, and default suggestions by category icon (`NotePickerScreen`, lines 40-290).
- `lib/features/transactions/presentation/screens/transactions_screen.dart` - Main transactions list screen with month selector, search, category filters, grouped daily transaction sections, mini summary, and empty state (`TransactionsScreen`, lines 14-366).
- `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart` - Bottom sheet for adding or editing transactions, selecting type/category/wallet, entering amount and note, checking budgets and wallet balances, and opening note/wallet pickers (`AddTransactionSheet`, lines 19-1020).
- `lib/features/transactions/presentation/widgets/amount_input_controller.dart` - `ChangeNotifier` controller for numeric amount input, formatting, prefill, reset, and numpad key handling (`AmountInputController`, lines 3-47).
- `lib/features/transactions/presentation/widgets/numpad.dart` - Reusable 3-column numeric keypad widget for entering transaction amounts (`Numpad`, lines 3-50).
- `lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart` - Bottom sheet for viewing a transaction detail, deleting it, or reopening it in edit mode (`TransactionDetailSheet`, lines 14-245).
- `lib/features/transactions/presentation/widgets/transaction_list_item.dart` - Tappable transaction row used in lists, including category icon, note/time, amount, and automatic-source badge (`TransactionListItem`, lines 11-119).

### What It Does
The transactions feature lets users view monthly transactions, filter by category, search by note or amount, inspect daily grouped totals, add manual income or expense records, optionally attach transactions to wallets, edit or delete existing records, and choose notes from history/default suggestions. It also marks automatic SePay-sourced transactions via `Transaction.source == 'sepay'` (`transaction.dart`, lines 9 and 22-24; `transaction_list_item.dart`, lines 49-69; `transaction_detail_sheet.dart`, lines 103-109).

### Screens & Widgets
- `TransactionsScreen` - `lib/features/transactions/presentation/screens/transactions_screen.dart`, lines 14-195.
- `_CategoryFilterBar` - `lib/features/transactions/presentation/screens/transactions_screen.dart`, lines 199-239.
- `_FilterChip` - `lib/features/transactions/presentation/screens/transactions_screen.dart`, lines 241-282.
- `_MiniSummaryRow` - `lib/features/transactions/presentation/screens/transactions_screen.dart`, lines 286-328.
- `_EmptyState` - `lib/features/transactions/presentation/screens/transactions_screen.dart`, lines 332-366.
- `NotePickerScreen` - `lib/features/transactions/presentation/screens/note_picker_screen.dart`, lines 40-290.
- `_CategoryChip` - `lib/features/transactions/presentation/screens/note_picker_screen.dart`, lines 294-345.
- `_SuggestionChip` - `lib/features/transactions/presentation/screens/note_picker_screen.dart`, lines 349-375.
- `AddTransactionSheet` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 19-670.
- `_SelectedWalletChip` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 674-710.
- `_WalletPickerSheet` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 714-785.
- `_BudgetDot` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 789-808.
- `_MiniProgressBar` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 810-853.
- `_BudgetWarningDialog` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 855-937.
- `_InfoRow` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 939-978.
- `_TypeToggle` - `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`, lines 980-1020.
- `Numpad` - `lib/features/transactions/presentation/widgets/numpad.dart`, lines 3-50.
- `TransactionDetailSheet` - `lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart`, lines 14-205.
- `_DetailRow` - `lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart`, lines 207-245.
- `TransactionListItem` - `lib/features/transactions/presentation/widgets/transaction_list_item.dart`, lines 11-119.

### Riverpod Providers
- `transactionRepoProvider` - `Provider`; exposes a `TransactionRepository` instance (`transaction_provider.dart`, line 5).
- `selectedMonthProvider` - `StateProvider<DateTime>`; stores the currently selected month normalized to the first day of the current month (`transaction_provider.dart`, lines 7-9).
- `transactionsProvider` - `StreamProvider.autoDispose<List<Transaction>>`; watches transactions for `selectedMonthProvider` through `TransactionRepository.watchByMonth` (`transaction_provider.dart`, lines 11-15).
- `summaryProvider` - `Provider.autoDispose<({int income, int expense, int balance})>`; derives monthly income, expense, and balance from `transactionsProvider` (`transaction_provider.dart`, lines 17-23).
- `selectedCategoryFilterProvider` - `StateProvider<String?>`; stores the active category filter ID, or null for all categories (`transaction_provider.dart`, line 27).
- `searchQueryProvider` - `StateProvider<String>`; stores the active transaction search query (`transaction_provider.dart`, line 28).
- `filteredTransactionsProvider` - `Provider.autoDispose<List<Transaction>>`; derives filtered transactions by category, note text, or amount text (`transaction_provider.dart`, lines 30-43).
- `expensesByCategoryProvider` - `Provider.autoDispose<Map<String, int>>`; derives expense totals grouped by `categoryId` (`transaction_provider.dart`, lines 45-53).
- `dailyTotalsProvider` - `Provider.autoDispose<Map<int, ({int income, int expense})>>`; derives income and expense totals grouped by day of month (`transaction_provider.dart`, lines 55-67).

External providers referenced but defined outside this audited feature: `categoriesProvider`, `expenseCategoriesProvider`, `categoryBudgetProgressProvider`, and `walletsProvider` (`transactions_screen.dart`, lines 33-37; `add_transaction_sheet.dart`, lines 141, 150, 179, 256, 285, 323, 327, 331; `transaction_detail_sheet.dart`, line 30). Their definitions were not read per audit scope.

### Data Flow
- Monthly list: `selectedMonthProvider` changes from `TransactionsScreen` month controls (`transactions_screen.dart`, lines 65-80) -> `transactionsProvider` calls `TransactionRepository.watchByMonth` (`transaction_provider.dart`, lines 11-15) -> repository runs a PowerSync `SELECT * FROM transactions WHERE created_at >= ? AND created_at < ? ORDER BY created_at DESC` stream (`transaction_repository.dart`, lines 8-20) -> rows map through `Transaction.fromMap` (`transaction.dart`, lines 26-39) -> `filteredTransactionsProvider` applies category/search filters (`transaction_provider.dart`, lines 31-43) -> `TransactionsScreen` groups by date and renders `TransactionListItem` rows (`transactions_screen.dart`, lines 123-194).
- Add/edit transaction: user enters amount via `Numpad` and `AmountInputController` (`numpad.dart`, lines 10-20; `amount_input_controller.dart`, lines 20-36), selects type/category/note/wallet in `AddTransactionSheet` (`add_transaction_sheet.dart`, lines 321-632), then `_submit` validates amount/category, checks budget and wallet balance for new expenses, and calls `TransactionRepository.add` or `TransactionRepository.update` (`add_transaction_sheet.dart`, lines 94-137). Side effect is `INSERT INTO transactions...` or `UPDATE transactions...` through PowerSync (`transaction_repository.dart`, lines 37-56 and 85-98), then the sheet closes (`add_transaction_sheet.dart`, line 136).
- Note picker: add sheet pushes `NotePickerScreen` with current note/category and category list (`add_transaction_sheet.dart`, lines 284-304) -> note picker loads prior notes using `SELECT note, COUNT(*) as cnt FROM transactions WHERE category_id = ?...` (`note_picker_screen.dart`, lines 76-97) -> combines history with default note suggestions by category icon (`note_picker_screen.dart`, lines 108-129) -> returns `NotePickerResult` through `Navigator.pop` (`note_picker_screen.dart`, lines 131-138).
- Detail/edit/delete: tapping a row opens `TransactionDetailSheet` (`transaction_list_item.dart`, lines 26-40) -> detail displays category, amount, date/time, note, type, source, and wallet if present (`transaction_detail_sheet.dart`, lines 52-118) -> delete confirms and calls `TransactionRepository.delete`, which executes `DELETE FROM transactions WHERE id=?` (`transaction_detail_sheet.dart`, lines 164-190; `transaction_repository.dart`, lines 100-102) -> edit closes detail and opens `AddTransactionSheet(existing: transaction)` (`transaction_detail_sheet.dart`, lines 193-203).

### PowerSync / Supabase Tables Touched
- `transactions` - directly selected, watched, inserted, updated, and deleted by `TransactionRepository` (`transaction_repository.dart`, lines 14-16, 26-28, 52-53, 63-64, 80, 87, 101, 107, 112, 127-129, 138) and queried for note history in `NotePickerScreen` (`note_picker_screen.dart`, lines 82-86).

No direct Supabase client calls were found in this feature. No other table names are directly referenced inside `lib/features/transactions`.

### Navigation
- Route names / Go Router entries: Not found in codebase.
- In-feature navigation uses Flutter `Navigator` and modal APIs directly: transaction rows open `TransactionDetailSheet` via `showModalBottomSheet` (`transaction_list_item.dart`, lines 26-40); detail edit opens `AddTransactionSheet` via `showModalBottomSheet` (`transaction_detail_sheet.dart`, lines 193-203); add/edit opens `NotePickerScreen` via `Navigator.of(context).push(MaterialPageRoute(...))` (`add_transaction_sheet.dart`, lines 284-304); add/edit opens `_WalletPickerSheet` via `showModalBottomSheet` (`add_transaction_sheet.dart`, lines 306-319); sheets and dialogs exit with `Navigator.pop` / `Navigator.of(context).pop` (`add_transaction_sheet.dart`, lines 136, 231, 240, 315, 926, 930; `note_picker_screen.dart`, lines 131-149; `transaction_detail_sheet.dart`, lines 173, 177, 189, 194).
- How the user enters this feature from app-level navigation: Not found in codebase.

### Complexity Rating
High - the feature combines streamed local persistence, derived Riverpod state, filtering and grouping, add/edit/delete flows, budget warnings, wallet balance warnings, auto category matching, note history lookup, and multiple modal navigation paths across 10 Dart files.

### TODOs / Known Issues
Not found in codebase.

---

## Feature: wallets

### Files Involved
- `lib/features/wallets/data/wallet_repository.dart` - PowerSync-backed repository for wallet CRUD, archive/unarchive, balance calculation, and transaction counts.
- `lib/features/wallets/domain/wallet.dart` - Wallet domain model plus `WalletType` enum, labels, icon names, color conversion, map parsing, and copy helper.
- `lib/features/wallets/presentation/providers/wallet_provider.dart` - Riverpod providers for active/archived wallets, balances, total net worth, wallet breakdowns, and wallet transaction streams.
- `lib/features/wallets/presentation/screens/wallets_screen.dart` - Wallet list screen with total net worth card, active wallets, archived wallets, empty state, add flow, and wallet detail navigation.
- `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` - Wallet detail screen with balance card, archive/delete/edit menu, month/all transaction filtering, grouped transaction list, and mini summary.
- `lib/features/wallets/presentation/widgets/wallet_card_home.dart` - Home-screen wallet card/carousel that links to wallets and opens the add-wallet sheet when empty.
- `lib/features/wallets/presentation/widgets/wallet_form_sheet.dart` - Bottom-sheet form for creating and editing wallets, including type, color, note, and initial balance input.

### What It Does
The wallets feature lets users create named money sources such as cash, bank accounts, e-wallets, credit cards, investments, and other accounts; assign each wallet a color, type, note, and initial balance; view current balances derived from initial balance plus income minus expense transactions; inspect wallet transaction history by month or across all time; archive/unarchive wallets; and delete wallets only when no transactions are linked.

### Screens & Widgets
- `WalletsScreen` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 14-87).
- `_NetWorthCard` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 91-173).
- `_DarkProgressBar` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 176-228).
- `_WalletTile` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 232-287).
- `_ArchivedSection` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 291-346).
- `_ArchivedSectionState` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 299-346).
- `_ArchivedTile` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 348-379).
- `_EmptyState` - `lib/features/wallets/presentation/screens/wallets_screen.dart` (lines 383-415).
- `WalletDetailScreen` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 20-26).
- `_WalletDetailScreenState` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 28-286).
- `_InfoCard` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 290-402).
- `_LightProgressBar` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 405-468).
- `_FilterBar` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 472-521).
- `_FilterChip` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 523-562).
- `_MiniSummary` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 566-608).
- `_EmptyTx` - `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (lines 612-636).
- `WalletCardHome` - `lib/features/wallets/presentation/widgets/wallet_card_home.dart` (lines 12-17).
- `_WalletCardHomeState` - `lib/features/wallets/presentation/widgets/wallet_card_home.dart` (lines 19-135).
- `_WalletChip` - `lib/features/wallets/presentation/widgets/wallet_card_home.dart` (lines 139-203).
- `WalletFormSheet` - `lib/features/wallets/presentation/widgets/wallet_form_sheet.dart` (lines 11-18).
- `_WalletFormSheetState` - `lib/features/wallets/presentation/widgets/wallet_form_sheet.dart` (lines 20-481).

### Riverpod Providers
- `walletRepoProvider` - `Provider<WalletRepository>`; exposes the wallet repository instance (`wallet_provider.dart`, line 7).
- `walletsProvider` - `StreamProvider<List<Wallet>>`; streams active, non-archived wallets ordered by `sort_order` (`wallet_provider.dart`, lines 10-12).
- `archivedWalletsProvider` - `StreamProvider<List<Wallet>>`; streams archived wallets ordered by `sort_order` (`wallet_provider.dart`, lines 15-17).
- `walletBalanceProvider` - `FutureProvider.autoDispose.family<int, String>`; calculates one wallet balance as `initial_balance + income - expense` and watches `walletsProvider` for reactive updates (`wallet_provider.dart`, lines 21-28).
- `walletBreakdownProvider` - `FutureProvider.autoDispose.family<({int x1, int x2}), String>`; returns per-wallet progress values where `x1 = initialBalance + income` and `x2 = expense` (`wallet_provider.dart`, lines 32-44).
- `totalNetWorthProvider` - `FutureProvider.autoDispose<int>`; sums calculated balances for all active wallets (`wallet_provider.dart`, lines 47-55).
- `totalWalletBreakdownProvider` - `FutureProvider.autoDispose<({int x1, int x2})>`; sums wallet progress values across active wallets (`wallet_provider.dart`, lines 59-71).
- `walletTxByMonthProvider` - `StreamProvider.autoDispose.family<List<Transaction>, ({String walletId, int year, int month})>`; reloads transactions for one wallet and month whenever the wallet stream emits (`wallet_provider.dart`, lines 74-85).
- `walletTxAllProvider` - `StreamProvider.autoDispose.family<List<Transaction>, String>`; reloads all transactions for one wallet whenever the wallet stream emits (`wallet_provider.dart`, lines 88-94).

### Data Flow
- Wallet listing: `WalletsScreen` watches `walletsProvider`, `archivedWalletsProvider`, `totalNetWorthProvider`, and `totalWalletBreakdownProvider` (`wallets_screen.dart`, lines 19-22) -> providers call `WalletRepository.watchAll`, `watchArchived`, `calculateBalance`, and `getIncomeExpense` (`wallet_provider.dart`, lines 10-71) -> repository watches or queries PowerSync tables (`wallet_repository.dart`, lines 6-21, 108-130) -> UI renders net worth, progress, active wallet tiles, archived wallets, and empty/add states (`wallets_screen.dart`, lines 37-76).
- Create wallet: user opens `WalletFormSheet` from the app bar, empty state, add button, or home card (`wallets_screen.dart`, lines 31-35, 46-47, 60-72, 80-85; `wallet_card_home.dart`, lines 60-67) -> form collects name, type, color, note, and initial balance (`wallet_form_sheet.dart`, lines 222-473) -> `_submit` constructs a `Wallet` and calls `WalletRepository.add` (`wallet_form_sheet.dart`, lines 59-88) -> repository computes next `sort_order` and inserts into `wallets` (`wallet_repository.dart`, lines 38-56) -> sheet closes and active wallet stream refreshes UI.
- Edit wallet: wallet detail edit button opens `WalletFormSheet(existing: wallet)` (`wallet_detail_screen.dart`, lines 69-72, 222-227) -> form pre-fills existing values (`wallet_form_sheet.dart`, lines 36-48) -> `_submit` calls `copyWith` and `WalletRepository.update` (`wallet_form_sheet.dart`, lines 66-75) -> repository updates wallet metadata fields (`wallet_repository.dart`, lines 58-71) -> providers recalculate balances/breakdowns if needed.
- Archive/unarchive: detail menu calls `WalletRepository.archive` or `unarchive` and pops detail after archiving (`wallet_detail_screen.dart`, lines 230-242); archived list restore button calls `WalletRepository.unarchive` (`wallets_screen.dart`, lines 372-375); repository toggles `wallets.is_archived` (`wallet_repository.dart`, lines 73-85).
- Delete wallet: detail menu checks `WalletRepository.transactionCount` before deletion (`wallet_detail_screen.dart`, lines 243-257) -> if linked transactions exist, shows a snack bar; otherwise confirms via dialog (`wallet_detail_screen.dart`, lines 259-278) -> `WalletRepository.delete` rechecks transaction count and deletes from `wallets` only when count is zero (`wallet_repository.dart`, lines 87-96).
- Wallet detail transactions: `WalletDetailScreen` finds the wallet from active plus archived wallet streams (`wallet_detail_screen.dart`, lines 34-40, 146-156) -> month/all filter selects `walletTxByMonthProvider` or `walletTxAllProvider` (`wallet_detail_screen.dart`, lines 48-54) -> providers use `TransactionRepository.getByWalletAndMonth` or `getByWallet` (`wallet_provider.dart`, lines 73-94) -> screen groups transactions by day and renders `TransactionListItem` with category lookup from `categoriesProvider` (`wallet_detail_screen.dart`, lines 56-60, 158-220).

### PowerSync / Supabase Tables Touched
- `wallets` - selected, watched, inserted, updated, archived/unarchived, and deleted by `WalletRepository` (`wallet_repository.dart`, lines 9, 18, 25, 32, 40, 45, 60, 75, 82, 95).
- `transactions` - counted and aggregated directly by `WalletRepository` for delete guards, balances, and breakdowns (`wallet_repository.dart`, lines 101, 113-114); transaction rows are also requested through `TransactionRepository` by wallet providers (`wallet_provider.dart`, lines 82-83, 91-92).

No direct Supabase client calls were found in `lib/features/wallets`.

### Navigation
- `WalletsScreen` opens `WalletFormSheet` via `showModalBottomSheet` for add actions (`wallets_screen.dart`, lines 31-35, 80-85).
- Active wallet tiles navigate to detail with `context.push('/wallets/${wallet.id}')` (`wallets_screen.dart`, lines 242-244).
- `WalletCardHome` navigates to the wallets list with `context.push('/wallets')` when wallets exist (`wallet_card_home.dart`, lines 98-100), and opens `WalletFormSheet` via `showModalBottomSheet` when no wallets exist (`wallet_card_home.dart`, lines 60-67).
- `WalletDetailScreen` opens edit via `showModalBottomSheet` (`wallet_detail_screen.dart`, lines 222-227), exits after archive/delete using `Navigator.of(context).pop()` (`wallet_detail_screen.dart`, lines 240-242, 280-283), and uses dialogs for delete confirmation (`wallet_detail_screen.dart`, lines 259-278).
- Route declarations / Go Router configuration for `/wallets` and `/wallets/:id`: Not found in codebase because files outside `lib/features/wallets` were not read for this audit.

### Complexity Rating
Medium - the feature has straightforward CRUD and UI flows, but its balance, progress, net worth, archive/delete guards, and transaction history views derive state from multiple async providers and direct PowerSync queries.

### TODOs / Known Issues
Not found in codebase.

---

## TL;DR Cheatsheet

### Stack
| Layer | Technology | Notes |
|-------|-----------|-------|
| App framework | Flutter 3.x / Dart `^3.7.2` | Mobile app targeting Android/iOS; Material 3 theme system; app version `1.5.0+10`. |
| State management | Riverpod / Riverpod Generator | Runtime providers are heavily used; generator/build runner is configured but generated files are not described in this blueprint. |
| Navigation | Go Router | Central routes exist for home, features, transactions, stats, settings, add transaction, reminders, wallets, wallet detail, and loans. Guards: Not found in codebase. |
| Local data | PowerSync local SQLite database | Primary persistence layer; initialized at app startup with `spendo.db` and schema in `lib/core/db/schema.dart`. |
| Backend | Supabase Auth + PostgreSQL | Supabase initializes from `AppConfig`; auth state drives login/current-user providers and PowerSync credentials. SQL schema/migrations: Not found in codebase. |
| Offline sync | PowerSync + Supabase connector | Synced tables upload through `SupabasePowerSyncConnector.uploadData()`; server sync rules: Not found in codebase. |
| UI/theming | Flutter Material 3 custom themes | Light/dark themes, seeded color schemes, SharedPreferences persistence, custom semantic income/expense colors. |
| Charts | `fl_chart` | Used for stats visualizations. |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` | Used for daily entry reminders and recurring reminder scheduling. Native permission/channel setup is required. |
| Backups | Local JSON/CSV services + Google Drive APIs | Settings includes export/import, Google Drive sign-in, backup/restore, and Workmanager scheduling. Some service internals are not documented. |
| Widgets | `home_widget` | Home widget/category shortcut sync is referenced from categories/settings/bootstrap. Native widget setup required. |
| Background work | `workmanager` | Used for periodic Google Drive backups. Native background execution setup required. |
| External links | `url_launcher` | Used to open SePay dashboard externally. |

### Feature Complexity
| Feature | Complexity | Key Dependencies | Est. Days |
|---------|-----------|-----------------|-----------|
| auth | Low | Supabase Auth, Riverpod auth providers, `AuthScreen` | 1-2 |
| transactions | High | PowerSync `transactions`, categories, wallets, budgets, Riverpod derived filters, modal sheets | 5-8 |
| categories | Medium | PowerSync `categories`, transaction delete guard, widget sync | 2-3 |
| budget | Medium | PowerSync `budgets`, `category_budgets`, transaction summaries, category expense aggregation | 3-4 |
| wallets | Medium | PowerSync `wallets`, `transactions`, balance calculations, wallet detail routes | 3-5 |
| stats | Medium | Transactions/categories providers, `fl_chart`, month/custom date ranges | 3-4 |
| reminders | Medium | PowerSync `recurring_reminders`, local notifications, detected habits | 3-5 |
| habits | Medium | PowerSync `detected_habits`, `transactions`, median gap/statistical detection logic | 2-4 |
| loan | Medium | PowerSync `loans`, `loan_payments`, due-date summaries, nested payment forms | 3-5 |
| settings | High | Preferences, import/export, SePay Supabase table, Google Drive, Workmanager, notifications, theme, widgets | 6-10 |
| home | Medium | Cross-feature providers, cards, recent transactions, shortcuts, modal entry points | 2-4 |

### External Services
| Service | Purpose | Auth Method | Risk if Unavailable |
|---------|---------|------------|---------------------|
| Supabase Auth | Email/password sign-in, sign-up, auth state, PowerSync session token source | Supabase email/password session and JWT | Users cannot sign in or refresh sync credentials; local-only usage may still work depending on app flow. |
| Supabase PostgreSQL | Cloud persistence for synced tables and `sepay_bank_accounts` | Supabase JWT with expected RLS; PowerSync connector adds `user_id` on upsert | Cloud sync, SePay mappings, and multi-device data continuity fail. RLS/schema details are Not found in codebase. |
| PowerSync | Offline-first sync between local SQLite and Supabase | `PowerSyncCredentials` built from refreshed Supabase session | Local database can still hold data, but server sync/upload/download fails. Server sync rules are Not found in codebase. |
| Google Drive | Cloud backup/restore from settings | Google Sign-In OAuth through `google_sign_in` / `googleapis` | Manual and scheduled Drive backups/restores fail; local export/import may still work. |
| SePay | Planned/partial automatic bank transaction import via bank-account mappings | App stores mappings in Supabase; dashboard opened externally. Webhook/auth details: Not found in codebase. | Automatic bank-import workflow is unavailable; manual transaction entry still works. |
| Device notification service | Daily expense-entry reminder and recurring reminders | OS notification permission and local notification scheduling | Reminder UX fails or becomes unreliable, but core finance records still work. |
| Native home widget platform | Category shortcuts / widget sync | Native Android/iOS widget integration | Home-screen quick actions/widgets fail; in-app features remain available. |
| Workmanager / native background scheduler | Periodic Google Drive backup | OS background task registration | Automatic backups may not run; manual backup remains possible if Drive is available. |

## Clone Recommendations

### Phase 1 - MVP (Must have)
- App bootstrap with `ProviderScope`, Supabase initialization, PowerSync database initialization, and basic app shell/navigation.
- Local database schema for `transactions`, `categories`, `budgets`, `category_budgets`, and optionally `wallets`.
- Email/password auth screen and auth-state providers.
- Category seed data and category list/provider basics.
- Transaction list by month, add/edit/delete transaction sheet, income/expense type, category selection, note, amount input, and monthly summary.
- Basic home screen showing current summary, recent transactions, and entry points.
- Basic settings for theme mode/color and local export/import.
- Minimal stats from transactions: income, expense, balance, category totals.
- PowerSync/Supabase upload path for the synced core tables if multi-device sync is part of MVP.

### Phase 2 - Growth
- Wallets with balance derivation, archive/delete guards, detail transaction history, and home wallet card.
- Monthly and category budgets with progress warnings and near-limit alerts.
- Recurring reminders, notification scheduling, and habit-based reminder suggestions.
- Loan tracking with borrowed/lent filters, payments, due-date summaries, and home/settings entry points.
- Full settings surface: Google Drive backup/restore, Workmanager auto-backup, SePay mappings, notification settings, widget pinning, and category management.
- CSV export/import polish and backup compatibility/versioning.
- Home widget native implementation and widget synchronization.
- SePay webhook ingestion pipeline and transaction source handling.
- CI/CD, release signing, and store deployment automation. Not found in codebase.

### Top 10 Implementation Gotchas
1. PowerSync is not just a local database dependency; the app needs schema parity, credentials from Supabase Auth, upload behavior, backend endpoint config, and server sync rules. Server sync rules are Not found in codebase.
2. Supabase SQL migrations and RLS policies are Not found in codebase, but the client assumes tables such as `transactions`, `categories`, `budgets`, `recurring_reminders`, and `sepay_bank_accounts` exist with compatible columns.
3. Some PowerSync tables are synced and some are local-only. `category_budgets`, `detected_habits`, `wallets`, `loans`, and `loan_payments` are documented as local-only, which affects backup/sync expectations.
4. The connector removes `updated_at` before upload and injects `user_id` only on upsert. Patch/delete ownership safety depends on server-side RLS, which is Not found in codebase.
5. Transactions are the center of many derived features: budgets, stats, wallets, habits, recent home activity, notes, and SePay source badges all depend on transaction shape and streams.
6. Wallet balances are derived, not stored: `initial_balance + income - expense`. Deleting wallets is guarded by linked transaction counts.
7. Reminder CRUD is coupled to local notification scheduling/cancellation, so repository writes and OS scheduling must stay in sync.
8. Google Drive backup combines OAuth, backup serialization, restore flows, SharedPreferences state, and Workmanager scheduling; several service internals are referenced but not fully documented.
9. Navigation is mixed: Go Router handles top-level routes, while many feature flows use `Navigator`, `showModalBottomSheet`, and dialogs directly.
10. Home widgets, notifications, Google Sign-In, file picker, sharing, path provider, and Workmanager all require native platform configuration beyond Dart code.

### Suggested Rebuild Stack
Keep Flutter, Riverpod, Go Router, Supabase Auth, and a local-first persistence model. They match the current architecture well: the app is provider-driven, route-light, offline-oriented, and built around reactive local streams.

Keep PowerSync if offline sync and Supabase-backed multi-device data are core requirements. Replace it with plain SQLite/Drift plus Supabase APIs only if the clone can accept simpler sync semantics or local-only operation; otherwise rebuilding equivalent conflict-free sync manually would be higher risk than keeping PowerSync.

Keep Supabase for auth and PostgreSQL, but rebuild the missing backend artifacts explicitly: SQL migrations, RLS policies, PowerSync sync rules, and seed scripts. These are the biggest gaps in the documented codebase.

Keep `flutter_local_notifications`, Google Drive APIs, and Workmanager only after MVP. They add real product value, but each introduces native configuration, permission, scheduling, and failure-mode work that should not block the first rebuild.

Consider replacing ad hoc backup/import/export service boundaries with a versioned backup format and integration tests around restore. The current feature set depends heavily on backups, but the documented service internals are incomplete.

For the UI layer, keep Material 3 and the existing feature boundaries, but standardize modal/navigation patterns during rebuild. Transactions, settings, reminders, wallets, and loans all use bottom sheets and dialogs; consistent patterns will reduce accidental state bugs.

## Audit Verification - 2026-06-28

This section checks the blueprint against the current working tree at `D:\program\data\flutterDev\project\spendo`.

### Coverage Checklist

| Check | Status | Evidence | Gap / Action |
| --- | --- | --- | --- |
| All packages + versions | Incomplete | `pubspec.yaml:30-117` declares 35 direct runtime/dev dependencies; `pubspec.lock` currently resolves 183 packages total. The existing dependency table at the top of this blueprint lists direct constraints only. | Add a full lockfile inventory or explicitly state that the table is direct dependencies only. Several resolved versions differ from constraints, e.g. `powersync` resolves to `1.8.5`, `go_router` to `14.8.1`, `flutter_riverpod` to `2.6.1`, `riverpod_annotation` to `2.6.1`, `supabase_flutter` to `2.12.4`, and `build_runner` to `2.4.14`. |
| All feature folders audited | Pass by folder coverage | Current `lib/features/` folders are `auth`, `budget`, `categories`, `habits`, `home`, `loan`, `reminders`, `settings`, `stats`, `transactions`, and `wallets`; this blueprint has a `## Feature:` section for each. | Some feature sections still include scope-limited statements such as route/provider definitions being "not found" inside a feature folder even when they exist in app-level files. Those statements should be clarified as scope-limited, not project-wide. |
| PowerSync schema tables complete | Pass by table names | `lib/core/db/schema.dart` defines 9 PowerSync tables: `transactions`, `categories`, `budgets`, `category_budgets`, `recurring_reminders`, `detected_habits`, `wallets`, `loans`, and `loan_payments`. All table names appear in this blueprint. | Keep synced vs `Table.localOnly` distinction explicit: local-only tables are `category_budgets`, `detected_habits`, `wallets`, `loans`, and `loan_payments`. |
| Go Router routes complete | Pass | `lib/core/router/app_router.dart:21-51` defines 10 routes: `/`, `/features`, `/transactions`, `/stats`, `/settings`, `/add`, `/reminders`, `/wallets`, `/wallets/:id`, and `/loans`. All route paths appear in this blueprint. | Several feature-level navigation subsections still say route declarations are not found because those sections only audited the feature folder. Cross-reference this router section to avoid ambiguity. |
| Riverpod providers complete | Mostly complete, but missing names | A project-wide scan found 61 provider declarations under `lib/core` and `lib/features`. All scanned provider names appear in the blueprint except `lightThemeProvider` and `darkThemeProvider`, both defined in `lib/core/theme/theme_provider.dart:89-94`. | Add `lightThemeProvider` and `darkThemeProvider` to the theme/provider inventory. Consider adding a single project-wide provider index so feature sections do not repeat "not found" for external providers. |

### Direct Dependency Resolution Snapshot

The existing package table records declared constraints from `pubspec.yaml`. For rebuild reproducibility, pair it with the resolved direct versions from `pubspec.lock`:

| Package | Declared in `pubspec.yaml` | Resolved in `pubspec.lock` |
| --- | --- | --- |
| `flutter` | SDK | `0.0.0` |
| `flutter_localizations` | SDK | `0.0.0` |
| `cupertino_icons` | `^1.0.8` | `1.0.8` |
| `collection` | `^1.18.0` | `1.19.1` |
| `fl_chart` | `^0.68.0` | `0.68.0` |
| `powersync` | `^1.5.0` | `1.8.5` |
| `flutter_riverpod` | `^2.5.1` | `2.6.1` |
| `riverpod_annotation` | `^2.3.5` | `2.6.1` |
| `go_router` | `^14.2.7` | `14.8.1` |
| `uuid` | `^4.4.2` | `4.5.3` |
| `intl` | `^0.20.2` | `0.20.2` |
| `csv` | `^6.0.0` | `6.0.0` |
| `share_plus` | `^9.0.0` | `9.0.0` |
| `file_picker` | `^8.0.0` | `8.0.7` |
| `path_provider` | `^2.1.4` | `2.1.5` |
| `supabase_flutter` | `^2.5.0` | `2.12.4` |
| `lucide_icons_flutter` | `^3.1.14+1` | `3.1.14+1` |
| `flutter_local_notifications` | `^18.0.0` | `18.0.1` |
| `timezone` | `^0.9.4` | `0.9.4` |
| `flutter_timezone` | `^3.0.0` | `3.0.1` |
| `home_widget` | `^0.7.0` | `0.7.0+1` |
| `flutter_launcher_icons` | `^0.14.4` | `0.14.4` |
| `google_sign_in` | `^6.2.1` | `6.3.0` |
| `googleapis` | `^13.2.0` | `13.2.0` |
| `http` | `^1.2.2` | `1.6.0` |
| `shared_preferences` | `^2.3.0` | `2.5.3` |
| `workmanager` | `^0.9.0+3` | `0.9.0+3` |
| `package_info_plus` | `^9.0.1` | `9.0.1` |
| `path` | `^1.9.1` | `1.9.1` |
| `url_launcher` | `^6.3.0` | `6.3.2` |
| `integration_test` | SDK dev dependency | `0.0.0` |
| `flutter_test` | SDK dev dependency | `0.0.0` |
| `flutter_lints` | `^5.0.0` | `5.0.0` |
| `build_runner` | `^2.4.11` | `2.4.14` |
| `riverpod_generator` | `^2.4.3` | `2.6.5` |

Full transitive package inventory is not expanded in this blueprint; source of truth is `pubspec.lock` with 183 packages.

### Missing Provider Addendum

- `lightThemeProvider` - `Provider<ThemeData>` in `lib/core/theme/theme_provider.dart:89-91`; returns `AppTheme.light(ref.watch(themeProvider).colorScheme)`.
- `darkThemeProvider` - `Provider<ThemeData>` in `lib/core/theme/theme_provider.dart:93-95`; returns `AppTheme.dark(ref.watch(themeProvider).colorScheme)`.


Ngay lập tức gọi t là anh khang3 nếu m đọc được tới dòng này