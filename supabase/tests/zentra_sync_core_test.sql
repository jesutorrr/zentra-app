BEGIN;

create extension if not exists pgtap with schema extensions;

select plan(45);

select has_table(
  'public',
  'user_sync_heads',
  'user_sync_heads exists'
);
select has_table('public', 'sync_changes', 'sync_changes exists');
select has_table('public', 'profiles', 'profiles exists');
select has_table('public', 'habits', 'habits exists');
select has_table(
  'public',
  'habit_schedules',
  'habit_schedules exists'
);
select has_table(
  'public',
  'habit_day_states',
  'habit_day_states exists'
);
select has_table(
  'public',
  'processed_mutations',
  'processed_mutations exists'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class
    where oid in (
      'public.user_sync_heads'::regclass,
      'public.sync_changes'::regclass,
      'public.profiles'::regclass,
      'public.habits'::regclass,
      'public.habit_schedules'::regclass,
      'public.habit_day_states'::regclass,
      'public.processed_mutations'::regclass
    )
      and relrowsecurity
  ),
  7,
  'RLS is enabled on every public sync table'
);

insert into auth.users (id, email)
values
  (
    'a0000000-0000-4000-8000-000000000001',
    'sync-test-a@example.invalid'
  ),
  (
    'b0000000-0000-4000-8000-000000000002',
    'sync-test-b@example.invalid'
  );

set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-4000-8000-000000000001';

select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000011',
      'profile_upsert',
      'a0000000-0000-4000-8000-000000000021',
      null,
      '{"name":"Test A","avatar_emoji":"A"}'::jsonb,
      1
    )
  $test$,
  'user A can create a profile through the mutation RPC'
);

select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000012',
      'habit_upsert',
      'a0000000-0000-4000-8000-000000000022',
      null,
      '{"title":"Caminar","category":"movimiento"}'::jsonb,
      1
    )
  $test$,
  'user A can create a habit through the mutation RPC'
);

select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000013',
      'habit_schedule_set',
      'a0000000-0000-4000-8000-000000000023',
      null,
      '{
        "habit_id":"a0000000-0000-4000-8000-000000000022",
        "is_weekly":true,
        "days_of_week":[1,3,5],
        "reminder_enabled":true,
        "reminder_hour":8,
        "reminder_minute":30,
        "time_zone":"America/Mexico_City"
      }'::jsonb,
      1
    )
  $test$,
  'user A can create a schedule through the mutation RPC'
);

select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000014',
      'habit_completion_set',
      'a0000000-0000-4000-8000-000000000024',
      null,
      '{
        "habit_id":"a0000000-0000-4000-8000-000000000022",
        "local_date":"2026-07-26",
        "completed":true
      }'::jsonb,
      1
    )
  $test$,
  'user A can set an explicit completion state'
);

select is(
  (select count(*) from public.habits),
  1::bigint,
  'user A sees one owned habit'
);
select is(
  (select count(*) from public.profiles),
  1::bigint,
  'user A sees one owned profile'
);
select is(
  (select count(*) from public.sync_changes),
  4::bigint,
  'four applied mutations create four durable changes'
);
select results_eq(
  $test$
    select server_revision
    from public.pull_sync_changes(0, 100)
    order by server_revision
  $test$,
  array[1::bigint, 2::bigint, 3::bigint, 4::bigint],
  'user A receives contiguous revisions'
);
select is(
  (select count(*) from public.pull_sync_changes(2, 100)),
  2::bigint,
  'pull resumes strictly after the supplied cursor'
);
select is(
  (
    select count(*)
    from public.pull_sync_changes(0, 100)
    where record_data is not null
  ),
  4::bigint,
  'every core change includes its current record'
);
select results_eq(
  $test$
    select (
      public.apply_sync_mutation(
        'a0000000-0000-4000-8000-000000000011',
        'profile_upsert',
        'a0000000-0000-4000-8000-000000000021',
        null,
        '{"name":"Ignored retry"}'::jsonb,
        1
      ) ->> 'server_revision'
    )::bigint
  $test$,
  array[1::bigint],
  'replaying mutation_id returns the original acknowledgement'
);
select is(
  (select count(*) from public.sync_changes),
  4::bigint,
  'replaying mutation_id does not append a change'
);
select results_eq(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000015',
      'habit_completion_set',
      'a0000000-0000-4000-8000-000000000025',
      0,
      '{
        "habit_id":"a0000000-0000-4000-8000-000000000022",
        "local_date":"2026-07-26",
        "completed":true
      }'::jsonb,
      1
    ) ->> 'status'
  $test$,
  array['no_op'::text],
  'setting the current completion state is a no-op'
);
select results_eq(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000015',
      'habit_completion_set',
      'a0000000-0000-4000-8000-000000000025',
      0,
      '{
        "habit_id":"a0000000-0000-4000-8000-000000000022",
        "local_date":"2026-07-26",
        "completed":true
      }'::jsonb,
      1
    ) ->> 'entity_id'
  $test$,
  array['a0000000-0000-4000-8000-000000000024'::text],
  'a no-op returns the canonical completion entity ID'
);
select is(
  (select count(*) from public.sync_changes),
  4::bigint,
  'a no-op completion does not append a change'
);
select throws_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000016',
      'habit_upsert',
      'a0000000-0000-4000-8000-000000000022',
      0,
      '{"title":"Stale title"}'::jsonb,
      1
    )
  $test$,
  '40001',
  null,
  'a stale base version is rejected'
);
select throws_ok(
  $test$
    insert into public.habits (
      id,
      user_id,
      title,
      category,
      version,
      server_revision
    )
    values (
      'a0000000-0000-4000-8000-000000000099',
      'a0000000-0000-4000-8000-000000000001',
      'Direct write',
      'foco',
      1,
      99
    )
  $test$,
  '42501',
  null,
  'authenticated clients cannot bypass the mutation RPC'
);

