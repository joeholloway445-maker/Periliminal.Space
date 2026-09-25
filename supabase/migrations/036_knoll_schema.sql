-- KNOLL private security dashboard schema
-- All tables are owner-isolated via RLS (auth.uid() = owner_id)

create table if not exists knoll_activity_log (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  agent_id    text not null,
  agent_name  text not null,
  action      text not null,
  target      text not null,
  status      text not null check (status in ('active','idle','error','standby')),
  latency_ms  integer,
  created_at  timestamptz not null default now()
);

create table if not exists knoll_personas (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references auth.users(id) on delete cascade,
  agent_id   text not null,
  name       text not null,
  voice      text,
  traits     text[] default '{}',
  created_at timestamptz not null default now()
);

create table if not exists knoll_documents (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references auth.users(id) on delete cascade,
  title      text not null,
  agent_id   text not null,
  content    text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists knoll_repos (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  url         text,
  agent_id    text,
  status      text not null default 'active' check (status in ('active','archived','consolidating')),
  description text,
  created_at  timestamptz not null default now()
);

-- RLS
alter table knoll_activity_log enable row level security;
alter table knoll_personas      enable row level security;
alter table knoll_documents     enable row level security;
alter table knoll_repos         enable row level security;

create policy "owner_only" on knoll_activity_log for all using (auth.uid() = owner_id);
create policy "owner_only" on knoll_personas      for all using (auth.uid() = owner_id);
create policy "owner_only" on knoll_documents     for all using (auth.uid() = owner_id);
create policy "owner_only" on knoll_repos         for all using (auth.uid() = owner_id);

-- Realtime for the live feed
alter publication supabase_realtime add table knoll_activity_log;
