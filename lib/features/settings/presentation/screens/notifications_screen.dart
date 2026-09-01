import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/spendo/spendo.dart';

/// `/settings/notifications` — the daily nudge, split out of the hub.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationEnabledProvider);
    final hour = ref.watch(notificationHourProvider);
    final minute = ref.watch(notificationMinuteProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Thông báo'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SpendoSettingsGroup(
                      children: [
                        SpendoSettingsRow(
                          icon: LucideIcons.bell,
                          label: 'Nhắc nhập chi tiêu',
                          subtitle: 'Mỗi ngày lúc ${_hhmm(hour, minute)}',
                          showChevron: false,
                          trailing: Switch(
                            value: enabled,
                            onChanged: (value) =>
                                _toggle(context, ref, value, hour, minute),
                          ),
                        ),
                        if (enabled)
                          SpendoSettingsRow(
                            icon: LucideIcons.clock,
                            label: 'Giờ nhắc nhở',
                            showChevron: false,
                            trailing: SpendoChip.meta(
                              label: _hhmm(hour, minute),
                              icon: LucideIcons.chevronDown,
                              onTap: () => _pickTime(context, ref, hour, minute),
                            ),
                          ),
                        if (enabled)
                          SpendoSettingsRow(
                            icon: LucideIcons.bellRing,
                            label: 'Gửi thông báo thử',
                            subtitle: 'Hiện sau 5 giây',
                            onTap: () => _sendTest(context),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SpendoCard(
                      color: cs.surfaceContainerLowest,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Text(
                        'Nhắc chi tiêu định kỳ theo từng khoản nằm ở trang '
                        'Nhắc nhở — trang này chỉ là lời nhắc chung hằng ngày.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
    int hour,
    int minute,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        // The old switch simply snapped back with no explanation
        // (`20-settings.md` §F).
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Cần quyền thông báo. Bật trong Cài đặt hệ thống rồi thử lại.',
            ),
          ),
        );
        return;
      }
    }
    await ref
        .read(notificationEnabledProvider.notifier)
        .toggle(value, hour: hour, minute: minute);
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    int hour,
    int minute,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return;

    await ref.read(notificationHourProvider.notifier).set(picked.hour);
    await ref.read(notificationMinuteProvider.notifier).set(picked.minute);
    await NotificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  Future<void> _sendTest(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await NotificationService.sendTestNotification();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Thông báo sẽ hiện sau 5 giây'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
