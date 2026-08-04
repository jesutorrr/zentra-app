import '../domain/backup_gateways.dart';
import 'platform_backup_file_gateway_io.dart'
    if (dart.library.html) 'platform_backup_file_gateway_web.dart' as platform;

class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  @override
  Future<String> saveJson({
    required String contents,
    required String fileName,
  }) {
    return platform.saveJson(contents: contents, fileName: fileName);
  }

  @override
  Future<String?> selectJson() => platform.selectJson();
}
