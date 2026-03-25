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

    const email = String(body.email ?? '').trim().toLowerCase();
    const password = String(body.password ?? '');
    const username = String(body.username ?? '').trim();
    const displayName = String(body.displayName ?? '').trim();
    const role = String(body.role ?? '').trim();

    if (!email || !email.includes('@')) {
      throw new HttpError(400, 'Valid email is required.');
    }

    if (!username) {
      throw new HttpError(400, 'Username is required.');
    }

    if (!displayName) {
      throw new HttpError(400, 'Display name is required.');
    }

    if (password.length < 6) {
      throw new HttpError(400, 'Password must be at least 6 characters.');
    }

    if (!['staff', 'owner', 'superadmin'].includes(role)) {
      throw new HttpError(400, 'Invalid role.');
    }

    const { data: existingUsername, error: existingUsernameError } =
        await adminClient
            .from('profiles')
            .select('id')
            .eq('username', username)
            .maybeSingle();

    if (existingUsernameError) {
      throw existingUsernameError;
    }

    if (existingUsername != null) {
      throw new HttpError(409, 'Username already exists.');
    }

    const { data: createdUser, error: createError } =
        await adminClient.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            username,
            display_name: displayName,
          },
        });

    if (createError || !createdUser.user) {
      throw new HttpError(
        400,
        createError?.message ?? 'Failed to create auth user.',
      );
    }

    try {
      const { error: profileInsertError } = await adminClient
          .from('profiles')
          .insert({
            id: createdUser.user.id,
            company_id: profile.company_id,
            username,
            display_name: displayName,
            role,
            status: 'ACTIVE',
          });

      if (profileInsertError) {
        throw profileInsertError;
      }
    } catch (error) {
      await adminClient.auth.admin.deleteUser(createdUser.user.id);
      throw error;
    }

    return jsonResponse(
      {
        message: 'User created successfully.',
        userId: createdUser.user.id,
      },
      201,
    );
  } catch (error) {
    return handleFunctionError(error);
  }
});