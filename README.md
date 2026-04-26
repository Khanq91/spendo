# 💸 Spendo

> A clean, offline-first personal finance tracker for Android — built with Flutter, PowerSync, and Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![PowerSync](https://img.shields.io/badge/PowerSync-Offline%20Sync-6C63FF)
![License](https://img.shields.io/badge/License-Private-lightgrey)

---

## 📱 Overview

Spendo is a minimalist yet feature-rich expense tracking app designed for daily personal finance management. It works fully offline out of the box and optionally syncs data to the cloud when signed in. The UI is built with a pink-pastel Material 3 design language, supporting both light and dark themes.

---

## ✨ Features

### 💰 Transaction Management
- Add, edit, and delete **income and expense** transactions
- Custom **numpad input** for fast amount entry
- Optional **note** field per transaction
- **Smart category auto-suggestion** — detects keywords in notes (e.g. "grab", "phở", "shopee") and highlights the matching category automatically, with a magic wand indicator
- Transactions are grouped by date with **daily net totals** in the list view

### 📊 Dashboard (Home Screen)
- **Monthly balance card** with gradient design showing total income, expense, and net balance
- **Month selector** — swipe backward/forward through months
- Grouped transaction list with date headers and per-day totals
- **Budget progress card** — shows spending vs. limit with a color-coded progress bar (normal → warning → over-limit)

### 📈 Statistics
- **Pie chart** breakdown of expenses by category (interactive — tap a slice to highlight)
- **Bar chart** of daily spending throughout the selected month
- Detailed daily breakdown list sorted by recency

### 🗂️ Category Management
- Default expense and income categories (pre-seeded on first launch)
- **Create, edit, and delete** custom categories
- Per-category **color** (14 pastel options) and **icon** (16 Lucide icons) customization
- Categories in use by existing transactions are protected from deletion

### 🎯 Monthly Budget
- Set a spending limit for any month
- Real-time progress tracking with three visual states: on track (purple), approaching limit (orange), over budget (red)
- Budget can be updated or deleted at any time

### 🔔 Daily Reminders
- Optional daily push notification to remind you to log expenses
- Configurable reminder time via a time picker
- Test notification (fires after 5 seconds) to verify setup
- Powered by `flutter_local_notifications` with exact alarm scheduling

### 🏠 Home Screen Widgets (Android)
- **Small widget** — one-tap "Add Expense" button from the home screen
- **Medium widget** — 2×2 grid of your top 4 expense categories, each launching the add screen with that category pre-selected
- Widget categories are configurable via the **Widget Pin** section in Settings
- Data synced to widgets automatically after any category change

### 🔄 Cloud Sync (Optional)
- Sign in with email/password via **Supabase Auth**
- Offline-first architecture using **PowerSync** — all data is written locally first, then synced to Supabase in the background
- Works completely without an account; sign in only when cloud backup is desired
- Automatic data migration for existing local data upon first sign-in

### 📤 Data Export
- Export transactions to **CSV** for three time ranges: current month, last 3 months, or all-time
- Shared via the native share sheet (email, Drive, Files, etc.)

### 🎨 Theming
- **Light**, **Dark**, and **System** theme modes
- Selection persisted across app restarts via `SharedPreferences`
- Full Material 3 color scheme with pink-pastel primary palette

---

## 🏗️ Architecture

```
lib/
├── app.dart                        # Root widget (MaterialApp.router + theme)
├── main.dart                       # App entry point (init DB, notifications, widgets)
├── core/
│   ├── config.dart                 # Supabase & PowerSync endpoints
│   ├── db/
│   │   ├── schema.dart             # PowerSync schema (transactions, categories, budgets)
│   │   ├── powersync_db.dart       # DB init, seeding, sync setup
│   │   └── powersync_connector.dart# CRUD upload to Supabase
│   ├── router/
│   │   └── app_router.dart         # GoRouter config (deep-link /add?category_id=...)
│   ├── theme/
│   │   ├── app_theme.dart          # Light & dark ThemeData
│   │   └── theme_provider.dart     # Riverpod StateNotifier + SharedPreferences
│   ├── notifications/
│   │   ├── notification_service.dart
│   │   └── notification_provider.dart
│   └── utils/
│       ├── category_icons.dart     # icon_name → Lucide IconData mapping
│       ├── category_matcher.dart   # Keyword → category auto-match
│       ├── currency_formatter.dart # VND formatter
│       ├── date_helpers.dart       # Date/time display helpers
│       ├── export_service.dart     # CSV export logic
│       └── widget_sync.dart        # HomeWidget data push
├── features/
│   ├── auth/                       # Supabase email auth screen & providers
│   ├── budget/                     # Budget CRUD, progress provider, UI
│   ├── categories/                 # Category domain, repo, providers, form sheet
│   ├── home/                       # Dashboard screen, summary cards, month selector
│   ├── settings/                   # Theme, notifications, widget pin, category mgmt
│   ├── stats/                      # Pie chart, bar chart, daily breakdown
│   └── transactions/               # Transaction domain, repo, providers, screens, sheets
└── shared/
    ├── widgets/
    │   ├── app_bottom_nav.dart     # AppShell with NavigationBar + FAB
    │   ├── category_icon.dart      # Reusable category icon widget
    │   └── global_fab.dart         # Floating action button helper
```

**State management:** [Riverpod](https://riverpod.dev) (`StreamProvider`, `StateNotifierProvider`, `Provider`)

**Navigation:** [GoRouter](https://pub.dev/packages/go_router) with deep-link support (`spendo:///add?category_id=<id>`)

**Local database:** [PowerSync](https://www.powersync.com) (SQLite-based, offline-first)

**Remote backend:** [Supabase](https://supabase.com) (Auth + Postgres)

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3 / Material 3 |
| State Management | flutter_riverpod 2.x |
| Navigation | go_router 14.x |
| Local DB | powersync 1.x (SQLite) |
| Cloud Backend | supabase_flutter 2.x |
| Charts | fl_chart 0.68 |
| Icons | lucide_icons_flutter |
| Notifications | flutter_local_notifications 18.x |
| Home Widgets | home_widget 0.7 |
| Export | csv + share_plus |
| Persistence | shared_preferences |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.7.2`
- Android SDK with `minSdk 24`, `compileSdk 36`
- A [Supabase](https://supabase.com) project (optional — app works offline without it)
- A [PowerSync](https://www.powersync.com) instance connected to Supabase (optional)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd spendo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure credentials** in `lib/core/config.dart`
   ```dart
   class AppConfig {
     static const supabaseUrl    = 'YOUR_SUPABASE_URL';
     static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     static const powerSyncUrl   = 'YOUR_POWERSYNC_URL';
   }
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

> The app seeds default categories on first launch and works fully offline — no account required.

---

## 🗄️ Database Schema

```sql
-- transactions
id          TEXT PRIMARY KEY  -- UUID
amount      TEXT              -- stored as string, parsed to int
type        TEXT              -- "expense" | "income"
category_id TEXT
note        TEXT
created_at  TEXT              -- millisecondsSinceEpoch as string

-- categories
id          TEXT PRIMARY KEY
name        TEXT
color_hex   TEXT              -- e.g. "#FF6B6B"
icon_name   TEXT              -- mapped to Lucide icon
is_default  INTEGER           -- 1 = seeded default
is_income   INTEGER           -- 0 = expense, 1 = income
sort_order  INTEGER

-- budgets
id          TEXT PRIMARY KEY
amount      TEXT
month       TEXT              -- "YYYY-MM" e.g. "2026-04"
```

---

## 📋 Default Categories

**Expense:** Ăn uống 🍜 · Di chuyển 🚗 · Học tập 📚 · Giải trí 🎮 · Sức khoẻ 💊 · Mua sắm 🛍️ · Khác 📦

**Income:** Lương 💼 · Freelance 💻 · Bán hàng 🏪 · Quà tặng 🎁 · Khác 📦

---

## 🔗 Deep Link Support

Spendo registers the `spendo://` URI scheme, enabling home screen widgets (and external links) to open the app directly to the add-transaction sheet with a pre-selected category:

```
spendo:///add                        # open add sheet (no category pre-selected)
spendo:///add?category_id=<uuid>     # open add sheet with category pre-selected
```

---

## 📦 Android Permissions

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

---

## 📄 License

Private — all rights reserved.