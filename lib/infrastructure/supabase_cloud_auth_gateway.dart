import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cloud_auth_gateway.dart';

class SupabaseCloudAuthGateway implements CloudAuthGateway {
  final SupabaseClient _client;
  final String _mobileRedirectUrl;

  @override
  final Set<CloudAuthProvider> availableProviders;

  const SupabaseCloudAuthGateway({
    required SupabaseClient client,
    required String mobileRedirectUrl,
    required this.availableProviders,
  })  : _client = client,
        _mobileRedirectUrl = mobileRedirectUrl;

  @override
  CloudIdentity? get currentIdentity {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired) return null;
    return _mapUser(session.user);
  }

  @override
  Stream<CloudIdentity?> get identityChanges {
    return _client.auth.onAuthStateChange
        .where((state) => state.event != AuthChangeEvent.initialSession)
        .map((state) {
      final session = state.session;
      if (session == null || session.isExpired) return null;
      return _mapUser(session.user);
    }).distinct();
  }

  @override
  Future<CloudIdentity?> restoreIdentity() async {
    final current = _client.auth.currentSession;
    if (current == null) return null;
    if (!current.isExpired) return _mapUser(current.user);

    final response = await _client.auth.refreshSession();
    final restored = response.session;
    if (restored == null || restored.isExpired) return null;
    return _mapUser(restored.user);
  }

  @override
  Future<void> signIn(CloudAuthProvider provider) async {
    if (!availableProviders.contains(provider)) {
      throw StateError(
        'El proveedor ${provider.name} no está habilitado en este ambiente.',
      );
    }
    final didLaunch = await _client.auth.signInWithOAuth(
      switch (provider) {
        CloudAuthProvider.google => OAuthProvider.google,
        CloudAuthProvider.apple => OAuthProvider.apple,
      },
      redirectTo: kIsWeb ? null : _mobileRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
    if (!didLaunch) {
      throw StateError('No se pudo abrir el proveedor de autenticación.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired) {
      throw StateError(
        'Necesitas una sesión vigente para eliminar la cuenta remota.',
      );
    }

    final response = await _client.functions.invoke('delete-account');
    final data = response.data;
    if (response.status != 200 || data is! Map || data['deleted'] != true) {
      throw StateError('Supabase no confirmó la eliminación de la cuenta.');
    }
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  CloudIdentity _mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email?.trim();
    final displayName = _firstNonEmpty([
      metadata['full_name'],
      metadata['name'],
      metadata['preferred_username'],
      email?.split('@').first,
      'Mi espacio',
    ]);
    final provider = _firstNonEmpty([
      user.appMetadata['provider'],
      user.identities?.firstOrNull?.provider,
      'supabase',
    ]);

    return CloudIdentity(
      userId: user.id,
      displayName: displayName,
      email: email?.isEmpty == true ? null : email,
      provider: provider,
    );
  }

  String _firstNonEmpty(List<Object?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value?.isNotEmpty == true) return value!;
    }
    return 'supabase';
  }
}
