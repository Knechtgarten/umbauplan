-- Umbauplan – Erweiterung 3: Kosten pro Gewerk (Offertpositionen)
-- Einmal im SQL Editor ausführen.

create table if not exists public.costs (
  id text primary key default gen_random_uuid()::text,
  trade_id text not null references public.trades(id) on delete cascade,
  offer_no text not null default '',
  label text not null default '',
  amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  created_by text default (auth.jwt() ->> 'email')
);

alter table public.costs enable row level security;
drop policy if exists "plan_costs" on public.costs;
create policy "plan_costs" on public.costs for all to authenticated using (public.is_allowed()) with check (public.is_allowed());

alter publication supabase_realtime add table public.costs;
