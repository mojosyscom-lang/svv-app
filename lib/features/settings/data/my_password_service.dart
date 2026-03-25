import 'package:supabase_flutter/supabase_flutter.dart';

class MyPasswordService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> getMyAccess() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final row = await _client
        .from('profiles')
        .select('id, company_id, username, display_name, role, status')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      throw Exception('Profile not found.');
    }

    final profile = Map<String, dynamic>.from(row);
    final role = (profile['role'] ?? '').toString().trim();
    final status = (profile['status'] ?? '').toString().trim();

    return {
      'profile': profile,
      'role': role,
      'status': status,
      'canChangeOwnPassword':
          (role == 'owner' || role == 'superadmin') && status == 'ACTIVE',
    };
  }

  Future<void> changeMyPassword({
    required String newPassword,
  }) async {
    final access = await getMyAccess();
    if (access['canChangeOwnPassword'] != true) {
      throw Exception('You are not allowed to change password here.');
    }

    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}