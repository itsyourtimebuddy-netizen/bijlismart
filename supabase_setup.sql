-- BijliSmart: Slice 1 database setup (run once in Supabase > SQL Editor)
-- Stores only numbers and a category. No name, phone, address or consumer number.
-- NOT YET RUN OR TESTED by the assistant. Run it, then send me any error text.

create table if not exists public.bills (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  bill       numeric(12,2) not null check (bill > 0 and bill <= 100000000),
  units      numeric(12,2) not null check (units > 0 and units <= 10000000),
  days       integer       not null check (days between 1 and 366),
  category   text          not null check (category in ('res','com','ind')),
  disc       text          check (disc is null or char_length(disc) <= 20)
);

create index if not exists bills_user_created_idx on public.bills (user_id, created_at desc);

-- Row Level Security: each logged-in user can only see and change their OWN rows.
alter table public.bills enable row level security;

create policy "bills_select_own" on public.bills
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "bills_insert_own" on public.bills
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "bills_delete_own" on public.bills
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- No update policy on purpose: saved bills cannot be edited, only added or deleted.
-- Deleting a user in Supabase > Authentication also deletes their bills (on delete cascade).
