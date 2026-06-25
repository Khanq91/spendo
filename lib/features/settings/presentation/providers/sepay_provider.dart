// lib/features/settings/presentation/providers/sepay_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/sepay_bank_account.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final sepayAccountsProvider =
    AsyncNotifierProvider<SepayAccountsNotifier, List<SepayBankAccount>>(
  SepayAccountsNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class SepayAccountsNotifier extends AsyncNotifier<List<SepayBankAccount>> {
  @override
  Future<List<SepayBankAccount>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('sepay_bank_accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => SepayBankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Bật/tắt auto-import cho 1 tài khoản
  Future<void> toggleActive(String id, bool isActive) async {
    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .update({'is_active': isActive})
        .eq('id', id);
    ref.invalidateSelf();
  }

  /// Thêm mapping tài khoản ngân hàng ↔ wallet
  Future<void> addMapping({
    required String accountNumber,
    required String bankShortName,
    required String walletId,
    String? label,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Chưa đăng nhập');

    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .upsert({
          'user_id': userId,
          'account_number': accountNumber,
          'bank_short_name': bankShortName,
          'wallet_id': walletId,
          'label': label,
          'is_active': true,
        },
        onConflict: 'user_id, account_number');

    ref.invalidateSelf();
  }

  /// Xoá mapping
  Future<void> removeMapping(String id) async {
    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .delete()
        .eq('id', id);
    ref.invalidateSelf();
  }
}
