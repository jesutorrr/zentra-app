import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/backup_gateways.dart';

Future<String> saveJson({
  required String contents,
  required String fileName,
}) async {
  Directory? saveDirectory;
  if (Platform.isAndroid) {
    try {
      saveDirectory = await getDownloadsDirectory();
    } catch (_) {
      // Fall back to app documents when Downloads is unavailable.
    }
    saveDirectory ??= await getApplicationDocumentsDirectory();
  } else {
    saveDirectory = await getApplicationDocumentsDirectory();
  }

  final file = File('${saveDirectory.path}/$fileName');
  await file.writeAsString(contents);
  return file.path;
}

Future<String?> selectJson() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  if (file.size > BackupSecurity.maximumBackupBytes) {
    throw Exception('El respaldo supera el límite seguro de 20 MB.');
  }
  if (file.bytes != null) return utf8.decode(file.bytes!);
  if (file.path != null) return File(file.path!).readAsString();
  throw Exception('No se pudo leer el archivo');
}
