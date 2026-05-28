import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/currency_formatter.dart';

const _kKey = 'amount_visible';

final amountVisibleProvider =
    StateNotifierProvider<AmountVisibilityNotifier, bool>(
      (_) => AmountVisibilityNotifier(),
    );

class AmountVisibilityNotifier extends StateNotifier<bool> {
  AmountVisibilityNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, state);
  }
}

/// Widget hiển thị số tiền, tự động ẩn/hiện theo [amountVisibleProvider].
///
/// Dùng thay thế cho `Text(formatVND(amount))` ở mọi nơi hiển thị số tiền.
class AmountText extends ConsumerWidget {
  final int amount;
  final TextStyle? style;

  /// Prefix hiển thị trước số tiền (ví dụ: '+', '-').
  final String prefix;

  /// Khi true, luôn hiện số tiền bất kể provider state.
  final bool alwaysShow;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.prefix = '',
    this.alwaysShow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = alwaysShow || ref.watch(amountVisibleProvider);
    final text = visible ? '$prefix${formatVND(amount)}' : '$prefix••••••';
    return Text(text, style: style);
  }
}

/// Toggle button nhỏ — đặt cạnh số tiền để ẩn/hiện.
class AmountVisibilityToggle extends ConsumerWidget {
  final double size;
  final Color? color;

  const AmountVisibilityToggle({super.key, this.size = 18, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(amountVisibleProvider);
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => ref.read(amountVisibleProvider.notifier).toggle(),
      child: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: size,
        color: color ?? cs.onSurfaceVariant,
      ),
    );
  }
}
