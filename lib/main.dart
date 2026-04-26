import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/db/powersync_db.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/utils/widget_sync.dart';
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

/// Chạy tất cả dịch vụ tuần tự, báo cáo progress về splash screen.
Future<void> _initServices(
    void Function(double progress, String message) report,
    ) async {
  report(0.0, 'Initializing…');
  await Future.delayed(const Duration(milliseconds: 100)); // allow first frame

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

  // 4. Home widgets sync
  report(0.85, 'Syncing widgets…');
  await WidgetSync.syncCategories();

  report(1.0, 'All done!');
  await Future.delayed(const Duration(milliseconds: 200));
}