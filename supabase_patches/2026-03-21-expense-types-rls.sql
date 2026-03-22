-- =========================================
-- EXPENSE TYPES RLS FIX
-- =========================================

-- Enable RLS
ALTER TABLE public.expense_types ENABLE ROW LEVEL SECURITY;

-- Drop old policies if exist
DROP POLICY IF EXISTS "expense_types_select" ON public.expense_types;
DROP POLICY IF EXISTS "expense_types_insert" ON public.expense_types;
DROP POLICY IF EXISTS "expense_types_update" ON public.expense_types;
DROP POLICY IF EXISTS "expense_types_delete" ON public.expense_types;

-- SELECT
CREATE POLICY "expense_types_select"
ON public.expense_types
FOR SELECT
USING (
  company_id = current_company_id()
);

-- INSERT
CREATE POLICY "expense_types_insert"
ON public.expense_types
FOR INSERT
WITH CHECK (
  company_id = current_company_id()
);

-- UPDATE
CREATE POLICY "expense_types_update"
ON public.expense_types
FOR UPDATE
USING (
  company_id = current_company_id()
)
WITH CHECK (
  company_id = current_company_id()
);

-- DELETE (optional → allow only owner/superadmin later)
CREATE POLICY "expense_types_delete"
ON public.expense_types
FOR DELETE
USING (
  company_id = current_company_id()
);