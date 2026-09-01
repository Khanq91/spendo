import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spendo/app.dart';
import 'package:spendo/core/config.dart';
import 'package:spendo/core/db/powersync_db.dart';
import 'package:spendo/core/router/app_router.dart';
import 'package:spendo/features/loan/presentation/widgets/loan_form_sheet.dart';
import 'package:spendo/features/reminders/presentation/widgets/reminder_form_sheet.dart';
import 'package:spendo/features/wallets/presentation/widgets/wallet_form_sheet.dart';

class ScreenshotStep {
  final String id;
  final String title;
  final String description;
  final Future<void> Function(WidgetTester tester) action;

  const ScreenshotStep({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
  });
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const screenshotDir = String.fromEnvironment(
    'SCREENSHOT_DIR',
    defaultValue: 'screenshots',
  );
  const seedData = bool.fromEnvironment(
    'SCREENSHOT_SEED_DATA',
    defaultValue: true,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'shown_retention_policy_notice': true,
    });

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    await openDatabase(databaseName: 'spendo_screenshot.db');
    if (seedData) {
      await _seedScreenshotData();
    }
  });

  group('Spendo screenshots', () {
    testWidgets('capture main screens', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SpendoApp()));
      await _settle(tester);

      try {
        await binding.convertFlutterSurfaceToImage();
      } catch (_) {
        // Some desktop/web targets do not need this Android-only conversion.
      }

      final dir = await _screenshotOutputDir(screenshotDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final meta = <Map<String, String>>[];

      for (final step in _steps) {
        debugPrint('Capturing ${step.id}: ${step.title}');
        await step.action(tester);
        await _settle(tester);

        final bytes = await binding.takeScreenshot(step.id);
        await File(p.join(dir.path, '${step.id}.png')).writeAsBytes(bytes);

        meta.add({
          'id': step.id,
          'title': step.title,
          'description': step.description,
          'file': '${step.id}.png',
        });
      }

      await File(
        p.join(dir.path, 'meta.json'),
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(meta));
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['screenshotMeta'] = meta;
    });
  });
}

Future<Directory> _screenshotOutputDir(String screenshotDir) async {
  if (Platform.isAndroid && !p.isAbsolute(screenshotDir)) {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return Directory(p.join(externalDir.path, screenshotDir));
    }
  }

  return Directory(screenshotDir);
}

