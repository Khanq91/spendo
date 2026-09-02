import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/spendo_colors.dart';
import 'package:spendo/shared/widgets/particle_field/particle_field.dart';
import 'package:spendo/shared/widgets/particle_theme_background.dart';

Widget _host(ThemeData theme, {bool reduceMotion = false}) => MaterialApp(
  theme: theme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Scaffold(body: ParticleThemeBackground()),
  ),
);

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light(AppColorScheme.roseDefault)),
    ('dark', AppTheme.dark(AppColorScheme.roseDefault)),
  ]) {
    testWidgets('paints the theme colours over the scaffold in $name', (
      tester,
    ) async {
      await tester.pumpWidget(_host(theme));
      await tester.pump(const Duration(milliseconds: 32));

      expect(tester.takeException(), isNull);
      final field = tester.widget<ParticleField>(find.byType(ParticleField));
      expect(field.colors, contains(theme.spendo.brand));
      expect(field.colors, contains(theme.colorScheme.primary));
      expect(field.animate, isTrue);
      // The flat colour is its own layer under the blurred field.
      final ground = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ParticleThemeBackground),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(ground.color, theme.scaffoldBackgroundColor);
      expect(find.byType(ImageFiltered), findsOneWidget);
    });
  }

  testWidgets('reduce motion stops the field', (tester) async {
    await tester.pumpWidget(
      _host(AppTheme.light(AppColorScheme.roseDefault), reduceMotion: true),
    );
    await tester.pump();

    final field = tester.widget<ParticleField>(find.byType(ParticleField));
    expect(field.animate, isFalse);
  });
}
