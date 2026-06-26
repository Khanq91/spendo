import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final screenshotDir =
      Platform.environment['SCREENSHOT_DIR'] ??
      const String.fromEnvironment(
        'SCREENSHOT_DIR',
        defaultValue: 'screenshots',
      );
  final dir = Directory(screenshotDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File(p.join(dir.path, '$name.png')).writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final meta = data?['screenshotMeta'];
      if (meta != null) {
        await File(
          p.join(dir.path, 'meta.json'),
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(meta));
      }
    },
  );
}
