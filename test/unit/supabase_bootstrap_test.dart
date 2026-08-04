import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/cloud_auth_gateway.dart';
import 'package:zentra/infrastructure/cloud_runtime_policy.dart';
import 'package:zentra/infrastructure/supabase_bootstrap.dart';

void main() {
  test('cloud runtime is parked unless ZENTRA_CLOUD_ENABLED is explicit', () {
    final policy = CloudRuntimePolicy.fromDartDefines();

    expect(CloudRuntimePolicy.dartDefineName, 'ZENTRA_CLOUD_ENABLED');
    expect(policy.enabled, isFalse);
    expect(policy.isParked, isTrue);
  });

  test('parked runtime ignores Supabase configuration and exposes no clients',
      () async {
    const environment = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: 'sb_publishable_example',
      googleAuthEnabled: true,
    );

    final result = await bootstrapSupabase(
      environment: environment,
      runtimePolicy: CloudRuntimePolicy.parked,
    );

    expect(result.authGateway, isNull);
    expect(result.syncTransport, isNull);
    expect(result.error, isNull);
    expect(result.isConfigured, isFalse);
  });

  test('active runtime preserves Supabase configuration validation', () async {
    const environment = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: '',
    );

    final result = await bootstrapSupabase(
      environment: environment,
      runtimePolicy: CloudRuntimePolicy.active,
    );

    expect(result.authGateway, isNull);
    expect(result.syncTransport, isNull);
    expect(result.error, contains('PUBLISHABLE_KEY'));
  });

  test('empty environment keeps Supabase disabled without an error', () {
    const environment = SupabaseEnvironment(
      url: '',
      publishableKey: '',
    );

    expect(environment.hasAnyConfiguration, isFalse);
    expect(environment.validationError, isNull);
    expect(environment.isConfigured, isFalse);
  });

  test('HTTPS and local Supabase environments validate explicitly', () {
    const cloud = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: 'sb_publishable_example',
      googleAuthEnabled: true,
    );
    const local = SupabaseEnvironment(
      url: 'http://127.0.0.1:54321',
      publishableKey: 'local-anon-key',
    );

    expect(cloud.validationError, isNull);
    expect(cloud.isConfigured, isTrue);
    expect(cloud.enabledProviders, {CloudAuthProvider.google});
    expect(local.validationError, isNull);
    expect(local.isConfigured, isTrue);
  });

  test('partial or unsafe configuration is rejected before SDK startup', () {
    const missingKey = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: '',
    );
    const unsafeUrl = SupabaseEnvironment(
      url: 'http://example.com',
      publishableKey: 'sb_publishable_example',
    );
    const invalidRedirect = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: 'sb_publishable_example',
      mobileRedirectUrl: 'com.jesutorr.appzentra://wrong-host',
    );

    expect(missingKey.validationError, contains('PUBLISHABLE_KEY'));
    expect(unsafeUrl.validationError, contains('HTTPS'));
    expect(invalidRedirect.validationError, contains('login-callback'));
  });

  test('privileged Supabase keys are rejected before SDK startup', () {
    const secretKey = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: 'sb_' 'secret_this-must-never-enter-flutter',
    );
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'role': 'service_role'})))
        .replaceAll('=', '');
    final legacyServiceRole = SupabaseEnvironment(
      url: 'https://project.supabase.co',
      publishableKey: 'header.$payload.signature',
    );

    expect(secretKey.validationError, contains('clave privilegiada'));
    expect(legacyServiceRole.validationError, contains('service role'));
  });
}
