import 'package:package_info_plus/package_info_plus.dart';

import '../domain/backup_gateways.dart';

class PackageInfoAppVersionGateway implements AppVersionGateway {
  const PackageInfoAppVersionGateway();

  @override
  Future<String> loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      return '1.0.0';
    }
  }
}
