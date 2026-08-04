BEGIN;

create extension if not exists pgtap with schema extensions;

select plan(34);

select has_table('public', 'notes', 'notes exists');
select has_table(
  'public',
  'note_reminders',
  'note_reminders exists'
);
select has_table(
  'public',
  'note_reviews',
  'note_reviews exists'
);
select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class
    where oid in (
      'public.notes'::regclass,
      'public.note_reminders'::regclass,
      'public.note_reviews'::regclass
    )
      and relrowsecurity
  ),
  3,
  'RLS is enabled on every public note sync table'
);

insert into auth.users (id, email)
values
  (
    'c0000000-0000-4000-8000-000000000001',
    'note-sync-a@example.invalid'
  ),
  (
    'd0000000-0000-4000-8000-000000000002',
    'note-sync-b@example.invalid'
  );

set local role authenticated;
set local request.jwt.claim.sub = 'c0000000-0000-4000-8000-000000000001';

select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000011',
      'note_upsert',
      'c0000000-0000-4000-8000-000000000021',
      null,
      '{
        "title":"Idea multidispositivo",
        "body":"Texto original",
        "category":"Ideas",
        "accent_key":"lavender",
        "is_pinned":true,
        "tags":["gate-7","nube"],
        "format_version":1,
        "created_at":"2026-07-27T12:00:00Z",
        "updated_at":"2026-07-27T12:00:00Z"
      }'::jsonb,
      1
    )
  $test$,
  'user A can create a note through the note mutation RPC'
);

select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000012',
      'note_reminder_set',
      'c0000000-0000-4000-8000-000000000022',
      null,
      '{
        "note_id":"c0000000-0000-4000-8000-000000000021",
        "scheduled_at_utc":"2026-07-28T14:00:00Z",
        "timezone_name":"America/Mexico_City",
        "status":"scheduled",
        "privacy_mode":"titleOnly",
        "created_at":"2026-07-27T12:01:00Z",
        "updated_at":"2026-07-27T12:01:00Z",
        "deleted":false
      }'::jsonb,
      1
    )
  $test$,
  'user A can create a note reminder'
);

select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000013',
      'note_review_add',
      'c0000000-0000-4000-8000-000000000023',
      null,
      '{
        "note_id":"c0000000-0000-4000-8000-000000000021",
        "reviewed_at":"2026-07-27T13:00:00Z",
        "focus_session_id":"focus-25",
        "outcome":"focusCompleted"
      }'::jsonb,
      1
    )
  $test$,
  'user A can append a note review'
);

