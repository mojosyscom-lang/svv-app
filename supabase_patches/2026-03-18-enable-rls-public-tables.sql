-- =========================================================
-- Enable RLS on public tables flagged by Supabase warnings
-- Date: 2026-03-18
-- =========================================================

-- -----------------------------
-- companies
-- -----------------------------
alter table public.companies enable row level security;

drop policy if exists "read own company" on public.companies;
create policy "read own company"
on public.companies
for select
using (id = public.current_company_id());

drop policy if exists "owner update own company" on public.companies;
create policy "owner update own company"
on public.companies
for update
using (
  id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  id = public.current_company_id()
);

-- -----------------------------
-- company_bank_accounts
-- -----------------------------
alter table public.company_bank_accounts enable row level security;

drop policy if exists "company isolation read" on public.company_bank_accounts;
create policy "company isolation read"
on public.company_bank_accounts
for select
using (company_id = public.current_company_id());

drop policy if exists "owner write company_bank_accounts" on public.company_bank_accounts;
create policy "owner write company_bank_accounts"
on public.company_bank_accounts
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- -----------------------------
-- company_profiles
-- -----------------------------
alter table public.company_profiles enable row level security;

drop policy if exists "company isolation read" on public.company_profiles;
create policy "company isolation read"
on public.company_profiles
for select
using (company_id = public.current_company_id());

drop policy if exists "owner write company_profiles" on public.company_profiles;
create policy "owner write company_profiles"
on public.company_profiles
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- -----------------------------
-- gst_profiles
-- -----------------------------
alter table public.gst_profiles enable row level security;

drop policy if exists "company isolation read" on public.gst_profiles;
create policy "company isolation read"
on public.gst_profiles
for select
using (company_id = public.current_company_id());

drop policy if exists "owner write gst_profiles" on public.gst_profiles;
create policy "owner write gst_profiles"
on public.gst_profiles
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- -----------------------------
-- notification_jobs
-- safer to keep client app locked out for now
-- service_role can still bypass RLS inherently
-- -----------------------------
alter table public.notification_jobs enable row level security;

drop policy if exists "owner read own company notification_jobs" on public.notification_jobs;
create policy "owner read own company notification_jobs"
on public.notification_jobs
for select
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
);

drop policy if exists "owner write own company notification_jobs" on public.notification_jobs;
create policy "owner write own company notification_jobs"
on public.notification_jobs
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- -----------------------------
-- role_permissions
-- global config table, no company_id column
-- allow authenticated users to read
-- allow only superadmin to manage
-- -----------------------------
alter table public.role_permissions enable row level security;

drop policy if exists "read role_permissions" on public.role_permissions;
create policy "read role_permissions"
on public.role_permissions
for select
to authenticated
using (true);

drop policy if exists "superadmin write role_permissions" on public.role_permissions;
create policy "superadmin write role_permissions"
on public.role_permissions
for all
using (public.app_current_role() = 'superadmin')
with check (public.app_current_role() = 'superadmin');