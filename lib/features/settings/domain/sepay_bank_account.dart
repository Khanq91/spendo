// lib/features/settings/domain/sepay_bank_account.dart

class SepayBankAccount {
  final String id;
  final String userId;
  final String walletId;
  final String accountNumber;
  final String bankShortName;
  final String? label;
  final bool isActive;

  const SepayBankAccount({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.accountNumber,
    required this.bankShortName,
    this.label,
    required this.isActive,
  });

  factory SepayBankAccount.fromJson(Map<String, dynamic> json) =>
      SepayBankAccount(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        walletId: json['wallet_id'] as String,
        accountNumber: json['account_number'] as String,
        bankShortName: json['bank_short_name'] as String,
        label: json['label'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  /// Display name: dùng label nếu có, ngược lại dùng bankShortName + số tài khoản rút gọn
  String get displayName {
    if (label != null && label!.isNotEmpty) return label!;
    final last4 = accountNumber.length > 4
        ? accountNumber.substring(accountNumber.length - 4)
        : accountNumber;
    return '$bankShortName ****$last4';
  }
}
