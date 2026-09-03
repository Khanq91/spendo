import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/spendo/spendo.dart';

/// `/settings/reset` — the door to the data reset.
///
/// Deliberately one step away from the switch itself: an explanation, a
/// warning card around the single button, and the confirmation screen only
/// after that.
class ResetDataScreen extends StatelessWidget {
  const ResetDataScreen({super.key});

  static const String title = 'Đặt lại dữ liệu';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    'Đưa Spendo về trạng thái như lần đầu cài đặt. Mọi dữ '
                    'liệu trên máy này sẽ bị xóa và không thể khôi phục.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DangerCard(
                    onPressed: () => context.push('/settings/reset/confirm'),
                  ),
                  const SizedBox(height: 16),
                  SpendoCard(
                    color: cs.surfaceContainerLowest,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Text(
                      'Muốn giữ lại dữ liệu? Xuất một bản sao lưu trong '
                      '"Sao lưu & đồng bộ" trước, hoặc ngay ở bước xác nhận.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: cs.onSurfaceVariant,
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
}

/// Pale error fill, solid error border: the one card on this screen.
class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        border: Border.all(color: cs.error, width: 1.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusCardFeature),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.triangleAlert, size: 20, color: cs.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vùng nguy hiểm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Xóa toàn bộ giao dịch, nguồn tiền, khoản vay, sổ theo dõi, nhắc '
            'nhở, danh mục tự tạo, ngân sách và mọi cài đặt trên máy này. '
            'Spendo sẽ quay về màn hình chào như lần đầu mở.',
            style: TextStyle(fontSize: 13, height: 1.5, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          SpendoButton.danger(
            label: 'Xóa toàn bộ dữ liệu',
            icon: LucideIcons.trash2,
            expand: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
