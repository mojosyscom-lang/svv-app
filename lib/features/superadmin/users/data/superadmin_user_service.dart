import 'package:supabase_flutter/supabase_flutter.dart';

class SuperadminUserService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

    Map<String, String> _authHeaders() {
    final session = _client.auth.currentSession;
    final token = session?.accessToken ?? '';

    if (token.isEmpty) {
      throw Exception('No active session token found. Please login again.');
    }

    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _requireMyProfile() async {
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

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> getMyAccess() async {
    final profile = await _requireMyProfile();
    final role = (profile['role'] ?? '').toString().trim();
    final status = (profile['status'] ?? '').toString().trim();

    return {
      'profile': profile,
      'role': role,
      'status': status,
      'isSuperadmin': role == 'superadmin' && status == 'ACTIVE',
      'canChangeOwnPassword':
          (role == 'owner' || role == 'superadmin') && status == 'ACTIVE',
    };
  }

  Future<void> _requireSuperadmin() async {
    final access = await getMyAccess();
    if (access['isSuperadmin'] != true) {
      throw Exception('Only superadmin can access this module.');
    }
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    await _requireSuperadmin();

    final res = await _client.functions.invoke(
      'admin-list-users',
      headers: _authHeaders(),
    );

    final data = res.data;
    final payload = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    if (res.status < 200 || res.status >= 300) {
      throw Exception((payload['error'] ?? 'Failed to load users.').toString());
    }

    final rawUsers = (payload['users'] as List?) ?? const [];
    return rawUsers
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required String role,
  }) async {
    await _requireSuperadmin();

    final res = await _client.functions.invoke(
      'admin-create-user',
      headers: _authHeaders(),
      body: {
        'email': email.trim(),
        'password': password,
        'username': username.trim(),
        'displayName': displayName.trim(),
        'role': role.trim(),
      },
    );

    final data = res.data;
    final payload = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    if (res.status < 200 || res.status >= 300) {
      throw Exception((payload['error'] ?? 'Failed to create user.').toString());
    }
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    await _requireSuperadmin();

    final res = await _client.functions.invoke(
      'admin-update-user-status',
      headers: _authHeaders(),
      body: {
        'userId': userId,
        'status': status,
      },
    );

    final data = res.data;
    final payload = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    if (res.status < 200 || res.status >= 300) {
      throw Exception(
        (payload['error'] ?? 'Failed to update user status.').toString(),
      );
    }
  }

  Future<void> updateUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    await _requireSuperadmin();

    final res = await _client.functions.invoke(
      'admin-update-user-password',
      headers: _authHeaders(),
      body: {
        'userId': userId,
        'newPassword': newPassword,
      },
    );

    final data = res.data;
    final payload = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    if (res.status < 200 || res.status >= 300) {
      throw Exception(
        (payload['error'] ?? 'Failed to update user password.').toString(),
      );
    }
  }
}