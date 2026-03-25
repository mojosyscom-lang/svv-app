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
    const newPassword = String(body.newPassword ?? '');

    if (!userId) {
      throw new HttpError(400, 'User ID is required.');
    }

    if (newPassword.length < 6) {
      throw new HttpError(400, 'Password must be at least 6 characters.');
    }

    const { data: targetProfile, error: targetError } = await adminClient
        .from('profiles')
        .select('id, company_id, username')
        .eq('id', userId)
        .maybeSingle();

    if (targetError || !targetProfile) {
      throw new HttpError(404, 'Target user not found.');
    }

    if (targetProfile.company_id !== profile.company_id) {
      throw new HttpError(403, 'You cannot edit another company user.');
    }

    const { error: updateError } = await adminClient.auth.admin.updateUserById(
      userId,
      { password: newPassword },
    );

    if (updateError) {
      throw new HttpError(400, updateError.message);
    }

    return jsonResponse({
      message: 'Password updated successfully.',
    });
  } catch (error) {
    return handleFunctionError(error);
  }
});