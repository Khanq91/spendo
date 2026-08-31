import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/db/powersync_db.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_notification_service.dart';
import 'core/services/gdrive_background_backup.dart';
import 'core/theme/app_glass_policy.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/widget_sync.dart';
import 'features/onboarding/presentation/startup_gate.dart';
import 'features/reminders/data/reminder_repository.dart';
import 'shared/widgets/splash_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) => runGDriveBackgroundTask(taskName),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final initialGlassQuality = AppGlassPolicy.parseSavedQuality(
    preferences.getString(AppGlassPolicy.adaptiveQualityPrefsKey),
  );
  await LiquidGlassWidgets.initialize();
  Workmanager().initialize(callbackDispatcher);
  runApp(
    LiquidGlassWidgets.wrap(
      child: const ProviderScope(child: _AppRoot()),
      theme: GlassThemeData.simple(quality: AppGlassPolicy.themeQuality),
      adaptiveQuality: true,
      // Intentional Phase 7 opt-in; this is the package's device quality cap.
      // ignore: experimental_member_use
      adaptiveConfig: GlassAdaptiveScopeConfig(
        minQuality: AppGlassPolicy.minimumAdaptiveQuality,
        maxQuality: AppGlassPolicy.maximumAdaptiveQuality,
        initialQuality: initialGlassQuality,
        allowStepUp: true,
        onQualityChanged: (_, quality) {
          unawaited(
            preferences.setString(
              AppGlassPolicy.adaptiveQualityPrefsKey,
              quality.name,
            ),
          );
        },
      ),
    ),
  );
}

/// The single [MaterialApp] of the app.
///
/// Splash and onboarding used to live inside their own `MaterialApp` seeded
/// with the brand colour, with [SpendoApp] pushed as a route *inside* it —
/// two nested MaterialApps, so the first frames ignored the user's theme.
/// Everything now runs under one themed app: splash and welcome are ordinary
/// screens, and the router takes over once onboarding is done.
class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Spendo',
      debugShowCheckedModeBanner: false,
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(
        onInit: _initServices,
        nextScreen: const StartupGate(),
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
    final reminders = await ReminderRepository().getAll().timeout(
      const Duration(seconds: 5),
    );
    await ReminderNotificationService.scheduleAll(
      reminders,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[Init] Reminder scheduling error: $e');
  }

  // 5. Home widgets sync
  report(0.90, 'Syncing widgets…');
  await WidgetSync.syncCategories();

  report(1.0, 'All done!');
  await Future.delayed(const Duration(milliseconds: 200));
}
