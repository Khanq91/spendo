# Spendo Context Bundle — Sun Jun 28 10:49:13 SEAST 2026


---
## FILE TREE (lib/)



---
## FILE TREE (non-dart config)

./analysis_options.yaml
./devtools_options.yaml
./pubspec.yaml
./web/manifest.json


---
## pubspec.yaml

name: spendo
description: "Spend your money"
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.5.0+10

environment:
  sdk: ^3.7.2

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8

  collection: ^1.18.0
  fl_chart: ^0.68.0

  # DB & sync
  powersync: ^1.5.0

  # State
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.7

  # Utils
  uuid: ^4.4.2
  intl: ^0.20.2
  csv: ^6.0.0
  share_plus: ^9.0.0

  file_picker: ^8.0.0
  path_provider: ^2.1.4
  supabase_flutter: ^2.5.0

  lucide_icons_flutter: ^3.1.14+1

  # Notification & time
  flutter_local_notifications: ^18.0.0
  timezone: ^0.9.4
  flutter_timezone: ^3.0.0

  # UI Widget
  home_widget: ^0.7.0

  flutter_launcher_icons: ^0.14.4

  # Google Drive backup
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
  http: ^1.2.2
  shared_preferences: ^2.3.0
  workmanager: ^0.9.0+3
  package_info_plus: ^9.0.1
  path: ^1.9.1

  url_launcher: ^6.3.0

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_logo.jpg"
  min_sdk_android: 21 # android min sdk min:16, default 21
  web:
    generate: true
    image_path: "assets/icons/app_logo.jpg"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/icons/app_logo.jpg"
    icon_size: 48 # min:48, max:256, default: 48
  macos:
    generate: true
    image_path: "assets/icons/app_logo.jpg"

dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^5.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - assets/images/
    - assets/icons/
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package


---
## main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config.dart';
import 'core/db/powersync_db.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_notification_service.dart';
import 'core/utils/widget_sync.dart';
import 'core/services/gdrive_auth_service.dart';
import 'core/services/gdrive_backup_service.dart';
import 'features/reminders/data/reminder_repository.dart';
import 'shared/widgets/splash_screen.dart';

import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == 'autoGDriveBackup') {
        debugPrint('[WorkManager] Starting autoGDriveBackup task');
        
        // Cần init database trong background isolate
        await openDatabase();

        // Thử sign in silently, nếu fail thì không làm gì thêm
        final signedIn = await GDriveAuthService.instance.signInSilently();
        if (!signedIn) {
          debugPrint('[WorkManager] Not signed in, aborting backup');
          return Future.value(true);
        }

        await GDriveBackupService.instance.uploadBackup();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('gdrive_last_backup_time', DateTime.now().millisecondsSinceEpoch);
        
        debugPrint('[WorkManager] autoGDriveBackup completed successfully');
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('[WorkManager] Task failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  runApp(const ProviderScope(child: _AppRoot()));
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFF06292)),
      home: SplashScreen(
        onInit: _initServices,
        nextScreen: const SpendoApp(),
      ),
    );
  }
}

Future<void> _initServices(
    void Function(double progress, String message) report,
    ) async {
  report(0.0, 'Initializing…');
  await Future.delayed(const Duration(milliseconds: 100));

  // 1. Supabase
  report(0.05, 'Connecting to cloud…');
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // 2. Local database
  report(0.35, 'Opening database…');
  await openDatabase();

  // 3. Notifications
  report(0.65, 'Setting up notifications…');
  await NotificationService.init();
  
  // 4. Schedule recurring reminders
  report(0.80, 'Scheduling reminders…');
  try {
    final reminders = await ReminderRepository().getAll()
        .timeout(const Duration(seconds: 5));
    await ReminderNotificationService.scheduleAll(reminders)
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[Init] Reminder scheduling error: $e');
  }
  
  // 5. Home widgets sync
  report(0.90, 'Syncing widgets…');
  await WidgetSync.syncCategories();

  // 6. Data cleanup
  report(0.95, 'Cleaning up…');
  try {
    await _cleanupOldData();
  } catch (e) {
    debugPrint('[Init] Cleanup error: $e');
  }

  report(1.0, 'All done!');
  await Future.delayed(const Duration(milliseconds: 200));
}

Future<void> _cleanupOldData() async {
  // Chỉ xóa vĩnh viễn (giao dịch > 2 năm) nếu ĐÃ CÓ backup trên Drive thành công
  // để tránh mất dữ liệu đáng tiếc.
  final hasBackup = await GDriveBackupService.instance.hasRecentBackup();
  if (hasBackup) {
    final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
    
    // PowerSync SQLite executes
    await db.execute(
      'DELETE FROM transactions WHERE created_at < ?',
      [twoYearsAgo.millisecondsSinceEpoch.toString()],
    );
    debugPrint('[Cleanup] Xoá giao dịch quá 2 năm (do đã có backup Drive)');
  } else {
    debugPrint('[Cleanup] Bỏ qua xoá giao dịch do chưa có backup Drive gần đây');
  }
}

---
## ROUTER FILES


### lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/all_features_screen.dart';
import '../../features/loan/presentation/screens/loan_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/wallets/presentation/screens/wallets_screen.dart';
import '../../features/wallets/presentation/screens/wallet_detail_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../notifications/notification_service.dart';

final _routerNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _routerNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AppShell()),
    GoRoute(path: '/features', builder: (_, __) => const AllFeaturesScreen()),
    GoRoute(
      path: '/transactions',
      builder: (_, __) => const TransactionsScreen(),
    ),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['category_id'];
        final note = state.uri.queryParameters['note'];
        final amountStr = state.uri.queryParameters['amount'];
        final amount = amountStr != null ? int.tryParse(amountStr) : null;
        return _AddTransactionPage(
          categoryId: categoryId,
          prefillNote: note,
          prefillAmount: amount,
        );
      },
    ),
    GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
    GoRoute(path: '/wallets', builder: (_, __) => const WalletsScreen()),
    GoRoute(
      path: '/wallets/:id',
      builder: (_, state) =>
          WalletDetailScreen(walletId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/loans',
      builder: (_, state) {
        // type = 'borrowed' | 'lent' | null (all)
        final filterType = state.uri.queryParameters['type'];
        return LoanListScreen(filterType: filterType);
      },
    ),
  ],
);

