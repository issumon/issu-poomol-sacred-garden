-- Issu & Poomol – The Sacred Garden
-- Run this in the EXISTING Supabase project's SQL Editor.
-- All objects are prefixed/isolated for this site; do not alter old Wedding Invitation tables.

create table if not exists public.sacred_garden_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.sacred_garden_settings (
  id boolean primary key default true check (id = true),
  couple_names text not null default 'Issu & Poomol',
  wedding_date date not null default '2027-12-12',
  wedding_time text not null default '4:00 PM',
  venue text not null default 'Udaipur, Rajasthan',
  whatsapp_number text not null default '',
  welcome_message text not null default 'Your presence and duas will make our day special.',
  updated_at timestamptz not null default now()
);

create table if not exists public.sacred_garden_media (
  id uuid primary key default gen_random_uuid(),
  media_type text not null check (media_type in ('photo','video')),
  storage_path text not null,
  caption text not null default '',
  created_at timestamptz not null default now()
);

alter table public.sacred_garden_admins enable row level security;
alter table public.sacred_garden_settings enable row level security;
alter table public.sacred_garden_media enable row level security;

drop policy if exists "Sacred Garden admins can read own admin row" on public.sacred_garden_admins;
create policy "Sacred Garden admins can read own admin row"
on public.sacred_garden_admins for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Sacred Garden admins manage settings" on public.sacred_garden_settings;
create policy "Sacred Garden admins manage settings"
on public.sacred_garden_settings for all to authenticated
using (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()));

drop policy if exists "Sacred Garden admins manage media records" on public.sacred_garden_media;
create policy "Sacred Garden admins manage media records"
on public.sacred_garden_media for all to authenticated
using (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()));

insert into public.sacred_garden_settings (id)
values (true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('sacred-garden-media', 'sacred-garden-media', true, 104857600,
  array['image/jpeg','image/png','image/webp','image/avif','video/mp4','video/webm','video/quicktime'])
on conflict (id) do nothing;

drop policy if exists "Sacred Garden admins upload media" on storage.objects;
create policy "Sacred Garden admins upload media"
on storage.objects for insert to authenticated
with check (bucket_id = 'sacred-garden-media' and exists (
  select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()
));

drop policy if exists "Sacred Garden admins update media files" on storage.objects;
create policy "Sacred Garden admins update media files"
on storage.objects for update to authenticated
using (bucket_id = 'sacred-garden-media' and exists (
  select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()
))
with check (bucket_id = 'sacred-garden-media' and exists (
  select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()
));

drop policy if exists "Sacred Garden admins delete media files" on storage.objects;
create policy "Sacred Garden admins delete media files"
on storage.objects for delete to authenticated
using (bucket_id = 'sacred-garden-media' and exists (
  select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()
));

drop policy if exists "Public can view Sacred Garden media" on storage.objects;
create policy "Public can view Sacred Garden media"
on storage.objects for select to anon, authenticated
using (bucket_id = 'sacred-garden-media');
