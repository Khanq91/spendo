import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../transactions/presentation/widgets/numpad.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WalletFormSheet extends ConsumerStatefulWidget {
  final Wallet? existing;

  const WalletFormSheet({super.key, this.existing});

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late final AmountInputController _balanceCtrl;

  late WalletType _type;
  late String _colorHex;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = AmountInputController();

    if (_isEdit) {
      final w = widget.existing!;
      _nameCtrl.text = w.name;
      _noteCtrl.text = w.note ?? '';
      _type = w.type;
      _colorHex = w.colorHex;
      if (w.initialBalance > 0) {
        _balanceCtrl.prefill(w.initialBalance.toString());
      }
    } else {
      _type = WalletType.cash;
      _colorHex = AppColors.palette[4]; // xanh lá mặc định
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = WalletRepository();
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          name: name,
          type: _type,
          initialBalance: _balanceCtrl.hasValue ? _balanceCtrl.value : 0,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          colorHex: _colorHex,
        );
        await repo.update(updated);
      } else {
        final w = Wallet(
          id: '',
          name: name,
          type: _type,
          initialBalance: _balanceCtrl.hasValue ? _balanceCtrl.value : 0,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          colorHex: _colorHex,
          sortOrder: 0,
          isArchived: false,
        );
        await repo.add(w);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showColorPickerPopup() {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím ảo nếu đang mở

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text(
            'Chọn màu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Hiển thị dưới dạng table 5 cột
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: AppColors.palette.length,
              itemBuilder: (context, index) {
                final hex = AppColors.palette[index];
                final color = AppColors.fromHex(hex);
                final selected = hex == _colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _colorHex = hex);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.rectangle,
                      border:
                          selected
                              ? Border.all(color: cs.onSurface, width: 2)
                              : null,
                      boxShadow:
                          selected
                              ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                              : null,
                    ),
                    child:
                        selected
                            ? const Icon(
                              LucideIcons.check,
                              size: 18,
                              color: Colors.white,
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = AppColors.fromHex(_colorHex);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12 + MediaQuery.of(context).padding.top,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Expanded(
                  child: Text(
                    _isEdit ? 'Chỉnh sửa nguồn tiền' : 'Thêm nguồn tiền',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 24), // Để cân bằng với icon Hủy bên trái
              ],
            ),
            const SizedBox(height: 16),

            // Tên
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên (vd: MB Bank, Tiền mặt...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Loại
            Text(
              'Loại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  WalletType.values.map((t) {
                    final selected = t == _type;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? accentColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? accentColor : cs.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoryIcon(t.iconName),
                              size: 13,
                              color:
                                  selected ? accentColor : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    selected
                                        ? accentColor
                                        : cs.onSurfaceVariant,
                                fontWeight:
                                    selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),

            // Màu
            Row(
              children: [
                Text(
                  'Màu sắc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showColorPickerPopup,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chọn màu',
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ghi chú
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Số dư ban đầu
            Text(
              'Số dư ban đầu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            // Info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Số dư thực tế sẽ được tính tự động từ các giao dịch ghi vào ví này.',
                      style: TextStyle(fontSize: 11, color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Amount display
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: _balanceCtrl,
                  builder:
                      (_, __) => Text(
                        _balanceCtrl.formatted,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          letterSpacing: -1,
                        ),
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₫',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 12, thickness: 0.5),

            ListenableBuilder(
              listenable: _balanceCtrl,
              builder: (_, __) => Numpad(onKey: _balanceCtrl.press),
            ),

            // Submit
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _isEdit ? 'Lưu thay đổi' : 'Tạo nguồn tiền',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