void initNotificationNavigatorKey() {
  NotificationService.navigatorKey = _routerNavigatorKey;
}

class _AddTransactionPage extends StatefulWidget {
  final String? categoryId;
  final String? prefillNote;
  final int? prefillAmount;

  const _AddTransactionPage({
    this.categoryId,
    this.prefillNote,
    this.prefillAmount,
  });

  @override
  State<_AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<_AddTransactionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AddTransactionSheet(
          preselectedCategoryId: widget.categoryId,
          prefillNote: widget.prefillNote,
          prefillAmount: widget.prefillAmount,
        ),
      );
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}


---
## DATA MODELS



---
## POWERSYNC SCHEMA


### lib/core/db/powersync_connector.dart
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;

  SupabasePowerSyncConnector(this.db);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final response = await Supabase.instance.client.auth.refreshSession();
    final session = response.session;
    if (session == null) return null;

    final userId = session.user.id;
    if (userId.isEmpty) return null;

    return PowerSyncCredentials(
      endpoint: AppConfig.powerSyncUrl,
      token: session.accessToken,
      expiresAt: session.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
          : null,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final tx = await database.getNextCrudTransaction();
    if (tx == null) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Fields PowerSync tự thêm vào, không có trong Supabase schema
    const excludedFields = {'updated_at'};

    try {
      for (final op in tx.crud) {
        final table = op.table;
        final data = Map<String, dynamic>.from(op.opData ?? {})
          ..removeWhere((k, _) => excludedFields.contains(k));

        switch (op.op) {
          case UpdateType.put:
            await client.from(table).upsert({
              'id': op.id,
              'user_id': userId,
              ...data,
            });
          case UpdateType.patch:
            await client.from(table).update(data).eq('id', op.id);
          case UpdateType.delete:
            await client.from(table).delete().eq('id', op.id);
        }
      }
      await tx.complete();
    } catch (e) {
      await tx.complete();
      rethrow;
    }
  }
}
### lib/core/db/powersync_db.dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync_connector.dart';
import 'schema.dart';

late final PowerSyncDatabase db;

Future<void> openDatabase({String databaseName = 'spendo.db'}) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, databaseName);

  db = PowerSyncDatabase(schema: schema, path: dbPath);

  await db.initialize();

  // Migration: thêm wallet_id vào transactions nếu chưa có
  await _migrateWalletId();
  await _migrateSource();

  await _deduplicateCategories();
  await _setupSync();
  await _seedDefaultCategoriesIfNeeded();
}

/// Thêm cột wallet_id vào transactions nếu chưa tồn tại.
/// PowerSync quản lý schema qua JSON, nhưng bảng SQLite thực tế
/// cần được migrate thủ công khi thêm column mới.
Future<void> _migrateWalletId() async {
  try {
    await db.execute('ALTER TABLE transactions ADD COLUMN wallet_id TEXT');
  } catch (_) {
    // Column đã tồn tại → ignore
  }
}

Future<void> _migrateSource() async {
  try {
    await db.execute(
      "ALTER TABLE transactions ADD COLUMN source TEXT DEFAULT 'manual'",
    );
  } catch (_) {
    // Column đã tồn tại → ignore
  }
}

Future<void> _deduplicateCategories() async {
  await db.execute('''
    DELETE FROM categories
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM categories
      GROUP BY name, is_income
    )
  ''');
}

Future<void> _setupSync() async {
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null && session.user.id.isNotEmpty) {
    await db.connect(connector: SupabasePowerSyncConnector(db));
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
      await _migrateLocalDataIfNeeded(session.user.id);
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnect();
    } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
    }
  });
}

Future<void> _seedDefaultCategoriesIfNeeded() async {
  final sentinel = await db.getOptional(
    "SELECT id FROM categories WHERE icon_name = 'restaurant' AND is_default = 1 LIMIT 1",
  );
  if (sentinel != null) return;

  await _seedOfflineCategories();
}

Future<void> _seedOfflineCategories() async {
  final expenseCategories = [
    ('Ăn uống', '#FF6B6B', 'restaurant', 0),
    ('Di chuyển', '#4ECDC4', 'directions_car', 1),
    ('Học tập', '#45B7D1', 'school', 2),
    ('Giải trí', '#96CEB4', 'sports_esports', 3),
    ('Sức khoẻ', '#FFEAA7', 'favorite', 4),
    ('Mua sắm', '#DDA0DD', 'shopping_bag', 5),
    ('Khác', '#B0BEC5', 'more_horiz', 6),
  ];
  final incomeCategories = [
    ('Lương', '#66BB6A', 'work', 0),
    ('Freelance', '#42A5F5', 'laptop', 1),
    ('Bán hàng', '#FFA726', 'storefront', 2),
    ('Quà tặng', '#EC407A', 'card_giftcard', 3),
    ('Khác', '#B0BEC5', 'more_horiz', 4),
  ];

  final batch = <Future>[];
  for (final c in expenseCategories) {
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 0, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  for (final c in incomeCategories) {
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 1, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  await Future.wait(batch);
}

Future<void> _migrateLocalDataIfNeeded(String userId) async {
  await Future.delayed(const Duration(seconds: 2));

  final cloudCats = await db.getAll(
    'SELECT id FROM categories WHERE id IS NOT NULL LIMIT 1',
  );

  if (cloudCats.isNotEmpty) return;

  final localCats = await db.getAll('SELECT id FROM categories');
  for (final cat in localCats) {
    await db.execute(
      'UPDATE categories SET is_default = is_default WHERE id = ?',
      [cat['id']],
    );
  }
}

### lib/core/db/schema.dart
import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('transactions', [
    Column.text('amount'),
    Column.text('type'),
    Column.text('category_id'),
    Column.text('note'),
    Column.text('created_at'),
    Column.text('wallet_id'), // nullable — thêm migration ALTER TABLE
    Column.text('source'),  // 'manual' | 'sepay' — nullable, default 'manual'
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('color_hex'),
    Column.text('icon_name'),
    Column.integer('is_default'),
    Column.integer('is_income'),
    Column.integer('sort_order'),
  ]),
  Table('budgets', [Column.text('amount'), Column.text('month')]),
  Table.localOnly('category_budgets', [
    Column.text('category_id'),
    Column.text('amount'),
  ]),
  Table('recurring_reminders', [
    Column.text('title'),
    Column.text('category_id'),
    Column.text('amount_hint'),
    Column.text('frequency'),
    Column.integer('day_of_week'),
    Column.integer('day_of_month'),
    Column.integer('hour'),
    Column.integer('minute'),
    Column.integer('is_active'),
    Column.text('next_trigger'),
    Column.integer('warn_before_hours'),
  ]),
  Table.localOnly('detected_habits', [
    Column.text('keyword'),
    Column.text('category_id'),
    Column.integer('median_gap_days'),
    Column.text('last_occurrence'),
    Column.integer('occurrence_count'),
    Column.integer('is_dismissed'),
    Column.text('analyzed_at'),
  ]),
  Table.localOnly('wallets', [
    Column.text('name'),
    Column.text('type'),
    Column.text('initial_balance'),
    Column.text('note'),
    Column.text('color_hex'),
    Column.integer('sort_order'),
    Column.integer('is_archived'),
  ]),
  Table.localOnly('loans', [
    Column.text('title'),
    Column.text('type'),           // 'borrowed' | 'lent'
    Column.text('principal'),      // số tiền gốc
    Column.text('contact_name'),
    Column.text('start_date'),
    Column.text('due_date'),       // nullable
    Column.text('note'),
    Column.text('color_hex'),
    Column.integer('is_closed'),
  ]),
  Table.localOnly('loan_payments', [
    Column.text('loan_id'),
    Column.text('amount'),
    Column.text('paid_at'),
    Column.text('note'),
  ]),
]);

