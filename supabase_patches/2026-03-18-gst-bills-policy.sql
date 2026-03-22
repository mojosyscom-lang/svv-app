alter table public.gst_bills enable row level security;

drop policy if exists "company isolation read" on public.gst_bills;
create policy "company isolation read"
on public.gst_bills
for select
using (company_id = public.current_company_id());

drop policy if exists "owner write gst_bills" on public.gst_bills;
create policy "owner write gst_bills"
on public.gst_bills
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);