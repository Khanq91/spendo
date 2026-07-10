import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:spendo/core/theme/app_glass_policy.dart';

void main() {
  test('saved adaptive glass quality parses known tiers', () {
    for (final quality in GlassQuality.values) {
      expect(AppGlassPolicy.parseSavedQuality(quality.name), quality);
    }
  });

  test('missing or invalid adaptive glass quality starts fresh', () {
    expect(AppGlassPolicy.parseSavedQuality(null), isNull);
    expect(AppGlassPolicy.parseSavedQuality('ultra'), isNull);
  });
}
