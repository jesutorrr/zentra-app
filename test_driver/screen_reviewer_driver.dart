import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputPath = Platform.environment['SCREEN_REVIEW_OUTPUT_DIR'] ??
      'build/screen-review/current';
  final outputDirectory = Directory(outputPath).absolute;
  outputDirectory.createSync(recursive: true);

  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (
      screenshotName,
      screenshotBytes, [
      arguments,
    ]) async {
      final screenshot = File(
        '${outputDirectory.path}${Platform.pathSeparator}$screenshotName.png',
      );
      if (screenshot.existsSync()) {
        throw StateError(
          'La captura "$screenshotName" ya existe en esta corrida.',
        );
      }
      screenshot.writeAsBytesSync(screenshotBytes);
      return screenshotBytes.isNotEmpty;
    },
  );
}
