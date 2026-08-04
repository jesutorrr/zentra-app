enum CloudAuthProvider {
  google,
  apple,
}

class CloudIdentity {
  final String userId;
  final String displayName;
  final String? email;
  final String provider;

  const CloudIdentity({
    required this.userId,
    required this.displayName,
    required this.provider,
    this.email,
  });

  @override
  bool operator ==(Object other) {
    return other is CloudIdentity &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.email == email &&
        other.provider == provider;
  }

  @override
  int get hashCode => Object.hash(userId, displayName, email, provider);
}

abstract interface class CloudAuthGateway {
  Set<CloudAuthProvider> get availableProviders;

  CloudIdentity? get currentIdentity;

  Stream<CloudIdentity?> get identityChanges;

  Future<CloudIdentity?> restoreIdentity();

  Future<void> signIn(CloudAuthProvider provider);

  Future<void> signOut();

  Future<void> deleteAccount();
}
