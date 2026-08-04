create schema if not exists zentra_private;

revoke all on schema zentra_private from public;

create table public.user_sync_heads (
  user_id uuid primary key references auth.users (id) on delete cascade,
  last_revision bigint not null default 0 check (last_revision >= 0),
  updated_at timestamptz not null default now()
);

create table public.sync_changes (
  user_id uuid not null references auth.users (id) on delete cascade,
  server_revision bigint not null check (server_revision > 0),
  entity_type text not null check (
    entity_type in (
      'profile',
      'habit',
      'habit_schedule',
      'habit_day_state'
    )
  ),
  entity_id uuid not null,
  operation text not null check (
    operation in ('upsert', 'archive', 'restore', 'delete')
  ),
  entity_version bigint not null check (entity_version > 0),
  changed_at timestamptz not null default now(),
  primary key (user_id, server_revision)
);

create table public.profiles (
  id uuid primary key,
  user_id uuid not null unique references auth.users (id) on delete cascade,
  name text not null check (
    char_length(btrim(name)) between 1 and 120
  ),
  avatar_emoji text check (
    avatar_emoji is null or char_length(avatar_emoji) <= 32
  ),
  talisman_id text check (
    talisman_id is null or char_length(talisman_id) <= 100
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id)
);

create table public.habits (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (
    char_length(btrim(title)) between 1 and 160
  ),
  category text not null check (
    category in ('agua', 'movimiento', 'sueno', 'foco', 'varios')
  ),
  is_one_time boolean not null default false,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id)
);

create table public.habit_schedules (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  habit_id uuid not null,
  is_weekly boolean not null default true,
  days_of_week smallint[] not null default array[]::smallint[],
  scheduled_date date,
  reminder_enabled boolean not null default false,
  reminder_hour smallint,
  reminder_minute smallint,
  time_zone text check (
    time_zone is null or char_length(time_zone) <= 100
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  unique (user_id, habit_id),
  foreign key (habit_id, user_id)
    references public.habits (id, user_id)
    on delete cascade,
  constraint habit_schedules_days_valid check (
    cardinality(days_of_week) <= 7
    and days_of_week <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]
    and array_position(days_of_week, null) is null
    and (not is_weekly or cardinality(days_of_week) > 0)
  ),
  constraint habit_schedules_reminder_hour_valid check (
    reminder_hour is null or reminder_hour between 0 and 23
  ),
  constraint habit_schedules_reminder_minute_valid check (
    reminder_minute is null or reminder_minute between 0 and 59
  ),
  constraint habit_schedules_enabled_reminder_has_time check (
    not reminder_enabled
    or (reminder_hour is not null and reminder_minute is not null)
  )
);

create table public.habit_day_states (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  habit_id uuid not null,
  local_date date not null,
  completed boolean not null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  unique (user_id, habit_id, local_date),
  foreign key (habit_id, user_id)
    references public.habits (id, user_id)
    on delete cascade,
  constraint habit_day_states_completion_time_valid check (
    (completed and completed_at is not null)
    or (not completed and completed_at is null)
  )
);

create table public.processed_mutations (
  user_id uuid not null references auth.users (id) on delete cascade,
  mutation_id uuid not null,
  operation text not null,
  entity_type text not null,
  entity_id uuid not null,
  response jsonb not null,
  processed_at timestamptz not null default now(),
  primary key (user_id, mutation_id)
);

create index habits_user_active_idx
  on public.habits (user_id, is_archived, deleted_at);

create index habit_schedules_user_active_idx
  on public.habit_schedules (user_id, deleted_at);

create index habit_day_states_user_date_idx
  on public.habit_day_states (user_id, local_date);

create index sync_changes_entity_idx
  on public.sync_changes (user_id, entity_type, entity_id);

alter table public.user_sync_heads enable row level security;
alter table public.sync_changes enable row level security;
alter table public.profiles enable row level security;
alter table public.habits enable row level security;
alter table public.habit_schedules enable row level security;
alter table public.habit_day_states enable row level security;
alter table public.processed_mutations enable row level security;

create policy user_sync_heads_select_own
  on public.user_sync_heads
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy sync_changes_select_own
  on public.sync_changes
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy profiles_select_own
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy habits_select_own
  on public.habits
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy habit_schedules_select_own
  on public.habit_schedules
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy habit_day_states_select_own
  on public.habit_day_states
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy processed_mutations_select_own
  on public.processed_mutations
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.user_sync_heads from anon, authenticated;
revoke all on table public.sync_changes from anon, authenticated;
revoke all on table public.profiles from anon, authenticated;
revoke all on table public.habits from anon, authenticated;
revoke all on table public.habit_schedules from anon, authenticated;
revoke all on table public.habit_day_states from anon, authenticated;
revoke all on table public.processed_mutations from anon, authenticated;

