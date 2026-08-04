import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/infrastructure/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppLogger().clearLogs);
  tearDown(AppLogger().clearLogs);

  test('diagnostic logs redact common identifiers and credentials', () {
    AppLogger().error(
      'Auth',
      'user=uri@example.com '
          'owner=550e8400-e29b-41d4-a716-446655440000 '
          'Authorization: Bearer secret.token-value '
          'url=https://example.com/callback?code=sensitive',
    );

    final logs = AppLogger().getLogsAsText();

    expect(logs, contains('[REDACTED_EMAIL]'));
    expect(logs, contains('[REDACTED_ID]'));
    expect(logs, contains('Bearer [REDACTED]'));
    expect(logs, contains('?[REDACTED_QUERY]'));
    expect(logs, isNot(contains('uri@example.com')));
    expect(logs, isNot(contains('550e8400-e29b-41d4-a716-446655440000')));
    expect(logs, isNot(contains('secret.token-value')));
    expect(logs, isNot(contains('code=sensitive')));
  });
}
