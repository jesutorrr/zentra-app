import 'dart:convert';
import 'dart:io';

const _fullExpectedScreenshotCount = 42;
// «focus» pasó de 12 a 13: la hoja de tiempos se captura en los dos modos, que es
// la diferencia que importa desde que una sola fila abre lo que antes abrían un ⚙
// y un chip «Otro».
const _scopedExpectedScreenshotCounts = <String, int>{
  'entry': 9,
  'habits': 4,
  'onboarding': 6,
  'habit-form': 8,
  'notes': 10,
  'focus': 13,
};

Future<void> main(List<String> arguments) async {
  final requestedDevice = _readOption(arguments, '--device');
  final scope = _readOption(arguments, '--scope') ?? 'full';
  final expectedScreenshotCount = scope == 'full'
      ? _fullExpectedScreenshotCount
      : _scopedExpectedScreenshotCounts[scope];
  if (expectedScreenshotCount == null) {
    stderr.writeln(
      'Scope desconocido "$scope". Usa full o uno de: '
      '${_scopedExpectedScreenshotCounts.keys.join(', ')}.',
    );
    exitCode = 2;
    return;
  }
  final outputRoot = _readOption(arguments, '--output') ??
      'build/screen-review/${_timestamp(DateTime.now())}';
  final flutterExecutable = _flutterExecutable();
  final devices = requestedDevice == null
      ? await _bootedIosSimulators()
      : [
          _ReviewDevice(
            id: requestedDevice,
            name: await _deviceName(requestedDevice),
          ),
        ];

  if (devices.isEmpty) {
    stderr.writeln(
      'No hay simuladores iOS encendidos. Abre al menos uno y vuelve a correr '
      'el Screen Reviewer.',
    );
    exitCode = 2;
    return;
  }

  final results = <_ReviewResult>[];
  for (final device in devices) {
    final slug = _slug(device.name);
    final outputDirectory = Directory('$outputRoot/$slug').absolute;
    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }
    outputDirectory.createSync(recursive: true);

    stdout.writeln('');
    stdout.writeln('Revisando ${device.name} (${device.id})...');

    final process = await Process.start(
      flutterExecutable,
      [
        'drive',
        '--driver=test_driver/screen_reviewer_driver.dart',
        '--target=integration_test/screen_reviewer_test.dart',
        '--no-pub',
        '-d',
        device.id,
        '--dart-define=SCREEN_REVIEW_DEVICE=$slug',
        '--dart-define=SCREEN_REVIEW_SCOPE=$scope',
      ],
      environment: {
        ...Platform.environment,
        'SCREEN_REVIEW_OUTPUT_DIR': outputDirectory.path,
      },
    );
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final stdoutDone = process.stdout.transform(utf8.decoder).listen((chunk) {
      stdout.write(chunk);
      stdoutBuffer.write(chunk);
    }).asFuture<void>();
    final stderrDone = process.stderr.transform(utf8.decoder).listen((chunk) {
      stderr.write(chunk);
      stderrBuffer.write(chunk);
    }).asFuture<void>();
    final processExitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    final processOutput =
        '${stdoutBuffer.toString()}\n${stderrBuffer.toString()}';
    final hadFrameworkException = processOutput.contains(
          'EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK',
        ) ||
        processOutput.contains(
          'This test failed after it had already completed.',
        );
    // A failed build does not stop `flutter drive`: it attaches to whatever
    // build is already installed on the simulator and the flow passes against
    // stale code. Reviewing those captures approves a binary nobody compiled,
    // so a build failure has to fail the device outright.
    final hadBuildFailure = processOutput.contains(
          'Could not build the application for the simulator.',
        ) ||
        processOutput.contains('Application failed to start on attempt') ||
        processOutput.contains('Error (Xcode)');
    final screenshots = outputDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.png'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    // Each capture is named after the slug passed in through `--dart-define`,
    // so a name from another device proves the flow ran against a binary
    // compiled for a previous run.
    final staleScreenshots = screenshots
        .where(
          (file) => !file.uri.pathSegments.last.startsWith('$slug-'),
        )
        .toList();

    results.add(
      _ReviewResult(
        device: device,
        exitCode: processExitCode,
        hadFrameworkException: hadFrameworkException,
        hadBuildFailure: hadBuildFailure,
        screenshots: screenshots,
        staleScreenshots: staleScreenshots,
        expectedScreenshotCount: expectedScreenshotCount,
      ),
    );
  }

  final report = _writeReport(
    outputRoot: Directory(outputRoot).absolute,
    results: results,
    scope: scope,
    expectedScreenshotCount: expectedScreenshotCount,
  );
  stdout.writeln('');
  stdout.writeln('Reporte: ${report.path}');

  if (results.any((result) => !result.passed)) {
    exitCode = 1;
  }
}

String _flutterExecutable() {
  final explicit = Platform.environment['SCREEN_REVIEW_FLUTTER'];
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit;
  }

  const localFlutter = './flutter/bin/flutter';
  if (File(localFlutter).existsSync()) {
    return localFlutter;
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    final rootedFlutter = '$flutterRoot/bin/flutter';
    if (File(rootedFlutter).existsSync()) {
      return rootedFlutter;
    }
  }

  return 'flutter';
}

