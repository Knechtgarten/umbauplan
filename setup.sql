-- Umbauplan Wohnungen – Supabase-Setup (separates Projekt)
-- Einmal im SQL Editor ausführen.

create table if not exists public.allowed_emails (
  email text primary key
);

create table if not exists public.units (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  sort int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.trades (
  id text primary key default gen_random_uuid()::text,
  unit_id text not null references public.units(id) on delete cascade,
  name text not null,
  sort int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.bars (
  id text primary key default gen_random_uuid()::text,
  trade_id text not null references public.trades(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  title text not null default '',
  details text not null default '',
  color text not null default 'navy',
  updated_at timestamptz not null default now(),
  updated_by text default (auth.jwt() ->> 'email')
);

-- Zugriffsprüfung: nur Adressen aus allowed_emails
create or replace function public.is_allowed() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.allowed_emails
                 where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

-- Vor dem Login: darf diese Adresse einen Login-Link bekommen?
create or replace function public.email_allowed(e text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.allowed_emails where lower(email) = lower(trim(e)));
$$;
grant execute on function public.email_allowed(text) to anon, authenticated;
grant execute on function public.is_allowed() to authenticated;

alter table public.allowed_emails enable row level security;  -- keine Policies = kein Zugriff von aussen
alter table public.units  enable row level security;
alter table public.trades enable row level security;
alter table public.bars   enable row level security;

drop policy if exists "plan_units" on public.units;
drop policy if exists "plan_trades" on public.trades;
drop policy if exists "plan_bars" on public.bars;
create policy "plan_units"  on public.units  for all to authenticated using (public.is_allowed()) with check (public.is_allowed());
create policy "plan_trades" on public.trades for all to authenticated using (public.is_allowed()) with check (public.is_allowed());
create policy "plan_bars"   on public.bars   for all to authenticated using (public.is_allowed()) with check (public.is_allowed());

-- Live-Aktualisierung
alter publication supabase_realtime add table public.units, public.trades, public.bars;

-- Zugang (weitere Adresse einfach hier ergänzen)
insert into public.allowed_emails (email) values ('mail@knechtgarten.ch') on conflict do nothing;

-- Grundstruktur
insert into public.units (id, name, sort) values
  ('zuberweg-pierre','Zuberweg Ex Pierre',1),
  ('zuberweg-horvort','Zuberweg Ex Horvort',2),
  ('buehl','Bühl',3)
on conflict do nothing;

insert into public.trades (id, unit_id, name, sort)
select u.id || '-' || t.n, u.id, t.name, t.n
from public.units u
cross join (values (1,'Eigenleistung'),(2,'Knechtgarten'),(3,'Elektriker'),(4,'Boden'),(5,'Wände'),
                   (6,'Küche'),(7,'Sanitär'),(8,'Weiteres Gewerk 1'),(9,'Weiteres Gewerk 2')) as t(n,name)
where u.id in ('zuberweg-pierre','zuberweg-horvort','buehl')
on conflict do nothing;
