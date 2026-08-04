begin;

select plan(1);

select ok(
  exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'sync_changes'
  ),
  'sync_changes publishes Realtime wake signals'
);

select * from finish();

rollback;
