import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  bool _isSameMonth(DateTime d, DateTime now) {
    return d.year == now.year && d.month == now.month;
  }

  bool _isSameYear(DateTime d, DateTime now) {
    return d.year == now.year;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<Map<String, dynamic>> getDashboardBundle() async {
    final profile = await _authService.getMyProfile();
    if (profile == null) {
      throw Exception('Profile not found.');
    }

    final companyId = profile['company_id'];
    final displayName =
        (profile['display_name'] ?? profile['username'] ?? 'User').toString();

    final now = DateTime.now();

    final results = await Future.wait([
      _client
          .from('incoming_payments')
          .select('received_amount, tds_amount, payment_date, status')
          .eq('company_id', companyId),
      _client
          .from('expenses')
          .select('amount, tds_amount, entry_date')
          .eq('company_id', companyId),
      _client
          .from('worker_advances')
          .select('amount, entry_date')
          .eq('company_id', companyId),
      _client
          .from('salary_payments')
          .select('amount, payment_date')
          .eq('company_id', companyId),
      _client
          .from('invoices')
          .select('cgst, sgst, igst, invoice_date, status, doc_type')
          .eq('company_id', companyId),
      _client
          .from('gst_bills')
          .select('cgst, sgst, igst, bill_date, status')
          .eq('company_id', companyId),
    ]);

    final incomeRows = List<Map<String, dynamic>>.from(results[0] as List);
    final expenseRows = List<Map<String, dynamic>>.from(results[1] as List);
    final advanceRows = List<Map<String, dynamic>>.from(results[2] as List);
    final salaryRows = List<Map<String, dynamic>>.from(results[3] as List);
    final invoiceRows = List<Map<String, dynamic>>.from(results[4] as List);
    final gstBillRows = List<Map<String, dynamic>>.from(results[5] as List);

    double incomeAll = 0;
    double incomeMonth = 0;
    double tdsCreditYear = 0;

    for (final row in incomeRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;

      final amount = _toDouble(row['received_amount']);
      final tds = _toDouble(row['tds_amount']);
      final dt = _toDate(row['payment_date']);

      incomeAll += amount;

      if (dt != null && _isSameMonth(dt, now)) {
        incomeMonth += amount;
      }

      if (dt != null && _isSameYear(dt, now)) {
        tdsCreditYear += tds;
      }
    }

    double expenseAll = 0;
    double expenseMonth = 0;
    double tdsDebitYear = 0;

    for (final row in expenseRows) {
      final amount = _toDouble(row['amount']);
      final tds = _toDouble(row['tds_amount']);
      final dt = _toDate(row['entry_date']);

      expenseAll += amount;

      if (dt != null && _isSameMonth(dt, now)) {
        expenseMonth += amount;
      }

      if (dt != null && _isSameYear(dt, now)) {
        tdsDebitYear += tds;
      }
    }

    double advanceAll = 0;
    double advanceMonth = 0;

    for (final row in advanceRows) {
      final amount = _toDouble(row['amount']);
      final dt = _toDate(row['entry_date']);

      advanceAll += amount;

      if (dt != null && _isSameMonth(dt, now)) {
        advanceMonth += amount;
      }
    }

    double salaryAll = 0;
    double salaryMonth = 0;

    for (final row in salaryRows) {
      final amount = _toDouble(row['amount']);
      final dt = _toDate(row['payment_date']);

      salaryAll += amount;

      if (dt != null && _isSameMonth(dt, now)) {
        salaryMonth += amount;
      }
    }

    double gstSalesYear = 0;

    for (final row in invoiceRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;
      final docType = (row['doc_type'] ?? '').toString();
      if (docType != 'INVOICE') continue;

      final dt = _toDate(row['invoice_date']);
      if (dt == null || !_isSameYear(dt, now)) continue;

      gstSalesYear +=
          _toDouble(row['cgst']) + _toDouble(row['sgst']) + _toDouble(row['igst']);
    }

    double gstPurchaseYear = 0;

    for (final row in gstBillRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;

      final dt = _toDate(row['bill_date']);
      if (dt == null || !_isSameYear(dt, now)) continue;

      gstPurchaseYear +=
          _toDouble(row['cgst']) + _toDouble(row['sgst']) + _toDouble(row['igst']);
    }

    final accountBalance =
        incomeAll - expenseAll - advanceAll - salaryAll;

    final gstNet = gstSalesYear - gstPurchaseYear;
    final tdsNet = tdsCreditYear - tdsDebitYear;

    return {
      'userName': displayName,
      'monthKey': _monthKey(now),
      'year': now.year,
      'accountBalance': accountBalance,
      'totalIncome': incomeAll,
      'salary': salaryMonth,
      'expense': expenseMonth,
      'advance': advanceMonth,
      'gstNet': gstNet,
      'tdsNet': tdsNet,
    };
  }

  String formatMoney(dynamic value) {
    final amount = _toDouble(value);
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    return f.format(amount);
  }
}