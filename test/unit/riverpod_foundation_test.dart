import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/riverpod_test_harness.dart';

final _configuredValueProvider = Provider<String>((ref) => 'default');

final _disposeCallbackProvider = Provider<void Function()>((ref) => () {});

final _lifecycleProbeProvider = Provider<Object>((ref) {
  final onDispose = ref.watch(_disposeCallbackProvider);
  ref.onDispose(onDispose);
  return Object();
});

void main() {
  test('container applies overrides and runs provider disposal', () {
    var disposeCalls = 0;
    final container = createTestProviderContainer(
      overrides: [
        _configuredValueProvider.overrideWithValue('overridden'),
        _disposeCallbackProvider.overrideWithValue(() => disposeCalls += 1),
      ],
    );

    expect(container.read(_configuredValueProvider), 'overridden');
    container.read(_lifecycleProbeProvider);

    container.dispose();

    expect(disposeCalls, 1);
  });

  testWidgets('widget scope exposes provider overrides', (tester) async {
    await tester.pumpWidget(
      createTestProviderScope(
        overrides: [
          _configuredValueProvider.overrideWithValue('widget override'),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              return Text(ref.watch(_configuredValueProvider));
            },
          ),
        ),
      ),
    );

    expect(find.text('widget override'), findsOneWidget);
  });
}
