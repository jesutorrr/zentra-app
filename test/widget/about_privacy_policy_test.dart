import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zentra/core/constants.dart';
import 'package:zentra/presentation/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  MethodCall? launcherCall;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Zentra',
      packageName: 'com.jesutorr.appzentra',
      version: '2.0.0',
      buildNumber: '25',
      buildSignature: '',
    );
    launcherCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      launcherChannel,
      (call) async {
        launcherCall = call;
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  testWidgets('privacy policy is visible and opens the public policy URL',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AboutScreen()),
    );
    await tester.pumpAndSettle();

    final privacyLink = find.text('Política de privacidad');
    expect(privacyLink, findsOneWidget);

    await tester.ensureVisible(privacyLink);
    await tester.tap(privacyLink);
    await tester.pump();

    expect(launcherCall?.method, 'launch');
    final arguments = launcherCall?.arguments as Map<Object?, Object?>;
    expect(arguments['url'], kPrivacyPolicyUrl);
    expect(arguments['useSafariVC'], isFalse);
    expect(arguments['useWebView'], isFalse);
  });
}