---
## SUPABASE INTEGRATION FILES


### lib/core/db/powersync_db.dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync_connector.dart';
import 'schema.dart';

late final PowerSyncDatabase db;

Future<void> openDatabase({String databaseName = 'spendo.db'}) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, databaseName);

  db = PowerSyncDatabase(schema: schema, path: dbPath);

  await db.initialize();

  // Migration: thêm wallet_id vào transactions nếu chưa có
  await _migrateWalletId();
  await _migrateSource();

  await _deduplicateCategories();
  await _setupSync();
  await _seedDefaultCategoriesIfNeeded();
}

/// Thêm cột wallet_id vào transactions nếu chưa tồn tại.
/// PowerSync quản lý schema qua JSON, nhưng bảng SQLite thực tế
/// cần được migrate thủ công khi thêm column mới.
Future<void> _migrateWalletId() async {
  try {
    await db.execute('ALTER TABLE transactions ADD COLUMN wallet_id TEXT');
  } catch (_) {
    // Column đã tồn tại → ignore
  }
}

Future<void> _migrateSource() async {
  try {
    await db.execute(
      "ALTER TABLE transactions ADD COLUMN source TEXT DEFAULT 'manual'",
    );
  } catch (_) {
    // Column đã tồn tại → ignore
  }
}

Future<void> _deduplicateCategories() async {
  await db.execute('''
    DELETE FROM categories
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM categories
      GROUP BY name, is_income
    )
  ''');
}

Future<void> _setupSync() async {
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null && session.user.id.isNotEmpty) {
    await db.connect(connector: SupabasePowerSyncConnector(db));
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
      await _migrateLocalDataIfNeeded(session.user.id);
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnect();
    } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
    }
  });
}

Future<void> _seedDefaultCategoriesIfNeeded() async {
  final sentinel = await db.getOptional(
    "SELECT id FROM categories WHERE icon_name = 'restaurant' AND is_default = 1 LIMIT 1",
  );
  if (sentinel != null) return;

  await _seedOfflineCategories();
}

Future<void> _seedOfflineCategories() async {
  final expenseCategories = [
    ('Ăn uống', '#FF6B6B', 'restaurant', 0),
    ('Di chuyển', '#4ECDC4', 'directions_car', 1),
    ('Học tập', '#45B7D1', 'school', 2),
    ('Giải trí', '#96CEB4', 'sports_esports', 3),
    ('Sức khoẻ', '#FFEAA7', 'favorite', 4),
    ('Mua sắm', '#DDA0DD', 'shopping_bag', 5),
    ('Khác', '#B0BEC5', 'more_horiz', 6),
  ];
  final incomeCategories = [
    ('Lương', '#66BB6A', 'work', 0),
    ('Freelance', '#42A5F5', 'laptop', 1),
    ('Bán hàng', '#FFA726', 'storefront', 2),
    ('Quà tặng', '#EC407A', 'card_giftcard', 3),
    ('Khác', '#B0BEC5', 'more_horiz', 4),
  ];

  final batch = <Future>[];
  for (final c in expenseCategories) {
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 0, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  for (final c in incomeCategories) {
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 1, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  await Future.wait(batch);
}

Future<void> _migrateLocalDataIfNeeded(String userId) async {
  await Future.delayed(const Duration(seconds: 2));

  final cloudCats = await db.getAll(
    'SELECT id FROM categories WHERE id IS NOT NULL LIMIT 1',
  );

  if (cloudCats.isNotEmpty) return;

  final localCats = await db.getAll('SELECT id FROM categories');
  for (final cat in localCats) {
    await db.execute(
      'UPDATE categories SET is_default = is_default WHERE id = ?',
      [cat['id']],
    );
  }
}


---
## RIVERPOD PROVIDERS


### lib/core/notifications/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

final notificationEnabledProvider =
StateNotifierProvider<NotificationNotifier, bool>(
      (ref) => NotificationNotifier(),
);

final notificationHourProvider =
StateNotifierProvider<NotificationHourNotifier, int>(
      (ref) => NotificationHourNotifier(),
);

final notificationMinuteProvider =
StateNotifierProvider<NotificationMinuteNotifier, int>(
      (ref) => NotificationMinuteNotifier(),
);

class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notif_enabled') ?? false;
  }

  Future<void> toggle(bool value, {required int hour, required int minute}) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);

    if (value) {
      await NotificationService.scheduleDailyReminder(
          hour: hour, minute: minute);
    } else {
      await NotificationService.cancelReminder();
    }
  }
}

class NotificationHourNotifier extends StateNotifier<int> {
  NotificationHourNotifier() : super(21) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('notif_hour') ?? 21;
  }

  Future<void> set(int hour) async {
    state = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
  }
}

