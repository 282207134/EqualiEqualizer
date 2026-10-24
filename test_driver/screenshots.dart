import 'dart:io';
import 'dart:convert';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    await Directory('docs/screenshots').create(recursive: true);
    await File('docs/screenshots/$name.png').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    await File('docs/test-results.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(data?['verification']));
  },
);
