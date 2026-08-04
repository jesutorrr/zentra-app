alter table public.sync_changes
  drop constraint sync_changes_entity_type_check;

alter table public.sync_changes
  add constraint sync_changes_entity_type_check check (
    entity_type in (
      'profile',
      'habit',
      'habit_schedule',
      'habit_day_state',
      'completed_task',
      'note',
      'note_reminder',
      'note_review',
      'focus_session'
    )
  );

create table public.completed_tasks (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) <= 160),
  category text not null check (
    category in ('agua', 'movimiento', 'sueno', 'foco', 'varios')
  ),
  completed_at timestamptz not null,
  was_one_time boolean not null default false,
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id)
);

create table public.focus_sessions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) <= 160),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  cycles_completed integer not null check (cycles_completed > 0),
  total_minutes integer not null check (total_minutes > 0),
  is_completed boolean not null check (is_completed),
  note_id uuid,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  constraint focus_sessions_time_valid check (ended_at >= started_at)
);

create index completed_tasks_user_completed_idx
  on public.completed_tasks (user_id, completed_at desc, deleted_at);

create index focus_sessions_user_started_idx
  on public.focus_sessions (user_id, started_at desc);

alter table public.completed_tasks enable row level security;
alter table public.focus_sessions enable row level security;

create policy completed_tasks_select_own
  on public.completed_tasks
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy focus_sessions_select_own
  on public.focus_sessions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.completed_tasks from anon, authenticated;
revoke all on table public.focus_sessions from anon, authenticated;

grant select on table public.completed_tasks to authenticated;
grant select on table public.focus_sessions to authenticated;

