alter table public.sync_changes
  drop constraint sync_changes_entity_type_check;

alter table public.sync_changes
  add constraint sync_changes_entity_type_check check (
    entity_type in (
      'profile',
      'habit',
      'habit_schedule',
      'habit_day_state',
      'note',
      'note_reminder',
      'note_review'
    )
  );

create table public.notes (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) <= 200),
  body text not null check (char_length(body) <= 1000000),
  category text check (
    category is null or char_length(category) <= 80
  ),
  accent_key text not null default 'mint' check (
    char_length(accent_key) between 1 and 40
  ),
  is_pinned boolean not null default false,
  is_archived boolean not null default false,
  archived_at timestamptz,
  tags text[] not null default array[]::text[],
  format_version integer not null default 1 check (format_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  constraint notes_archive_time_valid check (
    (is_archived and archived_at is not null)
    or (not is_archived and archived_at is null)
  ),
  constraint notes_tags_valid check (
    cardinality(tags) <= 50 and array_position(tags, null) is null
  )
);

create table public.note_reminders (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  note_id uuid not null,
  scheduled_at_utc timestamptz not null,
  timezone_name text not null check (
    char_length(timezone_name) between 1 and 100
  ),
  status text not null check (
    status in (
      'scheduled',
      'delivered',
      'snoozed',
      'completed',
      'cancelled',
      'failed'
    )
  ),
  privacy_mode text not null check (
    privacy_mode in ('titleAndBody', 'titleOnly', 'hidden')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  unique (user_id, note_id),
  foreign key (note_id, user_id)
    references public.notes (id, user_id)
    on delete cascade
);

create table public.note_reviews (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  note_id uuid not null,
  reviewed_at timestamptz not null,
  focus_session_id text,
  outcome text not null check (
    outcome in ('reviewed', 'focusCompleted', 'focusInterrupted')
  ),
  deleted_at timestamptz,
  version bigint not null check (version > 0),
  server_revision bigint not null check (server_revision > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  unique (id, user_id),
  foreign key (note_id, user_id)
    references public.notes (id, user_id)
    on delete cascade
);

create unique index note_reviews_user_focus_idx
  on public.note_reviews (user_id, focus_session_id)
  where focus_session_id is not null;

create index notes_user_active_idx
  on public.notes (user_id, is_archived, deleted_at, updated_at desc);

create index note_reminders_user_schedule_idx
  on public.note_reminders (user_id, status, scheduled_at_utc);

create index note_reviews_user_reviewed_idx
  on public.note_reviews (user_id, reviewed_at desc);

alter table public.notes enable row level security;
alter table public.note_reminders enable row level security;
alter table public.note_reviews enable row level security;

create policy notes_select_own
  on public.notes
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy note_reminders_select_own
  on public.note_reminders
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy note_reviews_select_own
  on public.note_reviews
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.notes from anon, authenticated;
revoke all on table public.note_reminders from anon, authenticated;
revoke all on table public.note_reviews from anon, authenticated;

grant select on table public.notes to authenticated;
grant select on table public.note_reminders to authenticated;
grant select on table public.note_reviews to authenticated;

create or replace function public.apply_note_sync_mutation(
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
  v_note public.notes%rowtype;
  v_reminder public.note_reminders%rowtype;
  v_review public.note_reviews%rowtype;
  v_note_id uuid;
  v_focus_session_id text;
  v_delete_reminder boolean;
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

  if p_operation = 'note_upsert' then
    v_entity_type := 'note';

    select *
    into v_note
    from public.notes
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      if not (v_payload ? 'title') or not (v_payload ? 'body') then
        raise exception 'note title and body are required'
          using errcode = '22023';
      end if;
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;
      if v_payload ? 'tags'
        and jsonb_typeof(v_payload -> 'tags') <> 'array'
      then
        raise exception 'note tags must be an array'
          using errcode = '22023';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.notes (
        id,
        user_id,
        title,
        body,
        category,
        accent_key,
        is_pinned,
        is_archived,
        archived_at,
        tags,
        format_version,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_payload ->> 'title',
        v_payload ->> 'body',
        nullif(btrim(v_payload ->> 'category'), ''),
        coalesce(nullif(v_payload ->> 'accent_key', ''), 'mint'),
        coalesce((v_payload ->> 'is_pinned')::boolean, false),
        false,
        null,
        case
          when v_payload ? 'tags' then array(
            select jsonb_array_elements_text(v_payload -> 'tags')
          )
          else array[]::text[]
        end,
        coalesce((v_payload ->> 'format_version')::integer, 1),
        coalesce(
          (v_payload ->> 'created_at')::timestamptz,
          v_now
        ),
        coalesce(
          (v_payload ->> 'updated_at')::timestamptz,
          v_now
        ),
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_note;
    else
      if v_note.deleted_at is not null then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      perform zentra_private.assert_base_version(
        p_base_version,
        v_note.version
      );

      if v_payload ? 'tags'
        and jsonb_typeof(v_payload -> 'tags') <> 'array'
      then
        raise exception 'note tags must be an array'
          using errcode = '22023';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      update public.notes
      set
        title = case
          when v_payload ? 'title' then v_payload ->> 'title'
          else title
        end,
        body = case
          when v_payload ? 'body' then v_payload ->> 'body'
          else body
        end,
        category = case
          when v_payload ? 'category'
            then nullif(btrim(v_payload ->> 'category'), '')
          else category
        end,
        accent_key = case
          when v_payload ? 'accent_key'
            then coalesce(nullif(v_payload ->> 'accent_key', ''), accent_key)
          else accent_key
        end,
        is_pinned = case
          when v_payload ? 'is_pinned'
            then (v_payload ->> 'is_pinned')::boolean
          else is_pinned
        end,
        tags = case
          when v_payload ? 'tags' then array(
            select jsonb_array_elements_text(v_payload -> 'tags')
          )
          else tags
        end,
        format_version = case
          when v_payload ? 'format_version'
            then (v_payload ->> 'format_version')::integer
          else format_version
        end,
        updated_at = coalesce(
          (v_payload ->> 'updated_at')::timestamptz,
          v_now
        ),
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_note.id
        and user_id = v_user_id
      returning * into v_note;
    end if;

    v_entity_id := v_note.id;
    v_version := v_note.version;
    v_record := to_jsonb(v_note) - 'user_id';
  elsif p_operation in ('note_archive', 'note_restore', 'note_delete') then
    v_entity_type := 'note';

    select *
    into v_note
    from public.notes
    where id = p_entity_id
      and user_id = v_user_id
    for update;

    if not found then
      raise exception 'note does not exist'
        using errcode = 'P0002';
    end if;

    if (
      p_operation = 'note_archive'
      and v_note.deleted_at is null
      and v_note.is_archived
    ) or (
      p_operation = 'note_restore'
      and v_note.deleted_at is null
      and not v_note.is_archived
    ) or (
      p_operation = 'note_delete'
      and v_note.deleted_at is not null
    ) then
      v_status := 'no_op';
      v_revision := v_note.server_revision;
    else
      if p_operation = 'note_restore' and v_note.deleted_at is not null then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      perform zentra_private.assert_base_version(
        p_base_version,
        v_note.version
      );

      v_revision := zentra_private.next_sync_revision(v_user_id);
      v_change_operation := case p_operation
        when 'note_archive' then 'archive'
        when 'note_restore' then 'restore'
        else 'delete'
      end;

      update public.notes
      set
        is_pinned = case
          when p_operation in ('note_archive', 'note_delete') then false
          else is_pinned
        end,
        is_archived = p_operation <> 'note_restore',
        archived_at = case
          when p_operation = 'note_restore' then null
          else coalesce(archived_at, v_now)
        end,
        deleted_at = case
          when p_operation = 'note_delete' then coalesce(deleted_at, v_now)
          else deleted_at
        end,
        updated_at = v_now,
        version = version + 1,
        server_revision = v_revision,
        schema_version = p_schema_version
      where id = v_note.id
        and user_id = v_user_id
      returning * into v_note;
    end if;

    v_entity_id := v_note.id;
    v_version := v_note.version;
    v_record := to_jsonb(v_note) - 'user_id';
  elsif p_operation = 'note_reminder_set' then
    v_entity_type := 'note_reminder';
    v_note_id := nullif(v_payload ->> 'note_id', '')::uuid;
    v_delete_reminder := coalesce(
      (v_payload ->> 'deleted')::boolean,
      false
    );

    if v_note_id is null then
      raise exception 'note_id is required'
        using errcode = '22023';
    end if;

    perform 1
    from public.notes
    where id = v_note_id
      and user_id = v_user_id
      and deleted_at is null;

    if not found then
      raise exception 'note does not exist'
        using errcode = 'P0002';
    end if;

    select *
    into v_reminder
    from public.note_reminders
    where user_id = v_user_id
      and (id = p_entity_id or note_id = v_note_id)
    order by (id = p_entity_id) desc
    limit 1
    for update;

    if not found then
      if v_delete_reminder then
        raise exception 'note reminder does not exist'
          using errcode = 'P0002';
      end if;
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;
      if coalesce(v_payload ->> 'status', '') not in (
        'scheduled',
        'delivered',
        'snoozed',
        'completed',
        'cancelled',
        'failed'
      ) or coalesce(v_payload ->> 'privacy_mode', '') not in (
        'titleAndBody',
        'titleOnly',
        'hidden'
      ) then
        raise exception 'invalid note reminder state'
          using errcode = '22023';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.note_reminders (
        id,
        user_id,
        note_id,
        scheduled_at_utc,
        timezone_name,
        status,
        privacy_mode,
        created_at,
        updated_at,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_note_id,
        (v_payload ->> 'scheduled_at_utc')::timestamptz,
        coalesce(nullif(v_payload ->> 'timezone_name', ''), 'UTC'),
        v_payload ->> 'status',
        v_payload ->> 'privacy_mode',
        coalesce(
          (v_payload ->> 'created_at')::timestamptz,
          v_now
        ),
        coalesce(
          (v_payload ->> 'updated_at')::timestamptz,
          v_now
        ),
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_reminder;
    else
      if v_delete_reminder and v_reminder.deleted_at is not null then
        v_status := 'no_op';
        v_revision := v_reminder.server_revision;
      else
        perform zentra_private.assert_base_version(
          p_base_version,
          v_reminder.version
        );

        if not v_delete_reminder and (
          coalesce(v_payload ->> 'status', '') not in (
            'scheduled',
            'delivered',
            'snoozed',
            'completed',
            'cancelled',
            'failed'
          ) or coalesce(v_payload ->> 'privacy_mode', '') not in (
            'titleAndBody',
            'titleOnly',
            'hidden'
          )
        ) then
          raise exception 'invalid note reminder state'
            using errcode = '22023';
        end if;

        v_revision := zentra_private.next_sync_revision(v_user_id);
        if v_delete_reminder then
          v_change_operation := 'delete';
        end if;

        update public.note_reminders
        set
          scheduled_at_utc = case
            when v_delete_reminder then scheduled_at_utc
            else (v_payload ->> 'scheduled_at_utc')::timestamptz
          end,
          timezone_name = case
            when v_delete_reminder then timezone_name
            else coalesce(nullif(v_payload ->> 'timezone_name', ''), 'UTC')
          end,
          status = case
            when v_delete_reminder then 'cancelled'
            else v_payload ->> 'status'
          end,
          privacy_mode = case
            when v_delete_reminder then privacy_mode
            else v_payload ->> 'privacy_mode'
          end,
          updated_at = case
            when v_delete_reminder then v_now
            else coalesce(
              (v_payload ->> 'updated_at')::timestamptz,
              v_now
            )
          end,
          deleted_at = case
            when v_delete_reminder then coalesce(deleted_at, v_now)
            else null
          end,
          version = version + 1,
          server_revision = v_revision,
          schema_version = p_schema_version
        where id = v_reminder.id
          and user_id = v_user_id
        returning * into v_reminder;
      end if;
    end if;

    v_entity_id := v_reminder.id;
    v_version := v_reminder.version;
    v_record := to_jsonb(v_reminder) - 'user_id';
  elsif p_operation = 'note_review_add' then
    v_entity_type := 'note_review';
    v_note_id := nullif(v_payload ->> 'note_id', '')::uuid;
    v_focus_session_id := nullif(v_payload ->> 'focus_session_id', '');

    if v_note_id is null then
      raise exception 'note_id is required'
        using errcode = '22023';
    end if;
    if coalesce(v_payload ->> 'outcome', '') not in (
      'reviewed',
      'focusCompleted',
      'focusInterrupted'
    ) then
      raise exception 'invalid note review outcome'
        using errcode = '22023';
    end if;

    perform 1
    from public.notes
    where id = v_note_id
      and user_id = v_user_id
      and deleted_at is null;

    if not found then
      raise exception 'note does not exist'
        using errcode = 'P0002';
    end if;

    select *
    into v_review
    from public.note_reviews
    where user_id = v_user_id
      and (
        id = p_entity_id
        or (
          v_focus_session_id is not null
          and focus_session_id = v_focus_session_id
        )
      )
    order by (id = p_entity_id) desc
    limit 1
    for update;

    if found then
      v_status := 'no_op';
      v_revision := v_review.server_revision;
    else
      if p_base_version is not null and p_base_version <> 0 then
        raise exception 'sync conflict'
          using errcode = '40001';
      end if;

      v_revision := zentra_private.next_sync_revision(v_user_id);

      insert into public.note_reviews (
        id,
        user_id,
        note_id,
        reviewed_at,
        focus_session_id,
        outcome,
        version,
        server_revision,
        schema_version
      )
      values (
        p_entity_id,
        v_user_id,
        v_note_id,
        coalesce(
          (v_payload ->> 'reviewed_at')::timestamptz,
          v_now
        ),
        v_focus_session_id,
        v_payload ->> 'outcome',
        1,
        v_revision,
        p_schema_version
      )
      returning * into v_review;
    end if;

    v_entity_id := v_review.id;
    v_version := v_review.version;
    v_record := to_jsonb(v_review) - 'user_id';
  else
    raise exception 'unsupported note sync operation'
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
    end as record_data
  from public.sync_changes as change
  where change.user_id = v_user_id
    and change.server_revision > p_after_revision
  order by change.server_revision
  limit least(p_limit, 500);
end;
$$;

revoke execute on function public.apply_note_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) from public, anon;

grant execute on function public.apply_note_sync_mutation(
  uuid,
  text,
  uuid,
  bigint,
  jsonb,
  integer
) to authenticated, service_role;
