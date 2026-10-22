-- Fasthabiqul Khairath 2026 — Supabase database setup
-- Run once in Supabase -> SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  email text primary key,
  created_at timestamptz not null default now()
);

create table if not exists public.visitors (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  place text not null check (char_length(place) between 1 and 100),
  created_at timestamptz not null default now()
);

create table if not exists public.visitor_sessions (
  id uuid primary key default gen_random_uuid(),
  visitor_id uuid references public.visitors(id) on delete set null,
  name text not null,
  place text not null,
  session_key text not null unique,
  started_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  duration_seconds integer not null default 0 check (duration_seconds >= 0)
);

create table if not exists public.scores (
  id uuid primary key default gen_random_uuid(),
  participant_id text not null,
  programme_id text not null,
  points numeric(10,2) not null default 0 check (points >= 0),
  updated_at timestamptz not null default now(),
  unique (participant_id, programme_id)
);

create table if not exists public.team_scores (
  id uuid primary key default gen_random_uuid(),
  team_id text not null,
  programme_id text not null,
  points numeric(10,2) not null default 0 check (points >= 0),
  updated_at timestamptz not null default now(),
  unique (team_id, programme_id)
);

create table if not exists public.gallery (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'Melaad Fest 2026',
  file_url text not null,
  file_path text not null,
  media_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  name text check (name is null or char_length(name) <= 80),
  message text not null check (char_length(btrim(message)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function public.start_visitor_session(
  p_name text,
  p_place text,
  p_session_key text,
  p_visitor_created_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  matched_visitor_id uuid;
begin
  select id into matched_visitor_id
  from public.visitors
  where created_at = p_visitor_created_at
    and lower(name) = lower(p_name)
    and lower(place) = lower(p_place)
  limit 1;

  insert into public.visitor_sessions (
    visitor_id, name, place, session_key
  )
  values (
    matched_visitor_id, p_name, p_place, p_session_key
  )
  on conflict (session_key) do update
    set last_seen_at = now();
end;
$$;

create or replace function public.touch_visitor_session(
  p_session_key text,
  p_duration_seconds integer
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.visitor_sessions
  set last_seen_at = now(),
      duration_seconds = greatest(duration_seconds, p_duration_seconds)
  where session_key = p_session_key;
$$;

alter table public.admins enable row level security;
alter table public.visitors enable row level security;
alter table public.visitor_sessions enable row level security;
alter table public.scores enable row level security;
alter table public.team_scores enable row level security;
alter table public.gallery enable row level security;
alter table public.feedback enable row level security;

drop policy if exists "approved admin can read own row" on public.admins;
create policy "approved admin can read own row"
on public.admins for select
to authenticated
using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

drop policy if exists "public can register visit" on public.visitors;
create policy "public can register visit"
on public.visitors for insert
to anon, authenticated
with check (true);

drop policy if exists "admin can read visitors" on public.visitors;
create policy "admin can read visitors"
on public.visitors for select
to authenticated
using (public.is_admin());

drop policy if exists "admin can read visitor sessions" on public.visitor_sessions;
create policy "admin can read visitor sessions"
on public.visitor_sessions for select
to authenticated
using (public.is_admin());

drop policy if exists "public can read scores" on public.scores;
create policy "public can read scores"
on public.scores for select
to anon, authenticated
using (true);

drop policy if exists "admin can insert scores" on public.scores;
create policy "admin can insert scores"
on public.scores for insert
to authenticated
with check (public.is_admin());

drop policy if exists "admin can update scores" on public.scores;
create policy "admin can update scores"
on public.scores for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admin can delete scores" on public.scores;
create policy "admin can delete scores"
on public.scores for delete
to authenticated
using (public.is_admin());

drop policy if exists "public can read team scores" on public.team_scores;
create policy "public can read team scores"
on public.team_scores for select
to anon, authenticated
using (true);

drop policy if exists "admin can insert team scores" on public.team_scores;
create policy "admin can insert team scores"
on public.team_scores for insert
to authenticated
with check (public.is_admin());

drop policy if exists "admin can update team scores" on public.team_scores;
create policy "admin can update team scores"
on public.team_scores for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admin can delete team scores" on public.team_scores;
create policy "admin can delete team scores"
on public.team_scores for delete
to authenticated
using (public.is_admin());

drop policy if exists "public can read gallery" on public.gallery;
create policy "public can read gallery"
on public.gallery for select
to anon, authenticated
using (true);

drop policy if exists "admin can insert gallery" on public.gallery;
create policy "admin can insert gallery"
on public.gallery for insert
to authenticated
with check (public.is_admin());

drop policy if exists "admin can update gallery" on public.gallery;
create policy "admin can update gallery"
on public.gallery for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admin can delete gallery" on public.gallery;
create policy "admin can delete gallery"
on public.gallery for delete
to authenticated
using (public.is_admin());

drop policy if exists "public can submit feedback" on public.feedback;
create policy "public can submit feedback"
on public.feedback for insert
to anon, authenticated
with check (
  char_length(btrim(message)) between 1 and 2000
  and (name is null or char_length(name) <= 80)
);

drop policy if exists "admin can read feedback" on public.feedback;
create policy "admin can read feedback"
on public.feedback for select
to authenticated
using (public.is_admin());

grant select on public.admins to authenticated;
grant insert on public.visitors to anon, authenticated;
grant select on public.visitors, public.visitor_sessions to authenticated;
grant select on public.scores, public.team_scores, public.gallery to anon, authenticated;
grant insert on public.feedback to anon, authenticated;
grant select on public.feedback to authenticated;
grant insert, update, delete
on public.scores, public.team_scores, public.gallery
to authenticated;
grant execute on function public.start_visitor_session(text, text, text, timestamptz)
to anon, authenticated;
grant execute on function public.touch_visitor_session(text, integer)
to anon, authenticated;

insert into storage.buckets (id, name, public)
values ('gallery', 'gallery', true)
on conflict (id) do update set public = true;

drop policy if exists "public can view gallery media" on storage.objects;
create policy "public can view gallery media"
on storage.objects for select
to public
using (bucket_id = 'gallery');

drop policy if exists "admin can upload gallery media" on storage.objects;
create policy "admin can upload gallery media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'gallery' and public.is_admin());

drop policy if exists "admin can update gallery media" on storage.objects;
create policy "admin can update gallery media"
on storage.objects for update
to authenticated
using (bucket_id = 'gallery' and public.is_admin())
with check (bucket_id = 'gallery' and public.is_admin());

drop policy if exists "admin can delete gallery media" on storage.objects;
create policy "admin can delete gallery media"
on storage.objects for delete
to authenticated
using (bucket_id = 'gallery' and public.is_admin());

-- Replace this with the approved administrator's email address.
insert into public.admins (email)
values ('muhammedthangal8921@gmail.com')
on conflict (email) do nothing;

-- Enable Realtime for scores and team_scores in Supabase Database settings.
