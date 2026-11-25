-- ASCENT Versus Sprint — shared cosmetic flight drones
-- This migration adds a server-validated, room-visible drone key. It is flavour only:
-- scoring, categories, timing, and answer validation remain identical for every player.

begin;

alter table public.ascent_versus_players
  add column if not exists pilot_key text not null default 'aurora';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ascent_versus_players_pilot_key_check'
      and conrelid = 'public.ascent_versus_players'::regclass
  ) then
    alter table public.ascent_versus_players
      add constraint ascent_versus_players_pilot_key_check
      check (pilot_key in ('aurora', 'comet', 'vector', 'orbit', 'pulse', 'sentry'));
  end if;
end;
$$;

create or replace function public.ascent_room_state(p_room_code text, p_player_secret text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room public.ascent_versus_rooms%rowtype;
  v_player public.ascent_versus_players%rowtype;
  v_players jsonb;
  v_answers jsonb := '{}'::jsonb;
  v_title text;
  v_hint text;
begin
  select r.* into v_room
  from public.ascent_versus_rooms r
  join public.ascent_versus_players p on p.room_id = r.id
  where r.room_code = upper(trim(p_room_code))
    and p.player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  if not found then
    raise exception 'Room not found or this device is not a room participant.';
  end if;

  if v_room.expires_at <= now() then
    delete from public.ascent_versus_rooms where id = v_room.id;
    raise exception 'This room has expired.';
  end if;

  select * into v_player
  from public.ascent_versus_players
  where room_id = v_room.id and player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  update public.ascent_versus_players
  set last_seen_at = now()
  where id = v_player.id;

  if v_room.phase = 'playing' and v_room.round_ends_at <= now() then
    update public.ascent_versus_rooms
      set phase = 'results'
      where id = v_room.id
      returning * into v_room;
  end if;

  select title, hint into v_title, v_hint
  from public.ascent_versus_categories
  where category_key = v_room.category_key;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'name', p.player_name,
    'pilot_key', p.pilot_key,
    'is_host', p.is_host,
    'is_connected', p.last_seen_at >= now() - interval '12 seconds',
    'score', p.total_score,
    'round_score', coalesce((
      select count(*)
      from public.ascent_versus_answers a
      where a.player_id = p.id and a.round_number = v_room.round_number
    ), 0)
  ) order by p.joined_at), '[]'::jsonb)
  into v_players
  from public.ascent_versus_players p
  where p.room_id = v_room.id;

  if v_room.phase = 'results' then
    select coalesce(jsonb_object_agg(answer_rows.player_id::text, answer_rows.answer_keys), '{}'::jsonb)
    into v_answers
    from (
      select a.player_id, jsonb_agg(a.answer_key order by a.submitted_at) as answer_keys
      from public.ascent_versus_answers a
      where a.room_id = v_room.id and a.round_number = v_room.round_number
      group by a.player_id
    ) answer_rows;
  end if;

  return jsonb_build_object(
    'room_code', v_room.room_code,
    'phase', v_room.phase,
    'category_key', v_room.category_key,
    'category_title', v_title,
    'category_hint', v_hint,
    'round_number', v_room.round_number,
    'round_starts_at', v_room.round_starts_at,
    'round_ends_at', v_room.round_ends_at,
    'server_now', now(),
    'you', jsonb_build_object('id', v_player.id, 'name', v_player.player_name, 'pilot_key', v_player.pilot_key, 'is_host', v_player.is_host),
    'players', v_players,
    'answers', v_answers
  );
end;
$$;

create or replace function public.ascent_create_room(p_room_code text, p_player_name text, p_player_secret text, p_pilot_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room_id uuid;
  v_pilot_key text;
begin
  perform public.ascent_cleanup_expired_rooms();

  if upper(trim(p_room_code)) !~ '^[A-Z2-9]{6}$' then
    raise exception 'Room code must use six unambiguous uppercase characters.';
  end if;
  if char_length(trim(p_player_name)) not between 2 and 18 then
    raise exception 'Choose a name between 2 and 18 characters.';
  end if;
  if char_length(p_player_secret) < 32 then
    raise exception 'Invalid local room credential.';
  end if;
  v_pilot_key := lower(trim(coalesce(p_pilot_key, '')));
  if v_pilot_key not in ('aurora', 'comet', 'vector', 'orbit', 'pulse', 'sentry') then
    raise exception 'Choose one of the available flight drones.';
  end if;

  insert into public.ascent_versus_rooms (room_code)
  values (upper(trim(p_room_code)))
  returning id into v_room_id;

  insert into public.ascent_versus_players (room_id, player_name, pilot_key, player_secret_hash, is_host)
  values (v_room_id, trim(p_player_name), v_pilot_key, encode(digest(p_player_secret, 'sha256'), 'hex'), true);

  return public.ascent_room_state(upper(trim(p_room_code)), p_player_secret);
end;
$$;

create or replace function public.ascent_join_room(p_room_code text, p_player_name text, p_player_secret text, p_pilot_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room public.ascent_versus_rooms%rowtype;
  v_existing_player uuid;
  v_pilot_key text;
begin
  if char_length(trim(p_player_name)) not between 2 and 18 then
    raise exception 'Choose a name between 2 and 18 characters.';
  end if;
  if char_length(p_player_secret) < 32 then
    raise exception 'Invalid local room credential.';
  end if;
  v_pilot_key := lower(trim(coalesce(p_pilot_key, '')));
  if v_pilot_key not in ('aurora', 'comet', 'vector', 'orbit', 'pulse', 'sentry') then
    raise exception 'Choose one of the available flight drones.';
  end if;

  select * into v_room
  from public.ascent_versus_rooms
  where room_code = upper(trim(p_room_code))
  for update;

  if not found or v_room.expires_at <= now() then
    raise exception 'That room code is unavailable or expired.';
  end if;

  select id into v_existing_player
  from public.ascent_versus_players
  where room_id = v_room.id and player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  if v_existing_player is not null then
    return public.ascent_room_state(v_room.room_code, p_player_secret);
  end if;

  if v_room.phase <> 'lobby' then
    raise exception 'That sprint has already started.';
  end if;
  if (select count(*) from public.ascent_versus_players where room_id = v_room.id) >= 2 then
    raise exception 'That room already has two players.';
  end if;

  insert into public.ascent_versus_players (room_id, player_name, pilot_key, player_secret_hash, is_host)
  values (v_room.id, trim(p_player_name), v_pilot_key, encode(digest(p_player_secret, 'sha256'), 'hex'), false);

  return public.ascent_room_state(v_room.room_code, p_player_secret);
end;
$$;

revoke all on function public.ascent_create_room(text, text, text, text) from public;
revoke all on function public.ascent_join_room(text, text, text, text) from public;
grant execute on function public.ascent_create_room(text, text, text, text) to anon;
grant execute on function public.ascent_join_room(text, text, text, text) to anon;

commit;
