import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';

class SummaryCards extends StatefulWidget {
  final int income;
  final int expense;
  final int balance;

  const SummaryCards({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  State<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends State<SummaryCards> {
  bool _balanceVisible = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Balance card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _balanceVisible ? formatVND(widget.balance) : '••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle button
              GestureDetector(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _balanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Income + expense mini cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Thu nhập',
                  amount: widget.income,
                  color: AppTheme.incomeColor,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  label: 'Chi tiêu',
                  amount: widget.expense,
                  color: AppTheme.expenseAltColor,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatefulWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _MiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  State<_MiniCard> createState() => _MiniCardState();
}

class _MiniCardState extends State<_MiniCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 14, color: widget.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  _visible ? formatVND(widget.amount) : '••••••',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Toggle button
          GestureDetector(
            onTap: () => setState(() => _visible = !_visible),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: cs.onSurfaceVariant,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
