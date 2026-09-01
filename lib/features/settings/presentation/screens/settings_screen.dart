import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/visual_mode_provider.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../loan/presentation/providers/loan_provider.dart';
import '../../../reminders/presentation/providers/reminder_provider.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../providers/gdrive_provider.dart';
import '../providers/sepay_provider.dart';
import '../providers/widget_pin_provider.dart';

/// Screen 05 of the redesign — the Settings hub.
///
/// The old screen was a 1366-line flat list of nine unrelated groups with no
/// second level of navigation, and buried Danh mục — a core entity — at the
/// bottom inside an expansion tile (`20-settings.md` §L). Everything now sits
/// behind three grouped cards, each row a page of its own.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFancy = ref.watch(visualModeProvider) == AppVisualMode.fancy;
    final bottomPadding =
        (isFancy ? MediaQuery.paddingOf(context).bottom : 0.0) + 24;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Cài đặt'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomPadding),
                children: [
                  const _Label('DỮ LIỆU'),
                  _dataGroup(context, ref),
                  const _Label('KẾT NỐI'),
                  _connectionGroup(context, ref),
                  const _Label('ỨNG DỤNG'),
                  _appGroup(context, ref),
                  const SizedBox(height: 20),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Groups ─────────────────────────────────────────────────────────────────

  Widget _dataGroup(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull;
    final wallets = ref.watch(walletsProvider).valueOrNull;
    final loans = ref.watch(loansProvider).valueOrNull;
    final reminders = ref.watch(remindersProvider).valueOrNull;

    return _Group(
      children: [
        SpendoSettingsRow(
          icon: LucideIcons.tag,
          label: 'Danh mục',
          trailingText: _count(categories?.length),
          onTap: () => context.push('/settings/categories'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.wallet,
          label: 'Nguồn tiền',
          trailingText: _count(wallets?.length),
          onTap: () => context.push('/wallets'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.handCoins,
          label: 'Khoản vay',
          trailingText: _count(loans?.length),
          onTap: () => context.push('/loans'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.bellRing,
          label: 'Nhắc nhở',
          trailingText: _count(reminders?.length),
          onTap: () => context.push('/reminders'),
        ),
      ],
    );
  }

  Widget _connectionGroup(BuildContext context, WidgetRef ref) {
    final drive = ref.watch(gdriveProvider);
    final accounts = ref.watch(sepayAccountsProvider).valueOrNull;
    final pinned = ref
        .watch(widgetPinnedIdsProvider)
        .where((id) => id.isNotEmpty)
        .length;

    return _Group(
      children: [
        SpendoSettingsRow(
          icon: LucideIcons.cloud,
          label: 'Sao lưu & đồng bộ',
          trailingText: _backupSummary(drive),
          onTap: () => context.push('/settings/backup'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.landmark,
          label: 'Ngân hàng tự động',
          trailingText: accounts == null
              ? null
              : accounts.isEmpty
              ? 'Chưa bật'
              : '${accounts.length} tài khoản',
          onTap: () => context.push('/settings/bank'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.smartphone,
          label: 'Widget màn hình chính',
          trailingText: '$pinned/4',
          onTap: () => context.push('/settings/widget'),
        ),
      ],
    );
  }

  Widget _appGroup(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(themeProvider).colorScheme;
    final mode = ref.watch(themeModeProvider);
    final notifOn = ref.watch(notificationEnabledProvider);
    final hour = ref.watch(notificationHourProvider);
    final minute = ref.watch(notificationMinuteProvider);

    return _Group(
      children: [
        SpendoSettingsRow(
          icon: LucideIcons.palette,
          label: 'Giao diện',
          trailingText: _modeLabel(mode),
          trailing: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.brandColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          onTap: () => context.push('/settings/appearance'),
        ),
        SpendoSettingsRow(
          icon: LucideIcons.bell,
          label: 'Thông báo',
          trailingText: notifOn
              ? 'Mỗi ngày · ${hour.toString().padLeft(2, '0')}'
                    ':${minute.toString().padLeft(2, '0')}'
              : 'Đã tắt',
          onTap: () => context.push('/settings/notifications'),
        ),
      ],
    );
  }

  // ── Trailing summaries ─────────────────────────────────────────────────────

  static String? _count(int? value) => value?.toString();

  static String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Hệ thống',
    ThemeMode.light => 'Sáng',
    ThemeMode.dark => 'Tối',
  };

  static String _backupSummary(GDriveState drive) {
    if (!drive.isSignedIn) return 'Chưa bật';
    final at = drive.lastBackupTime;
    if (at == null) return 'Drive · chưa sao lưu';

    final diff = DateTime.now().difference(at);
    final when = switch (diff) {
      _ when diff.inMinutes < 60 => 'vừa xong',
      _ when diff.inHours < 24 => '${diff.inHours} giờ trước',
      _ => '${diff.inDays} ngày trước',
    };
    return 'Drive · $when';
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SpendoSettingsGroup(children: children),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Tight on purpose: three groups plus the footer have to land inside a
      // 360×640 screen, which the old flat list missed by ~1400px.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: SpendoSectionHeader(label: text, padding: EdgeInsets.zero),
    );
  }
}

/// Version + tagline, so "which build am I on" no longer needs the Play Store.
class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  String? _version;

  @override
  void initState() {
    super.initState();
    // The version is a nicety, not a reason to fail the screen: on a platform
    // that cannot answer, the tagline stands on its own.
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) setState(() => _version = info.version);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.sprout, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _version == null
                  ? 'Spendo · Your money, clearly.'
                  : 'Spendo v$_version · Your money, clearly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
