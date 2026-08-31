import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';

/// The routed part of the app, shown once splash + onboarding are done.
///
/// This is deliberately NOT a `MaterialApp`: the single one lives in
/// `main.dart` so that splash and onboarding already run under the user's
/// theme. Here only the router is attached, via [Router.withConfig].
class SpendoApp extends StatefulWidget {
  const SpendoApp({super.key});

  @override
  State<SpendoApp> createState() => _SpendoAppState();
}

class _SpendoAppState extends State<SpendoApp> {
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
    return Router.withConfig(config: appRouter);
  }
}