final List<ScreenshotStep> _steps = [
  ScreenshotStep(
    id: '01_home',
    title: 'Tong quan',
    description:
        'Man hinh chinh cua Spendo voi tong thu, tong chi, vi va loi tat tinh nang.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _tapKey(tester, const ValueKey('spendo_tab_0'));
    },
  ),
  ScreenshotStep(
    id: '02_all_features',
    title: 'Tat ca tinh nang',
    description:
        'Danh sach day du cac tinh nang tai chinh, vay no, theo doi va cai dat.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/features');
    },
  ),
  ScreenshotStep(
    id: '03_transactions',
    title: 'Giao dich',
    description:
        'Danh sach giao dich theo thang, co loc danh muc va tong thu chi nhanh.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/transactions');
    },
  ),
  ScreenshotStep(
    id: '04_add_transaction',
    title: 'Them giao dich',
    description:
        'Bottom sheet them giao dich voi so tien, danh muc, ghi chu va nguon tien.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/add?amount=125000&note=Ca%20phe%20gap%20khach');
    },
  ),
  ScreenshotStep(
    id: '05_stats',
    title: 'Thong ke',
    description:
        'Bieu do va thong ke chi tieu theo danh muc trong khoang thoi gian dang chon.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/stats');
    },
  ),
  ScreenshotStep(
    id: '06_wallets',
    title: 'Nguon tien',
    description:
        'Danh sach vi va tai khoan ngan hang cung tong so du hien tai.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/wallets');
    },
  ),
  ScreenshotStep(
    id: '07_wallet_detail',
    title: 'Chi tiet nguon tien',
    description:
        'Chi tiet so du, muc su dung va lich su giao dich theo nguon tien.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/wallets/screenshot_cash');
    },
  ),
  ScreenshotStep(
    id: '08_wallet_form',
    title: 'Them nguon tien',
    description:
        'Bottom sheet tao vi hoac tai khoan moi voi loai, so du va mau hien thi.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/wallets');
      await _showSheet(tester, const WalletFormSheet());
    },
  ),
  ScreenshotStep(
    id: '09_budget',
    title: 'Han muc',
    description:
        'Trang han muc: tien do tong thang va han muc tung danh muc chi tieu.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/budget');
    },
  ),
  ScreenshotStep(
    id: '11_loans',
    title: 'Khoan vay',
    description:
        'Danh sach cac khoan dang vay va cho vay, gom trang thai sap den han.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/loans');
    },
  ),
  ScreenshotStep(
    id: '12_loans_borrowed',
    title: 'Dang vay',
    description: 'Bo loc rieng cac khoan tien ban dang vay.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/loans?type=borrowed');
    },
  ),
  ScreenshotStep(
    id: '13_loans_lent',
    title: 'Cho vay',
    description: 'Bo loc rieng cac khoan tien ban da cho nguoi khac vay.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/loans?type=lent');
    },
  ),
  ScreenshotStep(
    id: '14_loan_detail',
    title: 'Chi tiet khoan vay',
    description:
        'Chi tiet mot khoan vay voi so tien goc, tien da thanh toan va lich su.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/loans');
      await _tapText(tester, 'Vay mua xe');
    },
  ),
  ScreenshotStep(
    id: '15_loan_form',
    title: 'Them khoan vay',
    description:
        'Bottom sheet tao khoan vay hoac cho vay voi nguoi lien quan va han tra.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/loans');
      await _showSheet(tester, const LoanFormSheet());
    },
  ),
  ScreenshotStep(
    id: '16_reminders',
    title: 'Nhac nho dinh ky',
    description: 'Danh sach nhac nho chi tieu dinh ky va goi y theo thoi quen.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/reminders');
    },
  ),
  ScreenshotStep(
    id: '17_reminder_form',
    title: 'Them nhac nho',
    description:
        'Bottom sheet tao nhac nho voi danh muc, tan suat, gio va so tien goi y.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/reminders');
      await _showSheet(tester, const ReminderFormSheet());
    },
  ),
  ScreenshotStep(
    id: '18_settings',
    title: 'Cai dat',
    description:
        'Cai dat backup, giao dien, thong bao, danh muc va cac tich hop cua ung dung.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/settings');
    },
  ),
  ScreenshotStep(
    id: '19_settings_integrations',
    title: 'Tich hop va backup',
    description:
        'Phan cai dat ve Google Drive, SePay, widget va cac tien ich du lieu.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _go('/settings');
      await _scrollPrimary(tester, const Offset(0, -650));
    },
  ),
  ScreenshotStep(
    id: '20_home_after_flows',
    title: 'Tong quan sau khi seed',
    description:
        'Man hinh tong quan voi du lieu demo day du hon cho cac tinh nang trong app.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _tapKey(tester, const ValueKey('spendo_tab_0'));
    },
  ),
];

Future<void> _go(String location) async {
  appRouter.go(location);
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _showSheet(WidgetTester tester, Widget child) async {
  final context = tester.element(find.byType(Scaffold).last);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => child,
  );
}

Future<void> _scrollPrimary(WidgetTester tester, Offset offset) async {
  final scrollable = find.byType(Scrollable).last;
  await tester.drag(scrollable, offset);
  await _settle(tester);
}

