# Multi-client Wedding Invitation Studio

## Product direction
- Phase 1: master-admin-only project management; no client login.
- Phase 2: 10 distinct cover compositions + 10 independent invitation page layouts.
- Phase 3: graphics library, Malayalam/English/Arabic text fields, preview, publish.
- Later: optional client accounts and scoped editing.

## Data isolation
The existing single-wedding tables remain intact for the Issu & Poomol legacy invitation.
New clients use:
- sacred_garden_projects: one row per client invitation, unique public slug, draft/published/archived status.
- sacred_garden_project_settings: project-specific JSON configuration (selected templates, text, translations, colors, fonts, event details).
- sacred_garden_project_media: project-specific photo/video/audio references.
Storage paths use the project UUID as the first folder segment.

## Security model
Only users listed in sacred_garden_admins can create/manage studio projects.
Anonymous visitors can read only published project metadata/settings/media.
No service-role key is used in browser code. Existing site policies and tables are not dropped or rewritten.

## Migration
Review and run supabase-multi-client-studio.sql in the existing Supabase SQL Editor.
This file creates only new project-scoped tables and policies. It does not migrate the legacy Issu & Poomol content automatically.
