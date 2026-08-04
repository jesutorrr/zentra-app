// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

import '../domain/backup_gateways.dart';

Future<String> saveJson({
  required String contents,
  required String fileName,
}) async {
  final bytes = utf8.encode(contents);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  return 'WEB_DOWNLOAD:$fileName';
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
  final bytes = file.bytes;
  if (bytes == null) throw Exception('No se pudo leer el archivo');
  return utf8.decode(bytes);
}
