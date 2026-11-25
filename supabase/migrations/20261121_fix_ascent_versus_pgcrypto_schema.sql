-- Supabase installs pgcrypto in the extensions schema. The initial functions use
-- digest() for one-way room-credential hashing, so make that trusted schema visible
-- to their security-definer execution context.

begin;

alter function public.ascent_room_state(text, text) set search_path = public, extensions;
alter function public.ascent_create_room(text, text, text) set search_path = public, extensions;
alter function public.ascent_join_room(text, text, text) set search_path = public, extensions;
alter function public.ascent_start_round(text, text) set search_path = public, extensions;
alter function public.ascent_submit_answer(text, text, integer, text) set search_path = public, extensions;
alter function public.ascent_leave_room(text, text) set search_path = public, extensions;
alter function public.ascent_close_room(text, text) set search_path = public, extensions;

commit;