grant select on table public.user_sync_heads to authenticated;
grant select on table public.sync_changes to authenticated;
grant select on table public.profiles to authenticated;
grant select on table public.habits to authenticated;
grant select on table public.habit_schedules to authenticated;
grant select on table public.habit_day_states to authenticated;

create or replace function zentra_private.next_sync_revision(
  p_user_id uuid
)
returns bigint
language plpgsql
set search_path = ''
as $$
declare
  v_revision bigint;
begin
  update public.user_sync_heads
  set
    last_revision = last_revision + 1,
    updated_at = now()
  where user_id = p_user_id
  returning last_revision into v_revision;

  if v_revision is null then
    raise exception 'sync head is not locked'
      using errcode = '55000';
  end if;

  return v_revision;
end;
$$;

create or replace function zentra_private.assert_base_version(
  p_base_version bigint,
  p_current_version bigint
)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_base_version is distinct from p_current_version then
    raise exception 'sync conflict'
      using errcode = '40001';
  end if;
end;
$$;

revoke all on function zentra_private.next_sync_revision(uuid) from public;
revoke all on function zentra_private.assert_base_version(bigint, bigint)
  from public;

create or replace function public.apply_sync_mutation(
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
  v_entity_id uuid := p_entity_id;
  v_entity_type text;
  v_change_operation text := 'upsert';
  v_status text := 'applied';
  v_record jsonb;
  v_response jsonb;
  v_processed public.processed_mutations%rowtype;
  v_profile public.profiles%rowtype;
  v_habit public.habits%rowtype;
  v_schedule public.habit_schedules%rowtype;
  v_day_state public.habit_day_states%rowtype;
  v_habit_id uuid;
  v_local_date date;
  v_completed boolean;
  v_days smallint[];
  v_schedule_found boolean;
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

  if p_operation = 'profile_upsert' then
    v_entity_type := 'profile';

    select *
    into v_profile
    from public.profiles
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      if nullif(btrim(v_payload ->> 'name'), '') is null then
        raise exception 'profile name is required'
          using errcode = '22023';
      end if;

      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.profiles (
        id,
        user_id,
        name,
        avatar_emoji,
        talisman_id,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        btrim(v_payload ->> 'name'),
        nullif(v_payload ->> 'avatar_emoji', ''),
        nullif(v_payload ->> 'talisman_id', ''),
        v_now,
        v_now,
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_profile;
    else
      if v_profile.deleted_at is not null then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      perform zentra_private.assert_base_version(
        p_base_version,
        v_profile.version
      );

      if v_payload ? 'name'
        and nullif(btrim(v_payload ->> 'name'), '') is null
      then
        raise exception 'profile name cannot be empty'
          using errcode = '22023';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.profiles
      set
        name = case
          when v_payload ? 'name' then btrim(v_payload ->> 'name')
          else name
        end,
        avatar_emoji = case
          when v_payload ? 'avatar_emoji'
            then nullif(v_payload ->> 'avatar_emoji', '')
          else avatar_emoji
        end,
        talisman_id = case
          when v_payload ? 'talisman_id'
            then nullif(v_payload ->> 'talisman_id', '')
          else talisman_id
        end,
        updated_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_profile.id
        and user_id = v_user_id
      returning * into v_profile;
    end if;

    v_entity_id := v_profile.id;
    v_version := v_profile.version;
    v_record := to_jsonb(v_profile) - 'user_id';
  elsif p_operation = 'habit_upsert' then
    v_entity_type := 'habit';

    select *
    into v_habit
    from public.habits
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      if nullif(btrim(v_payload ->> 'title'), '') is null then
        raise exception 'habit title is required'
          using errcode = '22023';
      end if;

      if coalesce(v_payload ->> 'category', '') not in (
        'agua',
        'movimiento',
        'sueno',
        'foco',
        'varios'
      ) then
        raise exception 'habit category is invalid'
          using errcode = '22023';
      end if;

      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.habits (
        id,
        user_id,
        title,
        category,
        is_one_time,
        is_archived,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        btrim(v_payload ->> 'title'),
        v_payload ->> 'category',
        coalesce((v_payload ->> 'is_one_time')::boolean, false),
        false,
        v_now,
        v_now,
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_habit;
    else
      if v_habit.deleted_at is not null then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      perform zentra_private.assert_base_version(
        p_base_version,
        v_habit.version
      );

      if v_payload ? 'title'
        and nullif(btrim(v_payload ->> 'title'), '') is null
      then
        raise exception 'habit title cannot be empty'
          using errcode = '22023';
      end if;

      if v_payload ? 'category'
        and (v_payload ->> 'category') not in (
          'agua',
          'movimiento',
          'sueno',
          'foco',
          'varios'
        )
      then
        raise exception 'habit category is invalid'
          using errcode = '22023';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.habits
      set
        title = case
          when v_payload ? 'title' then btrim(v_payload ->> 'title')
          else title
        end,
        category = case
          when v_payload ? 'category' then v_payload ->> 'category'
          else category
        end,
        is_one_time = case
          when v_payload ? 'is_one_time'
            then (v_payload ->> 'is_one_time')::boolean
          else is_one_time
        end,
        updated_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_habit.id
        and user_id = v_user_id
      returning * into v_habit;
    end if;

    v_entity_id := v_habit.id;
    v_version := v_habit.version;
    v_record := to_jsonb(v_habit) - 'user_id';
  elsif p_operation in ('habit_archive', 'habit_restore', 'habit_delete') then
    v_entity_type := 'habit';

    select *
    into v_habit
    from public.habits
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      raise exception 'habit does not exist'
        using errcode = 'P0002';
    end if;

    if p_operation = 'habit_archive' and v_habit.deleted_at is not null then
      raise exception 'sync conflict'
        using errcode = '40001';
    end if;

    if (
      p_operation = 'habit_archive'
      and v_habit.is_archived
    ) or (
      p_operation = 'habit_restore'
      and not v_habit.is_archived
      and v_habit.deleted_at is null
    ) or (
      p_operation = 'habit_delete'
      and v_habit.deleted_at is not null
    ) then
      v_status := 'no_op';
      v_revision := v_habit.server_revision;
    else
      perform zentra_private.assert_base_version(
        p_base_version,
        v_habit.version
      );

      v_revision := zentra_private.next_sync_revision(v_user_id);

      if p_operation = 'habit_archive' then
        v_change_operation := 'archive';

        update public.habits
        set
          is_archived = true,
          updated_at = v_now,
          version = version + 1,
          server_revision = v_revision,
          schema_version = p_schema_version
        where id = v_habit.id
          and user_id = v_user_id
        returning * into v_habit;
      elsif p_operation = 'habit_restore' then
        v_change_operation := 'restore';

        update public.habits
        set
          is_archived = false,
          deleted_at = null,
          updated_at = v_now,
          version = version + 1,
          server_revision = v_revision,
          schema_version = p_schema_version
        where id = v_habit.id
          and user_id = v_user_id
        returning * into v_habit;
      else
        v_change_operation := 'delete';

        update public.habits
        set
          is_archived = true,
          deleted_at = v_now,
          updated_at = v_now,
          version = version + 1,
          server_revision = v_revision,
          schema_version = p_schema_version
        where id = v_habit.id
          and user_id = v_user_id
        returning * into v_habit;
      end if;
    end if;

    v_entity_id := v_habit.id;
    v_version := v_habit.version;
    v_record := to_jsonb(v_habit) - 'user_id';
  elsif p_operation = 'habit_schedule_set' then
    v_entity_type := 'habit_schedule';

    if not v_payload ? 'habit_id' then
      raise exception 'habit_id is required'
        using errcode = '22023';
    end if;

    v_habit_id := (v_payload ->> 'habit_id')::uuid;

    select *
    into v_habit
    from public.habits
    where id = v_habit_id
      and user_id = v_user_id
      and deleted_at is null;

    if not found then
      raise exception 'habit does not exist'
        using errcode = 'P0002';
    end if;

    select *
    into v_schedule
    from public.habit_schedules
    where user_id = v_user_id
      and (
        id = p_entity_id
        or habit_id = v_habit_id
      )
    order by (id = p_entity_id) desc
    limit 1
    for update;

    v_schedule_found := found;

    if v_payload ? 'days_of_week' then
      if jsonb_typeof(v_payload -> 'days_of_week') <> 'array' then
        raise exception 'days_of_week must be an array'
          using errcode = '22023';
      end if;

      select coalesce(
        array_agg(distinct value::smallint order by value::smallint),
        array[]::smallint[]
      )
      into v_days
      from jsonb_array_elements_text(
        v_payload -> 'days_of_week'
      ) as requested_day(value);
    elsif v_schedule_found then
      v_days := v_schedule.days_of_week;
    else
      v_days := array[1, 2, 3, 4, 5, 6, 7]::smallint[];
    end if;

    if not v_schedule_found then
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.habit_schedules (
        id,
        user_id,
        habit_id,
        is_weekly,
        days_of_week,
        scheduled_date,
        reminder_enabled,
        reminder_hour,
        reminder_minute,
        time_zone,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_habit_id,
        coalesce((v_payload ->> 'is_weekly')::boolean, true),
        v_days,
        case
          when v_payload ? 'scheduled_date'
            then nullif(v_payload ->> 'scheduled_date', '')::date
          else null
        end,
        coalesce((v_payload ->> 'reminder_enabled')::boolean, false),
        nullif(v_payload ->> 'reminder_hour', '')::smallint,
        nullif(v_payload ->> 'reminder_minute', '')::smallint,
        nullif(v_payload ->> 'time_zone', ''),
        v_now,
        v_now,
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_schedule;
    else
      if v_schedule.deleted_at is not null then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      perform zentra_private.assert_base_version(
        p_base_version,
        v_schedule.version
      );

      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.habit_schedules
      set
        is_weekly = case
          when v_payload ? 'is_weekly'
            then (v_payload ->> 'is_weekly')::boolean
          else is_weekly
        end,
        days_of_week = v_days,
        scheduled_date = case
          when v_payload ? 'scheduled_date'
            then nullif(v_payload ->> 'scheduled_date', '')::date
          else scheduled_date
        end,
        reminder_enabled = case
          when v_payload ? 'reminder_enabled'
            then (v_payload ->> 'reminder_enabled')::boolean
          else reminder_enabled
        end,
        reminder_hour = case
          when v_payload ? 'reminder_hour'
            then nullif(v_payload ->> 'reminder_hour', '')::smallint
          else reminder_hour
        end,
        reminder_minute = case
          when v_payload ? 'reminder_minute'
            then nullif(v_payload ->> 'reminder_minute', '')::smallint
          else reminder_minute
        end,
        time_zone = case
          when v_payload ? 'time_zone'
            then nullif(v_payload ->> 'time_zone', '')
          else time_zone
        end,
        updated_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_schedule.id
        and user_id = v_user_id
      returning * into v_schedule;
    end if;

    v_entity_id := v_schedule.id;
    v_version := v_schedule.version;
    v_record := to_jsonb(v_schedule) - 'user_id';
  elsif p_operation = 'habit_completion_set' then
    v_entity_type := 'habit_day_state';

    if not v_payload ? 'habit_id'
      or not v_payload ? 'local_date'
      or not v_payload ? 'completed'
    then
      raise exception 'habit_id, local_date and completed are required'
        using errcode = '22023';
    end if;

    v_habit_id := (v_payload ->> 'habit_id')::uuid;
    v_local_date := (v_payload ->> 'local_date')::date;
    v_completed := (v_payload ->> 'completed')::boolean;

    select *
    into v_habit
    from public.habits
    where id = v_habit_id
      and user_id = v_user_id
      and deleted_at is null;

    if not found then
      raise exception 'habit does not exist'
        using errcode = 'P0002';
    end if;

    select *
    into v_day_state
    from public.habit_day_states
    where user_id = v_user_id
      and habit_id = v_habit_id
      and local_date = v_local_date
    for update;

    if not found then
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.habit_day_states (
        id,
        user_id,
        habit_id,
        local_date,
        completed,
        completed_at,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_habit_id,
        v_local_date,
        v_completed,
        case when v_completed then v_now else null end,
        v_now,
        v_now,
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_day_state;
    elsif v_day_state.completed = v_completed then
      v_status := 'no_op';
      v_revision := v_day_state.server_revision;
    else
      perform zentra_private.assert_base_version(
        p_base_version,
        v_day_state.version
      );

      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.habit_day_states
      set
        completed = v_completed,
        completed_at = case when v_completed then v_now else null end,
        updated_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_day_state.id
        and user_id = v_user_id
      returning * into v_day_state;
    end if;

    v_entity_id := v_day_state.id;
    v_version := v_day_state.version;
    v_record := to_jsonb(v_day_state) - 'user_id';
  else
    raise exception 'unsupported sync operation'
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
      v_entity_id,
      v_change_operation,
      v_version,
      v_now
    );
  end if;

  v_response := jsonb_build_object(
    'mutation_id', p_mutation_id,
    'status', v_status,
    'entity_type', v_entity_type,
    'entity_id', v_entity_id,
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
    v_entity_id,
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
    end as record_data
  from public.sync_changes as change
  where change.user_id = v_user_id
    and change.server_revision > p_after_revision
  order by change.server_revision
  limit least(p_limit, 500);
end;
$$;

revoke execute on function public.apply_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) from public, anon;

revoke execute on function public.pull_sync_changes(
  bigint,
  integer
) from public, anon;

grant execute on function public.apply_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) to authenticated, service_role;

grant execute on function public.pull_sync_changes(
  bigint,
  integer
) to authenticated, service_role;

comment on function public.apply_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) is 'Applies one authenticated, idempotent Zentra sync mutation.';

comment on function public.pull_sync_changes(
  bigint,
  integer
) is 'Returns ordered Zentra changes for the authenticated user.';
