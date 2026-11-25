-- ASCENT Versus Sprint — Supabase schema
-- Run this file once in the Supabase SQL Editor for the ASCENT project.
-- It deliberately exposes no direct table access to the browser: the public client can only call
-- the narrowly scoped RPC functions below with an opaque, per-player room secret.

begin;

create extension if not exists pgcrypto;

create table if not exists public.ascent_versus_categories (
  category_key text primary key check (category_key ~ '^[a-z_]{3,48}$'),
  title text not null check (char_length(title) between 3 and 48),
  hint text not null check (char_length(hint) between 3 and 140),
  answers jsonb not null check (jsonb_typeof(answers) = 'object' and answers <> '{}'::jsonb)
);

insert into public.ascent_versus_categories (category_key, title, hint, answers) values
  ('facial_expressions','FACIAL EXPRESSIONS','Angry, happy, surprised … name an emotion or expression.','{"angry":"angry","happy":"happy","sad":"sad","surprised":"surprised","scared":"scared","afraid":"afraid","confused":"confused","disgusted":"disgusted","worried":"worried","bored":"bored","excited":"excited","nervous":"nervous","embarrassed":"embarrassed","proud":"proud","relieved":"relieved","shocked":"shocked","sleepy":"sleepy","curious":"curious","frustrated":"frustrated","calm":"calm","annoyed":"annoyed","delighted":"delighted","grumpy":"grumpy","puzzled":"puzzled","ashamed":"ashamed","amused":"amused","serious":"serious","smug":"smug","jealous":"jealous","lonely":"lonely","hopeful":"hopeful"}'::jsonb),
  ('animals','ANIMALS','Name a living animal.','{"dog":"dog","cat":"cat","horse":"horse","cow":"cow","sheep":"sheep","pig":"pig","lion":"lion","tiger":"tiger","elephant":"elephant","giraffe":"giraffe","zebra":"zebra","monkey":"monkey","gorilla":"gorilla","bear":"bear","wolf":"wolf","fox":"fox","rabbit":"rabbit","mouse":"mouse","rat":"rat","deer":"deer","camel":"camel","hippopotamus":"hippopotamus","panda":"panda","koala":"koala","kangaroo":"kangaroo","penguin":"penguin","eagle":"eagle","owl":"owl","parrot":"parrot","shark":"shark","whale":"whale","dolphin":"dolphin","octopus":"octopus","turtle":"turtle","snake":"snake","crocodile":"crocodile","frog":"frog","butterfly":"butterfly","bee":"bee"}'::jsonb),
  ('fruits','FRUITS','Name an edible fruit.','{"apple":"apple","banana":"banana","orange":"orange","pear":"pear","peach":"peach","plum":"plum","grape":"grape","strawberry":"strawberry","blueberry":"blueberry","raspberry":"raspberry","blackberry":"blackberry","cherry":"cherry","lemon":"lemon","lime":"lime","mango":"mango","pineapple":"pineapple","watermelon":"watermelon","melon":"melon","kiwi":"kiwi","papaya":"papaya","coconut":"coconut","pomegranate":"pomegranate","apricot":"apricot","fig":"fig","date":"date","avocado":"avocado","grapefruit":"grapefruit","guava":"guava","lychee":"lychee","passion fruit":"passion fruit"}'::jsonb),
  ('sports','SPORTS','Name an organised sport.','{"football":"football","basketball":"basketball","baseball":"baseball","tennis":"tennis","volleyball":"volleyball","golf":"golf","cricket":"cricket","rugby":"rugby","hockey":"hockey","ice hockey":"ice hockey","badminton":"badminton","table tennis":"table tennis","boxing":"boxing","wrestling":"wrestling","swimming":"swimming","cycling":"cycling","running":"running","athletics":"athletics","gymnastics":"gymnastics","skiing":"skiing","snowboarding":"snowboarding","surfing":"surfing","skateboarding":"skateboarding","karate":"karate","judo":"judo","fencing":"fencing","handball":"handball","water polo":"water polo","rowing":"rowing","sailing":"sailing","archery":"archery","climbing":"climbing","padel":"padel","pickleball":"pickleball"}'::jsonb),
  ('countries','COUNTRIES','Name an internationally recognised country or territory.','{"netherlands":"netherlands","belgium":"belgium","france":"france","germany":"germany","spain":"spain","portugal":"portugal","italy":"italy","switzerland":"switzerland","austria":"austria","sweden":"sweden","norway":"norway","denmark":"denmark","finland":"finland","ireland":"ireland","poland":"poland","greece":"greece","turkey":"turkey","ukraine":"ukraine","united kingdom":"united kingdom","united states":"united states","canada":"canada","mexico":"mexico","brazil":"brazil","argentina":"argentina","chile":"chile","colombia":"colombia","peru":"peru","japan":"japan","china":"china","india":"india","south korea":"south korea","thailand":"thailand","vietnam":"vietnam","indonesia":"indonesia","australia":"australia","new zealand":"new zealand","egypt":"egypt","morocco":"morocco","south africa":"south africa","nigeria":"nigeria","kenya":"kenya","saudi arabia":"saudi arabia","united arab emirates":"united arab emirates"}'::jsonb),
  ('instruments','MUSICAL INSTRUMENTS','Name a standard musical instrument.','{"guitar":"guitar","piano":"piano","violin":"violin","cello":"cello","viola":"viola","double bass":"double bass","drums":"drums","flute":"flute","trumpet":"trumpet","trombone":"trombone","tuba":"tuba","saxophone":"saxophone","clarinet":"clarinet","oboe":"oboe","bassoon":"bassoon","harp":"harp","ukulele":"ukulele","banjo":"banjo","mandolin":"mandolin","accordion":"accordion","harmonica":"harmonica","recorder":"recorder","keyboard":"keyboard","organ":"organ","xylophone":"xylophone","tambourine":"tambourine","triangle":"triangle","cymbals":"cymbals","maracas":"maracas","conga":"conga","gong":"gong","sitar":"sitar","bagpipes":"bagpipes"}'::jsonb),
  ('kitchen_items','KITCHEN ITEMS','Name something normally found in a kitchen.','{"spoon":"spoon","fork":"fork","knife":"knife","plate":"plate","bowl":"bowl","cup":"cup","glass":"glass","mug":"mug","pan":"pan","pot":"pot","kettle":"kettle","toaster":"toaster","oven":"oven","stove":"stove","fridge":"fridge","freezer":"freezer","microwave":"microwave","blender":"blender","mixer":"mixer","whisk":"whisk","grater":"grater","colander":"colander","cutting board":"cutting board","spatula":"spatula","ladle":"ladle","peeler":"peeler","can opener":"can opener","bottle opener":"bottle opener","tongs":"tongs","rolling pin":"rolling pin","measuring cup":"measuring cup","napkin":"napkin"}'::jsonb)
