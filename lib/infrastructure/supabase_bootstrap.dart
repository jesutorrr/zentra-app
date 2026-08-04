import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cloud_auth_gateway.dart';
import '../domain/sync/sync.dart';
import 'cloud_runtime_policy.dart';
import 'secure_supabase_storage.dart';
import 'supabase_cloud_auth_gateway.dart';
import 'supabase_sync_transport.dart';

class SupabaseEnvironment {
  static const defaultMobileRedirectUrl =
      'com.jesutorr.appzentra://login-callback';

  final String url;
  final String publishableKey;
  final String mobileRedirectUrl;
  final bool googleAuthEnabled;
  final bool appleAuthEnabled;

  const SupabaseEnvironment({
    required this.url,
    required this.publishableKey,
    this.mobileRedirectUrl = defaultMobileRedirectUrl,
    this.googleAuthEnabled = false,
    this.appleAuthEnabled = false,
  });

  factory SupabaseEnvironment.fromDartDefines() {
    return const SupabaseEnvironment(
      url: String.fromEnvironment('SUPABASE_URL'),
      publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      mobileRedirectUrl: String.fromEnvironment(
        'SUPABASE_REDIRECT_URL',
        defaultValue: defaultMobileRedirectUrl,
      ),
      googleAuthEnabled: bool.fromEnvironment('SUPABASE_GOOGLE_AUTH_ENABLED'),
      appleAuthEnabled: bool.fromEnvironment('SUPABASE_APPLE_AUTH_ENABLED'),
    );
  }

  bool get hasAnyConfiguration =>
      url.trim().isNotEmpty ||
      publishableKey.trim().isNotEmpty ||
      googleAuthEnabled ||
      appleAuthEnabled;

  Set<CloudAuthProvider> get enabledProviders => {
        if (googleAuthEnabled) CloudAuthProvider.google,
        if (appleAuthEnabled) CloudAuthProvider.apple,
      };

  String? get validationError {
    if (!hasAnyConfiguration) return null;
    final parsedUrl = Uri.tryParse(url.trim());
    if (parsedUrl == null ||
        !parsedUrl.hasScheme ||
        !parsedUrl.hasAuthority ||
        (parsedUrl.scheme != 'https' &&
            parsedUrl.host != '127.0.0.1' &&
            parsedUrl.host != 'localhost')) {
      return 'SUPABASE_URL no es una URL HTTPS válida.';
    }
    if (publishableKey.trim().isEmpty) {
      return 'Falta SUPABASE_PUBLISHABLE_KEY.';
    }
    if (_isPrivilegedKey(publishableKey.trim())) {
      return 'SUPABASE_PUBLISHABLE_KEY contiene una clave privilegiada. '
          'La service role nunca debe compilarse en Zentra.';
    }
    final redirect = Uri.tryParse(mobileRedirectUrl.trim());
    if (redirect == null ||
        !redirect.hasScheme ||
        redirect.host != 'login-callback') {
      return 'SUPABASE_REDIRECT_URL debe terminar en //login-callback.';
    }
    return null;
  }

  bool _isPrivilegedKey(String key) {
    if (key.startsWith('sb_secret_')) return true;
    final segments = key.split('.');
    if (segments.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      return payload is Map && payload['role'] == 'service_role';
    } catch (_) {
      return false;
    }
  }

  bool get isConfigured => hasAnyConfiguration && validationError == null;
}

class SupabaseBootstrapResult {
  final CloudAuthGateway? authGateway;
  final SyncTransport? syncTransport;
  final String? error;

  const SupabaseBootstrapResult({
    this.authGateway,
    this.syncTransport,
    this.error,
  });

  bool get isConfigured => authGateway != null && syncTransport != null;
}

Future<SupabaseBootstrapResult> bootstrapSupabase({
  SupabaseEnvironment? environment,
  CloudRuntimePolicy? runtimePolicy,
}) async {
  final resolvedPolicy = runtimePolicy ?? CloudRuntimePolicy.fromDartDefines();
  if (resolvedPolicy.isParked) {
    return const SupabaseBootstrapResult();
  }

  final resolved = environment ?? SupabaseEnvironment.fromDartDefines();
  if (!resolved.hasAnyConfiguration) {
    return const SupabaseBootstrapResult();
  }

  final validationError = resolved.validationError;
  if (validationError != null) {
    return SupabaseBootstrapResult(error: validationError);
  }

  try {
    const secureStore = FlutterSecureKeyValueStore();
    await Supabase.initialize(
      url: resolved.url.trim(),
      publishableKey: resolved.publishableKey.trim(),
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSupabaseSessionStorage(secureStore),
        pkceAsyncStorage: SecureSupabasePkceStorage(secureStore),
      ),
    );
    return SupabaseBootstrapResult(
      authGateway: SupabaseCloudAuthGateway(
        client: Supabase.instance.client,
        mobileRedirectUrl: resolved.mobileRedirectUrl.trim(),
        availableProviders: resolved.enabledProviders,
      ),
      syncTransport: SupabaseSyncTransport(Supabase.instance.client),
    );
  } catch (error) {
    return SupabaseBootstrapResult(
      error: 'No se pudo inicializar Supabase: $error',
    );
  }
}
