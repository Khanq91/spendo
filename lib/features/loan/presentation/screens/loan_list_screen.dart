import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/loan_form_sheet.dart';
import 'loan_detail_screen.dart';

class LoanListScreen extends ConsumerWidget {
  /// null = all, 'borrowed' = chỉ đang vay, 'lent' = chỉ cho vay
  final String? filterType;

  const LoanListScreen({super.key, this.filterType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);
    final cs = Theme.of(context).colorScheme;

    // Title theo filter
    final title = switch (filterType) {
      'borrowed' => 'Đang vay',
      'lent' => 'Cho vay',
      _ => 'Khoản vay',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (allLoans) {
          // Apply filter
          final loans = _applyFilter(allLoans);

          if (loans.isEmpty) {
            return _EmptyState(
              filterType: filterType,
              onAdd: () => _openForm(context),
            );
          }

          final active = loans.where((l) => !l.isClosed).toList();
          final closed = loans.where((l) => l.isClosed).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(label: 'Đang hoạt động (${active.length})'),
                ...active.map((l) => _LoanTile(loan: l)),
              ],
              if (closed.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Đã tất toán (${closed.length})',
                  muted: true,
                ),
                ...closed.map((l) => _LoanTile(loan: l)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'loan_fab',
        onPressed: () => _openForm(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  List<Loan> _applyFilter(List<Loan> loans) {
    if (filterType == 'borrowed') {
      return loans.where((l) => l.type == LoanType.borrowed).toList();
    }
    if (filterType == 'lent') {
      return loans.where((l) => l.type == LoanType.lent).toList();
    }
    return loans;
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoanFormSheet(
        // Pre-select type nếu đang trong filter view
        initialType: filterType == 'borrowed'
            ? LoanType.borrowed
            : filterType == 'lent'
                ? LoanType.lent
                : null,
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool muted;

  const _SectionHeader({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: muted ? cs.outlineVariant : cs.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Loan tile ─────────────────────────────────────────────────────────────────

class _LoanTile extends ConsumerWidget {
  final Loan loan;
  const _LoanTile({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color = loan.isClosed ? cs.outlineVariant : loan.color;
    final status = loan.status;

    Color? statusColor;
    String? statusLabel;
    if (status == LoanStatus.overdue) {
      statusColor = Colors.red;
      statusLabel = 'Quá hạn';
    } else if (status == LoanStatus.upcoming) {
      statusColor = Colors.orange;
      final daysLeft = loan.dueDate!.difference(DateTime.now()).inDays;
      statusLabel = 'Còn $daysLeft ngày';
    }

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          loan.type == LoanType.borrowed
              ? LucideIcons.arrowDownLeft
              : LucideIcons.arrowUpRight,
          size: 18,
          color: color,
        ),
      ),
      title: Text(
        loan.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: loan.isClosed ? cs.onSurfaceVariant : cs.onSurface,
        ),
      ),
      subtitle: Text(
        loan.contactName.isNotEmpty ? loan.contactName : loan.type.label,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatVND(loan.principal),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: loan.isClosed
                  ? cs.outlineVariant
                  : (loan.type == LoanType.borrowed
                      ? Colors.red.shade400
                      : Colors.green.shade500),
            ),
          ),
          if (statusLabel != null)
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (loan.isClosed)
            Text(
              'Đã tất toán',
              style: TextStyle(fontSize: 11, color: cs.outlineVariant),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? filterType;
  final VoidCallback onAdd;

  const _EmptyState({required this.filterType, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final message = switch (filterType) {
      'borrowed' => 'Chưa có khoản vay nào',
      'lent' => 'Chưa có khoản cho vay nào',
      _ => 'Chưa có khoản vay nào',
    };

    final subMessage = switch (filterType) {
      'borrowed' => 'Ghi lại khoản bạn đang vay',
      'lent' => 'Ghi lại khoản bạn đã cho vay',
      _ => 'Ghi lại khoản vay để theo dõi',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.handCoins, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            subMessage,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm khoản vay'),
          ),
        ],
      ),
    );
  }
}