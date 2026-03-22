import 'package:supabase_flutter/supabase_flutter.dart';

class WorkersService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _requireProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final profile = await _client
        .from('profiles')
        .select('id, company_id, username, display_name, role, status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Profile not found.');
    }

    final companyId = (profile['company_id'] ?? '').toString();
    if (companyId.isEmpty) {
      throw Exception('Company not found for current user.');
    }

    return Map<String, dynamic>.from(profile);
  }

  String _normalizeRole(dynamic role) {
    return (role ?? '').toString().trim().toLowerCase();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> getWorkersPermission() async {
    final profile = await _requireProfile();
    final role = _normalizeRole(profile['role']);

    Map<String, dynamic>? permissionRow;

    try {
      final row = await _client
          .from('role_permissions')
          .select('module_key, can_view, can_create, can_update, can_delete, can_export')
          .eq('role', role)
          .eq('module_key', 'workers')
          .maybeSingle();

      if (row != null) {
        permissionRow = Map<String, dynamic>.from(row);
      }
    } catch (_) {}

    if (permissionRow != null) {
      return {
        'role': role,
        'canView': permissionRow['can_view'] == true,
        'canCreate': permissionRow['can_create'] == true,
        'canUpdate': permissionRow['can_update'] == true,
        'canDelete': permissionRow['can_delete'] == true,
        'canExport': permissionRow['can_export'] == true,
      };
    }

    final fallbackAllowed = role == 'owner' || role == 'superadmin';

    return {
      'role': role,
      'canView': fallbackAllowed,
      'canCreate': fallbackAllowed,
      'canUpdate': fallbackAllowed,
      'canDelete': role == 'superadmin',
      'canExport': role == 'superadmin',
    };
  }

  Future<List<Map<String, dynamic>>> fetchWorkers() async {
    final profile = await _requireProfile();
    final companyId = profile['company_id'].toString();

    final rows = await _client
        .from('workers')
        .select('id, worker_name, monthly_salary, start_date, status, inactive_date, active_date, added_by, created_at, updated_at')
        .eq('company_id', companyId)
        .order('worker_name', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<bool> workerNameExists({
    required String workerName,
    String? excludeId,
  }) async {
    final profile = await _requireProfile();
    final companyId = profile['company_id'].toString();

    dynamic query = _client
        .from('workers')
        .select('id')
        .eq('company_id', companyId)
        .ilike('worker_name', workerName.trim());

    final rows = await query;
    final list = List<Map<String, dynamic>>.from(rows);

    if ((excludeId ?? '').trim().isEmpty) {
      return list.isNotEmpty;
    }

    return list.any((row) => row['id'].toString() != excludeId!.trim());
  }

  Future<void> createWorker({
    required String workerName,
    required double monthlySalary,
    required String startDate,
  }) async {
    final profile = await _requireProfile();
    final user = _client.auth.currentUser!;

    await _client.from('workers').insert({
      'company_id': profile['company_id'],
      'worker_name': workerName.trim(),
      'monthly_salary': monthlySalary,
      'start_date': startDate,
      'status': 'ACTIVE',
      'active_date': startDate,
      'added_by': user.id,
    });
  }

  Future<void> updateWorker({
    required String workerId,
    required String workerName,
    required double monthlySalary,
    required String startDate,
  }) async {
    await _client
        .from('workers')
        .update({
          'worker_name': workerName.trim(),
          'monthly_salary': monthlySalary,
          'start_date': startDate,
        })
        .eq('id', workerId);
  }

  Future<void> updateWorkerStatus({
    required String workerId,
    required String nextStatus,
    required String statusDate,
  }) async {
    final status = nextStatus.trim().toUpperCase();

    if (status != 'ACTIVE' && status != 'INACTIVE') {
      throw Exception('Invalid worker status.');
    }

    await _client
        .from('workers')
        .update({
          'status': status,
          'active_date': status == 'ACTIVE' ? statusDate : null,
          'inactive_date': status == 'INACTIVE' ? statusDate : null,
        })
        .eq('id', workerId);
  }

  Future<String> usernameByUserId(String? userId) async {
    final id = (userId ?? '').trim();
    if (id.isEmpty) return '-';

    try {
      final row = await _client
          .from('profiles')
          .select('username, display_name')
          .eq('id', id)
          .maybeSingle();

      if (row == null) return '-';

      final displayName = (row['display_name'] ?? '').toString().trim();
      final username = (row['username'] ?? '').toString().trim();

      if (displayName.isNotEmpty) return displayName;
      if (username.isNotEmpty) return username;
      return '-';
    } catch (_) {
      return '-';
    }
  }

  double moneyValue(dynamic value) => _toDouble(value);
}