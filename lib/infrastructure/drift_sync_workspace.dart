import '../domain/sync/sync.dart';
import 'database/zentra_database.dart';
import 'drift_core_repository.dart';
import 'drift_note_repository.dart';
import 'drift_sync_repository.dart';

class DriftSyncWorkspace {
  final ZentraDatabase _database;
  final String ownerId;
  final DriftCoreRepository _core;
  final DriftNoteRepository _notes;
  final DriftSyncRepository _sync;

  DriftSyncWorkspace({
    required ZentraDatabase database,
    required this.ownerId,
  })  : _database = database,
        _core = DriftCoreRepository.forOwner(database, ownerId: ownerId),
        _notes = DriftNoteRepository.forOwner(database, ownerId: ownerId),
        _sync = DriftSyncRepository.forOwner(database, ownerId: ownerId);

  Future<SyncQueueState> loadQueueState() => _sync.loadQueueState();

  Future<SyncSnapshot> loadSnapshot() async {
    final queue = await _sync.loadQueueState();
    final coreEntities = await _core.loadSyncEntities();
    final noteEntities = await _notes.loadSyncEntities();
    return queue.toReducerSnapshot(
      entities: {
        ...coreEntities,
        ...noteEntities,
      },
    );
  }

  Future<void> commitSnapshot(
    SyncSnapshot snapshot, {
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastAttemptAt,
  }) {
    return _database.transaction(() async {
      await _core.replaceSyncEntities(
        _onlyTypes(snapshot.entities, const {
          SyncEntityType.profile,
          SyncEntityType.habit,
          SyncEntityType.habitSchedule,
          SyncEntityType.habitDayState,
          SyncEntityType.completedTask,
          SyncEntityType.focusSession,
          SyncEntityType.userPreferences,
        }),
      );
      await _notes.replaceSyncEntities(
        _onlyTypes(snapshot.entities, const {
          SyncEntityType.note,
          SyncEntityType.noteReminder,
          SyncEntityType.noteReview,
        }),
      );
      await _sync.saveReducerMetadata(
        snapshot,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt,
        lastAttemptAt: lastAttemptAt,
      );
    });
  }

  Future<void> linkToRemoteUser(String remoteUserId) {
    if (remoteUserId != ownerId) {
      throw StateError(
        'Cloud cache owner $ownerId must match auth.uid() $remoteUserId.',
      );
    }
    return _sync.linkOwner(
      localOwnerId: ownerId,
      remoteUserId: remoteUserId,
    );
  }

  Future<String?> getLinkedRemoteUserId() => _sync.getLinkedRemoteUserId();
}

Map<SyncEntityKey, SyncLocalEntity> _onlyTypes(
  Map<SyncEntityKey, SyncLocalEntity> entities,
  Set<SyncEntityType> types,
) {
  return {
    for (final entry in entities.entries)
      if (types.contains(entry.key.type)) entry.key: entry.value,
  };
}
