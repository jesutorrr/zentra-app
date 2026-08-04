import 'dart:async';

import 'sync_models.dart';
import 'sync_retry_policy.dart';

class SyncPullPage {
  final List<SyncRemoteChange> changes;
  final int requestedLimit;

  SyncPullPage({
    required List<SyncRemoteChange> changes,
    required this.requestedLimit,
  }) : changes = List.unmodifiable(changes) {
    if (requestedLimit < 1) {
      throw ArgumentError.value(
        requestedLimit,
        'requestedLimit',
        'Must be positive',
      );
    }
  }

  bool get hasMore => changes.length == requestedLimit;
}

class SyncTransportException implements Exception {
  final SyncFailure failure;
  final String message;

  const SyncTransportException({
    required this.failure,
    required this.message,
  });

  @override
  String toString() => message;
}

abstract interface class SyncTransport {
  String? get authenticatedUserId;

  Future<SyncPullPage> pull({
    required int afterRevision,
    int limit = 200,
  });

  Future<SyncMutationAcknowledgement> push(SyncMutation mutation);
}

/// Optional accelerator for transports that can announce remote changes.
///
/// A wake signal is intentionally content-free. Callers must still use the
/// durable incremental pull contract before changing local state.
abstract interface class SyncWakeSignalSource {
  Stream<void> watchRemoteChanges({required String ownerId});
}
