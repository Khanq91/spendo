import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/db/powersync_db.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_notification_service.dart';
import 'core/utils/widget_sync.dart';
import 'features/reminders/data/reminder_repository.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final reminders = await ReminderRepository().getAll();
  await ReminderNotificationService.scheduleAll(reminders);

  // 5. Home widgets sync
  report(0.90, 'Syncing widgets…');
  await WidgetSync.syncCategories();

  report(1.0, 'All done!');
  await Future.delayed(const Duration(milliseconds: 200));
}