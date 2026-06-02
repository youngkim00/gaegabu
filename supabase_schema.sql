-- ============================================================
-- 가계부 (gaegabu) Supabase 스키마  v2
-- 단일 사용자(anon 접근) · 카테고리/결제수단/거래/정기결제/예산
-- ============================================================

-- 1) 카테고리
create table public.categories (
  id          bigint generated always as identity primary key,
  name        text    not null,
  type        text    not null check (type in ('income','expense')),
  color       text    not null default '#888888',
  sort_order  int     not null default 0,
  created_at  timestamptz not null default now(),
  unique (name, type)
);

-- 2) 결제수단
create table public.payment_methods (
  id          bigint generated always as identity primary key,
  name        text    not null unique,
  kind        text    not null default 'card' check (kind in ('cash','card','account')),
  color       text    not null default '#888888',
  sort_order  int     not null default 0,
  created_at  timestamptz not null default now()
);

-- 3) 거래 내역
create table public.transactions (
  id                bigint generated always as identity primary key,
  txn_date          date    not null,
  type              text    not null check (type in ('income','expense')),
  amount            numeric not null check (amount > 0),
  description       text    not null default '',
  category_id       bigint  references public.categories(id)      on delete set null,
  payment_method_id bigint  references public.payment_methods(id) on delete set null,
  created_at        timestamptz not null default now()
);
create index transactions_date_idx     on public.transactions (txn_date desc);
create index transactions_category_idx on public.transactions (category_id);
create index transactions_pay_idx      on public.transactions (payment_method_id);

-- 4) 정기결제 (결제일 알림)
create table public.recurring_payments (
  id                bigint generated always as identity primary key,
  name              text    not null,
  amount            numeric not null check (amount > 0),
  pay_day           int     not null check (pay_day between 1 and 31),
  type              text    not null default 'expense' check (type in ('income','expense')),
  category_id       bigint  references public.categories(id)      on delete set null,
  payment_method_id bigint  references public.payment_methods(id) on delete set null,
  active            boolean not null default true,
  memo              text    not null default '',
  created_at        timestamptz not null default now()
);

-- 5) 월별 예산
create table public.budgets (
  id          bigint generated always as identity primary key,
  year_month  text    not null check (year_month ~ '^[0-9]{4}-[0-9]{2}$'),
  category_id bigint  not null references public.categories(id) on delete cascade,
  amount      numeric not null check (amount >= 0),
  created_at  timestamptz not null default now(),
  unique (year_month, category_id)
);

-- ============================================================
-- RLS: 전 테이블 활성화 + anon 전체 허용 (로그인 없는 단일 사용자용)
-- 로그인 도입 시 auth.uid() 기반 정책 + user_id 컬럼으로 교체할 것
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['categories','payment_methods','transactions','recurring_payments','budgets']
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "anon_all" on public.%I;', t);
    execute format($p$create policy "anon_all" on public.%I for all to anon using (true) with check (true);$p$, t);
  end loop;
end $$;

-- 기본 시드
insert into public.categories (name, type, color, sort_order) values
  ('월급','income','#27ae60',1),('용돈','income','#2ecc71',2),('기타수입','income','#16a085',3),
  ('식비','expense','#e74c3c',1),('교통','expense','#e67e22',2),('생활','expense','#f39c12',3),
  ('문화','expense','#9b59b6',4),('의료','expense','#1abc9c',5),('기타지출','expense','#95a5a6',6)
on conflict (name, type) do nothing;

insert into public.payment_methods (name, kind, color, sort_order) values
  ('현금','cash','#8e44ad',1),('개인카드','card','#2980b9',2),('법인카드','card','#e67e22',3)
on conflict (name) do nothing;