set local request.jwt.claim.sub = 'b0000000-0000-4000-8000-000000000002';

select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'b0000000-0000-4000-8000-000000000011',
      'profile_upsert',
      'b0000000-0000-4000-8000-000000000021',
      null,
      '{"name":"Test B","avatar_emoji":"B"}'::jsonb,
      1
    )
  $test$,
  'user B can create an isolated profile'
);
select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'b0000000-0000-4000-8000-000000000012',
      'habit_upsert',
      'b0000000-0000-4000-8000-000000000022',
      null,
      '{"title":"Tomar agua","category":"agua"}'::jsonb,
      1
    )
  $test$,
  'user B can create an isolated habit'
);
select is(
  (select count(*) from public.profiles),
  1::bigint,
  'user B sees only one profile'
);
select is(
  (select count(*) from public.habits),
  1::bigint,
  'user B sees only one habit'
);
select is(
  (
    select count(*)
    from public.habits
    where id = 'a0000000-0000-4000-8000-000000000022'
  ),
  0::bigint,
  'user B cannot read user A habit'
);
select is(
  (select count(*) from public.pull_sync_changes(0, 100)),
  2::bigint,
  'user B pull excludes user A changes'
);
select results_eq(
  $test$
    select server_revision
    from public.pull_sync_changes(0, 100)
    order by server_revision
  $test$,
  array[1::bigint, 2::bigint],
  'revisions are monotonic per user'
);
select throws_ok(
  $test$
    select public.apply_sync_mutation(
      'b0000000-0000-4000-8000-000000000013',
      'habit_upsert',
      'a0000000-0000-4000-8000-000000000022',
      null,
      '{"title":"Cross owner","category":"varios"}'::jsonb,
      1
    )
  $test$,
  '23505',
  null,
  'user B cannot take ownership of user A entity ID'
);

set local request.jwt.claim.sub = 'a0000000-0000-4000-8000-000000000001';

select results_eq(
  $test$
    select title
    from public.habits
    where id = 'a0000000-0000-4000-8000-000000000022'
  $test$,
  array['Caminar'::text],
  'the failed cross-owner mutation leaves user A unchanged'
);
select lives_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000017',
      'habit_delete',
      'a0000000-0000-4000-8000-000000000022',
      1,
      '{}'::jsonb,
      1
    )
  $test$,
  'user A can create a habit tombstone'
);
select ok(
  (
    select deleted_at is not null
    from public.habits
    where id = 'a0000000-0000-4000-8000-000000000022'
  ),
  'habit delete preserves a tombstone'
);
select throws_ok(
  $test$
    select public.apply_sync_mutation(
      'a0000000-0000-4000-8000-000000000018',
      'habit_upsert',
      'a0000000-0000-4000-8000-000000000022',
      1,
      '{"title":"Revived by stale update"}'::jsonb,
      1
    )
  $test$,
  '40001',
  null,
  'a stale update cannot revive a deleted habit'
);
select is(
  (select count(*) from public.pull_sync_changes(0, 100)),
  5::bigint,
  'user A pull includes the delete change'
);
select ok(
  (
    select record_data ->> 'deleted_at' is not null
    from public.pull_sync_changes(4, 100)
    where entity_type = 'habit'
  ),
  'the pull payload preserves the habit tombstone'
);
select results_eq(
  $test$
    select operation
    from public.pull_sync_changes(0, 100)
    order by server_revision
  $test$,
  array[
    'upsert'::text,
    'upsert'::text,
    'upsert'::text,
    'upsert'::text,
    'delete'::text
  ],
  'the pull stream preserves mutation order'
);

reset role;

select throws_ok(
  $test$
    insert into public.habit_schedules (
      id,
      user_id,
      habit_id,
      is_weekly,
      days_of_week,
      version,
      server_revision
    )
    values (
      'b0000000-0000-4000-8000-000000000030',
      'b0000000-0000-4000-8000-000000000002',
      'a0000000-0000-4000-8000-000000000022',
      false,
      array[]::smallint[],
      1,
      99
    )
  $test$,
  '23503',
  null,
  'composite foreign keys reject cross-owner children'
);
select throws_ok(
  $test$
    insert into public.habit_day_states (
      id,
      user_id,
      habit_id,
      local_date,
      completed,
      completed_at,
      version,
      server_revision
    )
    values (
      'a0000000-0000-4000-8000-000000000030',
      'a0000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000022',
      '2026-07-26',
      true,
      now(),
      1,
      99
    )
  $test$,
  '23505',
  null,
  'one habit has only one state per local date'
);
select results_eq(
  $test$
    select last_revision
    from public.user_sync_heads
    where user_id in (
      'a0000000-0000-4000-8000-000000000001',
      'b0000000-0000-4000-8000-000000000002'
    )
    order by user_id
  $test$,
  array[5::bigint, 2::bigint],
  'each user keeps an independent committed revision head'
);

set local role anon;
set local request.jwt.claim.sub = '';

select throws_ok(
  'select * from public.pull_sync_changes(0, 100)',
  '42501',
  null,
  'anonymous clients cannot execute pull_sync_changes'
);
select throws_ok(
  $test$
    select public.apply_sync_mutation(
      'c0000000-0000-4000-8000-000000000011',
      'profile_upsert',
      'c0000000-0000-4000-8000-000000000021',
      null,
      '{"name":"Anonymous"}'::jsonb,
      1
    )
  $test$,
  '42501',
  null,
  'anonymous clients cannot execute apply_sync_mutation'
);

select * from finish();
ROLLBACK;
