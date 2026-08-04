import 'auth_models.dart';

class BackupRestoreResult {
  final String targetUserId;
  final LocalUser currentUser;
  final List<LocalUser> accounts;
  final bool restoredAccount;

  BackupRestoreResult({
    required this.targetUserId,
    required this.currentUser,
    required List<LocalUser> accounts,
    required this.restoredAccount,
  }) : accounts = List.unmodifiable(accounts);
}

abstract interface class BackupService {
  Future<String> exportBackup({
    required String? userId,
    required String passphrase,
  });

  Future<BackupData?> selectBackup({
    required String passphrase,
    String? jsonData,
  });

  Future<BackupRestoreResult> restoreBackup(
    BackupData backupData, {
    required LocalUser? currentUser,
    required List<LocalUser> accounts,
    required bool preserveCurrentUser,
  });
}
