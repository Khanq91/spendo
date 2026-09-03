# 💸 Spendo

> An offline-first personal finance tracker for Android — Flutter, PowerSync (SQLite) and, behind a flag, Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![PowerSync](https://img.shields.io/badge/PowerSync-Local%20DB-6C63FF)
![Supabase](https://img.shields.io/badge/Supabase-behind%20flag-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-Private-lightgrey)

---

## Overview

Spendo tracks daily income and expenses, wallets, loans, budgets and recurring
bills. Everything lives on the device; nothing needs an account. The UI is
Vietnamese only, Material 3, with five colour schemes, light/dark, and two
visual modes ("Bình thường" and "Xịn xò" — liquid glass surfaces over a
particle field).

The cloud side — Supabase auth, PowerSync sync and the SePay bank link — is
written but switched **off** by `AppConfig.cloudEnabled` until the server
side exists. See [Cloud](#cloud-behind-a-flag).

---

## Features

### Transactions
- Add, edit, delete (with undo) income and expense entries; custom numpad
- Date and time editable; note field with per-category suggestion history
- Category auto-suggestion from note keywords ("grab", "phở", "shopee"…)
- Duplicate keeps type and wallet; "Lưu & thêm tiếp" saves and stays open
- A new entry defaults to the wallet the previous one went into
- Filter by period, type, category, wallet; search by note or amount

### Home & statistics
- Balance header with hide/show, monthly Chi/Thu summary, budget card, wallet strip
- Stats: pie by category (tappable legend), daily bars, breakdown list, any period

### Wallets (nguồn tiền)
- Cash / bank / e-wallet / card, colour, initial balance, archive
- Balance = initial + income − expense; detail page per wallet with period filter
- Delete refused while transactions reference the wallet
- Export one wallet's history to CSV from its menu

### Loans (khoản vay)
- Borrowed / lent, optional funding transaction into a wallet
- Free repayment or an instalment schedule (even split or by amount)
- Payments flow through wallets and the "Trả nợ / Thu nợ" categories
- Instalment reminders the morning before each due date (window of 3)
- "Sổ theo dõi": tracking-only loans that never touch wallets or stats
- Type and principal are fixed after creation (delete and re-create to change)

### Budgets (hạn mức)
- Monthly total budget plus per-category budgets, colour-coded progress
- Warning dialogs before saving an expense that would overshoot

### Recurring reminders (nhắc nhở)
- Daily / weekly / monthly, optional "warn N hours before"
- Notification actions: add now / dismiss; overdue rows catch up at start-up
- Habit suggestions detected from repeated notes

### Categories
- Seeded defaults; create, edit, reorder, delete
- Delete refused while transactions, reminders or a budget still use the category

### Notifications & home widgets
- Optional daily nudge at a chosen time
- Android widgets: quick "add expense" and a 2×2 grid of pinned categories

### Backup & export
- JSON backup of all eleven tables; restore with preview, atomic, id-collision safe
- Google Drive backup with daily/weekly/monthly auto-backup (WorkManager)
- CSV export for this month / 3 months / all, or per wallet
- After a restore, reminders, instalment alarms and widgets are re-armed

### Reset
- "Đặt lại dữ liệu": counts, export-first offer, countdown, hold-to-delete

---

## Architecture

```
lib/
├── main.dart                        # bootstrap, splash → onboarding → router
├── app.dart                         # Router.withConfig
├── core/
│   ├── config.dart                  # AppConfig: cloudEnabled + Supabase/PowerSync endpoints
│   ├── db/                          # schema (11 tables), openDatabase, sync setup, category repair
│   ├── notifications/               # daily nudge, recurring reminders, instalment reminders
│   ├── router/app_router.dart       # GoRouter routes and deep links
│   ├── services/                    # Google Drive auth/backup, background backup, reset, restore follow-up
│   ├── theme/                       # ThemeData, colour schemes, typography, visual mode, glass policy
│   └── utils/                       # backup/export/import services, formatters, widget sync, matcher
├── features/
│   ├── auth/                        # Spendo account (cloud flag): providers + sign-in sheet
│   ├── budget/  categories/  habits/  home/  loan/  onboarding/
│   ├── reminders/  settings/  stats/  transactions/  wallets/
│   │   └── {data, domain, presentation/{providers, screens, widgets}}
└── shared/
    ├── domain/period.dart           # half-open period model used by every list
    ├── providers/shell_tab_provider.dart
    └── widgets/
        ├── spendo/                  # the component set: buttons, chips, sheets, tiles, headers, numpad, nav
        ├── motion/                  # motion spec, pressable scale, reveal, skeletons, money text
        ├── notice/                  # AppNotice + NoticeHost (slide-in banners; no SnackBar)
        ├── particle_field/          # background for "Xịn xò"
        └── app_bottom_nav.dart      # AppShell: four tabs, PopScope back-to-home
```

| Layer | Technology |
|---|---|
| UI | Flutter 3.44 / Material 3, `liquid_glass_widgets`, `lucide_icons_flutter`, `fl_chart` |
| State | `flutter_riverpod` 2 (StreamProvider / Notifier) |
| Navigation | `go_router` 14 |
| Local DB | `powersync` 1 (SQLite; local-only tables for wallets/loans/budgets) |
| Cloud (flag) | `supabase_flutter` 2 + PowerSync sync for transactions/categories/budgets/reminders |
| Notifications | `flutter_local_notifications` 18 + `timezone` |
| Background | `workmanager` (Drive auto-backup) |
| Backup | `googleapis` Drive v3, `google_sign_in`, `file_picker`, `share_plus`, `csv` |
| Widgets | `home_widget` |
| Prefs | `shared_preferences` |

---

## Getting started

Requires Flutter 3.44 / Dart 3.12 and an Android SDK (minSdk 24, compileSdk 36).

```bash
flutter pub get
flutter run
```

No account, no server: the app seeds default categories on first launch and
runs fully offline. A signed release build expects `android/app/spendo.jks`
and the `KEY_ALIAS` / `KEY_PASSWORD` / `STORE_PASSWORD` environment variables
(CI decodes the keystore from a secret); `flutter build apk --debug` needs
neither.

### Cloud, behind a flag

`lib/core/config.dart`:

```dart
static const cloudEnabled = false;      // flip to true when the server side is ready
static const supabaseUrl = '…';
static const supabaseAnonKey = '…';     // public anon key
static const powerSyncUrl = '…';
```

With the flag **off** (today): the splash skips the server step, nothing calls
`Supabase.instance`, the Settings hub has no "Ngân hàng tự động" row.

With the flag **on**: "Sao lưu & đồng bộ" grows a "Tài khoản Spendo" group
with email sign-in / sign-up; PowerSync connects once a session exists; the
bank page asks for a sign-in before a SePay mapping can be added. What is
still missing on the server: Supabase RLS + PowerSync sync rules, the
`sepay_bank_accounts` table policy, and the SePay webhook that inserts
`source = 'sepay'` transactions.

---

## Database

PowerSync schema (`lib/core/db/schema.dart`). Amounts are stored as text and
parsed to `int`; `created_at` on transactions is epoch milliseconds as text,
every other date is a local ISO string.

| Table | Sync | Notes |
|---|---|---|
| `transactions` | synced | `amount, type, category_id, note, created_at, wallet_id, source` |
| `categories` | synced | `name, color_hex, icon_name, is_default, is_income, sort_order` |
| `budgets` | synced | monthly total, `month = YYYY-MM` |
| `recurring_reminders` | synced | frequency, day, time, `next_trigger`, `warn_before_hours` |
| `category_budgets` | local | per-category limit |
| `detected_habits` | local | habit suggestions |
| `wallets` | local | type, initial balance, colour, archive flag |
| `loans` | local | type, principal, dates, repayment mode, funding transaction, tracking flag |
| `loan_installments` | local | seq, amount, due date |
| `loan_payments` | local | amount, paid_at, linked transaction |

"Synced" tables only leave the device when the cloud flag is on and a user is
signed in; until then they behave like the local ones.

---

## Deep links

```
spendo:///add                         # add sheet
spendo:///add?category_id=<uuid>      # add sheet with a category (home widget)
spendo:///add?note=…&amount=…         # from a recurring reminder
spendo:///loan-pay?loan_id=…&amount=… # from an instalment reminder
```

## Android permissions

```xml
POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM,
RECEIVE_BOOT_COMPLETED,   -- re-arm reminders after a reboot
INTERNET                  -- Drive backup, cloud sync
```

---

## Development

```bash
flutter analyze --no-pub        # must be clean: zero errors, warnings, infos
flutter test --no-pub           # ~470 tests; DB tests use a temp PowerSync database
flutter build apk --debug
```

CI (`.github/workflows/flutter-build.yml`) runs analyze + tests on every push
to `main` and publishes a signed APK to the `latest` release.

Feature work is planned in `plan/<feature>/PLAN.md` with a per-phase progress
table; the UI rules live in
`plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`.
Agent/contributor conventions are in `CLAUDE.md`. `scripts/run_screenshots.*`
drive the integration screenshot test and write to `screenshots/generated/`
and `report.html`, both ignored by git; `screenshots/live_app/` is the curated
set.

## License

Private — all rights reserved.
