-- Local-only fixtures. These users have no password and cannot sign in.
insert into auth.users (id, email, raw_user_meta_data)
values
  (
    '10000000-0000-4000-8000-000000000001',
    'zentra-local-a@example.invalid',
    '{}'::jsonb
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    'zentra-local-b@example.invalid',
    '{}'::jsonb
  )
on conflict (id) do nothing;

select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  false
);
set role authenticated;

select public.apply_sync_mutation(
  '10000000-0000-4000-8000-000000000011',
  'profile_upsert',
  '10000000-0000-4000-8000-000000000021',
  null,
  '{"name":"Local A","avatar_emoji":"A"}'::jsonb,
  1
);

select public.apply_sync_mutation(
  '10000000-0000-4000-8000-000000000012',
  'habit_upsert',
  '10000000-0000-4000-8000-000000000022',
  null,
  '{"title":"Caminar 30 minutos","category":"movimiento"}'::jsonb,
  1
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-4000-8000-000000000002',
  false
);
set role authenticated;

select public.apply_sync_mutation(
  '20000000-0000-4000-8000-000000000011',
  'profile_upsert',
  '20000000-0000-4000-8000-000000000021',
  null,
  '{"name":"Local B","avatar_emoji":"B"}'::jsonb,
  1
);

select public.apply_sync_mutation(
  '20000000-0000-4000-8000-000000000012',
  'habit_upsert',
  '20000000-0000-4000-8000-000000000022',
  null,
  '{"title":"Tomar agua","category":"agua"}'::jsonb,
  1
);

reset role;
reset request.jwt.claim.sub;
