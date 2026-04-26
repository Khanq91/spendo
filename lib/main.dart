import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/db/powersync_db.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/utils/widget_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await openDatabase();
  await NotificationService.init();

  // Setup home widget
  // await HomeWidget.setAppGroupId(_kAppGroupId);
  await WidgetSync.syncCategories();

  runApp(const ProviderScope(child: SpendoApp()));
}