on conflict (category_key) do update set title=excluded.title, hint=excluded.hint, answers=excluded.answers;

create table if not exists public.ascent_versus_rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text not null unique check (room_code ~ '^[A-Z2-9]{6}$'),
  phase text not null default 'lobby' check (phase in ('lobby','playing','results','closed')),
  category_key text references public.ascent_versus_categories(category_key),
  round_number integer not null default 0 check (round_number >= 0),
  round_starts_at timestamptz,
  round_ends_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '2 hours')
);

create table if not exists public.ascent_versus_players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.ascent_versus_rooms(id) on delete cascade,
  player_name text not null check (char_length(player_name) between 2 and 18),
  pilot_key text not null default 'aurora' check (pilot_key in ('aurora', 'comet', 'vector', 'orbit', 'pulse', 'sentry')),
  player_secret_hash text not null unique check (char_length(player_secret_hash) = 64),
  is_host boolean not null default false,
  total_score integer not null default 0 check (total_score >= 0),
  joined_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

alter table public.ascent_versus_players
  add column if not exists last_seen_at timestamptz not null default now();

create table if not exists public.ascent_versus_answers (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.ascent_versus_rooms(id) on delete cascade,
  player_id uuid not null references public.ascent_versus_players(id) on delete cascade,
  round_number integer not null check (round_number > 0),
  answer_key text not null check (char_length(answer_key) between 1 and 48),
  submitted_at timestamptz not null default now(),
  unique (player_id, round_number, answer_key)
);

