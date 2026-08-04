abstract final class BackupSecurity {
  static const minimumPassphraseLength = 12;
  static const maximumBackupBytes = 20 * 1024 * 1024;
}

abstract interface class BackupFileGateway {
  Future<String> saveJson({
    required String contents,
    required String fileName,
  });

  Future<String?> selectJson();
}

abstract interface class AppVersionGateway {
  Future<String> loadAppVersion();
}

abstract interface class BackupProtector {
  Future<String> protect({
    required String plaintext,
    required String passphrase,
  });

  Future<String> unprotect({
    required String storedContents,
    required String passphrase,
  });
}