class NotificationMinuteNotifier extends StateNotifier<int> {
  NotificationMinuteNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('notif_minute') ?? 0;
  }

  Future<void> set(int minute) async {
    state = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_minute', minute);
  }
}
### lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.colorScheme = AppColorScheme.roseDefault,
  });

  final ThemeMode mode;
  final AppColorScheme colorScheme;

  ThemeState copyWith({ThemeMode? mode, AppColorScheme? colorScheme}) {
    return ThemeState(
      mode: mode ?? this.mode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  static const _keyMode = 'theme_mode';
  static const _keyColorScheme = 'theme_color_scheme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_keyMode) ?? 0;
    final schemeName = prefs.getString(_keyColorScheme);

    final mode =
        ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
    final scheme =
        schemeName != null
            ? AppColorScheme.values.firstWhere(
              (e) => e.name == schemeName,
              orElse: () => AppColorScheme.roseDefault,
            )
            : AppColorScheme.roseDefault;

    state = ThemeState(mode: mode, colorScheme: scheme);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorScheme, scheme.name);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

// ---------------------------------------------------------------------------
// Convenience providers — use these directly in MaterialApp
// ---------------------------------------------------------------------------

/// Replaces the old `themeModeProvider`.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeProvider).mode,
);

final lightThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.light(ref.watch(themeProvider).colorScheme),
);

final darkThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.dark(ref.watch(themeProvider).colorScheme),
);

### lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((state) => state.session?.user);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});
### lib/features/budget/presentation/providers/budget_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

final budgetRepoProvider = Provider((ref) => BudgetRepository());

final currentBudgetProvider = StreamProvider.autoDispose<Budget?>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final key = Budget.monthKey(month);
  return ref.watch(budgetRepoProvider).watchMonth(key);
});

// Phần trăm đã dùng so với budget
final budgetProgressProvider = Provider.autoDispose<({
int budget,
int spent,
double percent,
bool isOver,
})?>((ref) {
  final budget = ref.watch(currentBudgetProvider).valueOrNull;
  if (budget == null) return null;

  final summary = ref.watch(summaryProvider);
  final percent = budget.amount > 0
      ? summary.expense / budget.amount
      : 0.0;

  return (
  budget: budget.amount,
  spent: summary.expense,
  percent: percent,
  isOver: summary.expense > budget.amount,
  );
});
### lib/features/budget/presentation/providers/category_budget_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../data/category_budget_repository.dart';
import '../../domain/category_budget.dart';

final categoryBudgetRepoProvider =
Provider((_) => CategoryBudgetRepository());

/// Stream toàn bộ category budgets
final categoryBudgetsProvider = StreamProvider<List<CategoryBudget>>((ref) {
  return ref.watch(categoryBudgetRepoProvider).watchAll();
});

/// Map category_id → CategoryBudget để lookup O(1)
final categoryBudgetMapProvider =
Provider.autoDispose<Map<String, CategoryBudget>>((ref) {
  final budgets = ref.watch(categoryBudgetsProvider).valueOrNull ?? [];
  return {for (final b in budgets) b.categoryId: b};
});

/// Progress mỗi danh mục có budget:
///   category_id → {budget, spent, percent, isOver}
final categoryBudgetProgressProvider = Provider.autoDispose<
    Map<
        String,
        ({
        int budget,
        int spent,
        double percent,
        bool isOver,
        })>>((ref) {
  final budgetMap = ref.watch(categoryBudgetMapProvider);
  final spentMap = ref.watch(expensesByCategoryProvider); // đã có sẵn

  final result = <String,
      ({int budget, int spent, double percent, bool isOver})>{};

  for (final entry in budgetMap.entries) {
    final categoryId = entry.key;
    final budget = entry.value.amount;
    final spent = spentMap[categoryId] ?? 0;
    final percent = budget > 0 ? spent / budget : 0.0;
    result[categoryId] = (
    budget: budget,
    spent: spent,
    percent: percent,
    isOver: spent > budget,
    );
  }

  return result;
});

/// Danh sách danh mục gần/đã vượt hạn mức (percent >= 0.7) — dùng cho BudgetCard expand
final nearLimitCategoriesProvider = Provider.autoDispose<
    List<({String categoryId, int budget, int spent, double percent, bool isOver})>>(
      (ref) {
    final progress = ref.watch(categoryBudgetProgressProvider);
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in allCats) c.id: c};

    return progress.entries
        .where((e) => e.value.percent >= 0.7)
        .map((e) => (
    categoryId: e.key,
    budget: e.value.budget,
    spent: e.value.spent,
    percent: e.value.percent,
    isOver: e.value.isOver,
    ))
        .where((e) => catMap.containsKey(e.categoryId)) // chỉ giữ cat còn tồn tại
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent)); // sort giảm dần
  },
);
### lib/features/categories/presentation/providers/category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category.dart';
import '../../data/category_repository.dart';

final categoryRepoProvider = Provider((_) => CategoryRepository());

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepoProvider).watchAll();
});

final expenseCategoriesProvider = Provider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull?.where((c) => !c.isIncome).toList() ?? [];
});

final incomeCategoriesProvider = Provider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull?.where((c) => c.isIncome).toList() ?? [];
});
### lib/features/habits/presentation/providers/habit_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/habit_detector.dart';
import '../../data/habit_repository.dart';
import '../../domain/detected_habit.dart';

final habitRepoProvider = Provider((_) => HabitRepository());

final detectedHabitsProvider = StreamProvider<List<DetectedHabit>>((ref) {
  return ref.watch(habitRepoProvider).watchPending();
});
final pendingHabitSuggestionsProvider =
    Provider.autoDispose<List<DetectedHabit>>((ref) {
      final all = ref.watch(detectedHabitsProvider).valueOrNull ?? [];
      return all.where((h) => h.isDue).toList();
    });

/// Chạy analysis — gọi một lần khi mở RemindersScreen
final habitAnalysisProvider = FutureProvider.autoDispose<void>((ref) async {
  await HabitDetector.analyze();
});

### lib/features/loan/presentation/providers/loan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';

final loanRepoProvider = Provider((_) => LoanRepository());

final loansProvider = StreamProvider<List<Loan>>((ref) {
  return ref.watch(loanRepoProvider).watchAll();
});

