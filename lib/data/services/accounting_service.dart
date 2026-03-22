import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_refresh_bus.dart';

class AccountingService {
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

  String _newCode(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> getAccountingHomeSummary() async {
    final companyId = await _requireCompanyId();

    final incomeRows = await _client
        .from('incoming_payments')
        .select('received_amount, status')
        .eq('company_id', companyId)
        .order('payment_date', ascending: false);

    final expenseRows = await _client
        .from('expenses')
        .select('amount')
        .eq('company_id', companyId)
        .order('entry_date', ascending: false);

    final gstRows = await _client
        .from('gst_bills')
        .select('gst_amount, status')
        .eq('company_id', companyId)
        .order('bill_date', ascending: false);

    final invoiceRows = await _client
        .from('invoices')
        .select('grand_total, doc_type, status')
        .eq('company_id', companyId)
        .order('invoice_date', ascending: false);

    final bankRows = await _client
        .from('company_bank_accounts')
        .select('id, is_active')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    double incomeTotal = 0;
    for (final row in incomeRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;
      incomeTotal += _toDouble(row['received_amount']);
    }

    double expenseTotal = 0;
    for (final row in expenseRows) {
      expenseTotal += _toDouble(row['amount']);
    }

    double gstInputTotal = 0;
    for (final row in gstRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;
      gstInputTotal += _toDouble(row['gst_amount']);
    }

    double invoiceTotal = 0;
    int invoiceCount = 0;
    for (final row in invoiceRows) {
      if ((row['status'] ?? 'ACTIVE').toString() != 'ACTIVE') continue;
      if ((row['doc_type'] ?? '').toString() != 'INVOICE') continue;
      invoiceCount += 1;
      invoiceTotal += _toDouble(row['grand_total']);
    }

    int activeBankCount = 0;
    for (final row in bankRows) {
      if (row['is_active'] == true) activeBankCount += 1;
    }

    return {
      'incomeCount': incomeRows.length,
      'expenseCount': expenseRows.length,
      'gstBillCount': gstRows.length,
      'invoiceCount': invoiceCount,
      'bankAccountCount': activeBankCount,
      'incomeTotal': incomeTotal,
      'expenseTotal': expenseTotal,
      'gstInputTotal': gstInputTotal,
      'invoiceTotal': invoiceTotal,
    };
  }

  Future<List<Map<String, dynamic>>> fetchIncomingPayments() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('incoming_payments')
        .select(
          'id, payment_code, payment_date, pay_type, mode, '
          'client_id, client_name_snapshot, invoice_id, quotation_id, '
          'bank_account_id, cheque_no, ref_no, '
          'received_amount, tds_amount, note, status',
        )
        .eq('company_id', companyId)
        .order('payment_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('expenses')
        .select('id, entry_date, category, description, amount, tds_amount')
        .eq('company_id', companyId)
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchGstBills() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('gst_bills')
        .select('id, bill_code, bill_no, bill_date, vendor, total_amount, gst_type, gst_amount, cgst, sgst, igst, status')
        .eq('company_id', companyId)
        .order('bill_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchInvoices() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('invoices')
        .select(
          'id, invoice_no, invoice_date, doc_type, client_id, '
          'client_name_snapshot, client_company_snapshot, '
          'client_phone_snapshot, client_phone2_snapshot, '
          'client_address_snapshot, client_gstin_snapshot, '
          'venue, gst_type, gst_rate, subtotal, cgst, sgst, igst, '
          'grand_total, status',
        )
        .eq('company_id', companyId)
        .order('invoice_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchBankAccounts() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('company_bank_accounts')
        .select('id, label, bank_name, branch_name, account_name, account_no_last4, ifsc, upi_id, is_active, is_default')
        .eq('company_id', companyId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchInvoiceOptions() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('invoices')
        .select(
          'id, invoice_no, doc_type, client_id, client_name_snapshot, '
          'grand_total, status, invoice_date',
        )
        .eq('company_id', companyId)
        .order('invoice_date', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchBankAccountOptions() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('company_bank_accounts')
        .select('id, label, bank_name, is_active, is_default')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<double> getInvoiceSettledAmount(String invoiceId, {String? excludePaymentId}) async {
    final companyId = await _requireCompanyId();

    var query = _client
        .from('incoming_payments')
        .select('id, invoice_id, applied_to_invoice_id, received_amount, tds_amount, status')
        .eq('company_id', companyId)
        .eq('status', 'ACTIVE');

    final rows = await query;

    double settled = 0;
    for (final row in rows) {
      if (excludePaymentId != null && row['id'].toString() == excludePaymentId) {
        continue;
      }

      final invoiceMatch = row['invoice_id']?.toString() == invoiceId;
      final appliedMatch = row['applied_to_invoice_id']?.toString() == invoiceId;
      if (!invoiceMatch && !appliedMatch) continue;

      settled += _toDouble(row['received_amount']) + _toDouble(row['tds_amount']);
    }

    return settled;
  }

  Future<double> getInvoiceBalance(String invoiceId, {String? excludePaymentId}) async {
    final invoice = await _client
        .from('invoices')
        .select('id, grand_total')
        .eq('id', invoiceId)
        .maybeSingle();

    if (invoice == null) return 0;

    final grandTotal = _toDouble(invoice['grand_total']);
    final settled = await getInvoiceSettledAmount(
      invoiceId,
      excludePaymentId: excludePaymentId,
    );

    final balance = grandTotal - settled;
    return balance < 0 ? 0 : balance;
  }



  Future<List<Map<String, dynamic>>> fetchExpenseTypes() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('expense_types')
        .select('id, type_name, status')
        .eq('company_id', companyId)
        .eq('status', 'ACTIVE')
        .order('type_name', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchClientOptions() async {
    final companyId = await _requireCompanyId();

    final rows = await _client
        .from('clients')
        .select('id, client_name, client_company, phone1, phone2, address, gst, status')
        .eq('company_id', companyId)
        .eq('status', 'ACTIVE')
        .order('client_name', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createExpenseType(String typeName) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    await _client.from('expense_types').insert({
      'company_id': companyId,
      'type_name': typeName.trim(),
      'status': 'ACTIVE',
      'added_by': userId,
    });
  }



  Future<void> createIncomingPayment({
    required String paymentDate,
    required String payType,
    required String mode,
    String? clientId,
    required String clientName,
    String? invoiceId,
    String? quotationId,
    String? bankAccountId,
    String? chequeNo,
    String? refNo,
    required double receivedAmount,
    required double tdsAmount,
    required String note,
    required String status,
  }) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    final normalizedPayType = payType.trim().toUpperCase();
    final normalizedMode = mode.trim().toUpperCase();
    final cleanInvoiceId = (invoiceId == null || invoiceId.isEmpty) ? null : invoiceId;
    final cleanQuotationId = (quotationId == null || quotationId.isEmpty) ? null : quotationId;

    await _client.from('incoming_payments').insert({
      'company_id': companyId,
      'payment_code': _newCode('PAY-'),
      'payment_date': paymentDate,
      'pay_type': normalizedPayType.isEmpty ? null : normalizedPayType,
      'mode': normalizedMode.isEmpty ? null : normalizedMode,
      'client_id': (clientId == null || clientId.isEmpty) ? null : clientId,
      'client_name_snapshot': clientName.trim().isEmpty ? null : clientName.trim(),
      'invoice_id': normalizedPayType == 'INVOICE' ? cleanInvoiceId : null,
      'quotation_id': normalizedPayType == 'QUOTATION_ADVANCE' ? cleanQuotationId : null,
      'bank_account_id': (bankAccountId == null || bankAccountId.isEmpty) ? null : bankAccountId,
      'cheque_no': (chequeNo == null || chequeNo.trim().isEmpty) ? null : chequeNo.trim(),
      'ref_no': (refNo == null || refNo.trim().isEmpty) ? null : refNo.trim(),
      'applied_to_invoice_id': normalizedPayType == 'INVOICE' ? cleanInvoiceId : null,
      'applied_amount': normalizedPayType == 'INVOICE' ? receivedAmount : null,
      'received_amount': receivedAmount,
      'tds_amount': tdsAmount,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': status,
      'added_by': userId,
    });

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> updateIncomingPayment({
    required String id,
    required String paymentDate,
    required String payType,
    required String mode,
    String? clientId,
    required String clientName,
    String? invoiceId,
    String? quotationId,
    String? bankAccountId,
    String? chequeNo,
    String? refNo,
    required double receivedAmount,
    required double tdsAmount,
    required String note,
    required String status,
  }) async {
    final normalizedPayType = payType.trim().toUpperCase();
    final normalizedMode = mode.trim().toUpperCase();
    final cleanInvoiceId = (invoiceId == null || invoiceId.isEmpty) ? null : invoiceId;
    final cleanQuotationId = (quotationId == null || quotationId.isEmpty) ? null : quotationId;

    await _client.from('incoming_payments').update({
      'payment_date': paymentDate,
      'pay_type': normalizedPayType.isEmpty ? null : normalizedPayType,
      'mode': normalizedMode.isEmpty ? null : normalizedMode,
      'client_id': (clientId == null || clientId.isEmpty) ? null : clientId,
      'client_name_snapshot': clientName.trim().isEmpty ? null : clientName.trim(),
      'invoice_id': normalizedPayType == 'INVOICE' ? cleanInvoiceId : null,
      'quotation_id': normalizedPayType == 'QUOTATION_ADVANCE' ? cleanQuotationId : null,
      'bank_account_id': (bankAccountId == null || bankAccountId.isEmpty) ? null : bankAccountId,
      'cheque_no': (chequeNo == null || chequeNo.trim().isEmpty) ? null : chequeNo.trim(),
      'ref_no': (refNo == null || refNo.trim().isEmpty) ? null : refNo.trim(),
      'applied_to_invoice_id': normalizedPayType == 'INVOICE' ? cleanInvoiceId : null,
      'applied_amount': normalizedPayType == 'INVOICE' ? receivedAmount : null,
      'received_amount': receivedAmount,
      'tds_amount': tdsAmount,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': status,
    }).eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> setIncomingPaymentStatus({
    required String id,
    required String status,
  }) async {
    await _client
        .from('incoming_payments')
        .update({'status': status})
        .eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> createExpense({
    required String entryDate,
    required String category,
    required String description,
    required double amount,
    required double tdsAmount,
  }) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    await _client.from('expenses').insert({
      'company_id': companyId,
      'entry_date': entryDate,
      'month_key': entryDate.substring(0, 7),
      'category': category.trim().isEmpty ? null : category.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'amount': amount,
      'tds_amount': tdsAmount,
      'added_by': userId,
    });

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> updateExpense({
    required String id,
    required String entryDate,
    required String category,
    required String description,
    required double amount,
    required double tdsAmount,
  }) async {
    await _client.from('expenses').update({
      'entry_date': entryDate,
      'month_key': entryDate.substring(0, 7),
      'category': category.trim().isEmpty ? null : category.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'amount': amount,
      'tds_amount': tdsAmount,
    }).eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> createGstBill({
    required String billDate,
    required String billNo,
    required String vendor,
    required double totalAmount,
    required String gstType,
    required double gstAmount,
    required double cgst,
    required double sgst,
    required double igst,
    required String status,
  }) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    await _client.from('gst_bills').insert({
      'company_id': companyId,
      'bill_code': _newCode('GSTB-'),
      'bill_no': billNo.trim().isEmpty ? null : billNo.trim(),
      'bill_date': billDate,
      'vendor': vendor.trim().isEmpty ? null : vendor.trim(),
      'total_amount': totalAmount,
      'gst_type': gstType.trim().isEmpty ? null : gstType.trim(),
      'gst_amount': gstAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'status': status,
      'added_by': userId,
    });

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> updateGstBill({
    required String id,
    required String billDate,
    required String billNo,
    required String vendor,
    required double totalAmount,
    required String gstType,
    required double gstAmount,
    required double cgst,
    required double sgst,
    required double igst,
    required String status,
  }) async {
    await _client.from('gst_bills').update({
      'bill_no': billNo.trim().isEmpty ? null : billNo.trim(),
      'bill_date': billDate,
      'vendor': vendor.trim().isEmpty ? null : vendor.trim(),
      'total_amount': totalAmount,
      'gst_type': gstType.trim().isEmpty ? null : gstType.trim(),
      'gst_amount': gstAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'status': status,
    }).eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> setGstBillStatus({
    required String id,
    required String status,
  }) async {
    await _client
        .from('gst_bills')
        .update({'status': status})
        .eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> createBankAccount({
    required String label,
    required String bankName,
    required String branchName,
    required String accountName,
    required String accountNoFull,
    required String ifsc,
    required String upiId,
    required bool isActive,
    required bool isDefault,
  }) async {
    final companyId = await _requireCompanyId();

    if (isDefault) {
      await _client
          .from('company_bank_accounts')
          .update({'is_default': false})
          .eq('company_id', companyId);
    }

    final digits = accountNoFull.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    await _client.from('company_bank_accounts').insert({
      'company_id': companyId,
      'bank_account_code': _newCode('BANK-'),
      'label': label.trim().isEmpty ? null : label.trim(),
      'bank_name': bankName.trim().isEmpty ? null : bankName.trim(),
      'branch_name': branchName.trim().isEmpty ? null : branchName.trim(),
      'account_name': accountName.trim().isEmpty ? null : accountName.trim(),
      'account_no_full': accountNoFull.trim().isEmpty ? null : accountNoFull.trim(),
      'account_no_last4': last4.isEmpty ? null : last4,
      'ifsc': ifsc.trim().isEmpty ? null : ifsc.trim(),
      'upi_id': upiId.trim().isEmpty ? null : upiId.trim(),
      'is_active': isActive,
      'is_default': isDefault,
    });

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> updateBankAccount({
    required String id,
    required String label,
    required String bankName,
    required String branchName,
    required String accountName,
    required String accountNoFull,
    required String ifsc,
    required String upiId,
    required bool isActive,
    required bool isDefault,
  }) async {
    final companyId = await _requireCompanyId();

    if (isDefault) {
      await _client
          .from('company_bank_accounts')
          .update({'is_default': false})
          .eq('company_id', companyId);
    }

    final digits = accountNoFull.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    await _client.from('company_bank_accounts').update({
      'label': label.trim().isEmpty ? null : label.trim(),
      'bank_name': bankName.trim().isEmpty ? null : bankName.trim(),
      'branch_name': branchName.trim().isEmpty ? null : branchName.trim(),
      'account_name': accountName.trim().isEmpty ? null : accountName.trim(),
      'account_no_full': accountNoFull.trim().isEmpty ? null : accountNoFull.trim(),
      'account_no_last4': last4.isEmpty ? null : last4,
      'ifsc': ifsc.trim().isEmpty ? null : ifsc.trim(),
      'upi_id': upiId.trim().isEmpty ? null : upiId.trim(),
      'is_active': isActive,
      'is_default': isDefault,
    }).eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> setBankAccountActive({
    required String id,
    required bool isActive,
  }) async {
    await _client
        .from('company_bank_accounts')
        .update({'is_active': isActive})
        .eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

    String _normalizeDocType(String value) {
    final v = value.trim().toUpperCase();
    return v == 'QUOTATION' ? 'QUOTATION' : 'INVOICE';
  }

  String _normalizeGstType(String value) {
    final v = value.trim().toUpperCase();
    if (v == 'CGST_SGST') return 'CGST_SGST';
    if (v == 'IGST') return 'IGST';
    return 'NONE';
  }

  String _normalizeInvoiceStatus(String value) {
    final v = value.trim().toUpperCase();
    return v == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
  }

  double _round2(num value) {
    return double.parse(value.toStringAsFixed(2));
  }

  Map<String, double> calculateInvoiceAmounts({
    required String docType,
    required String gstType,
    required double gstRate,
    required double subtotal,
  }) {
    final normalizedDocType = _normalizeDocType(docType);
    final normalizedGstType = _normalizeGstType(gstType);
    final double cleanSubtotal = subtotal < 0 ? 0.0 : _round2(subtotal);
    final double cleanRate = gstRate < 0 ? 0.0 : gstRate;

    if (normalizedDocType == 'QUOTATION' ||
        normalizedGstType == 'NONE' ||
        cleanRate <= 0) {
      return <String, double>{
        'subtotal': cleanSubtotal,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'grand_total': cleanSubtotal,
      };
    }

    if (normalizedGstType == 'IGST') {
      final double igst = _round2(cleanSubtotal * cleanRate / 100);
      return <String, double>{
        'subtotal': cleanSubtotal,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': igst,
        'grand_total': _round2(cleanSubtotal + igst),
      };
    }

    final double halfRate = cleanRate / 2;
    final double cgst = _round2(cleanSubtotal * halfRate / 100);
    final double sgst = _round2(cleanSubtotal * halfRate / 100);

    return <String, double>{
      'subtotal': cleanSubtotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': 0.0,
      'grand_total': _round2(cleanSubtotal + cgst + sgst),
    };
  }

  Future<bool> invoiceNoExists({
    required String invoiceNo,
    required String docType,
    String? excludeId,
  }) async {
    final companyId = await _requireCompanyId();
    final normalizedDocType = _normalizeDocType(docType);
    final cleanInvoiceNo = invoiceNo.trim();

    if (cleanInvoiceNo.isEmpty) return false;

    final rows = await _client
        .from('invoices')
        .select('id, invoice_no, doc_type')
        .eq('company_id', companyId)
        .eq('invoice_no', cleanInvoiceNo)
        .eq('doc_type', normalizedDocType);

    for (final row in rows) {
      if (excludeId != null && row['id']?.toString() == excludeId) {
        continue;
      }
      return true;
    }

    return false;
  }

  Future<void> createInvoice({
    required String invoiceNo,
    required String invoiceDate,
    required String docType,
    String? clientId,
    required String clientNameSnapshot,
    required String clientCompanySnapshot,
    required String clientPhoneSnapshot,
    required String clientPhone2Snapshot,
    required String clientAddressSnapshot,
    required String clientGstinSnapshot,
    required String venue,
    required String gstType,
    required double gstRate,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double igst,
    required double grandTotal,
    required String status,
  }) async {
    final companyId = await _requireCompanyId();
    final userId = _requireUserId();

    final normalizedDocType = _normalizeDocType(docType);
    final normalizedGstType =
        normalizedDocType == 'QUOTATION' ? 'NONE' : _normalizeGstType(gstType);
    final normalizedStatus = _normalizeInvoiceStatus(status);

    final amounts = calculateInvoiceAmounts(
      docType: normalizedDocType,
      gstType: normalizedGstType,
      gstRate: normalizedDocType == 'QUOTATION' ? 0 : gstRate,
      subtotal: subtotal,
    );

    await _client.from('invoices').insert({
      'company_id': companyId,
      'invoice_code': _newCode('INV-'),
      'invoice_no': invoiceNo.trim(),
      'invoice_date': invoiceDate,
      'doc_type': normalizedDocType,
      'client_id': (clientId == null || clientId.isEmpty) ? null : clientId,
      'client_name_snapshot': clientNameSnapshot.trim(),
      'client_company_snapshot': clientCompanySnapshot.trim().isEmpty
          ? null
          : clientCompanySnapshot.trim(),
      'client_phone_snapshot': clientPhoneSnapshot.trim().isEmpty
          ? null
          : clientPhoneSnapshot.trim(),
      'client_phone2_snapshot': clientPhone2Snapshot.trim().isEmpty
          ? null
          : clientPhone2Snapshot.trim(),
      'client_address_snapshot': clientAddressSnapshot.trim().isEmpty
          ? null
          : clientAddressSnapshot.trim(),
      'client_gstin_snapshot': clientGstinSnapshot.trim().isEmpty
          ? null
          : clientGstinSnapshot.trim(),
      'venue': venue.trim().isEmpty ? null : venue.trim(),
      'gst_type': normalizedGstType,
      'gst_rate': normalizedDocType == 'QUOTATION' ? 0 : _round2(gstRate),
      'subtotal': amounts['subtotal'],
      'cgst': amounts['cgst'],
      'sgst': amounts['sgst'],
      'igst': amounts['igst'],
      'grand_total': amounts['grand_total'],
      'status': normalizedStatus,
      'created_by': userId,
    });

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> updateInvoice({
    required String id,
    required String invoiceNo,
    required String invoiceDate,
    required String docType,
    String? clientId,
    required String clientNameSnapshot,
    required String clientCompanySnapshot,
    required String clientPhoneSnapshot,
    required String clientPhone2Snapshot,
    required String clientAddressSnapshot,
    required String clientGstinSnapshot,
    required String venue,
    required String gstType,
    required double gstRate,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double igst,
    required double grandTotal,
    required String status,
  }) async {
    final normalizedDocType = _normalizeDocType(docType);
    final normalizedGstType =
        normalizedDocType == 'QUOTATION' ? 'NONE' : _normalizeGstType(gstType);
    final normalizedStatus = _normalizeInvoiceStatus(status);

    final amounts = calculateInvoiceAmounts(
      docType: normalizedDocType,
      gstType: normalizedGstType,
      gstRate: normalizedDocType == 'QUOTATION' ? 0 : gstRate,
      subtotal: subtotal,
    );

    await _client.from('invoices').update({
      'invoice_no': invoiceNo.trim(),
      'invoice_date': invoiceDate,
      'doc_type': normalizedDocType,
      'client_id': (clientId == null || clientId.isEmpty) ? null : clientId,
      'client_name_snapshot': clientNameSnapshot.trim(),
      'client_company_snapshot': clientCompanySnapshot.trim().isEmpty
          ? null
          : clientCompanySnapshot.trim(),
      'client_phone_snapshot': clientPhoneSnapshot.trim().isEmpty
          ? null
          : clientPhoneSnapshot.trim(),
      'client_phone2_snapshot': clientPhone2Snapshot.trim().isEmpty
          ? null
          : clientPhone2Snapshot.trim(),
      'client_address_snapshot': clientAddressSnapshot.trim().isEmpty
          ? null
          : clientAddressSnapshot.trim(),
      'client_gstin_snapshot': clientGstinSnapshot.trim().isEmpty
          ? null
          : clientGstinSnapshot.trim(),
      'venue': venue.trim().isEmpty ? null : venue.trim(),
      'gst_type': normalizedGstType,
      'gst_rate': normalizedDocType == 'QUOTATION' ? 0 : _round2(gstRate),
      'subtotal': amounts['subtotal'],
      'cgst': amounts['cgst'],
      'sgst': amounts['sgst'],
      'igst': amounts['igst'],
      'grand_total': amounts['grand_total'],
      'status': normalizedStatus,
    }).eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }

  Future<void> setInvoiceStatus({
    required String id,
    required String status,
  }) async {
    await _client
        .from('invoices')
        .update({'status': _normalizeInvoiceStatus(status)})
        .eq('id', id);

    AppRefreshBus.notifyDashboardChanged();
  }
}