create index if not exists ascent_versus_players_room_idx on public.ascent_versus_players(room_id);
create index if not exists ascent_versus_answers_round_idx on public.ascent_versus_answers(room_id, round_number, submitted_at);

alter table public.ascent_versus_categories enable row level security;
alter table public.ascent_versus_rooms enable row level security;
alter table public.ascent_versus_players enable row level security;
alter table public.ascent_versus_answers enable row level security;

revoke all on table public.ascent_versus_categories, public.ascent_versus_rooms, public.ascent_versus_players, public.ascent_versus_answers from anon, authenticated, public;

-- The browser has no raw table permissions. These explicit deny policies are defense in depth:
-- the security-definer RPCs below are the only supported browser surface.
drop policy if exists "deny direct browser category access" on public.ascent_versus_categories;
create policy "deny direct browser category access" on public.ascent_versus_categories for all to anon, authenticated using (false) with check (false);
drop policy if exists "deny direct browser room access" on public.ascent_versus_rooms;
create policy "deny direct browser room access" on public.ascent_versus_rooms for all to anon, authenticated using (false) with check (false);
drop policy if exists "deny direct browser player access" on public.ascent_versus_players;
create policy "deny direct browser player access" on public.ascent_versus_players for all to anon, authenticated using (false) with check (false);
drop policy if exists "deny direct browser answer access" on public.ascent_versus_answers;
create policy "deny direct browser answer access" on public.ascent_versus_answers for all to anon, authenticated using (false) with check (false);

create or replace function public.ascent_cleanup_expired_rooms()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  delete from public.ascent_versus_rooms where expires_at <= now();
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

