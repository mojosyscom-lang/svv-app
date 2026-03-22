import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerAdvancesService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> _requireCompanyId() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', user.id)
        .maybeSingle();

    final companyId = (profile?['company_id'] ?? '').toString();
    if (companyId.isEmpty) {
      throw Exception('No company found for current user.');
    }

    return companyId;
  }

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    return user.id;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String monthKeyFromDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]}-${date.year}';
  }

  Future<List<Map<String, dynamic>>> fetchActiveWorkers() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('workers')
        .select('id, worker_name, status')
        .eq('company_id', companyId)
        .eq('status', 'ACTIVE')
        .order('worker_name', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<bool> isDuplicateAdvance({
    required String workerId,
    required String entryDate,
    required double amount,
  }) async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('worker_advances')
        .select('id, amount')
        .eq('company_id', companyId)
        .eq('worker_id', workerId)
        .eq('entry_date', entryDate);

    for (final row in rows) {
      if (_toDouble(row['amount']) == amount) {
        return true;
      }
    }
    return false;
  }

  Future<void> createAdvance({
    required String workerId,
    required String workerNameSnapshot,
    required String entryDate,
    required double amount,
    String? description,
  }) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    final parsedDate = DateTime.parse(entryDate);
    final monthKey = monthKeyFromDate(parsedDate);

    await _client.from('worker_advances').insert({
      'company_id': companyId,
      'worker_id': workerId,
      'worker_name_snapshot': workerNameSnapshot,
      'entry_date': entryDate,
      'month_key': monthKey,
      'amount': amount,
      'description': (description ?? '').trim().isEmpty ? null : description!.trim(),
      'added_by': userId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchAdvances({
    String? monthKey,
    String? workerId,
  }) async {
    final companyId = await _requireCompanyId();

    dynamic query = _client
        .from('worker_advances')
        .select(
          'id, worker_id, worker_name_snapshot, entry_date, month_key, amount, description, added_by, created_at',
        )
        .eq('company_id', companyId);

    if ((monthKey ?? '').trim().isNotEmpty) {
      query = query.eq('month_key', monthKey!.trim());
    }

    if ((workerId ?? '').trim().isNotEmpty) {
      query = query.eq('worker_id', workerId!.trim());
    }

    final rows = await query
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  double computeTotal(List<Map<String, dynamic>> rows) {
    double total = 0;
    for (final row in rows) {
      total += _toDouble(row['amount']);
    }
    return total;
  }
}