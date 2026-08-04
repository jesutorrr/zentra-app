BEGIN;

create extension if not exists pgtap with schema extensions;

select plan(22);

select has_table(
  'public',
  'completed_tasks',
  'completed_tasks exists'
);
select has_table(
  'public',
  'focus_sessions',
  'focus_sessions exists'
);
select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class
    where oid in (
      'public.completed_tasks'::regclass,
      'public.focus_sessions'::regclass
    )
      and relrowsecurity
  ),
  2,
  'RLS is enabled on every public activity sync table'
);

insert into auth.users (id, email)
values
  (
    'e0000000-0000-4000-8000-000000000001',
    'activity-sync-a@example.invalid'
  ),
  (
    'f0000000-0000-4000-8000-000000000002',
    'activity-sync-b@example.invalid'
  );

set local role authenticated;
set local request.jwt.claim.sub = 'e0000000-0000-4000-8000-000000000001';

select lives_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000011',
      'completed_task_upsert',
      'e0000000-0000-4000-8000-000000000021',
      null,
      '{
        "title":"Cerrar historial",
        "category":"foco",
        "completed_at":"2026-07-27T16:00:00Z",
        "was_one_time":true
      }'::jsonb,
      1
    )
  $test$,
  'user A can create a completed task event'
);

select lives_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000012',
      'focus_session_complete',
      'e0000000-0000-4000-8000-000000000022',
      null,
      '{
        "name":"Gate 7",
        "started_at":"2026-07-27T16:00:00Z",
        "ended_at":"2026-07-27T16:25:00Z",
        "cycles_completed":1,
        "total_minutes":25,
        "is_completed":true,
        "note_id":null
      }'::jsonb,
      1
    )
  $test$,
  'user A can append a completed focus session'
);

select is(
  (select count(*) from public.completed_tasks),
  1::bigint,
  'one completed task exists'
);
select is(
  (select count(*) from public.focus_sessions),
  1::bigint,
  'one focus session exists'
);
select is(
  (select count(*) from public.sync_changes),
  2::bigint,
  'two activity events create two durable changes'
);
select is(
  (
    select count(*)
    from public.pull_sync_changes(0, 100)
    where record_data is not null
  ),
  2::bigint,
  'activity pull records include their current rows'
);
select results_eq(
  $test$
    select (
      public.apply_activity_sync_mutation(
        'e0000000-0000-4000-8000-000000000012',
        'focus_session_complete',
        'e0000000-0000-4000-8000-000000000022',
        null,
        '{}'::jsonb,
        1
      ) ->> 'server_revision'
    )::bigint
  $test$,
  array[2::bigint],
  'replaying mutation_id returns the original focus acknowledgement'
);
select results_eq(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000013',
      'focus_session_complete',
      'e0000000-0000-4000-8000-000000000022',
      0,
      '{
        "name":"Gate 7",
        "started_at":"2026-07-27T16:00:00Z",
        "ended_at":"2026-07-27T16:25:00Z",
        "cycles_completed":1,
        "total_minutes":25,
        "is_completed":true,
        "note_id":null
      }'::jsonb,
      1
    ) ->> 'status'
  $test$,
  array['no_op'::text],
  'the same immutable focus event is a no-op across mutation IDs'
);
select is(
  (select count(*) from public.sync_changes),
  2::bigint,
  'focus idempotency does not append a change'
);
select throws_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000014',
      'completed_task_upsert',
      'e0000000-0000-4000-8000-000000000021',
      0,
      '{
        "title":"stale",
        "category":"foco",
        "completed_at":"2026-07-27T16:00:00Z",
        "was_one_time":true
      }'::jsonb,
      1
    )
  $test$,
  '40001',
  null,
  'a stale completed task update is rejected'
);
select lives_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000015',
      'completed_task_upsert',
      'e0000000-0000-4000-8000-000000000021',
      1,
      '{
        "title":"Historial cerrado",
        "category":"foco",
        "completed_at":"2026-07-27T16:00:00Z",
        "was_one_time":true
      }'::jsonb,
      1
    )
  $test$,
  'the current completed task version can be updated'
);
select results_eq(
  $test$
    select title
    from public.completed_tasks
    where id = 'e0000000-0000-4000-8000-000000000021'
  $test$,
  array['Historial cerrado'::text],
  'completed task content remains exact'
);
select lives_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'e0000000-0000-4000-8000-000000000016',
      'completed_task_delete',
      'e0000000-0000-4000-8000-000000000021',
      2,
      '{}'::jsonb,
      1
    )
  $test$,
  'completed task history can be cleared with a tombstone'
);
select ok(
  (
    select deleted_at is not null
    from public.completed_tasks
    where id = 'e0000000-0000-4000-8000-000000000021'
  ),
  'completed task deletion preserves its tombstone'
);
select is(
  (select count(*) from public.pull_sync_changes(0, 100)),
  4::bigint,
  'the pull stream includes task create update delete and focus completion'
);

set local request.jwt.claim.sub = 'f0000000-0000-4000-8000-000000000002';

select is(
  (select count(*) from public.completed_tasks),
  0::bigint,
  'user B cannot read user A task history'
);
select throws_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'f0000000-0000-4000-8000-000000000011',
      'completed_task_upsert',
      'e0000000-0000-4000-8000-000000000021',
      null,
      '{
        "title":"cross owner",
        "category":"varios",
        "completed_at":"2026-07-27T17:00:00Z",
        "was_one_time":false
      }'::jsonb,
      1
    )
  $test$,
  '23505',
  null,
  'user B cannot take ownership of user A completed task ID'
);
select throws_ok(
  $test$
    insert into public.focus_sessions (
      id,
      user_id,
      name,
      started_at,
      ended_at,
      cycles_completed,
      total_minutes,
      is_completed,
      version,
      server_revision
    )
    values (
      'f0000000-0000-4000-8000-000000000099',
      'f0000000-0000-4000-8000-000000000002',
      'Direct write',
      now() - interval '25 minutes',
      now(),
      1,
      25,
      true,
      1,
      99
    )
  $test$,
  '42501',
  null,
  'authenticated clients cannot bypass the activity mutation RPC'
);

reset role;
set local role anon;
set local request.jwt.claim.sub = '';

select throws_ok(
  $test$
    select public.apply_activity_sync_mutation(
      'f0000000-0000-4000-8000-000000000099',
      'focus_session_complete',
      'f0000000-0000-4000-8000-000000000099',
      null,
      '{}'::jsonb,
      1
    )
  $test$,
  '42501',
  null,
  'anonymous clients cannot execute activity mutations'
);

select * from finish();

ROLLBACK;
