import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _requireMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final row = await _client
        .from('profiles')
        .select('id, company_id, role, username, display_name, status')
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

    return {
      'profile': profile,
      'role': role,
      'canView': role == 'owner' || role == 'superadmin',
      'canEdit': role == 'superadmin',
      'isSuperadmin': role == 'superadmin',
      'isOwner': role == 'owner',
      'isStaff': role == 'staff',
    };
  }

  Future<Map<String, dynamic>> fetchCompanyProfile() async {
    final access = await getMyAccess();
    final profile = Map<String, dynamic>.from(access['profile'] as Map);

    if (access['canView'] != true) {
      throw Exception('You are not allowed to view company profile.');
    }

    final companyId = (profile['company_id'] ?? '').toString();

    if (companyId.isEmpty) {
      throw Exception('No company found for current user.');
    }

    final row = await _client
        .from('company_profiles')
        .select()
        .eq('company_id', companyId)
        .maybeSingle();

    if (row == null) {
      return {
        'company_id': companyId,
        'company_name': '',
        'address': '',
        'phone': '',
        'gstin': '',
        'place_of_supply': '',
        'terms': '',
        'terms_invoice': '',
        'short_desc': '',
        'logo_url': '',
        'bank_qr_url': '',
        'print_bg_url': '',
        'inv_format': '',
        'install_terms': '',
      };
    }

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> fetchAdminOverview() async {
    final access = await getMyAccess();
    final company = await fetchCompanyProfile();

    final companyName = (company['company_name'] ?? '').toString().trim();
    final gstin = (company['gstin'] ?? '').toString().trim();
    final logoUrl = (company['logo_url'] ?? '').toString().trim();

    return {
      'companyName': companyName.isEmpty ? 'Not Saved' : companyName,
      'gstinStatus': gstin.isEmpty ? 'Missing' : 'Saved',
      'logoStatus': logoUrl.isEmpty ? 'Missing' : 'Saved',
      'editAccess': access['canEdit'] == true ? 'Superadmin' : 'Read Only',
    };
  }

  Future<String?> fetchSplashLogoUrl() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final company = await fetchCompanyProfile();
    final logoUrl = (company['logo_url'] ?? '').toString().trim();

    if (logoUrl.isEmpty) return null;
    return logoUrl;
  }

  Future<void> saveCompanyProfile({
    required String companyName,
    required String address,
    required String phone,
    required String gstin,
    required String placeOfSupply,
    required String terms,
    required String termsInvoice,
    required String shortDesc,
    required String logoUrl,
    required String bankQrUrl,
    required String printBgUrl,
    required String invFormat,
    required String installTerms,
  }) async {
    final access = await getMyAccess();
    final canEdit = access['canEdit'] == true;
    if (!canEdit) {
      throw Exception('You are not allowed to edit company profile.');
    }

    final profile = Map<String, dynamic>.from(access['profile'] as Map);
    final companyId = (profile['company_id'] ?? '').toString();

    final existing = await _client
        .from('company_profiles')
        .select('id')
        .eq('company_id', companyId)
        .maybeSingle();

    final payload = {
      'company_id': companyId,
      'company_name': companyName.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'gstin': gstin.trim(),
      'place_of_supply': placeOfSupply.trim(),
      'terms': terms.trim(),
      'terms_invoice': termsInvoice.trim(),
      'short_desc': shortDesc.trim(),
      'logo_url': logoUrl.trim(),
      'bank_qr_url': bankQrUrl.trim(),
      'print_bg_url': printBgUrl.trim(),
      'inv_format': invFormat.trim(),
      'install_terms': installTerms.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing == null) {
      await _client.from('company_profiles').insert({
        ...payload,
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }

    await _client
        .from('company_profiles')
        .update(payload)
        .eq('id', existing['id']);
  }
}