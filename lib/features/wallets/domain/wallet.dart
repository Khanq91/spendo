import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum WalletType {
  cash,
  bank,
  ewallet,
  credit,
  investment,
  other;

  String get label => switch (this) {
        WalletType.cash => 'Tiền mặt',
        WalletType.bank => 'Ngân hàng',
        WalletType.ewallet => 'Ví điện tử',
        WalletType.credit => 'Thẻ tín dụng',
        WalletType.investment => 'Đầu tư',
        WalletType.other => 'Khác',
      };

  String get iconName => switch (this) {
        WalletType.cash => 'wallet',
        WalletType.bank => 'landmark',
        WalletType.ewallet => 'smartphone',
        WalletType.credit => 'credit_card',
        WalletType.investment => 'trending_up',
        WalletType.other => 'more_horiz',
      };
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final int initialBalance;
  final String? note;
  final String colorHex;
  final int sortOrder;
  final bool isArchived;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.note,
    required this.colorHex,
    required this.sortOrder,
    required this.isArchived,
  });

  Color get color => AppColors.fromHex(colorHex);

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: WalletType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => WalletType.other,
      ),
      initialBalance: int.tryParse(map['initial_balance'] as String? ?? '0') ?? 0,
      note: map['note'] as String?,
      colorHex: map['color_hex'] as String,
      sortOrder: map['sort_order'] as int,
      isArchived: (map['is_archived'] as int) == 1,
    );
  }

  Wallet copyWith({
    String? name,
    WalletType? type,
    int? initialBalance,
    String? note,
    String? colorHex,
    int? sortOrder,
    bool? isArchived,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