create or replace function public.ascent_start_round(p_room_code text, p_player_secret text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room public.ascent_versus_rooms%rowtype;
  v_player public.ascent_versus_players%rowtype;
  v_category_key text;
begin
  select r.* into v_room
  from public.ascent_versus_rooms r
  join public.ascent_versus_players p on p.room_id = r.id
  where r.room_code = upper(trim(p_room_code)) and p.player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex')
  for update of r;

  if not found or v_room.expires_at <= now() then
    raise exception 'Room not found or expired.';
  end if;

  select * into v_player
  from public.ascent_versus_players
  where room_id = v_room.id and player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  update public.ascent_versus_players
  set last_seen_at = now()
  where id = v_player.id;

  if not v_player.is_host then
    raise exception 'Only the host can start the next sprint.';
  end if;
  if v_room.phase not in ('lobby','results') then
    raise exception 'This room is already running a sprint.';
  end if;
  if (select count(*) from public.ascent_versus_players where room_id = v_room.id) <> 2 then
    raise exception 'Wait for a second player before starting.';
  end if;
  if exists (
    select 1 from public.ascent_versus_players
    where room_id = v_room.id and last_seen_at < now() - interval '12 seconds'
  ) then
    raise exception 'Your opponent is reconnecting. Wait until their signal returns.';
  end if;
  select category_key into v_category_key
  from public.ascent_versus_categories
  where category_key is distinct from v_room.category_key
  order by random()
  limit 1;

  if v_category_key is null then
    raise exception 'No sprint category is available.';
  end if;

  update public.ascent_versus_rooms
  set phase = 'playing',
      category_key = v_category_key,
      round_number = round_number + 1,
      round_starts_at = now() + interval '3 seconds',
      round_ends_at = now() + interval '28 seconds',
      expires_at = greatest(expires_at, now() + interval '2 hours')
  where id = v_room.id;

  return public.ascent_room_state(v_room.room_code, p_player_secret);
end;
$$;

create or replace function public.ascent_submit_answer(p_room_code text, p_player_secret text, p_round_number integer, p_answer_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room public.ascent_versus_rooms%rowtype;
  v_player public.ascent_versus_players%rowtype;
  v_inserted uuid;
  v_is_valid boolean;
begin
  select r.* into v_room
  from public.ascent_versus_rooms r
  join public.ascent_versus_players p on p.room_id = r.id
  where r.room_code = upper(trim(p_room_code)) and p.player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex')
  for update of r;

  if not found or v_room.expires_at <= now() then
    raise exception 'Room not found or expired.';
  end if;

  select * into v_player
  from public.ascent_versus_players
  where room_id = v_room.id and player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  update public.ascent_versus_players
  set last_seen_at = now()
  where id = v_player.id;

  if v_room.phase <> 'playing' or v_room.round_number <> p_round_number then
    raise exception 'This answer window is closed.';
  end if;
  if now() < v_room.round_starts_at then
    raise exception 'The sprint has not started yet.';
  end if;
  if now() > v_room.round_ends_at then
    update public.ascent_versus_rooms set phase = 'results' where id = v_room.id;
    raise exception 'Time is up.';
  end if;

  select answers ? lower(trim(p_answer_key)) into v_is_valid
  from public.ascent_versus_categories
  where category_key = v_room.category_key;

  if coalesce(v_is_valid, false) is not true then
    raise exception 'That word is not in this category.';
  end if;

  insert into public.ascent_versus_answers (room_id, player_id, round_number, answer_key)
  values (v_room.id, v_player.id, v_room.round_number, lower(trim(p_answer_key)))
  on conflict (player_id, round_number, answer_key) do nothing
  returning id into v_inserted;

  if v_inserted is null then
    return jsonb_build_object('accepted', false, 'reason', 'Already counted.');
  end if;

  update public.ascent_versus_players
  set total_score = total_score + 1
  where id = v_player.id;

  return jsonb_build_object('accepted', true, 'answer_key', lower(trim(p_answer_key)));
end;
$$;

create or replace function public.ascent_leave_room(p_room_code text, p_player_secret text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room public.ascent_versus_rooms%rowtype;
  v_player public.ascent_versus_players%rowtype;
begin
  select r.* into v_room
  from public.ascent_versus_rooms r
  join public.ascent_versus_players p on p.room_id = r.id
  where r.room_code = upper(trim(p_room_code)) and p.player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex')
  for update of r;

  if not found then
    return true;
  end if;

  select * into v_player
  from public.ascent_versus_players
  where room_id = v_room.id and player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex');

  if v_player.is_host then
    delete from public.ascent_versus_rooms where id = v_room.id;
    return true;
  end if;

  delete from public.ascent_versus_players where id = v_player.id;
  -- A guest departure returns the host to a truthful one-player lobby rather than
  -- leaving a phantom opponent in a live sprint.
  update public.ascent_versus_rooms
  set phase = 'lobby',
      category_key = null,
      round_starts_at = null,
      round_ends_at = null
  where id = v_room.id;
  return true;
end;
$$;

create or replace function public.ascent_close_room(p_room_code text, p_player_secret text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_room_id uuid;
begin
  select r.id into v_room_id
  from public.ascent_versus_rooms r
  join public.ascent_versus_players p on p.room_id = r.id
  where r.room_code = upper(trim(p_room_code))
    and p.player_secret_hash = encode(digest(p_player_secret, 'sha256'), 'hex')
    and p.is_host = true;

  if v_room_id is null then
    raise exception 'Only the host can close this room.';
  end if;

  delete from public.ascent_versus_rooms where id = v_room_id;
  return true;
end;
$$;

revoke all on function public.ascent_cleanup_expired_rooms() from public;
revoke all on function public.ascent_room_state(text, text) from public;
revoke all on function public.ascent_create_room(text, text, text, text) from public;
revoke all on function public.ascent_join_room(text, text, text, text) from public;
revoke all on function public.ascent_start_round(text, text) from public;
revoke all on function public.ascent_submit_answer(text, text, integer, text) from public;
revoke all on function public.ascent_leave_room(text, text) from public;
revoke all on function public.ascent_close_room(text, text) from public;

grant execute on function public.ascent_room_state(text, text) to anon;
grant execute on function public.ascent_create_room(text, text, text, text) to anon;
grant execute on function public.ascent_join_room(text, text, text, text) to anon;
grant execute on function public.ascent_start_round(text, text) to anon;
grant execute on function public.ascent_submit_answer(text, text, integer, text) to anon;
grant execute on function public.ascent_leave_room(text, text) to anon;
grant execute on function public.ascent_close_room(text, text) to anon;

commit;
