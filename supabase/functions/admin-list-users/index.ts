import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { handleFunctionError, jsonResponse, requireSuperadmin } from '../_shared/admin.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { profile, adminClient } = await requireSuperadmin(req);

    const { data, error } = await adminClient
        .from('profiles')
        .select('id, company_id, username, display_name, role, status, created_at, last_login_at')
        .eq('company_id', profile.company_id)
        .order('created_at', { ascending: true });

    if (error) {
      throw error;
    }

    return jsonResponse({
      users: data ?? [],
    });
  } catch (error) {
    return handleFunctionError(error);
  }
});