-- ============================================
-- 가계부 (gaegabu) Supabase 테이블 스키마
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- ============================================

create table if not exists public.entries (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  entry_date  date        not null,
  type        text        not null check (type in ('income', 'expense')),
  pay         text        not null check (pay  in ('cash', 'pcard', 'ccard')),
  description text        not null,
  amount      numeric     not null check (amount > 0)
);

-- 날짜별 조회 성능을 위한 인덱스
create index if not exists entries_entry_date_idx on public.entries (entry_date desc);

-- ============================================
-- RLS (Row Level Security)
-- 개발 연습용: 익명(anon) 키로 누구나 읽고 쓸 수 있도록 허용.
-- 실제 서비스라면 auth.uid() 기반 정책으로 교체하세요.
-- ============================================
alter table public.entries enable row level security;

drop policy if exists "allow anon all" on public.entries;
create policy "allow anon all"
  on public.entries
  for all
  to anon
  using (true)
  with check (true);
