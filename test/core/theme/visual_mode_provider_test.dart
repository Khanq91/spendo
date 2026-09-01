import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/visual_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a choice made before the initial read survives it', () async {
    // Stored value differs from the one the user is about to pick, so a
    // clobber is visible.
    SharedPreferences.setMockInitialValues({
      appVisualModePrefsKey: AppVisualMode.normal.name,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Chosen in the same turn the notifier is created — before the async read
    // of preferences has had a chance to resolve.
    await container.read(visualModeProvider.notifier).setMode(
      AppVisualMode.fancy,
    );
    // Let the pending load land.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(visualModeProvider), AppVisualMode.fancy);
  });

  test('with no choice made it takes the stored value', () async {
    SharedPreferences.setMockInitialValues({
      appVisualModePrefsKey: AppVisualMode.fancy.name,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(visualModeProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(visualModeProvider), AppVisualMode.fancy);
  });

  test('an unset preference falls back to normal', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(visualModeProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(visualModeProvider), AppVisualMode.normal);
  });
}