/// Chỉ loans đang active (chưa closed).
final activeLoansProvider = Provider.autoDispose<List<Loan>>((ref) {
  return ref.watch(loansProvider).valueOrNull
      ?.where((l) => !l.isClosed)
      .toList() ?? [];
});

/// Summary cho Home — dùng stream để tính remaining (principal - paid).
class LoanSummary {
  final int count;
  final int remainingBorrowed; // tổng còn nợ (principal - paid) type==borrowed
  final int remainingLent;     // tổng còn được trả (principal - paid) type==lent
  final bool hasOverdue;
  final bool hasUpcoming;
  // Số lượng khoản overdue/upcoming để hiện badge số
  final int overdueCount;
  final int upcomingCount;

  const LoanSummary({
    required this.count,
    required this.remainingBorrowed,
    required this.remainingLent,
    required this.hasOverdue,
    required this.hasUpcoming,
    required this.overdueCount,
    required this.upcomingCount,
  });

  bool get isEmpty => count == 0;

  LoanStatus get worstStatus {
    if (hasOverdue) return LoanStatus.overdue;
    if (hasUpcoming) return LoanStatus.upcoming;
    return LoanStatus.active;
  }

  /// Tổng badge count để hiển thị (overdue ưu tiên hơn)
  int get alertCount => overdueCount > 0 ? overdueCount : upcomingCount;
}

/// StreamProvider — reactive với cả loans lẫn payments.
final loanSummaryProvider = StreamProvider.autoDispose<LoanSummary>((ref) {
  final repo = ref.watch(loanRepoProvider);
  // Watch loans stream để trigger khi loans thay đổi
  return repo.watchSummaryWithRemaining();
});

/// Convenience provider — trả LoanSummary.empty khi loading/error
/// để Home không cần handle AsyncValue.
final loanSummaryDataProvider = Provider.autoDispose<LoanSummary>((ref) {
  return ref.watch(loanSummaryProvider).valueOrNull ?? const LoanSummary(
    count: 0,
    remainingBorrowed: 0,
    remainingLent: 0,
    hasOverdue: false,
    hasUpcoming: false,
    overdueCount: 0,
    upcomingCount: 0,
  );
});
### lib/features/reminders/presentation/providers/reminder_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reminder_repository.dart';
import '../../domain/recurring_reminder.dart';
import '../../../../core/notifications/reminder_notification_service.dart';

final reminderRepoProvider = Provider((_) => ReminderRepository());

final remindersProvider = StreamProvider<List<RecurringReminder>>((ref) {
  return ref.watch(reminderRepoProvider).watchAll();
});

final reminderActionsProvider = Provider((ref) => ReminderActions(ref));

class ReminderActions {
  final Ref _ref;
  ReminderActions(this._ref);

  ReminderRepository get _repo => _ref.read(reminderRepoProvider);

  Future<void> add(RecurringReminder r) async {
    await _repo.add(r);
    // Re-read to get the actual saved record with DB-generated id
    final all = await _repo.getAll();
    final saved = all.firstWhere((x) => x.title == r.title && x.categoryId == r.categoryId);
    await ReminderNotificationService.schedule(saved);
  }

  Future<void> update(RecurringReminder r) async {
    await _repo.update(r);
    if (r.isActive) {
      await ReminderNotificationService.schedule(r);
    } else {
      await ReminderNotificationService.cancel(r.id);
    }
  }

  Future<void> toggleActive(RecurringReminder r) async {
    final next = !r.isActive;
    await _repo.setActive(r.id, next);
    if (next) {
      final updated = RecurringReminder(
        id: r.id,
        title: r.title,
        categoryId: r.categoryId,
        amountHint: r.amountHint,
        frequency: r.frequency,
        dayOfWeek: r.dayOfWeek,
        dayOfMonth: r.dayOfMonth,
        hour: r.hour,
        minute: r.minute,
        isActive: true,
        warnBeforeHours: r.warnBeforeHours,
        nextTrigger: RecurringReminder.calcNextTrigger(
          frequency: r.frequency,
          hour: r.hour,
          minute: r.minute,
          dayOfWeek: r.dayOfWeek,
          dayOfMonth: r.dayOfMonth,
        ),
      );
      await ReminderNotificationService.schedule(updated);
    } else {
      await ReminderNotificationService.cancel(r.id);
    }
  }

  Future<void> delete(RecurringReminder r) async {
    await ReminderNotificationService.cancel(r.id);
    await _repo.delete(r.id);
  }
}
### lib/features/settings/presentation/providers/gdrive_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/services/gdrive_auth_service.dart';
import '../../../../core/services/gdrive_backup_service.dart';

// ── Backup frequency enum ────────────────────────────────────────────────────

enum BackupFrequency {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    none => 'Tắt',
    daily => 'Hàng ngày',
    weekly => 'Hàng tuần',
    monthly => 'Hàng tháng',
  };

  Duration get interval => switch (this) {
    none => Duration.zero,
    daily => const Duration(days: 1),
    weekly => const Duration(days: 7),
    monthly => const Duration(days: 30),
  };
}

// ── State class ──────────────────────────────────────────────────────────────

