// lib/features/settings/presentation/widgets/sepay_connection_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wallets/data/wallet_repository.dart';
import '../../../wallets/domain/wallet.dart';
import '../providers/sepay_provider.dart';
import '../../domain/sepay_bank_account.dart';

class SepayConnectionSection extends ConsumerWidget {
  const SepayConnectionSection({super.key});

  static const _sepayDashboardUrl = 'https://my.sepay.vn';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(sepayAccountsProvider);

    return Material(
      color: cs.surface,
      child: Column(
        children: [
          // ── Link đến SePay dashboard ─────────────────────────────────────
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.landmark, size: 18,
                  color: Color(0xFF1E88E5)),
            ),
            title: const Text('Quản lý kết nối SePay',
                style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Mở SePay để kết nối/ngắt kết nối tài khoản ngân hàng',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(LucideIcons.externalLink, size: 16,
                color: cs.onSurfaceVariant),
            onTap: () => _openSepayDashboard(context),
          ),

          // ── Danh sách accounts đã mapping ───────────────────────────────
          accountsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (accounts) => Column(
              children: [
                if (accounts.isNotEmpty)
                  const Divider(height: 1, indent: 16),
                ...accounts.map((account) => _AccountTile(
                  account: account,
                  onToggle: (isActive) => ref
                      .read(sepayAccountsProvider.notifier)
                      .toggleActive(account.id, isActive),
                  onDelete: () => _confirmDelete(context, ref, account),
                )),
              ],
            ),
          ),

          // ── Nút thêm mapping mới ─────────────────────────────────────────
          Divider(height: 1, indent: 16, color: cs.outlineVariant),
          ListTile(
            leading: Icon(LucideIcons.plus, size: 18, color: cs.primary),
            title: Text('Thêm tài khoản ngân hàng',
                style: TextStyle(fontSize: 14, color: cs.primary)),
            onTap: () => _showAddMappingSheet(context, ref),
          ),

          // ── Hướng dẫn ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Sau khi kết nối ngân hàng trên SePay, thêm tài khoản ở đây '
              'để giao dịch tự động đồng bộ vào Spendo.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSepayDashboard(BuildContext context) async {
    final uri = Uri.parse(_sepayDashboardUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được trình duyệt')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SepayBankAccount account,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá kết nối?'),
        content: Text(
          'Xoá "${account.displayName}"?\n\n'
          'Giao dịch đã nhập sẽ không bị ảnh hưởng. '
          'Chỉ dừng tự động đồng bộ từ tài khoản này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.expenseAltColor,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(sepayAccountsProvider.notifier).removeMapping(account.id);
    }
  }

  Future<void> _showAddMappingSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMappingSheet(ref: ref),
    );
  }
}

// ── Tile hiển thị 1 account ───────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final SepayBankAccount account;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _AccountTile({
    required this.account,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (account.isActive
              ? const Color(0xFF43A047)
              : cs.onSurfaceVariant)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          LucideIcons.landmark,
          size: 18,
          color: account.isActive
              ? const Color(0xFF43A047)
              : cs.onSurfaceVariant,
        ),
      ),
      title: Text(account.displayName, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        account.isActive ? 'Đang đồng bộ' : 'Tạm dừng',
        style: TextStyle(
          fontSize: 12,
          color: account.isActive
              ? const Color(0xFF43A047)
              : cs.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: account.isActive,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 16,
                color: AppTheme.expenseAltColor),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Sheet thêm mapping mới ────────────────────────────────────────────────────

class _AddMappingSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddMappingSheet({required this.ref});

  @override
  ConsumerState<_AddMappingSheet> createState() => _AddMappingSheetState();
}

class _AddMappingSheetState extends ConsumerState<_AddMappingSheet> {
  final _accountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  String? _selectedWalletId;
  List<Wallet> _wallets = [];
  bool _loading = false;

  // Danh sách ngân hàng phổ biến VN
  static const _banks = [
    'VCB', 'TCB', 'MB', 'ACB', 'VPB', 'BID', 'CTG',
    'STB', 'TPB', 'OCB', 'MSB', 'VIB', 'SHB', 'HDBank',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await WalletRepository().getAll();
    if (mounted) setState(() => _wallets = wallets);
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _bankCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Thêm tài khoản ngân hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Điền thông tin tài khoản bạn đã kết nối trên SePay',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Số tài khoản
          TextField(
            controller: _accountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số tài khoản *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(LucideIcons.creditCard, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Ngân hàng
          DropdownButtonFormField<String>(
            initialValue: _bankCtrl.text.isEmpty ? null : _bankCtrl.text,
            decoration: InputDecoration(
              labelText: 'Ngân hàng *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(LucideIcons.landmark, size: 18),
            ),
            items: _banks.map((b) => DropdownMenuItem(
              value: b,
              child: Text(b),
            )).toList(),
            onChanged: (val) {
              if (val != null) _bankCtrl.text = val;
            },
          ),
          const SizedBox(height: 12),

          // Wallet
          DropdownButtonFormField<String>(
            initialValue: _selectedWalletId,
            decoration: InputDecoration(
              labelText: 'Nguồn tiền trong Spendo *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(LucideIcons.wallet, size: 18),
            ),
            items: _wallets.map((w) => DropdownMenuItem(
              value: w.id,
              child: Text(w.name),
            )).toList(),
            onChanged: (val) => setState(() => _selectedWalletId = val),
          ),
          const SizedBox(height: 12),

          // Label (optional)
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: 'Tên hiển thị (tùy chọn)',
              hintText: 'VD: Thẻ lương, Thẻ chính',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(LucideIcons.tag, size: 18),
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Thêm kết nối'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final account = _accountCtrl.text.trim();
    final bank = _bankCtrl.text.trim();

    if (account.isEmpty || bank.isEmpty || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(sepayAccountsProvider.notifier).addMapping(
        accountNumber: account,
        bankShortName: bank,
        walletId: _selectedWalletId!,
        label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
