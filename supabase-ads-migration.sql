-- Chay doan nay trong Supabase SQL Editor (sau khi da chay supabase-schema.sql)

-- 1. Them link affiliate cho tung san pham
alter table products add column if not exists affiliate_url text;

-- 2. Bang banner quang cao (hien thi o trang chu, bam vao dan toi link)
create table if not exists banners (
  id bigint generated always as identity primary key,
  title text,
  image text not null,
  link text not null,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz default now()
);

alter table banners enable row level security;
create policy "public read active banners" on banners for select using (true);
