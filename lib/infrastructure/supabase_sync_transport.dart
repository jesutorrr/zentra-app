import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sync/sync.dart';

class SupabaseSyncTransport implements SyncTransport, SyncWakeSignalSource {
  final SupabaseClient _client;

  const SupabaseSyncTransport(this._client);

  @override
  String? get authenticatedUserId {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired) return null;
    return session.user.id;
  }

  @override
  Stream<void> watchRemoteChanges({required String ownerId}) {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired || session.user.id != ownerId) {
      return Stream<void>.error(
        const SyncTransportException(
          failure: SyncFailure(
            kind: SyncFailureKind.authExpired,
            code: 'realtime_owner_mismatch',
          ),
          message: 'Supabase Realtime requires the authenticated owner.',
        ),
      );
    }

    RealtimeChannel? channel;
    Timer? retryTimer;
    Timer? safetyPullTimer;
    var retryAttempt = 0;
    var safetyPullAttempt = 0;
    var subscriptionStarting = false;
    late final StreamController<void> controller;
    late final Future<void> Function() subscribe;

    Duration retryDelay() => Duration(
          seconds: switch (retryAttempt) {
            0 => 1,
            1 => 2,
            2 => 4,
            3 => 8,
            _ => 16,
          },
        );

    Duration safetyPullDelay() => Duration(
          seconds: switch (safetyPullAttempt) {
            0 => 2,
            1 => 5,
            2 => 15,
            _ => 60,
          },
        );

    void scheduleSafetyPull() {
      if (controller.isClosed || !controller.hasListener) return;
      safetyPullTimer?.cancel();
      final delay = safetyPullDelay();
      safetyPullAttempt++;
      safetyPullTimer = Timer(delay, () {
        if (controller.isClosed || !controller.hasListener) return;
        controller.add(null);
        scheduleSafetyPull();
      });
    }

    Future<void> removeChannelQuietly(RealtimeChannel staleChannel) async {
      try {
        await _client.removeChannel(staleChannel);
      } catch (_) {
        // Removal is best effort. A failed cleanup must not suppress the
        // durable retry path or surface as an unhandled asynchronous error.
      }
    }

    void scheduleRetry() {
      if (controller.isClosed || !controller.hasListener) return;
      retryTimer?.cancel();
      final delay = retryDelay();
      retryAttempt++;
      retryTimer = Timer(delay, () {
        unawaited(subscribe());
      });
    }

    subscribe = () async {
      if (subscriptionStarting ||
          channel != null ||
          controller.isClosed ||
          !controller.hasListener) {
        return;
      }
      subscriptionStarting = true;
      // Supabase forwards auth changes to Realtime asynchronously. Set the
      // current token explicitly so a channel created immediately after login
      // cannot join with the anon key.
      try {
        await _client.realtime.setAuth(session.accessToken);
      } catch (error, stackTrace) {
        subscriptionStarting = false;
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
          scheduleRetry();
        }
        return;
      }
      subscriptionStarting = false;
      if (controller.isClosed || !controller.hasListener) return;

      final nextChannel =
          _client.channel('zentra:sync:$ownerId').onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'sync_changes',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: ownerId,
                ),
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              );
      channel = nextChannel;
      nextChannel.subscribe((status, error) {
        if (controller.isClosed || channel != nextChannel) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          retryAttempt = 0;
          safetyPullAttempt = 0;
          // Connecting or reconnecting is itself a reason to catch up.
          controller.add(null);
          // A cold Realtime service can acknowledge the websocket before its
          // logical replication slot is ready. Short catch-up pulls bridge
          // that window, then a low-frequency pull keeps the durable cursor
          // authoritative if a notification is ever lost.
          scheduleSafetyPull();
        } else if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          safetyPullTimer?.cancel();
          if (status != RealtimeSubscribeStatus.closed) {
            controller.addError(
              SyncTransportException(
                failure: const SyncFailure(
                  kind: SyncFailureKind.serverUnavailable,
                  code: 'realtime_subscription_failed',
                ),
                message: 'Supabase Realtime subscription failed: $error',
              ),
            );
          }
          channel = null;
          unawaited(
            removeChannelQuietly(nextChannel).whenComplete(scheduleRetry),
          );
        }
      });
    };

    controller = StreamController<void>(
      onListen: () {
        unawaited(subscribe());
      },
      onCancel: () {
        retryTimer?.cancel();
        safetyPullTimer?.cancel();
        final activeChannel = channel;
        channel = null;
        if (activeChannel != null) {
          unawaited(removeChannelQuietly(activeChannel));
        }
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  @override
  Future<SyncPullPage> pull({
    required int afterRevision,
    int limit = 200,
  }) async {
    if (afterRevision < 0) {
      throw ArgumentError.value(
        afterRevision,
        'afterRevision',
        'Cannot be negative',
      );
    }
    if (limit < 1 || limit > 500) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 500');
    }

    try {
      final response = await _client.rpc(
        'pull_sync_changes',
        params: {
          'p_after_revision': afterRevision,
          'p_limit': limit,
        },
      );
      final rows = (response as List).cast<Object?>();
      return SyncPullPage(
        requestedLimit: limit,
        changes: [
          for (final row in rows)
            SyncRemoteChange.fromJson(
              (row as Map).cast<String, Object?>(),
            ),
        ],
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<SyncMutationAcknowledgement> push(SyncMutation mutation) async {
    final remoteUserId = authenticatedUserId;
    if (remoteUserId == null) {
      throw const SyncTransportException(
        failure: SyncFailure(
          kind: SyncFailureKind.authExpired,
          code: 'auth_required',
        ),
        message: 'Supabase authentication is required.',
      );
    }
    if (mutation.ownerId != remoteUserId) {
      throw SyncTransportException(
        failure: const SyncFailure(
          kind: SyncFailureKind.forbidden,
          code: 'owner_mismatch',
        ),
        message:
            'Mutation owner ${mutation.ownerId} does not match auth.uid().',
      );
    }

    try {
      final rpcName = switch (mutation.entityType) {
        SyncEntityType.note ||
        SyncEntityType.noteReminder ||
        SyncEntityType.noteReview =>
          'apply_note_sync_mutation',
        SyncEntityType.completedTask ||
        SyncEntityType.focusSession =>
          'apply_activity_sync_mutation',
        SyncEntityType.userPreferences => 'apply_preference_sync_mutation',
        _ => 'apply_sync_mutation',
      };
      final response = await _client.rpc(
        rpcName,
        params: mutation.toRpcParameters(),
      );
      return SyncMutationAcknowledgement.fromJson(
        (response as Map).cast<String, Object?>(),
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  SyncTransportException _mapFailure(Object error) {
    if (error is SyncTransportException) return error;
    if (error is TimeoutException || error is SocketException) {
      return SyncTransportException(
        failure: SyncFailure(
          kind: error is TimeoutException
              ? SyncFailureKind.timeout
              : SyncFailureKind.offline,
          code: error.runtimeType.toString(),
        ),
        message: 'Supabase sync request failed.',
      );
    }
    if (error is PostgrestException) {
      final code = error.code ?? 'postgrest_error';
      final kind = switch (code) {
        '40001' => SyncFailureKind.versionConflict,
        '42501' || 'PGRST301' => SyncFailureKind.authExpired,
        '22023' || 'P0002' => SyncFailureKind.invalidRequest,
        '23503' || '23505' => SyncFailureKind.forbidden,
        _ when code.startsWith('5') => SyncFailureKind.serverUnavailable,
        _ => SyncFailureKind.unknown,
      };
      return SyncTransportException(
        failure: SyncFailure(kind: kind, code: code),
        message: 'Supabase sync rejected the request ($code).',
      );
    }
    return SyncTransportException(
      failure: SyncFailure(
        kind: SyncFailureKind.unknown,
        code: error.runtimeType.toString(),
      ),
      message: 'Unexpected Supabase sync failure.',
    );
  }
}
