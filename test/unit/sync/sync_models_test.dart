import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/sync/sync.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 26, 12);

  SyncMutation mutation({
    Map<String, Object?> payload = const {'title': 'Leer'},
  }) {
    return SyncMutation(
      mutationId: 'mutation-1',
      ownerId: 'owner-1',
      deviceId: 'device-1',
      entityType: SyncEntityType.habit,
      entityId: 'habit-1',
      operation: SyncMutationOperation.habitUpsert,
      payload: payload,
      baseVersion: 4,
      createdAt: createdAt,
    );
  }

  group('wire contracts', () {
    test('parses supported values and rejects unknown values', () {
      expect(
        SyncEntityType.fromWire('habit_day_state'),
        SyncEntityType.habitDayState,
      );
      expect(
        SyncMutationOperation.fromWire('note_review_add'),
        SyncMutationOperation.noteReviewAdd,
      );
      expect(
        SyncServerOperation.fromWire('restore'),
        SyncServerOperation.restore,
      );

      expect(
        () => SyncEntityType.fromWire('future_entity'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SyncMutationOperation.fromWire('future_operation'),
        throwsA(isA<FormatException>()),
      );
    });

    test('RPC parameters expose only the server mutation contract', () {
      expect(
        mutation().toRpcParameters(),
        {
          'p_mutation_id': 'mutation-1',
          'p_operation': 'habit_upsert',
          'p_entity_id': 'habit-1',
          'p_base_version': 4,
          'p_payload': {'title': 'Leer'},
          'p_schema_version': 1,
        },
      );
      expect(mutation().toRpcParameters(), isNot(contains('owner_id')));
      expect(mutation().toRpcParameters(), isNot(contains('device_id')));
    });

    test('rejects mismatched operations and empty identifiers', () {
      expect(
        () => SyncMutation(
          mutationId: 'mutation-1',
          ownerId: 'owner-1',
          deviceId: 'device-1',
          entityType: SyncEntityType.note,
          entityId: 'note-1',
          operation: SyncMutationOperation.habitUpsert,
          createdAt: createdAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => SyncMutation(
          mutationId: '',
          ownerId: 'owner-1',
          deviceId: 'device-1',
          entityType: SyncEntityType.habit,
          entityId: 'habit-1',
          operation: SyncMutationOperation.habitUpsert,
          createdAt: createdAt,
        ),
        throwsArgumentError,
      );
    });
  });

  test('mutation payload is an isolated deeply immutable JSON value', () {
    final source = <String, Object?>{
      'metadata': <String, Object?>{
        'tags': <Object?>['salud'],
      },
    };
    final result = mutation(payload: source);
    final metadata = result.payload['metadata']! as Map<String, Object?>;
    final tags = metadata['tags']! as List<Object?>;

    (source['metadata']! as Map<String, Object?>)['extra'] = true;
    ((source['metadata']! as Map<String, Object?>)['tags']! as List<Object?>)
        .add('foco');

    expect(metadata, isNot(contains('extra')));
    expect(tags, ['salud']);
    expect(() => result.payload['title'] = 'Otro', throwsUnsupportedError);
    expect(() => metadata['extra'] = true, throwsUnsupportedError);
    expect(() => tags.add('otro'), throwsUnsupportedError);
  });

  test('mutation payload rejects values that cannot cross the JSON boundary',
      () {
    expect(
      () => mutation(payload: {'when': createdAt}),
      throwsArgumentError,
    );
    expect(
      () => mutation(payload: {'score': double.nan}),
      throwsArgumentError,
    );
  });

  test('logical identities collapse schedule day-state and reminder aliases',
      () {
    expect(
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.habitSchedule,
        entityId: 'local-schedule',
        record: const {'habit_id': 'habit-1'},
      ),
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.habitSchedule,
        entityId: 'server-schedule',
        record: const {'habit_id': 'habit-1'},
      ),
    );
    expect(
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.habitDayState,
        entityId: 'local-state',
        record: const {
          'habit_id': 'habit-1',
          'local_date': '2026-07-26',
        },
      ),
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.habitDayState,
        entityId: 'server-state',
        record: const {
          'habit_id': 'habit-1',
          'local_date': '2026-07-26',
        },
      ),
    );
    expect(
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.noteReminder,
        entityId: 'local-reminder',
        record: const {'note_id': 'note-1'},
      ),
      SyncLogicalIdentity.forRecord(
        entityType: SyncEntityType.noteReminder,
        entityId: 'server-reminder',
        record: const {'note_id': 'note-1'},
      ),
    );
  });

  test('diagnostic JSON contains sorted serializable entity maps', () {
    const habitKey = SyncEntityKey(
      type: SyncEntityType.habit,
      id: 'z-habit',
    );
    const profileKey = SyncEntityKey(
      type: SyncEntityType.profile,
      id: 'a-profile',
    );
    final json = SyncSnapshot(
      entities: {
        habitKey: SyncLocalEntity(
          key: habitKey,
          version: 1,
          serverRevision: 2,
          record: const {'title': 'Caminar'},
        ),
        profileKey: SyncLocalEntity(
          key: profileKey,
          version: 1,
          serverRevision: 1,
          record: const {'name': 'Uri'},
        ),
      },
    ).toDiagnosticJson();
    final entities = json['entities']! as List<Map<String, Object?>>;

    expect(
      entities.map((entity) => entity['entity_type']),
      ['habit', 'profile'],
    );
    expect(entities.every((entity) => entity['record'] is Map), isTrue);
  });

  test('snapshot rejects mismatched keys and duplicate durable IDs', () {
    const mapKey = SyncEntityKey(
      type: SyncEntityType.habit,
      id: 'map-key',
    );
    const entityKey = SyncEntityKey(
      type: SyncEntityType.habit,
      id: 'entity-key',
    );
    expect(
      () => SyncSnapshot(
        entities: {
          mapKey: SyncLocalEntity(
            key: entityKey,
            version: 1,
            serverRevision: 1,
            record: const {'title': 'Caminar'},
          ),
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => SyncSnapshot(outbox: [mutation(), mutation()]),
      throwsArgumentError,
    );
  });
}
