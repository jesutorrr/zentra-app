import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/backup_gateways.dart';
import 'package:zentra/infrastructure/encrypted_backup_protector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const passphrase = 'correct horse battery staple';
  const plaintext = '{"backupVersion":4,"profile":{"name":"Uri"}}';

  test('AES-GCM envelope round trips without storing plaintext', () async {
    final protector = EncryptedBackupProtector();

    final protected = await protector.protect(
      plaintext: plaintext,
      passphrase: passphrase,
    );
    final envelope = jsonDecode(protected) as Map<String, dynamic>;

    expect(envelope['format'], EncryptedBackupProtector.format);
    expect(envelope['version'], EncryptedBackupProtector.version);
    expect(protected, isNot(contains('Uri')));
    expect(
      await protector.unprotect(
        storedContents: protected,
        passphrase: passphrase,
      ),
      plaintext,
    );
  });

  test('wrong passphrase and ciphertext tampering are rejected', () async {
    final protector = EncryptedBackupProtector();
    final protected = await protector.protect(
      plaintext: plaintext,
      passphrase: passphrase,
    );

    await expectLater(
      protector.unprotect(
        storedContents: protected,
        passphrase: 'this password is wrong',
      ),
      throwsA(isA<BackupProtectionException>()),
    );

    final envelope = jsonDecode(protected) as Map<String, dynamic>;
    final ciphertext = envelope['ciphertext'] as String;
    envelope['ciphertext'] =
        '${ciphertext.substring(0, ciphertext.length - 2)}AA';
    await expectLater(
      protector.unprotect(
        storedContents: jsonEncode(envelope),
        passphrase: passphrase,
      ),
      throwsA(isA<BackupProtectionException>()),
    );
  });

  test('short export passwords are rejected and legacy JSON stays importable',
      () async {
    final protector = EncryptedBackupProtector();

    await expectLater(
      protector.protect(
        plaintext: plaintext,
        passphrase: 'too-short',
      ),
      throwsA(isA<BackupProtectionException>()),
    );
    expect(
      await protector.unprotect(
        storedContents: plaintext,
        passphrase: '',
      ),
      plaintext,
    );
    expect(BackupSecurity.minimumPassphraseLength, 12);
  });
}