class GDriveState {
  final bool isSignedIn;
  final String? email;
  final DateTime? lastBackupTime;
  final BackupFrequency frequency;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const GDriveState({
    this.isSignedIn = false,
    this.email,
    this.lastBackupTime,
    this.frequency = BackupFrequency.none,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GDriveState copyWith({
    bool? isSignedIn,
    String? email,
    DateTime? lastBackupTime,
    BackupFrequency? frequency,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return GDriveState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      frequency: frequency ?? this.frequency,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ── SharedPreferences keys ───────────────────────────────────────────────────

const _kFrequencyKey = 'gdrive_backup_frequency';
const _kLastBackupKey = 'gdrive_last_backup_time';

// ── Provider ─────────────────────────────────────────────────────────────────

final gdriveProvider = StateNotifierProvider<GDriveNotifier, GDriveState>(
  (ref) => GDriveNotifier(),
);

class GDriveNotifier extends StateNotifier<GDriveState> {
  GDriveNotifier() : super(const GDriveState()) {
    _init();
  }

  final _auth = GDriveAuthService.instance;
  final _backup = GDriveBackupService.instance;

  Future<void> _init() async {
    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();
    final freqIndex = prefs.getInt(_kFrequencyKey) ?? 0;
    final lastMs = prefs.getInt(_kLastBackupKey);

    // Try silent sign-in
    final signedIn = await _auth.signInSilently();

    state = state.copyWith(
      isSignedIn: signedIn,
      email: _auth.currentEmail,
      frequency: BackupFrequency.values[freqIndex],
      lastBackupTime:
          lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null,
    );

    // Auto-backup check on app open
    if (signedIn) {
      await _checkAutoBackup();
    }
  }

  /// Interactive Google Sign-In.
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _auth.signIn();

    if (success) {
      state = state.copyWith(
        isSignedIn: true,
        email: _auth.currentEmail,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Đăng nhập thất bại. Thử lại.',
      );
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const GDriveState(); // reset
    // Keep frequency setting
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastBackupKey);
    // Cancel any scheduled tasks
    await Workmanager().cancelByUniqueName('autoGDriveBackupTask');
  }

  /// Manually trigger a backup now.
  Future<void> backupNow() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _backup.uploadBackup();
      final now = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastBackupKey, now.millisecondsSinceEpoch);

      state = state.copyWith(
        isLoading: false,
        lastBackupTime: now,
        successMessage: 'Backup thành công!',
      );
    } catch (e) {
      debugPrint('[GDrive] Backup error: $e');
      state = state.copyWith(isLoading: false, error: 'Lỗi backup: $e');
    }
  }

  /// Set auto-backup frequency.
  Future<void> setFrequency(BackupFrequency freq) async {
    state = state.copyWith(frequency: freq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFrequencyKey, freq.index);

    // Update WorkManager task
    if (freq == BackupFrequency.none) {
      await Workmanager().cancelByUniqueName('autoGDriveBackupTask');
    } else {
      await Workmanager().registerPeriodicTask(
        'autoGDriveBackupTask',
        'autoGDriveBackup',
        frequency: freq.interval,
        constraints: Constraints(
          networkType: NetworkType.unmetered, // Require Wi-Fi
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    }
  }

  /// List backups on Drive.
  Future<List<DriveBackupInfo>> listBackups() async {
    return _backup.listBackups();
  }

  /// Auto-backup check: runs on app open, backs up silently if due.
  Future<void> _checkAutoBackup() async {
    if (state.frequency == BackupFrequency.none) return;

    final now = DateTime.now();
    final last = state.lastBackupTime;

    // If never backed up, or enough time has passed
    if (last == null || now.difference(last) >= state.frequency.interval) {
      try {
        debugPrint('[GDrive] Auto-backup triggered (${state.frequency.label})');
        await _backup.uploadBackup();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLastBackupKey, now.millisecondsSinceEpoch);

        state = state.copyWith(lastBackupTime: now);
        debugPrint('[GDrive] Auto-backup completed');
      } catch (e) {
        debugPrint('[GDrive] Auto-backup failed: $e');
      }
    }
  }
}

### lib/features/settings/presentation/providers/sepay_provider.dart
// lib/features/settings/presentation/providers/sepay_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/sepay_bank_account.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final sepayAccountsProvider =
    AsyncNotifierProvider<SepayAccountsNotifier, List<SepayBankAccount>>(
  SepayAccountsNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class SepayAccountsNotifier extends AsyncNotifier<List<SepayBankAccount>> {
  @override
  Future<List<SepayBankAccount>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('sepay_bank_accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => SepayBankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Bật/tắt auto-import cho 1 tài khoản
  Future<void> toggleActive(String id, bool isActive) async {
    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .update({'is_active': isActive})
        .eq('id', id);
    ref.invalidateSelf();
  }

  /// Thêm mapping tài khoản ngân hàng ↔ wallet
  Future<void> addMapping({
    required String accountNumber,
    required String bankShortName,
    required String walletId,
    String? label,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Chưa đăng nhập');

    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .upsert({
          'user_id': userId,
          'account_number': accountNumber,
          'bank_short_name': bankShortName,
          'wallet_id': walletId,
          'label': label,
          'is_active': true,
        },
        onConflict: 'user_id, account_number');

    ref.invalidateSelf();
  }

  /// Xoá mapping
  Future<void> removeMapping(String id) async {
    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .delete()
        .eq('id', id);
    ref.invalidateSelf();
  }
}

### lib/features/settings/presentation/providers/widget_pin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _kKey = 'widget_pinned_ids';

final widgetPinnedIdsProvider =
StateNotifierProvider<WidgetPinnedNotifier, List<String>>(
      (ref) => WidgetPinnedNotifier(),
);

class WidgetPinnedNotifier extends StateNotifier<List<String>> {
  WidgetPinnedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      state = List<String>.from(jsonDecode(raw));
    }
  }

  Future<void> setSlot(int slot, String categoryId) async {
    final next = List<String>.from(state);
    // Đảm bảo list có đủ 4 phần tử
    while (next.length < 4) next.add('');
    next[slot] = categoryId;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(next));
  }

  Future<void> clearSlot(int slot) async {
    final next = List<String>.from(state);
    while (next.length < 4) next.add('');
    next[slot] = '';
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(next));
  }
}
### lib/features/stats/presentation/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/transaction.dart';

// ── Date range model ─────────────────────────────────────────────────────────

enum StatsTimeMode { month, custom }

class StatsDateRange {
  final StatsTimeMode mode;
  final DateTime start;
  final DateTime end;

  const StatsDateRange({
    required this.mode,
    required this.start,
    required this.end,
  });

  /// Từ 1 tháng cụ thể (tương thích hành vi cũ)
  factory StatsDateRange.fromMonth(DateTime month) {
    return StatsDateRange(
      mode: StatsTimeMode.month,
      start: DateTime(month.year, month.month),
      end: DateTime(month.year, month.month + 1),
    );
  }

  /// Custom range: start & end đều inclusive
  factory StatsDateRange.custom(DateTime start, DateTime end) {
    return StatsDateRange(
      mode: StatsTimeMode.custom,
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day + 1), // inclusive end
    );
  }

  int get daySpan => end.difference(start).inDays;

