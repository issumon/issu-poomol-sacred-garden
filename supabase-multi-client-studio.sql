-- Multi-client Wedding Invitation Studio foundation
-- Run ONLY in the existing Supabase project after reviewing this migration.
-- Existing sacred_garden_settings / sacred_garden_media rows are intentionally untouched.
-- The existing Issu & Poomol invitation remains the legacy/default project during migration.

create extension if not exists pgcrypto;

create table if not exists public.sacred_garden_projects (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  client_name text not null,
  couple_names text not null default '',
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sacred_garden_projects_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

create table if not exists public.sacred_garden_project_settings (
  project_id uuid primary key references public.sacred_garden_projects(id) on delete cascade,
  config jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.sacred_garden_project_media (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.sacred_garden_projects(id) on delete cascade,
  media_type text not null check (media_type in ('photo','video','audio')),
  storage_path text not null,
  caption text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(project_id, storage_path)
);

create index if not exists sacred_garden_projects_created_by_idx
  on public.sacred_garden_projects(created_by, created_at desc);
create index if not exists sacred_garden_projects_status_idx
  on public.sacred_garden_projects(status);
create index if not exists sacred_garden_project_media_project_idx
  on public.sacred_garden_project_media(project_id, sort_order, created_at);

alter table public.sacred_garden_projects enable row level security;
alter table public.sacred_garden_project_settings enable row level security;
alter table public.sacred_garden_project_media enable row level security;

drop policy if exists "Studio admins manage projects" on public.sacred_garden_projects;
create policy "Studio admins manage projects"
on public.sacred_garden_projects for all to authenticated
using (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()))
with check (
  created_by = auth.uid()
  and exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid())
);

drop policy if exists "Public can view published studio projects" on public.sacred_garden_projects;
create policy "Public can view published studio projects"
on public.sacred_garden_projects for select to anon, authenticated
using (status = 'published');

drop policy if exists "Studio admins manage project settings" on public.sacred_garden_project_settings;
create policy "Studio admins manage project settings"
on public.sacred_garden_project_settings for all to authenticated
using (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()));

drop policy if exists "Public can view published project settings" on public.sacred_garden_project_settings;
create policy "Public can view published project settings"
on public.sacred_garden_project_settings for select to anon, authenticated
using (exists (
  select 1 from public.sacred_garden_projects p
  where p.id = project_id and p.status = 'published'
));

drop policy if exists "Studio admins manage project media" on public.sacred_garden_project_media;
create policy "Studio admins manage project media"
on public.sacred_garden_project_media for all to authenticated
using (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid()));

drop policy if exists "Public can view published project media" on public.sacred_garden_project_media;
create policy "Public can view published project media"
on public.sacred_garden_project_media for select to anon, authenticated
using (exists (
  select 1 from public.sacred_garden_projects p
  where p.id = project_id and p.status = 'published'
));

-- Project assets must be uploaded under: <project-uuid>/<filename>
-- The bucket remains the existing sacred-garden-media bucket.
drop policy if exists "Studio admins upload project assets" on storage.objects;
create policy "Studio admins upload project assets"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'sacred-garden-media'
  and exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid())
  and (storage.foldername(name))[1] ~* '^[0-9a-f-]{36}$'
  and exists (
    select 1 from public.sacred_garden_projects p
    where p.id::text = (storage.foldername(name))[1]
  )
);

drop policy if exists "Studio admins delete project assets" on storage.objects;
create policy "Studio admins delete project assets"
on storage.objects for delete to authenticated
using (
  bucket_id = 'sacred-garden-media'
  and exists (select 1 from public.sacred_garden_admins a where a.user_id = auth.uid())
  and exists (
    select 1 from public.sacred_garden_projects p
    where p.id::text = (storage.foldername(name))[1]
  )
);

-- Existing bucket-wide public-read policy is retained for compatibility.
-- New public invitation reads are gated by published project rows and project status.
