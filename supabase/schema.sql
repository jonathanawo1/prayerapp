-- ============================================================
-- Prayer Walk Tracker — Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Enable uuid extension (usually already enabled)
create extension if not exists "uuid-ossp";

-- ============================================================
-- walks table
-- ============================================================
create table if not exists public.walks (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  path        jsonb not null default '[]',       -- array of {latitude, longitude}
  distance    float not null default 0,          -- metres
  duration    int   not null default 0,          -- seconds
  created_at  timestamptz not null default now()
);

-- Index for fast per-user queries
create index if not exists walks_user_id_idx on public.walks(user_id);

-- Index for chronological ordering
create index if not exists walks_created_at_idx on public.walks(created_at desc);

-- ============================================================
-- Row-Level Security
-- ============================================================
alter table public.walks enable row level security;

-- Anyone (including anonymous) can read all walks
create policy "walks_public_read"
  on public.walks
  for select
  using (true);

-- Users can only insert their own walks
create policy "walks_insert_own"
  on public.walks
  for insert
  with check (auth.uid() = user_id);

-- Users can only update their own walks
create policy "walks_update_own"
  on public.walks
  for update
  using (auth.uid() = user_id);

-- Users can only delete their own walks
create policy "walks_delete_own"
  on public.walks
  for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Realtime — enable for walks table
-- ============================================================
-- In the Supabase dashboard go to:
-- Database > Replication > supabase_realtime publication
-- and enable the `walks` table.
--
-- Or run:
alter publication supabase_realtime add table public.walks;
