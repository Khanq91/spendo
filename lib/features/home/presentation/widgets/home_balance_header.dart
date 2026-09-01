import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Stand-in shown instead of an amount while the header is masked.
const _kMask = '••••••';

/// "Còn lại tháng này" + the month's net balance, with Thu/Chi underneath.
///
/// Replaces the old gradient `SummaryCards`: one number leads, the two
/// components sit beside it as dotted read-outs, and a single eye masks all
/// three at once (the audit counted three independent toggles before).
class HomeBalanceHeader extends ConsumerStatefulWidget {
  const HomeBalanceHeader({super.key});

  @override
  ConsumerState<HomeBalanceHeader> createState() => _HomeBalanceHeaderState();
}

class _HomeBalanceHeaderState extends ConsumerState<HomeBalanceHeader> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final summary = ref.watch(summaryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Còn lại tháng này',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: _visible ? 'Ẩn số dư' : 'Hiện số dư',
                child: GestureDetector(
                  key: const ValueKey('home_balance_eye'),
                  onTap: () => setState(() => _visible = !_visible),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _visible ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedMoneyText(
            value: summary.balance,
            formatter: (value) => formatVND(value.round()),
            privacyMask: _visible ? null : _kMask,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Component(
                label: 'Thu',
                value: summary.income,
                color: theme.spendo.income,
                visible: _visible,
              ),
              const SizedBox(width: 18),
              _Component(
                label: 'Chi',
                value: summary.expense,
                color: theme.spendo.expense,
                visible: _visible,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Component extends StatelessWidget {
  const _Component({
    required this.label,
    required this.value,
    required this.color,
    required this.visible,
  });

  final String label;
  final int value;
  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: AnimatedMoneyText(
              value: value,
              formatter: (v) => formatVND(v.round()),
              privacyMask: visible ? null : _kMask,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
