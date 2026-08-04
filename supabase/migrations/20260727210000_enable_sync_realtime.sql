-- Realtime is an accelerator only. Clients receive a content-free wake-up and
-- then recover durable state through pull_sync_changes(server_revision).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'sync_changes'
  ) then
    alter publication supabase_realtime add table public.sync_changes;
  end if;
end;
$$;