select is((select count(*) from public.notes), 1::bigint, 'one note exists');
select is(
  (select count(*) from public.note_reminders),
  1::bigint,
  'one note reminder exists'
);
select is(
  (select count(*) from public.note_reviews),
  1::bigint,
  'one note review exists'
);
select is(
  (
    select count(*)
    from public.sync_changes
    where entity_type in ('note', 'note_reminder', 'note_review')
  ),
  3::bigint,
  'three applied note mutations create three durable changes'
);
select is(
  (
    select count(*)
    from public.pull_sync_changes(0, 100)
    where record_data is not null
  ),
  3::bigint,
  'every note change includes its current record'
);
select results_eq(
  $test$
    select unnest(tags)
    from public.notes
    where id = 'c0000000-0000-4000-8000-000000000021'
  $test$,
  array['gate-7'::text, 'nube'::text],
  'note tags round-trip as text values'
);
select results_eq(
  $test$
    select (
      public.apply_note_sync_mutation(
        'c0000000-0000-4000-8000-000000000011',
        'note_upsert',
        'c0000000-0000-4000-8000-000000000021',
        null,
        '{"title":"ignored","body":"ignored"}'::jsonb,
        1
      ) ->> 'server_revision'
    )::bigint
  $test$,
  array[1::bigint],
  'replaying mutation_id returns the original note acknowledgement'
);
select is(
  (select count(*) from public.sync_changes),
  3::bigint,
  'replaying a note mutation does not append a change'
);
select results_eq(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000014',
      'note_review_add',
      'c0000000-0000-4000-8000-000000000024',
      null,
      '{
        "note_id":"c0000000-0000-4000-8000-000000000021",
        "reviewed_at":"2026-07-27T13:01:00Z",
        "focus_session_id":"focus-25",
        "outcome":"focusCompleted"
      }'::jsonb,
      1
    ) ->> 'status'
  $test$,
  array['no_op'::text],
  'a repeated focus review is idempotent across mutation IDs'
);
select results_eq(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000014',
      'note_review_add',
      'c0000000-0000-4000-8000-000000000024',
      null,
      '{}'::jsonb,
      1
    ) ->> 'entity_id'
  $test$,
  array['c0000000-0000-4000-8000-000000000023'::text],
  'a repeated focus review returns the canonical review ID'
);
select is(
  (select count(*) from public.sync_changes),
  3::bigint,
  'a repeated focus review does not append a change'
);
select throws_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000015',
      'note_upsert',
      'c0000000-0000-4000-8000-000000000021',
      0,
      '{"body":"stale edit"}'::jsonb,
      1
    )
  $test$,
  '40001',
  null,
  'a stale note edit is rejected for conflict reconciliation'
);
select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000016',
      'note_archive',
      'c0000000-0000-4000-8000-000000000021',
      1,
      '{}'::jsonb,
      1
    )
  $test$,
  'a note can be archived'
);
select ok(
  (
    select is_archived and archived_at is not null
    from public.notes
    where id = 'c0000000-0000-4000-8000-000000000021'
  ),
  'archive state keeps its timestamp'
);
select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000017',
      'note_restore',
      'c0000000-0000-4000-8000-000000000021',
      2,
      '{}'::jsonb,
      1
    )
  $test$,
  'an archived note can be restored'
);
select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000018',
      'note_reminder_set',
      'c0000000-0000-4000-8000-000000000022',
      1,
      '{
        "note_id":"c0000000-0000-4000-8000-000000000021",
        "deleted":true
      }'::jsonb,
      1
    )
  $test$,
  'a note reminder can be cancelled with a tombstone'
);
select ok(
  (
    select deleted_at is not null and status = 'cancelled'
    from public.note_reminders
    where id = 'c0000000-0000-4000-8000-000000000022'
  ),
  'reminder deletion preserves its tombstone'
);
select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000019',
      'note_upsert',
      'c0000000-0000-4000-8000-000000000021',
      3,
      '{
        "body":"Texto actualizado en otro dispositivo",
        "updated_at":"2026-07-27T14:00:00Z"
      }'::jsonb,
      1
    )
  $test$,
  'a note body can be updated at the current version'
);
select results_eq(
  $test$
    select body
    from public.notes
    where id = 'c0000000-0000-4000-8000-000000000021'
  $test$,
  array['Texto actualizado en otro dispositivo'::text],
  'the current note body is preserved verbatim'
);
select lives_ok(
  $test$
    select public.apply_note_sync_mutation(
      'c0000000-0000-4000-8000-000000000020',
      'note_delete',
      'c0000000-0000-4000-8000-000000000021',
      4,
      '{}'::jsonb,
      1
    )
  $test$,
  'a note can be soft-deleted'
);
select ok(
  (
    select deleted_at is not null and is_archived
    from public.notes
    where id = 'c0000000-0000-4000-8000-000000000021'
  ),
  'note deletion preserves its tombstone'
);
select is(
  (select count(*) from public.pull_sync_changes(0, 100)),
  8::bigint,
  'the note pull stream includes every applied lifecycle change'
);

set local request.jwt.claim.sub = 'd0000000-0000-4000-8000-000000000002';

select is(
  (select count(*) from public.notes),
  0::bigint,
  'user B cannot read user A notes'
);
select throws_ok(
  $test$
    select public.apply_note_sync_mutation(
      'd0000000-0000-4000-8000-000000000011',
      'note_upsert',
      'c0000000-0000-4000-8000-000000000021',
      null,
      '{"title":"cross owner","body":"blocked"}'::jsonb,
      1
    )
  $test$,
  '23505',
  null,
  'user B cannot take ownership of user A note ID'
);
select throws_ok(
  $test$
    select public.apply_note_sync_mutation(
      'd0000000-0000-4000-8000-000000000012',
      'note_reminder_set',
      'd0000000-0000-4000-8000-000000000022',
      null,
      '{
        "note_id":"c0000000-0000-4000-8000-000000000021",
        "scheduled_at_utc":"2026-07-29T12:00:00Z",
        "timezone_name":"UTC",
        "status":"scheduled",
        "privacy_mode":"hidden"
      }'::jsonb,
      1
    )
  $test$,
  'P0002',
  null,
  'user B cannot attach a reminder to user A note'
);
select throws_ok(
  $test$
    insert into public.notes (
      id,
      user_id,
      title,
      body,
      accent_key,
      version,
      server_revision
    )
    values (
      'd0000000-0000-4000-8000-000000000099',
      'd0000000-0000-4000-8000-000000000002',
      'Direct write',
      'Blocked',
      'mint',
      1,
      99
    )
  $test$,
  '42501',
  null,
  'authenticated clients cannot bypass the note mutation RPC'
);

reset role;
set local role anon;
set local request.jwt.claim.sub = '';

select throws_ok(
  $test$
    select public.apply_note_sync_mutation(
      'd0000000-0000-4000-8000-000000000099',
      'note_upsert',
      'd0000000-0000-4000-8000-000000000099',
      null,
      '{"title":"anonymous","body":"blocked"}'::jsonb,
      1
    )
  $test$,
  '42501',
  null,
  'anonymous clients cannot execute note mutations'
);

select * from finish();

ROLLBACK;
