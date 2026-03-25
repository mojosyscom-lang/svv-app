import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { handleFunctionError, jsonResponse, requireSuperadmin } from '../_shared/admin.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { profile, adminClient } = await requireSuperadmin(req);

const { data: profiles, error } = await adminClient
    .from('profiles')
    .select('id, company_id, username, display_name, role, status, created_at, last_login_at')
    .eq('company_id', profile.company_id)
    .order('created_at', { ascending: true });

if (error) {
  throw error;
}

// 🔥 fetch auth users (emails)
const { data: authUsersData, error: authError } =
  await adminClient.auth.admin.listUsers();

if (authError) {
  throw authError;
}

const authUsers = authUsersData?.users ?? [];

// 🔗 merge email into profiles
const users = (profiles ?? []).map((p) => {
  const authUser = authUsers.find((u) => u.id === p.id);
  return {
    ...p,
    email: authUser?.email ?? null,
  };
});

    if (error) {
      throw error;
    }

return jsonResponse({
  users,
});
  } catch (error) {
    return handleFunctionError(error);
  }
});