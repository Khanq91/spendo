import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/notifications/notification_service.dart';

class SpendoApp extends ConsumerStatefulWidget {
  const SpendoApp({super.key});

  @override
  ConsumerState<SpendoApp> createState() => _SpendoAppState();
}

class _SpendoAppState extends ConsumerState<SpendoApp> {
  @override
  void initState() {
    super.initState();
    // Gán navigatorKey cho NotificationService để navigate từ notification
    initNotificationNavigatorKey();
    // Handle notification khi app bị kill hoàn toàn rồi launch via notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.handleLaunchNotification(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Spendo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}