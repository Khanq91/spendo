import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

const _food = Category(
  id: 'food',
  name: 'Ăn uống',
  colorHex: '#C67139',
  iconName: 'restaurant',
  isDefault: true,
  isIncome: false,
  sortOrder: 0,
);

const _wallet = Wallet(
  id: 'bank',
  name: 'MB Bank',
  type: WalletType.bank,
  initialBalance: 0,
  colorHex: '#5E7E8A',
  sortOrder: 0,
  isArchived: false,
);

Future<void> _pump(
  WidgetTester tester,
  Transaction transaction, {
  List<Wallet> wallets = const [_wallet],
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletsProvider.overrideWith((ref) => Stream.value(wallets)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: Scaffold(
          body: TransactionDetailSheet(
            transaction: transaction,
            category: _food,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Transaction _tx({
  String? note,
  String? walletId = 'bank',
  String source = 'manual',
}) {
  return Transaction(
    id: 't1',
    amount: 85000,
    type: 'expense',
    categoryId: 'food',
    note: note,
    createdAt: DateTime.now(),
    walletId: walletId,
    source: source,
  );
}

void main() {
  testWidgets('offers duplicate alongside edit and delete', (tester) async {
    await _pump(tester, _tx(note: 'Ăn trưa'));

    expect(find.text('Nhân bản'), findsOneWidget);
    expect(find.text('Chỉnh sửa'), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
  });

  testWidgets('a long note wraps instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _tx(
        note: 'Ăn trưa với team — Highlands Lê Lợi, chia hoá đơn 4 người, '
            'có thêm hai ly cà phê mang về',
      ),
    );

    // The audit flagged the old fixed-height row as overflowing here.
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Highlands Lê Lợi'), findsOneWidget);
  });

  testWidgets('the date row is editable, the other rows are not', (
    tester,
  ) async {
    await _pump(tester, _tx(note: 'Ăn trưa'));

    // Only the date row carries the edit affordance — editing the date was
    // impossible anywhere in the app before.
    final dateRow = find.byKey(const ValueKey('detail_date_row'));
    expect(dateRow, findsOneWidget);
    expect(
      find.descendant(of: dateRow, matching: find.byIcon(LucideIcons.pencil)),
      findsOneWidget,
    );

    // The other rows are read-only, so the only other pencil is on the
    // "Chỉnh sửa" button.
    expect(find.byIcon(LucideIcons.pencil), findsNWidgets(2));
  });

  testWidgets('an archived wallet is named rather than silently hidden', (
    tester,
  ) async {
    // The wallet exists on the transaction but not in the active list.
    await _pump(tester, _tx(), wallets: const []);

    expect(find.text('Nguồn tiền'), findsOneWidget);
    expect(find.text('Ví đã lưu trữ'), findsOneWidget);
  });

  testWidgets('a transaction with no wallet shows no wallet row', (
    tester,
  ) async {
    await _pump(tester, _tx(walletId: null));

    expect(find.text('Nguồn tiền'), findsNothing);
  });

  testWidgets('an imported transaction is badged', (tester) async {
    await _pump(tester, _tx(source: 'sepay'));

    expect(find.text('Tự động · SePay'), findsOneWidget);
  });
}
