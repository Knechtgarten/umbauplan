-- Umbauplan – Erweiterung 2: Firmendetails, Pendenzen, Dateien, Notizen

alter table public.trades
  add column if not exists contact text not null default '',
  add column if not exists phone   text not null default '',
  add column if not exists mobile  text not null default '',
  add column if not exists email   text not null default '',
  add column if not exists website text not null default '',
  add column if not exists address text not null default '',
  add column if not exists info    text not null default '';

create table if not exists public.tasks (
  id text primary key default gen_random_uuid()::text,
  trade_id text not null references public.trades(id) on delete cascade,
  text text not null,
  done boolean not null default false,
  created_at timestamptz not null default now(),
  created_by text default (auth.jwt() ->> 'email')
);

create table if not exists public.notes (
  id text primary key default gen_random_uuid()::text,
  text text not null,
  created_at timestamptz not null default now(),
  created_by text default (auth.jwt() ->> 'email')
);

alter table public.tasks enable row level security;
alter table public.notes enable row level security;
drop policy if exists "plan_tasks" on public.tasks;
drop policy if exists "plan_notes" on public.notes;
create policy "plan_tasks" on public.tasks for all to authenticated using (public.is_allowed()) with check (public.is_allowed());
create policy "plan_notes" on public.notes for all to authenticated using (public.is_allowed()) with check (public.is_allowed());

alter publication supabase_realtime add table public.tasks, public.notes;

-- Dateiablage (privat, nur für Adressen aus allowed_emails)
insert into storage.buckets (id, name, public, file_size_limit)
values ('dateien', 'dateien', false, 52428800)
on conflict (id) do nothing;

drop policy if exists "plan_files_read"   on storage.objects;
drop policy if exists "plan_files_insert" on storage.objects;
drop policy if exists "plan_files_update" on storage.objects;
drop policy if exists "plan_files_delete" on storage.objects;
create policy "plan_files_read"   on storage.objects for select to authenticated using (bucket_id = 'dateien' and public.is_allowed());
create policy "plan_files_insert" on storage.objects for insert to authenticated with check (bucket_id = 'dateien' and public.is_allowed());
create policy "plan_files_update" on storage.objects for update to authenticated using (bucket_id = 'dateien' and public.is_allowed());
create policy "plan_files_delete" on storage.objects for delete to authenticated using (bucket_id = 'dateien' and public.is_allowed());