Future<void> _closeModalIfAny(WidgetTester tester) async {
  final bottomSheet = find.byType(BottomSheet);
  if (bottomSheet.evaluate().isNotEmpty) {
    final context = tester.element(bottomSheet.first);
    await Navigator.of(context).maybePop();
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _seedScreenshotData() async {
  await db.execute('DELETE FROM detected_habits');
  await db.execute('DELETE FROM recurring_reminders');
  await db.execute('DELETE FROM category_budgets');
  await db.execute('DELETE FROM budgets');
  await db.execute('DELETE FROM transactions');
  await db.execute('DELETE FROM wallets');
  await db.execute('DELETE FROM loan_payments');
  await db.execute('DELETE FROM loans');

  await db.execute(
    '''INSERT INTO wallets(id, name, type, initial_balance, note, color_hex, sort_order, is_archived)
       VALUES(?, ?, ?, ?, ?, ?, ?, 0)''',
    [
      'screenshot_cash',
      'Tien mat',
      'cash',
      '2500000',
      'Du lieu demo screenshot',
      '#16A34A',
      0,
    ],
  );
  await db.execute(
    '''INSERT INTO wallets(id, name, type, initial_balance, note, color_hex, sort_order, is_archived)
       VALUES(?, ?, ?, ?, ?, ?, ?, 0)''',
    [
      'screenshot_bank',
      'Ngan hang',
      'bank',
      '12000000',
      'Du lieu demo screenshot',
      '#2563EB',
      1,
    ],
  );
  await db.execute(
    '''INSERT INTO wallets(id, name, type, initial_balance, note, color_hex, sort_order, is_archived)
       VALUES(?, ?, ?, ?, ?, ?, ?, 0)''',
    [
      'screenshot_card',
      'The tin dung',
      'card',
      '5000000',
      'Han muc chi tieu demo',
      '#DC2626',
      2,
    ],
  );

  final expenseCat =
      await _categoryIdByIcon('restaurant', isIncome: false) ??
      await _firstCategoryId(isIncome: false);
  final travelCat =
      await _categoryIdByIcon('directions_car', isIncome: false) ?? expenseCat;
  final shoppingCat =
      await _categoryIdByIcon('shopping_cart', isIncome: false) ?? expenseCat;
  final incomeCat =
      await _categoryIdByIcon('work', isIncome: true) ??
      await _firstCategoryId(isIncome: true);

  final now = DateTime.now();
  await _insertTx(
    id: 'screenshot_tx_income',
    amount: 18000000,
    type: 'income',
    categoryId: incomeCat,
    note: 'Luong thang nay',
    createdAt: DateTime(now.year, now.month, 2, 9),
    walletId: 'screenshot_bank',
  );
  await _insertTx(
    id: 'screenshot_tx_food',
    amount: 85000,
    type: 'expense',
    categoryId: expenseCat,
    note: 'An trua',
    createdAt: DateTime(now.year, now.month, now.day, 12),
    walletId: 'screenshot_cash',
  );
  await _insertTx(
    id: 'screenshot_tx_transport',
    amount: 45000,
    type: 'expense',
    categoryId: travelCat,
    note: 'Di chuyen',
    createdAt: DateTime(now.year, now.month, now.day - 1, 18),
    walletId: 'screenshot_cash',
  );
  await _insertTx(
    id: 'screenshot_tx_shopping',
    amount: 1250000,
    type: 'expense',
    categoryId: shoppingCat,
    note: 'Mua do gia dung',
    createdAt: DateTime(now.year, now.month, now.day - 3, 20),
    walletId: 'screenshot_card',
  );

  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  await db.execute('INSERT INTO budgets(id, amount, month) VALUES(?, ?, ?)', [
    'screenshot_budget_month',
    '12000000',
    monthKey,
  ]);
  await db.execute(
    'INSERT INTO category_budgets(id, category_id, amount) VALUES(?, ?, ?)',
    ['screenshot_budget_food', expenseCat, '3000000'],
  );
  await db.execute(
    'INSERT INTO category_budgets(id, category_id, amount) VALUES(?, ?, ?)',
    ['screenshot_budget_shopping', shoppingCat, '1000000'],
  );

  await _insertLoan(
    id: 'screenshot_loan_borrowed',
    title: 'Vay mua xe',
    type: 'borrowed',
    principal: 45000000,
    contactName: 'Anh Minh',
    startDate: now.subtract(const Duration(days: 20)),
    dueDate: now.add(const Duration(days: 6)),
    note: 'Tra gop trong 3 dot',
    colorHex: '#DC2626',
    isClosed: false,
  );
  await _insertLoan(
    id: 'screenshot_loan_lent',
    title: 'Cho Lan vay',
    type: 'lent',
    principal: 8000000,
    contactName: 'Lan',
    startDate: now.subtract(const Duration(days: 12)),
    dueDate: now.add(const Duration(days: 18)),
    note: 'Ho tro dong hoc phi',
    colorHex: '#0891B2',
    isClosed: false,
  );
  await db.execute(
    '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note)
       VALUES(?, ?, ?, ?, ?)''',
    [
      'screenshot_loan_payment_1',
      'screenshot_loan_borrowed',
      '12000000',
      now.subtract(const Duration(days: 5)).toIso8601String(),
      'Dot 1',
    ],
  );

  await db.execute(
    '''INSERT INTO recurring_reminders(
        id, title, category_id, amount_hint, frequency,
        day_of_week, day_of_month, hour, minute, is_active, next_trigger,
        warn_before_hours
      ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      'screenshot_reminder_rent',
      'Tien nha',
      expenseCat,
      '3500000',
      'monthly',
      null,
      5,
      8,
      30,
      1,
      DateTime(now.year, now.month + 1, 5, 8, 30).toIso8601String(),
      24,
    ],
  );
  await db.execute(
    '''INSERT INTO detected_habits(
        id, keyword, category_id, median_gap_days, last_occurrence,
        occurrence_count, is_dismissed, analyzed_at
      ) VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      'screenshot_habit_coffee',
      'ca phe',
      expenseCat,
      7,
      now.subtract(const Duration(days: 7)).toIso8601String(),
      5,
      0,
      now.toIso8601String(),
    ],
  );
}

Future<String?> _categoryIdByIcon(
  String iconName, {
  required bool isIncome,
}) async {
  final row = await db.getOptional(
    'SELECT id FROM categories WHERE icon_name = ? AND is_income = ? LIMIT 1',
    [iconName, isIncome ? 1 : 0],
  );
  return row?['id'] as String?;
}

Future<String> _firstCategoryId({required bool isIncome}) async {
  final row = await db.get(
    'SELECT id FROM categories WHERE is_income = ? ORDER BY sort_order ASC LIMIT 1',
    [isIncome ? 1 : 0],
  );
  return row['id'] as String;
}

Future<void> _insertTx({
  required String id,
  required int amount,
  required String type,
  required String categoryId,
  required String note,
  required DateTime createdAt,
  required String walletId,
}) async {
  await db.execute(
    '''INSERT INTO transactions(id, amount, type, category_id, note, created_at, wallet_id, source)
       VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      id,
      amount.toString(),
      type,
      categoryId,
      note,
      createdAt.millisecondsSinceEpoch.toString(),
      walletId,
      'screenshot',
    ],
  );
}

Future<void> _insertLoan({
  required String id,
  required String title,
  required String type,
  required int principal,
  required String contactName,
  required DateTime startDate,
  required DateTime dueDate,
  required String note,
  required String colorHex,
  required bool isClosed,
}) async {
  await db.execute(
    '''INSERT INTO loans(id, title, type, principal, contact_name,
         start_date, due_date, note, color_hex, is_closed)
       VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      id,
      title,
      type,
      principal.toString(),
      contactName,
      startDate.toIso8601String(),
      dueDate.toIso8601String(),
      note,
      colorHex,
      isClosed ? 1 : 0,
    ],
  );
}
