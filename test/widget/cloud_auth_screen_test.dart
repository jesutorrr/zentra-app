import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/cloud_auth_gateway.dart';
import 'package:zentra/presentation/auth_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('local-only access hides cloud providers and startup failures',
      (tester) async {
    final gateway = _RecordingCloudAuthGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudAuthGatewayProvider.overrideWithValue(gateway),
          cloudAuthStartupErrorProvider.overrideWithValue(
            'Supabase no pudo iniciar',
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-local-path')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-backup-path')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-cloud-options')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('auth-google-action')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('auth-google-future')),
      findsNothing,
    );
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
    expect(gateway.signInProviders, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingCloudAuthGateway implements CloudAuthGateway {
  final signInProviders = <CloudAuthProvider>[];

  @override
  Set<CloudAuthProvider> get availableProviders => const {
        CloudAuthProvider.google,
      };

  @override
  CloudIdentity? get currentIdentity => null;

  @override
  Stream<CloudIdentity?> get identityChanges => const Stream.empty();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<CloudIdentity?> restoreIdentity() async => currentIdentity;

  @override
  Future<void> signIn(CloudAuthProvider provider) async {
    signInProviders.add(provider);
  }

  @override
  Future<void> signOut() async {}
}