Future<List<_ReviewDevice>> _bootedIosSimulators() async {
  final result = await Process.run(
    'xcrun',
    ['simctl', 'list', 'devices', 'booted', '--json'],
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'xcrun',
      const ['simctl', 'list', 'devices', 'booted', '--json'],
      result.stderr.toString(),
      result.exitCode,
    );
  }

  final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final runtimes = decoded['devices'] as Map<String, dynamic>;
  final devices = <_ReviewDevice>[];

  for (final entry in runtimes.entries) {
    if (!entry.key.contains('iOS')) continue;
    for (final rawDevice in entry.value as List<dynamic>) {
      final device = rawDevice as Map<String, dynamic>;
      if (device['state'] != 'Booted' || device['isAvailable'] == false) {
        continue;
      }
      devices.add(
        _ReviewDevice(
          id: device['udid'] as String,
          name: device['name'] as String,
        ),
      );
    }
  }

  devices.sort((left, right) => left.name.compareTo(right.name));
  return devices;
}

Future<String> _deviceName(String id) async {
  final devices = await _bootedIosSimulators();
  for (final device in devices) {
    if (device.id == id) return device.name;
  }
  return id;
}

File _writeReport({
  required Directory outputRoot,
  required List<_ReviewResult> results,
  required String scope,
  required int expectedScreenshotCount,
}) {
  outputRoot.createSync(recursive: true);
  final report = File('${outputRoot.path}/report.md');
  final buffer = StringBuffer()
    ..writeln('# Zentra Screen Review')
    ..writeln()
    ..writeln('Generado: ${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('Scope: `$scope`')
    ..writeln()
    ..writeln(
      '> PASS confirma que el recorrido terminó sin excepciones y produjo las '
      '$expectedScreenshotCount capturas esperadas. La aprobación visual de '
      'jerarquía, espaciado, contraste y feeling se realiza revisando las '
      'imágenes de este reporte.',
    )
    ..writeln()
    ..writeln('| Dispositivo | Recorrido | Capturas |')
    ..writeln('|---|---:|---:|');

  for (final result in results) {
    buffer.writeln(
      '| ${result.device.name} | '
      '${result.passed ? 'PASS' : 'FAIL'} | '
      '${result.screenshots.length}/$expectedScreenshotCount |',
    );
  }

  for (final result in results) {
    final deviceDirectory = _slug(result.device.name);
    buffer
      ..writeln()
      ..writeln('## ${result.device.name}')
      ..writeln()
      ..writeln('Recorrido: ${result.passed ? 'PASS' : 'FAIL'}')
      ..writeln();

    if (!result.passed) {
      if (result.exitCode != 0) {
        buffer.writeln('- El flujo terminó con código ${result.exitCode}.');
      }
      if (result.hadFrameworkException) {
        buffer.writeln(
          '- Flutter reportó una excepción del framework, incluso si apareció '
          'después de terminar el recorrido.',
        );
      }
      if (result.hadBuildFailure) {
        buffer.writeln(
          '- El build para el simulador falló. El recorrido se ejecutó contra '
          'la app ya instalada, así que estas capturas no representan el '
          'código actual.',
        );
      }
      if (result.staleScreenshots.isNotEmpty) {
        buffer.writeln(
          '- ${result.staleScreenshots.length} capturas no llevan el nombre de '
          'este dispositivo, señal de que el binario venía de una corrida '
          'anterior.',
        );
      }
      if (result.screenshots.length != expectedScreenshotCount) {
        buffer.writeln(
          '- Se esperaban $expectedScreenshotCount capturas y se generaron '
          '${result.screenshots.length}.',
        );
      }
      buffer.writeln();
    }

    for (final screenshot in result.screenshots) {
      final name = screenshot.uri.pathSegments.last;
      buffer
        ..writeln('### $name')
        ..writeln()
        ..writeln('![$name]($deviceDirectory/$name)')
        ..writeln();
    }
  }

  report.writeAsStringSync(buffer.toString());
  return report;
}

String? _readOption(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index == -1) return null;
  if (index + 1 >= arguments.length) {
    throw ArgumentError('Falta el valor para $name.');
  }
  return arguments[index + 1];
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('(^-|-\$)'), '');
}

String _timestamp(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}'
      '${twoDigits(value.month)}'
      '${twoDigits(value.day)}-'
      '${twoDigits(value.hour)}'
      '${twoDigits(value.minute)}'
      '${twoDigits(value.second)}';
}

class _ReviewDevice {
  final String id;
  final String name;

  const _ReviewDevice({
    required this.id,
    required this.name,
  });
}

class _ReviewResult {
  final _ReviewDevice device;
  final int exitCode;
  final bool hadFrameworkException;
  final bool hadBuildFailure;
  final List<File> screenshots;
  final List<File> staleScreenshots;
  final int expectedScreenshotCount;

  const _ReviewResult({
    required this.device,
    required this.exitCode,
    required this.hadFrameworkException,
    required this.hadBuildFailure,
    required this.screenshots,
    required this.staleScreenshots,
    required this.expectedScreenshotCount,
  });

  bool get passed =>
      exitCode == 0 &&
      !hadFrameworkException &&
      !hadBuildFailure &&
      staleScreenshots.isEmpty &&
      screenshots.length == expectedScreenshotCount;
}