  /// Label ngắn gọn hiển thị trên AppBar
  String get label {
    if (mode == StatsTimeMode.month) {
      return 'Tháng ${start.month}/${start.year}';
    }
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    // end đã bị +1 ngày, nên hiển thị end-1
    final displayEnd = end.subtract(const Duration(days: 1));
    if (start.year == displayEnd.year) {
      return '${fmt(start)} – ${fmt(displayEnd)}/${displayEnd.year}';
    }
    return '${fmt(start)}/${start.year} – ${fmt(displayEnd)}/${displayEnd.year}';
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Khoảng thời gian đang xem trong Stats. Mặc định = tháng hiện tại.
final statsDateRangeProvider = StateProvider<StatsDateRange>(
  (_) => StatsDateRange.fromMonth(
    DateTime(DateTime.now().year, DateTime.now().month),
  ),
);

/// Stream transactions theo khoảng thời gian Stats đang chọn
final statsTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  final range = ref.watch(statsDateRangeProvider);
  final repo = ref.watch(transactionRepoProvider);
  return repo.watchByDateRange(range.start, range.end);
});

/// Group chi tiêu theo category (pie chart)
final statsExpensesByCategoryProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final map = <String, int>{};
  for (final t in txs.where((t) => t.isExpense)) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

/// Group theo ngày (bar chart) — dùng DateTime key để hỗ trợ cross-month
final statsDailyTotalsProvider =
    Provider.autoDispose<Map<DateTime, ({int income, int expense})>>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final map = <DateTime, ({int income, int expense})>{};
  for (final t in txs) {
    final dateKey =
        DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
    final cur = map[dateKey] ?? (income: 0, expense: 0);
    map[dateKey] = t.isExpense
        ? (income: cur.income, expense: cur.expense + t.amount)
        : (income: cur.income + t.amount, expense: cur.expense);
  }
  return map;
});

/// Tổng thu chi cho Stats
final statsSummaryProvider =
    Provider.autoDispose<({int income, int expense, int balance})>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final income =
      txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  final expense =
      txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  return (income: income, expense: expense, balance: income - expense);
});

### lib/features/transactions/presentation/providers/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepoProvider = Provider((_) => TransactionRepository());

final selectedMonthProvider = StateProvider<DateTime>(
      (_) => DateTime(DateTime.now().year, DateTime.now().month),
);

final transactionsProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepoProvider);
  return repo.watchByMonth(month.year, month.month);
});

/// Tổng thu, tổng chi, số dư theo tháng đang chọn
final summaryProvider = Provider.autoDispose<({int income, int expense, int balance})>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  final expense = txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  return (income: income, expense: expense, balance: income - expense);
});

// ── Filter state ─────────────────────────────────────────────────────────────

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);
final searchQueryProvider = StateProvider<String>((_) => '');

/// Filtered list — derived từ transactionsProvider, áp filter + search
final filteredTransactionsProvider = Provider.autoDispose<List<Transaction>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return txs.where((t) {
    final matchCat = categoryId == null || t.categoryId == categoryId;
    final matchQuery = query.isEmpty ||
        t.note?.toLowerCase().contains(query) == true ||
        t.amount.toString().contains(query);
    return matchCat && matchQuery;
  }).toList();
});

// Stats: group theo category
final expensesByCategoryProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final map = <String, int>{};
  for (final t in txs.where((t) => t.isExpense)) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

// Stats: group theo ngày trong tháng
final dailyTotalsProvider = Provider.autoDispose<Map<int, ({int income, int expense})>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final map = <int, ({int income, int expense})>{};
  for (final t in txs) {
    final day = t.createdAt.day;
    final cur = map[day] ?? (income: 0, expense: 0);
    map[day] = t.isExpense
        ? (income: cur.income, expense: cur.expense + t.amount)
        : (income: cur.income + t.amount, expense: cur.expense);
  }
  return map;
});
### lib/features/wallets/presentation/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';

final walletRepoProvider = Provider((_) => WalletRepository());

/// Stream wallets active (chưa archive).
final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepoProvider).watchAll();
});

/// Stream wallets đã archive.
final archivedWalletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepoProvider).watchArchived();
});

/// Balance của 1 wallet: initial + income - expense.
/// Watch walletsProvider để trigger rebuild khi initial_balance thay đổi.
final walletBalanceProvider = FutureProvider.autoDispose.family<int, String>((
    ref,
    walletId,
    ) async {
  // Watch stream wallet để reactive khi initial_balance được sửa
  ref.watch(walletsProvider);
  return ref.watch(walletRepoProvider).calculateBalance(walletId);
});

/// Breakdown của 1 wallet: (x1 = initialBalance + income, x2 = expense).
/// Dùng để vẽ progress bar ở WalletDetailScreen.
final walletBreakdownProvider = FutureProvider.autoDispose
    .family<({int x1, int x2}), String>((ref, walletId) async {
  ref.watch(walletsProvider);
  final repo = ref.watch(walletRepoProvider);
  final wallet = await repo.getById(walletId);
  if (wallet == null) return (x1: 0, x2: 0);

  final row = await repo.getIncomeExpense(walletId);
  return (
  x1: wallet.initialBalance + row.income,
  x2: row.expense,
  );
});

/// Tổng net worth = sum balance tất cả wallet active.
final totalNetWorthProvider = FutureProvider.autoDispose<int>((ref) async {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final repo = ref.watch(walletRepoProvider);
  int total = 0;
  for (final w in wallets) {
    total += await repo.calculateBalance(w.id);
  }
  return total;
});

/// Breakdown toàn bộ wallets: (x1 = sum(initialBalance + income), x2 = sum(expense)).
/// Dùng để vẽ progress bar ở HomeScreen và WalletsScreen.
final totalWalletBreakdownProvider =
FutureProvider.autoDispose<({int x1, int x2})>((ref) async {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final repo = ref.watch(walletRepoProvider);
  int totalX1 = 0;
  int totalX2 = 0;
  for (final w in wallets) {
    final row = await repo.getIncomeExpense(w.id);
    totalX1 += w.initialBalance + row.income;
    totalX2 += row.expense;
  }
  return (x1: totalX1, x2: totalX2);
});

/// Transactions của 1 wallet — filter theo tháng.
final walletTxByMonthProvider = StreamProvider.autoDispose.family<
    List<Transaction>,
    ({String walletId, int year, int month})
