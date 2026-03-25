import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from './cors.ts';

export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function jsonResponse(data: unknown, status = 200) {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: corsHeaders,
    },
  );
}

export function handleFunctionError(error: unknown) {
  if (error instanceof HttpError) {
    return jsonResponse({ error: error.message }, error.status);
  }

  console.error(error);
  return jsonResponse({ error: 'Unexpected server error.' }, 500);
}

export function createClients(authHeader: string) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    throw new HttpError(500, 'Missing Supabase environment variables.');
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });

  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  return { userClient, adminClient };
}

export async function requireSuperadmin(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new HttpError(401, 'Missing Authorization header.');
  }

  const { userClient, adminClient } = createClients(authHeader);

  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();

  if (authError || !user) {
    throw new HttpError(401, 'Invalid user session.');
  }

  const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('id, company_id, username, display_name, role, status')
      .eq('id', user.id)
      .maybeSingle();

  if (profileError || !profile) {
    throw new HttpError(403, 'Profile not found.');
  }

  if (profile.status !== 'ACTIVE') {
    throw new HttpError(403, 'Inactive user is not allowed.');
  }

  if (profile.role !== 'superadmin') {
    throw new HttpError(403, 'Only superadmin can access this function.');
  }

  return {
    user,
    profile,
    adminClient,
  };
}