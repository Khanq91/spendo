import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/settings/domain/sepay_bank_account.dart';
import 'package:spendo/features/settings/presentation/providers/sepay_provider.dart';
import 'package:spendo/features/settings/presentation/screens/bank_screen.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

/// Serves a fixed account list without reaching Supabase.
class _FakeSepay extends SepayAccountsNotifier {
  _FakeSepay(this.accounts);

  final List<SepayBankAccount> accounts;

  @override
  Future<List<SepayBankAccount>> build() async => accounts;
}

const _account = SepayBankAccount(
  id: 'a1',
  userId: 'u1',
  accountNumber: '0123456789',
  bankShortName: 'MB',
  walletId: 'cash',
  label: 'Thẻ lương',
  isActive: true,
);

const _wallets = [
  Wallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: WalletType.cash,
    initialBalance: 0,
    colorHex: '#7A8A5E',
    sortOrder: 0,
    isArchived: false,
  ),
];

Widget _app(List<SepayBankAccount> accounts) {
  return ProviderScope(
    overrides: [
      sepayAccountsProvider.overrideWith(() => _FakeSepay(accounts)),
      walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const BankScreen(),
    ),
  );
}

void main() {
  testWidgets('with no account linked, the page explains the order of steps', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    expect(find.text('SePay'), findsOneWidget);
    expect(find.text('Mở SePay'), findsOneWidget);
    expect(find.text('Chưa liên kết tài khoản nào'), findsOneWidget);
  });

  testWidgets('a linked account shows its sync state and both controls', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_account]));
    await tester.pumpAndSettle();

    expect(find.text('TÀI KHOẢN ĐÃ LIÊN KẾT (1)'), findsOneWidget);
    expect(find.text('Thẻ lương'), findsOneWidget);
    expect(find.text('Đang đồng bộ'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('the form uses the shared sheet tokens, not its own', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm tài khoản').last);
    await tester.pumpAndSettle();

    // The old sheet had a 40px handle, outlined fields and default M3 buttons
    // (`28-sepay-add-mapping-sheet.md` §L).
    expect(find.text('Số tài khoản *'), findsOneWidget);
    expect(find.text('NGÂN HÀNG *'), findsOneWidget);
    expect(find.text('GHI VÀO VÍ *'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
  });

  testWidgets('submitting an empty form fails field by field, inline', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm tài khoản').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập số tài khoản'), findsOneWidget);
    expect(find.text('Chưa chọn ngân hàng'), findsOneWidget);
    expect(find.text('Chưa chọn ví nhận giao dịch'), findsOneWidget);
  });

  testWidgets('the page fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app([_account]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
