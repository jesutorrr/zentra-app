import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../domain/backup_gateways.dart';

class BackupProtectionException implements Exception {
  final String message;

  const BackupProtectionException(this.message);

  @override
  String toString() => message;
}

/// Password-based authenticated encryption for portable Zentra backups.
///
/// The passphrase never leaves the caller. PBKDF2 derives a unique AES-256 key
/// for every export and AES-GCM authenticates both the ciphertext and format.
class EncryptedBackupProtector implements BackupProtector {
  static const format = 'zentra-encrypted-backup';
  static const version = 1;
  static const _iterations = 210000;
  static const _aad = 'zentra-encrypted-backup:v1';

  final Cipher _cipher;
  final Random _random;

  EncryptedBackupProtector({
    Cipher? cipher,
    Random? random,
  })  : _cipher = cipher ?? AesGcm.with256bits(),
        _random = random ?? Random.secure();

  @override
  Future<String> protect({
    required String plaintext,
    required String passphrase,
  }) async {
    if (passphrase.length < BackupSecurity.minimumPassphraseLength) {
      throw const BackupProtectionException(
        'La contraseña del respaldo debe tener al menos 12 caracteres.',
      );
    }
    final clearBytes = utf8.encode(plaintext);
    if (clearBytes.length > BackupSecurity.maximumBackupBytes) {
      throw const BackupProtectionException(
        'El respaldo supera el límite seguro de 20 MB.',
      );
    }

    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final key = await _deriveKey(
      passphrase: passphrase,
      salt: salt,
      iterations: _iterations,
    );
    final box = await _cipher.encrypt(
      clearBytes,
      secretKey: key,
      nonce: _cipher.newNonce(),
      aad: utf8.encode(_aad),
    );

    return jsonEncode({
      'format': format,
      'version': version,
      'kdf': {
        'name': 'pbkdf2-hmac-sha256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'name': 'aes-256-gcm',
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
      },
      'ciphertext': base64Encode(box.cipherText),
    });
  }

  @override
  Future<String> unprotect({
    required String storedContents,
    required String passphrase,
  }) async {
    if (utf8.encode(storedContents).length >
        BackupSecurity.maximumBackupBytes) {
      throw const BackupProtectionException(
        'El respaldo supera el límite seguro de 20 MB.',
      );
    }

    final decoded = _decodeJsonObject(storedContents);
    if (decoded['format'] != format) {
      return storedContents;
    }
    if (passphrase.isEmpty) {
      throw const BackupProtectionException(
        'Este respaldo está cifrado. Ingresa su contraseña.',
      );
    }

    try {
      if (decoded['version'] != version) {
        throw const FormatException('Unsupported backup envelope version.');
      }
      final kdf = (decoded['kdf'] as Map).cast<String, dynamic>();
      final cipher = (decoded['cipher'] as Map).cast<String, dynamic>();
      if (kdf['name'] != 'pbkdf2-hmac-sha256' ||
          cipher['name'] != 'aes-256-gcm') {
        throw const FormatException('Unsupported backup protection.');
      }

      final iterations = kdf['iterations'] as int;
      if (iterations < 100000 || iterations > 1000000) {
        throw const FormatException('Invalid KDF work factor.');
      }
      final salt = base64Decode(kdf['salt'] as String);
      final nonce = base64Decode(cipher['nonce'] as String);
      final mac = base64Decode(cipher['mac'] as String);
      final ciphertext = base64Decode(decoded['ciphertext'] as String);
      if (salt.length < 16 ||
          salt.length > 64 ||
          nonce.length != _cipher.nonceLength ||
          mac.length != _cipher.macAlgorithm.macLength ||
          ciphertext.isEmpty) {
        throw const FormatException('Invalid encrypted backup fields.');
      }

      final key = await _deriveKey(
        passphrase: passphrase,
        salt: salt,
        iterations: iterations,
      );
      final clearBytes = await _cipher.decrypt(
        SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(mac),
        ),
        secretKey: key,
        aad: utf8.encode(_aad),
      );
      return utf8.decode(clearBytes);
    } catch (_) {
      throw const BackupProtectionException(
        'La contraseña es incorrecta o el respaldo fue alterado.',
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup root must be an object.');
      }
      return decoded;
    } catch (_) {
      throw const BackupProtectionException(
        'El archivo no contiene un respaldo válido de Zentra.',
      );
    }
  }

  Future<SecretKey> _deriveKey({
    required String passphrase,
    required List<int> salt,
    required int iterations,
  }) {
    return Pbkdf2.hmacSha256(
      iterations: iterations,
      bits: 256,
    ).deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }
}