create or replace function public.apply_activity_sync_mutation(
  p_mutation_id uuid,
  p_operation text,
  p_entity_id uuid,
  p_base_version bigint default null,
  p_payload jsonb default '{}'::jsonb,
  p_schema_version integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_now timestamptz := now();
  v_revision bigint;
  v_version bigint;
  v_entity_type text;
  v_change_operation text := 'upsert';
  v_status text := 'applied';
  v_record jsonb;
  v_response jsonb;
  v_processed public.processed_mutations%rowtype;
  v_task public.completed_tasks%rowtype;
  v_session public.focus_sessions%rowtype;
  v_started_at timestamptz;
  v_ended_at timestamptz;
  v_cycles integer;
  v_minutes integer;
  v_note_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required'
      using errcode = '42501';
  end if;

  if p_mutation_id is null or p_entity_id is null then
    raise exception 'mutation_id and entity_id are required'
      using errcode = '22023';
  end if;

  if p_schema_version is null or p_schema_version < 1 then
    raise exception 'schema_version must be positive'
      using errcode = '22023';
  end if;

  if jsonb_typeof(v_payload) <> 'object' then
    raise exception 'payload must be a JSON object'
      using errcode = '22023';
  end if;

  insert into public.user_sync_heads (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  perform 1
  from public.user_sync_heads
  where user_id = v_user_id
  for update;

  select *
  into v_processed
  from public.processed_mutations
  where user_id = v_user_id
    and mutation_id = p_mutation_id;

  if found then
    return v_processed.response;
  end if;

  if p_operation = 'completed_task_upsert' then
    v_entity_type := 'completed_task';

    if not (v_payload ? 'title')
      or coalesce(v_payload ->> 'category', '') not in (
        'agua',
        'movimiento',
        'sueno',
        'foco',
        'varios'
      )
      or not (v_payload ? 'completed_at')
    then
      raise exception 'invalid completed task payload'
        using errcode = '22023';
    end if;

    select *
    into v_task
    from public.completed_tasks
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.completed_tasks (
        id,
        user_id,
        title,
        category,
        completed_at,
        was_one_time,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_payload ->> 'title',
        v_payload ->> 'category',
        (v_payload ->> 'completed_at')::timestamptz,
        coalesce((v_payload ->> 'was_one_time')::boolean, false),
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_task;
    else
      perform zentra_private.assert_base_version(
        p_base_version,
        v_task.version
      );
      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.completed_tasks
      set
        title = v_payload ->> 'title',
        category = v_payload ->> 'category',
        completed_at = (v_payload ->> 'completed_at')::timestamptz,
        was_one_time = coalesce(
          (v_payload ->> 'was_one_time')::boolean,
          false
        ),
        deleted_at = null,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_task.id
        and user_id = v_user_id
      returning * into v_task;
    end if;

    v_version := v_task.version;
    v_record := to_jsonb(v_task) - 'user_id';
  elsif p_operation = 'completed_task_delete' then
    v_entity_type := 'completed_task';
    v_change_operation := 'delete';

    select *
    into v_task
    from public.completed_tasks
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      raise exception 'completed task does not exist'
        using errcode = 'P0002';
    end if;

    if v_task.deleted_at is not null then
      v_status := 'no_op';
      v_revision := v_task.server_revision;
    else
      perform zentra_private.assert_base_version(
        p_base_version,
        v_task.version
      );
      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.completed_tasks
      set
        deleted_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_task.id
        and user_id = v_user_id
      returning * into v_task;
    end if;

    v_version := v_task.version;
    v_record := to_jsonb(v_task) - 'user_id';
  elsif p_operation = 'focus_session_complete' then
    v_entity_type := 'focus_session';
    v_started_at := nullif(v_payload ->> 'started_at', '')::timestamptz;
    v_ended_at := nullif(v_payload ->> 'ended_at', '')::timestamptz;
    v_cycles := coalesce(
      (v_payload ->> 'cycles_completed')::integer,
      0
    );
    v_minutes := coalesce((v_payload ->> 'total_minutes')::integer, 0);
    v_note_id := nullif(v_payload ->> 'note_id', '')::uuid;

    if v_started_at is null
      or v_ended_at is null
      or v_ended_at < v_started_at
      or v_cycles < 1
      or v_minutes < 1
      or coalesce((v_payload ->> 'is_completed')::boolean, false) is false
    then
      raise exception 'invalid completed focus session'
        using errcode = '22023';
    end if;

    if v_note_id is not null and exists (
      select 1
      from public.notes
      where id = v_note_id
        and user_id <> v_user_id
    ) then
      raise exception 'linked note belongs to another user'
        using errcode = '23503';
    end if;

    select *
    into v_session
    from public.focus_sessions
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if found
      and v_session.name = coalesce(v_payload ->> 'name', '')
      and v_session.started_at = v_started_at
      and v_session.ended_at = v_ended_at
      and v_session.cycles_completed = v_cycles
      and v_session.total_minutes = v_minutes
      and v_session.note_id is not distinct from v_note_id
    then
      v_status := 'no_op';
      v_revision := v_session.server_revision;
    elsif not found then
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;
      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.focus_sessions (
        id,
        user_id,
        name,
        started_at,
        ended_at,
        cycles_completed,
        total_minutes,
        is_completed,
        note_id,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        coalesce(v_payload ->> 'name', ''),
        v_started_at,
        v_ended_at,
        v_cycles,
        v_minutes,
        true,
        v_note_id,
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_session;
    else
      perform zentra_private.assert_base_version(
        p_base_version,
        v_session.version
      );
      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.focus_sessions
      set
        name = coalesce(v_payload ->> 'name', ''),
        started_at = v_started_at,
        ended_at = v_ended_at,
        cycles_completed = v_cycles,
        total_minutes = v_minutes,
        is_completed = true,
        note_id = v_note_id,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_session.id
        and user_id = v_user_id
      returning * into v_session;
    end if;

    v_version := v_session.version;
    v_record := to_jsonb(v_session) - 'user_id';
  else
    raise exception 'unsupported activity sync operation'
      using errcode = '22023';
  end if;

  if v_status = 'applied' then
    insert into public.sync_changes (
      user_id,
      server_revision,
      entity_type,
      entity_id,
      operation,
      entity_version,
      changed_at
    )
    values (
      v_user_id,
      v_revision,
      v_entity_type,
      p_entity_id,
      v_change_operation,
      v_version,
      v_now
    );
  end if;

  v_response := jsonb_build_object(
    'mutation_id', p_mutation_id,
    'status', v_status,
    'entity_type', v_entity_type,
    'entity_id', p_entity_id,
    'operation', p_operation,
    'version', v_version,
    'server_revision', v_revision,
    'record', v_record
  );

  insert into public.processed_mutations (
    user_id,
    mutation_id,
    operation,
    entity_type,
    entity_id,
    response
  )
  values (
    v_user_id,
    p_mutation_id,
    p_operation,
    v_entity_type,
    p_entity_id,
    v_response
  );

  return v_response;
end;
$$;

create or replace function public.pull_sync_changes(
  p_after_revision bigint default 0,
  p_limit integer default 200
)
returns table (
  server_revision bigint,
  entity_type text,
  entity_id uuid,
  operation text,
  entity_version bigint,
  record_data jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'authentication required'
      using errcode = '42501';
  end if;

  if p_after_revision is null
    or p_limit is null
    or p_after_revision < 0
    or p_limit < 1
  then
    raise exception 'invalid pull cursor or limit'
      using errcode = '22023';
  end if;

  return query
  select
    change.server_revision,
    change.entity_type,
    change.entity_id,
    change.operation,
    change.entity_version,
    case change.entity_type
      when 'profile' then (
        select to_jsonb(profile_row) - 'user_id'
        from public.profiles as profile_row
        where profile_row.user_id = v_user_id
          and profile_row.id = change.entity_id
      )
      when 'habit' then (
        select to_jsonb(habit_row) - 'user_id'
        from public.habits as habit_row
        where habit_row.user_id = v_user_id
          and habit_row.id = change.entity_id
      )
      when 'habit_schedule' then (
        select to_jsonb(schedule_row) - 'user_id'
        from public.habit_schedules as schedule_row
        where schedule_row.user_id = v_user_id
          and schedule_row.id = change.entity_id
      )
      when 'habit_day_state' then (
        select to_jsonb(day_state_row) - 'user_id'
        from public.habit_day_states as day_state_row
        where day_state_row.user_id = v_user_id
          and day_state_row.id = change.entity_id
      )
      when 'completed_task' then (
        select to_jsonb(task_row) - 'user_id'
        from public.completed_tasks as task_row
        where task_row.user_id = v_user_id
          and task_row.id = change.entity_id
      )
      when 'note' then (
        select to_jsonb(note_row) - 'user_id'
        from public.notes as note_row
        where note_row.user_id = v_user_id
          and note_row.id = change.entity_id
      )
      when 'note_reminder' then (
        select to_jsonb(reminder_row) - 'user_id'
        from public.note_reminders as reminder_row
        where reminder_row.user_id = v_user_id
          and reminder_row.id = change.entity_id
      )
      when 'note_review' then (
        select to_jsonb(review_row) - 'user_id'
        from public.note_reviews as review_row
        where review_row.user_id = v_user_id
          and review_row.id = change.entity_id
      )
      when 'focus_session' then (
        select to_jsonb(session_row) - 'user_id'
        from public.focus_sessions as session_row
        where session_row.user_id = v_user_id
          and session_row.id = change.entity_id
      )
    end as record_data
  from public.sync_changes as change
  where change.user_id = v_user_id
    and change.server_revision > p_after_revision
  order by change.server_revision
  limit least(p_limit, 500);
end;
$$;

revoke execute on function public.apply_activity_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) from public, anon;

grant execute on function public.apply_activity_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) to authenticated, service_role;
