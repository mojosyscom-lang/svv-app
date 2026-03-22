import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    final data = await _client
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }
}