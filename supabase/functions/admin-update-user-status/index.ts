import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { corsHeaders } from '../_shared/cors.ts';
import {
  handleFunctionError,
  HttpError,
  jsonResponse,
  requireSuperadmin,
} from '../_shared/admin.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { profile, adminClient } = await requireSuperadmin(req);
    const body = await req.json();

    const userId = String(body.userId ?? '').trim();
    const status = String(body.status ?? '').trim();

    if (!userId) {
      throw new HttpError(400, 'User ID is required.');
    }

    if (!['ACTIVE', 'INACTIVE'].includes(status)) {
      throw new HttpError(400, 'Invalid status.');
    }

    if (userId == profile.id && status == 'INACTIVE') {
      throw new HttpError(400, 'Superadmin cannot deactivate own account here.');
    }

    const { data: targetProfile, error: targetError } = await adminClient
        .from('profiles')
        .select('id, company_id, username, status')
        .eq('id', userId)
        .maybeSingle();

    if (targetError || !targetProfile) {
      throw new HttpError(404, 'Target user not found.');
    }

    if (targetProfile.company_id !== profile.company_id) {
      throw new HttpError(403, 'You cannot update another company user.');
    }

    const { error: updateError } = await adminClient
        .from('profiles')
        .update({
          status,
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId);

    if (updateError) {
      throw updateError;
    }

    return jsonResponse({
      message: 'User status updated successfully.',
    });
  } catch (error) {
    return handleFunctionError(error);
  }
});