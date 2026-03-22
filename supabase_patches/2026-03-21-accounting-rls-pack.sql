-- =========================================================
-- SVV APP - ACCOUNTING RLS PACK
-- Date: 2026-03-21
-- Covers:
--   expense_types
--   expenses
--   incoming_payments
--   invoices
--   invoice_items
--   gst_bills
--   company_bank_accounts
-- =========================================================

-- =========================================================
-- expense_types
-- =========================================================
alter table public.expense_types enable row level security;

drop policy if exists "expense_types_select" on public.expense_types;
drop policy if exists "expense_types_insert" on public.expense_types;
drop policy if exists "expense_types_update" on public.expense_types;
drop policy if exists "expense_types_delete" on public.expense_types;

create policy "expense_types_select"
on public.expense_types
for select
using (
  company_id = public.current_company_id()
);

create policy "expense_types_insert"
on public.expense_types
for insert
with check (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
);

create policy "expense_types_update"
on public.expense_types
for update
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

create policy "expense_types_delete"
on public.expense_types
for delete
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
);

-- =========================================================
-- expenses
-- =========================================================
alter table public.expenses enable row level security;

drop policy if exists "company isolation read expenses" on public.expenses;
drop policy if exists "owner write expenses" on public.expenses;

create policy "company isolation read expenses"
on public.expenses
for select
using (
  company_id = public.current_company_id()
);

create policy "owner write expenses"
on public.expenses
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- =========================================================
-- incoming_payments
-- =========================================================
alter table public.incoming_payments enable row level security;

drop policy if exists "company isolation read incoming_payments" on public.incoming_payments;
drop policy if exists "owner write incoming_payments" on public.incoming_payments;

create policy "company isolation read incoming_payments"
on public.incoming_payments
for select
using (
  company_id = public.current_company_id()
);

create policy "owner write incoming_payments"
on public.incoming_payments
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- =========================================================
-- invoices
-- =========================================================
alter table public.invoices enable row level security;

drop policy if exists "company isolation read invoices" on public.invoices;
drop policy if exists "owner write invoices" on public.invoices;

create policy "company isolation read invoices"
on public.invoices
for select
using (
  company_id = public.current_company_id()
);

create policy "owner write invoices"
on public.invoices
for all
using (
  company_id = public.current_company_id()
  and public.app_current_role() = any (array['owner', 'superadmin'])
)
with check (
  company_id = public.current_company_id()
);

-- =========================================================
-- invoice_items
-- Important: no company_id usually, so secure through parent invoice
-- =========================================================
alter table public.invoice_items enable row level security;

drop policy if exists "read invoice_items via parent invoice" on public.invoice_items;
drop policy if exists "write invoice_items via parent invoice" on public.invoice_items;

create policy "read invoice_items via parent invoice"
on public.invoice_items
for select
using (
  exists (
    select 1
    from public.invoices i
    where i.id = invoice_items.invoice_id
      and i.company_id = public.current_company_id()
  )
);

create policy "write invoice_items via parent invoice"
on public.invoice_items
for all
using (
  exists (
    select 1
    from public.invoices i
    where i.id = invoice_items.invoice_id
      and i.company_id = public.current_company_id()
      and public.app_current_role() = any (array['owner', 'superadmin'])
  )
)
with check (
  exists (
    select 1
    from public.invoices i
    where i.id = invoice_items.invoice_id
      and i.company_id = public.current_company_id()
  )
);

-- =========================================================
-- gst_bills
-- =========================================================
alter table public.gst_bills enable row level security;

drop policy if exists "company isolation read gst_bills" on public.gst_bills;
drop policy if exists "owner write gst_bills" on public.gst_bills;
drop policy if exists "company isolation read" on public.gst_bills;

create policy "company isolation read gst_bills"
on public.gst_bills
for select
using (
  company_id = public.current_company_id()
);

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

-- =========================================================
-- company_bank_accounts
-- =========================================================
alter table public.company_bank_accounts enable row level security;

drop policy if exists "company isolation read company_bank_accounts" on public.company_bank_accounts;
drop policy if exists "owner write company_bank_accounts" on public.company_bank_accounts;
drop policy if exists "company isolation read" on public.company_bank_accounts;
drop policy if exists "owner write company_bank_accounts" on public.company_bank_accounts;

create policy "company isolation read company_bank_accounts"
on public.company_bank_accounts
for select
using (
  company_id = public.current_company_id()
);

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