-- ============================================================
-- PrayerWalk — Supabase Schema (PostGIS)
-- Run in Supabase SQL Editor. Enable PostGIS first if prompted.
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists postgis;

-- ============================================================
-- groups: prayer walking communities
-- ============================================================
create table if not exists public.groups (
  id           uuid primary key default uuid_generate_v4(),
  name         text not null,
  description  text,
  invite_code  text unique not null,
  created_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now()
);

-- ============================================================
-- profiles: user display names + group membership
-- ============================================================
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url   text,
  group_id     uuid references public.groups(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============================================================
-- walks: prayer walk routes
-- ============================================================
drop table if exists public.walks cascade;

create table public.walks (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  group_id       uuid references public.groups(id) on delete set null,
  start_time     timestamptz not null,
  end_time       timestamptz not null,
  polyline_data  jsonb not null,
  route          geometry(LineString, 4326),
  distance       double precision not null default 0,
  duration       int not null default 0,
  title          text,
  prayer_notes   text,
  created_at     timestamptz not null default now()
);

create index walks_user_id_idx on public.walks(user_id);
create index walks_end_time_idx on public.walks(end_time desc);
create index walks_group_id_idx on public.walks(group_id);
create index walks_route_gix on public.walks using gist (route) where (route is not null);

-- ============================================================
-- Auto-populate PostGIS route from polyline_data [[lat,lng],...]
-- ============================================================
create or replace function public.walks_sync_route()
returns trigger
language plpgsql
as $$
begin
  if new.polyline_data is null
     or jsonb_typeof(new.polyline_data) <> 'array'
     or jsonb_array_length(new.polyline_data) < 2 then
    new.route := null;
    return new;
  end if;

  new.route := (
    select ST_MakeLine(array_agg(pt ORDER BY ord))
    from (
      select
        row_number() over () as ord,
        ST_SetSRID(
          ST_MakePoint(
            (elem->>1)::double precision,
            (elem->>0)::double precision
          ),
          4326
        ) as pt
      from jsonb_array_elements(new.polyline_data) as elem
    ) s
  );

  return new;
end;
$$;

drop trigger if exists walks_sync_route_trigger on public.walks;
create trigger walks_sync_route_trigger
  before insert or update of polyline_data
  on public.walks
  for each row
  execute function public.walks_sync_route();

-- ============================================================
-- Row-Level Security — walks
-- ============================================================
alter table public.walks enable row level security;

create policy "walks_public_read"   on public.walks for select using (true);
create policy "walks_insert_own"    on public.walks for insert with check (auth.uid() = user_id);
create policy "walks_update_own"    on public.walks for update using (auth.uid() = user_id);
create policy "walks_delete_own"    on public.walks for delete using (auth.uid() = user_id);

-- ============================================================
-- Row-Level Security — profiles
-- ============================================================
alter table public.profiles enable row level security;

create policy "profiles_public_read"  on public.profiles for select using (true);
create policy "profiles_self_insert"  on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_self_update"  on public.profiles for update using (auth.uid() = id);

-- ============================================================
-- Row-Level Security — groups
-- ============================================================
alter table public.groups enable row level security;

create policy "groups_public_read"    on public.groups for select using (true);
create policy "groups_insert_auth"    on public.groups for insert with check (auth.uid() is not null);
create policy "groups_update_creator" on public.groups for update using (auth.uid() = created_by);

-- ============================================================
-- Realtime
-- ============================================================
do $$
begin
  alter publication supabase_realtime add table public.walks;
exception
  when duplicate_object then null;
end $$;
