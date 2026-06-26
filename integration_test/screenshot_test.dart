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
    id: '02_transactions',
    title: 'Giao dich',
    description:
        'Danh sach giao dich theo thang, co loc danh muc va tong thu chi nhanh.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _tapKey(tester, const ValueKey('spendo_tab_1'));
    },
  ),
  ScreenshotStep(
    id: '03_stats',
    title: 'Thong ke',
    description:
        'Bieu do va thong ke chi tieu theo danh muc trong khoang thoi gian dang chon.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _tapKey(tester, const ValueKey('spendo_tab_2'));
    },
  ),
  ScreenshotStep(
    id: '04_add_transaction',
    title: 'Them giao dich',
    description:
        'Bottom sheet them giao dich voi so tien, danh muc, ghi chu va nguon tien.',
    action: (tester) async {
      await _tapKey(tester, const ValueKey('spendo_tab_0'));
      await _tapKey(tester, const ValueKey('spendo_fab_add_transaction'));
    },
  ),
  ScreenshotStep(
    id: '05_settings',
    title: 'Cai dat',
    description:
        'Cai dat backup, giao dien, thong bao, danh muc va cac tich hop cua ung dung.',
    action: (tester) async {
      await _closeModalIfAny(tester);
      await _tapKey(tester, const ValueKey('spendo_tab_3'));
    },
  ),
];

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
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
  await db.execute('DELETE FROM transactions');
  await db.execute('DELETE FROM wallets');
  await db.execute('DELETE FROM loans');
  await db.execute('DELETE FROM loan_payments');

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

  final expenseCat =
      await _categoryIdByIcon('restaurant', isIncome: false) ??
      await _firstCategoryId(isIncome: false);
  final travelCat =
      await _categoryIdByIcon('directions_car', isIncome: false) ?? expenseCat;
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
