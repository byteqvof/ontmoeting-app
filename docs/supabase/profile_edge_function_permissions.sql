-- Required privileges for the `profiles` Edge Function.
-- Run this in the Supabase SQL editor or convert it to a Supabase migration.
--
-- The Edge Function log showed:
-- permission denied for table profiles
-- hint: GRANT SELECT ON public.profiles TO service_role;
--
-- The function reads, creates, updates and deletes the authenticated user's
-- profile, and replaces profile category links when interests are saved.

grant usage on schema public to service_role;

grant select, insert, update, delete
on table public.profiles
to service_role;

grant select, insert, delete
on table public.profile_category_links
to service_role;

grant select
on table public.activity_categories
to service_role;

