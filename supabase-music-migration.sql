-- Run this once in the EXISTING Supabase project's SQL Editor.
-- Adds music URL support and permits audio uploads in the Sacred Garden bucket.
alter table public.sacred_garden_settings
  add column if not exists music_url text not null default '';

update storage.buckets
set allowed_mime_types = array[
  'image/jpeg','image/png','image/webp','image/avif',
  'video/mp4','video/webm','video/quicktime',
  'audio/mpeg','audio/mp3','audio/wav','audio/aac','audio/ogg','audio/mp4'
]
where id = 'sacred-garden-media';
