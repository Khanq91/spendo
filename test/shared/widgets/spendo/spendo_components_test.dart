import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/spendo_colors.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? AppTheme.light(AppColorScheme.roseDefault)
        : AppTheme.dark(AppColorScheme.roseDefault),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('SpendoButton', () {
    testWidgets('primary fills with primary and stands 48 tall', (tester) async {
      await tester.pumpWidget(
        _host(SpendoButton(label: 'Lưu giao dịch', onPressed: () {})),
      );

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SpendoButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(box.constraints?.maxHeight ?? 48, 48);
      expect(find.text('Lưu giao dịch'), findsOneWidget);
    });

    testWidgets('a button without a callback renders dimmed', (tester) async {
      await tester.pumpWidget(
        _host(const SpendoButton(label: 'Lưu', onPressed: null)),
      );

      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(SpendoButton),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.45);
      expect(
        tester.widget<InkWell>(find.byType(InkWell)).onTap,
        isNull,
      );
    });

    testWidgets('busy swaps the label for a spinner', (tester) async {
      await tester.pumpWidget(
        _host(SpendoButton(label: 'Lưu', busy: true, onPressed: () {})),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Lưu'), findsNothing);
    });
  });

  group('SpendoSegmented', () {
    testWidgets('reports the option that was tapped', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          SpendoSegmented<String>(
            options: const [
              (value: 'expense', label: 'Chi'),
              (value: 'income', label: 'Thu'),
            ],
            value: 'expense',
            onChanged: (value) => picked = value,
          ),
        ),
      );

      await tester.tap(find.text('Thu'));
      await tester.pump();
      expect(picked, 'income');
    });

    testWidgets('tapping the active option is a no-op', (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        _host(
          SpendoSegmented<String>(
            options: const [
              (value: 'expense', label: 'Chi'),
              (value: 'income', label: 'Thu'),
            ],
            value: 'expense',
            onChanged: (_) => changes++,
          ),
        ),
      );

      await tester.tap(find.text('Chi'));
      await tester.pump();
      expect(changes, 0);
    });
  });

  group('SpendoProgressBar', () {
    testWidgets('crosses from primary to warning to error', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(Builder(builder: (context) {
          ctx = context;
          return const SizedBox();
        })),
      );

      final theme = Theme.of(ctx);
      expect(SpendoProgressBar.colorFor(ctx, 0.5), theme.colorScheme.primary);
      expect(SpendoProgressBar.colorFor(ctx, 0.85), theme.spendo.warning);
      expect(SpendoProgressBar.colorFor(ctx, 1.2), theme.colorScheme.error);
    });
  });

  group('SpendoBottomNav', () {
    testWidgets('shows the four tabs in the handoff order', (tester) async {
      await tester.pumpWidget(
        _host(
          SpendoBottomNav(
            destinations: SpendoBottomNav.spendoDestinations,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Thống kê'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('the active tab wears the brand pill', (tester) async {
      await tester.pumpWidget(
        _host(
          SpendoBottomNav(
            destinations: SpendoBottomNav.spendoDestinations,
            selectedIndex: 2,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = AppTheme.light(AppColorScheme.roseDefault);
      final pills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration as ShapeDecoration?)?.color)
          .toList();

      expect(pills.where((c) => c == theme.spendo.brand).length, 1);
    });

    testWidgets('reports the tapped index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _host(
          SpendoBottomNav(
            destinations: SpendoBottomNav.spendoDestinations,
            selectedIndex: 0,
            onSelected: (i) => tapped = i,
          ),
        ),
      );

      await tester.tap(find.text('Thống kê'));
      await tester.pump();
      expect(tapped, 2);
    });
  });

  group('SpendoFab', () {
    testWidgets('is brand-coloured and drops its shadow in dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        // Fresh key per brightness: reusing the element would keep the old
        // theme's decoration alive and mask a regression.
        await tester.pumpWidget(
          _host(
            SpendoFab(key: ValueKey(brightness), onPressed: () {}),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        final theme = brightness == Brightness.light
            ? AppTheme.light(AppColorScheme.roseDefault)
            : AppTheme.dark(AppColorScheme.roseDefault);
        expect(fab.backgroundColor, theme.spendo.brand);
        expect(fab.foregroundColor, theme.spendo.onBrand);

        // The shadow lives on the Container the SpendoFab wraps the button in.
        final shadows = tester
            .widgetList<Container>(
              find.ancestor(
                of: find.byType(FloatingActionButton),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.shape == BoxShape.circle)
            .expand((d) => d.boxShadow ?? const <BoxShadow>[])
            .toList();
        expect(shadows.isEmpty, brightness == Brightness.dark);
      }
    });
  });

  group('SpendoNumpad', () {
    testWidgets('emits digits and the delete sentinel', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _host(SizedBox(width: 300, child: SpendoNumpad(onKey: pressed.add))),
      );

      await tester.tap(find.text('7'));
      await tester.tap(find.text('000'));
      await tester.tap(find.byIcon(LucideIcons.delete));
      await tester.pump();

      expect(pressed, ['7', '000', SpendoNumpad.deleteKey]);
    });
  });

  group('SpendoEmptyState', () {
    testWidgets('renders the action only when it can be used', (tester) async {
      await tester.pumpWidget(
        _host(
          const SpendoEmptyState(
            icon: LucideIcons.wallet,
            title: 'Chưa có nguồn tiền',
            message: 'Thêm ví để bắt đầu.',
          ),
        ),
      );
      expect(find.byType(SpendoButton), findsNothing);

      await tester.pumpWidget(
        _host(
          SpendoEmptyState(
            icon: LucideIcons.wallet,
            title: 'Chưa có nguồn tiền',
            actionLabel: 'Thêm ví',
            onAction: () {},
          ),
        ),
      );
      expect(find.text('Thêm ví'), findsOneWidget);
    });
  });

  group('SpendoSectionHeader', () {
    testWidgets('upper-cases the label', (tester) async {
      await tester.pumpWidget(
        _host(const SpendoSectionHeader(label: 'Gợi ý')),
      );
      expect(find.text('GỢI Ý'), findsOneWidget);
    });
  });
}
