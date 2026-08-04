begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

select has_table(
  'public',
  'user_preferences',
  'user_preferences exists'
);
select ok(
  (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.user_preferences'::regclass
  ),
  'RLS is enabled on user_preferences'
);

insert into auth.users (id, email)
values
  (
    '91000000-0000-4000-8000-000000000001',
    'preferences-sync-a@example.invalid'
  ),
  (
    '92000000-0000-4000-8000-000000000002',
    'preferences-sync-b@example.invalid'
  );

set local role authenticated;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000001';

select lives_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000011',
      'preferences_patch',
      '91000000-0000-4000-8000-000000000001',
      null,
      '{"theme_mode":"dark"}'::jsonb,
      1
    )
  $test$,
  'user A can create portable preferences'
);
select results_eq(
  $test$
    select theme_mode
    from public.user_preferences
  $test$,
  array['dark'::text],
  'the portable theme is stored exactly'
);
select is(
  (select count(*) from public.sync_changes),
  1::bigint,
  'the preference patch creates one durable change'
);
select results_eq(
  $test$
    select record_data ->> 'theme_mode'
    from public.pull_sync_changes(0, 100)
    where entity_type = 'user_preferences'
  $test$,
  array['dark'::text],
  'incremental pull returns the portable theme'
);
select results_eq(
  $test$
    select (
      public.apply_preference_sync_mutation(
        '91000000-0000-4000-8000-000000000011',
        'preferences_patch',
        '91000000-0000-4000-8000-000000000001',
        null,
        '{}'::jsonb,
        1
      ) ->> 'server_revision'
    )::bigint
  $test$,
  array[1::bigint],
  'replaying mutation_id returns the original acknowledgement'
);
select results_eq(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000012',
      'preferences_patch',
      '91000000-0000-4000-8000-000000000001',
      0,
      '{"theme_mode":"dark"}'::jsonb,
      1
    ) ->> 'status'
  $test$,
  array['no_op'::text],
  'the same desired theme is idempotent across mutation IDs'
);
select is(
  (select count(*) from public.sync_changes),
  1::bigint,
  'a semantic preference no-op does not append a change'
);
select throws_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000013',
      'preferences_patch',
      '91000000-0000-4000-8000-000000000001',
      1,
      '{"theme_mode":"sepia"}'::jsonb,
      1
    )
  $test$,
  '22023',
  null,
  'unsupported theme modes are rejected'
);
select throws_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000014',
      'preferences_patch',
      '92000000-0000-4000-8000-000000000002',
      1,
      '{"theme_mode":"light"}'::jsonb,
      1
    )
  $test$,
  '22023',
  null,
  'preferences cannot target a different owner'
);
select throws_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000015',
      'preferences_patch',
      '91000000-0000-4000-8000-000000000001',
      0,
      '{"theme_mode":"light"}'::jsonb,
      1
    )
  $test$,
  '40001',
  null,
  'a stale preference update is rejected'
);
select lives_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '91000000-0000-4000-8000-000000000016',
      'preferences_patch',
      '91000000-0000-4000-8000-000000000001',
      1,
      '{"theme_mode":"light"}'::jsonb,
      1
    )
  $test$,
  'the current preference version can be updated'
);
select results_eq(
  $test$
    select theme_mode || ':' || version::text
    from public.user_preferences
  $test$,
  array['light:2'::text],
  'preference updates advance version and preserve content'
);

set local request.jwt.claim.sub = '92000000-0000-4000-8000-000000000002';

select is(
  (select count(*) from public.user_preferences),
  0::bigint,
  'user B cannot read user A preferences'
);
select throws_ok(
  $test$
    insert into public.user_preferences (
      user_id,
      theme_mode,
      updated_at,
      version,
      server_revision
    )
    values (
      '92000000-0000-4000-8000-000000000002',
      'dark',
      now(),
      1,
      99
    )
  $test$,
  '42501',
  null,
  'authenticated clients cannot write preferences directly'
);

reset role;
set local role anon;
select throws_ok(
  $test$
    select public.apply_preference_sync_mutation(
      '92000000-0000-4000-8000-000000000021',
      'preferences_patch',
      '92000000-0000-4000-8000-000000000002',
      null,
      '{"theme_mode":"dark"}'::jsonb,
      1
    )
  $test$,
  '42501',
  null,
  'anon cannot execute the preferences RPC'
);

select * from finish();

rollback;