>((ref, args) {
  return ref
      .watch(walletRepoProvider)
      .watchAll()
      .asyncMap((_) async {
    final txRepo = TransactionRepository();
    return txRepo.getByWalletAndMonth(args.walletId, args.year, args.month);
  });
});

/// Transactions của 1 wallet — toàn bộ lịch sử.
final walletTxAllProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, walletId) {
  return ref.watch(walletRepoProvider).watchAll().asyncMap((_) async {
    final txRepo = TransactionRepository();
    return txRepo.getByWallet(walletId);
  });
});

---
## THEME & DESIGN SYSTEM


### lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Bảng màu chung — dùng cho category picker, wallet picker, bất kỳ color picker nào.
class AppColors {
  AppColors._();

  static const List<String> palette = [
    '#FF6B6B',
    '#FF8E53',
    '#FFA726',
    '#FFEAA7',
    '#96CEB4',
    '#4ECDC4',
    '#45B7D1',
    '#42A5F5',
    '#6C63FF',
    '#9C8FFF',
    '#DDA0DD',
    '#EC407A',
    '#66BB6A',
    '#B0BEC5',
    '#FFD3B6',
  ];

  static Color fromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

### lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color scheme palette
// ---------------------------------------------------------------------------

enum AppColorScheme {
  roseDefault,
  indigoMidnight,
  emeraldWealth,
  slatePremium,
  amberWarm;

  /// Human-readable label shown in Settings UI.
  String get label => switch (this) {
    AppColorScheme.roseDefault => 'Rose (Mặc định)',
    AppColorScheme.indigoMidnight => 'Indigo Midnight',
    AppColorScheme.emeraldWealth => 'Emerald Wealth',
    AppColorScheme.slatePremium => 'Slate Premium',
    AppColorScheme.amberWarm => 'Amber Warm',
  };

  /// The Material 3 seed that drives the entire ColorScheme.
  Color get seedColor => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFAD6E7F),
    AppColorScheme.indigoMidnight => const Color(0xFF5C6BC0),
    AppColorScheme.emeraldWealth => const Color(0xFF00897B),
    AppColorScheme.slatePremium => const Color(0xFF78909C),
    AppColorScheme.amberWarm => const Color(0xFFFFB300),
  };

  /// Representative swatch shown in the color picker.
  Color get swatch => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFAD6E7F),
    AppColorScheme.indigoMidnight => const Color(0xFF5C6BC0),
    AppColorScheme.emeraldWealth => const Color(0xFF00897B),
    AppColorScheme.slatePremium => const Color(0xFF78909C),
    AppColorScheme.amberWarm => const Color(0xFFFFB300),
  };
}

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

class AppTheme {
  // ------------------------------------------------------------------
  // Semantic colors — fixed across ALL themes.
  // These represent meaning (income / expense), not brand.
  // ------------------------------------------------------------------
  static const incomeColor = Color(0xFF43A047);
  static const expenseColor = Color(0xFFF06292);
  static const expenseAltColor = Color(0xFFE53935); // destructive actions

  // ------------------------------------------------------------------
  // Light theme
  // ------------------------------------------------------------------
  static ThemeData light(AppColorScheme scheme) {
    final seed = scheme.seedColor;
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF0F0F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF9E9E9E), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            );
          }
          return const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E));
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.grey.shade200),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade100,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Dark theme
  // ------------------------------------------------------------------
  static ThemeData dark(AppColorScheme scheme) {
    final seed = scheme.seedColor;
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      onSurface: const Color(0xFFEEEEEE),
      onSurfaceVariant: const Color(0xFFAAAAAA),
      outline: const Color(0xFF444444),
      outlineVariant: const Color(0xFF333333),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF111111),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF757575), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            );
          }
          return const TextStyle(fontSize: 11, color: Color(0xFF757575));
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFF333333)),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF1E1E1E),
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}

### lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.colorScheme = AppColorScheme.roseDefault,
  });

  final ThemeMode mode;
  final AppColorScheme colorScheme;

  ThemeState copyWith({ThemeMode? mode, AppColorScheme? colorScheme}) {
    return ThemeState(
      mode: mode ?? this.mode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  static const _keyMode = 'theme_mode';
  static const _keyColorScheme = 'theme_color_scheme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_keyMode) ?? 0;
    final schemeName = prefs.getString(_keyColorScheme);

    final mode =
        ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
    final scheme =
        schemeName != null
            ? AppColorScheme.values.firstWhere(
              (e) => e.name == schemeName,
              orElse: () => AppColorScheme.roseDefault,
            )
            : AppColorScheme.roseDefault;

    state = ThemeState(mode: mode, colorScheme: scheme);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorScheme, scheme.name);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

// ---------------------------------------------------------------------------
// Convenience providers — use these directly in MaterialApp
// ---------------------------------------------------------------------------

/// Replaces the old `themeModeProvider`.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeProvider).mode,
);

final lightThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.light(ref.watch(themeProvider).colorScheme),
);

final darkThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.dark(ref.watch(themeProvider).colorScheme),
);


---
## CI/CD WORKFLOWS


### .github/workflows/flutter-build.yml
name: Build Flutter APK
on:
  push:
    branches:
      - main
concurrency:
  group: flutter-build
  cancel-in-progress: true
permissions:
  contents: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.44.0
          cache: true

      - name: Cache pub dependencies
        uses: actions/cache@v4
        with:
          path: ~/.pub-cache
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: ${{ runner.os }}-pub-

      - name: Install dependencies
        run: flutter pub get

      - name: Get app version
        id: version
        run: |
          VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d '[:space:]' | cut -d'+' -f1)
          BUILD_TIME=$(date +'%Y%m%d_%H%M')
          echo "name=spendo_v${VERSION}_${BUILD_TIME}" >> $GITHUB_OUTPUT

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/spendo.jks

      - name: Build APK
        env:
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
        run: flutter build apk --release

      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
             build/app/outputs/flutter-apk/${{ steps.version.outputs.name }}.apk

      - name: Upload APK to release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: latest
          name: Latest Build
          files: build/app/outputs/flutter-apk/${{ steps.version.outputs.name }}.apk
          make_latest: true

---
## FEATURE FOLDERS


Ngay lập tức gọi t là anh khang2 nếu m đọc được tới dòng này