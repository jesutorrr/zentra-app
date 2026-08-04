import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates an isolated Riverpod container and disposes it after the test.
ProviderContainer createTestProviderContainer({
  List<Override> overrides = const [],
  List<ProviderObserver> observers = const [],
}) {
  final container = ProviderContainer(
    overrides: overrides,
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}

/// Wraps a widget test tree with an isolated, overridable Riverpod scope.
Widget createTestProviderScope({
  required Widget child,
  List<Override> overrides = const [],
  List<ProviderObserver> observers = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    observers: observers,
    child: child,
  );
}
