import 'package:flutter/material.dart';
import '../../../data/services/accounting_service.dart';

class IncomingPaymentsPage extends StatefulWidget {
  const IncomingPaymentsPage({super.key});

  @override
  State<IncomingPaymentsPage> createState() => _IncomingPaymentsPageState();
}

class _IncomingPaymentsPageState extends State<IncomingPaymentsPage> {
  final AccountingService _service = AccountingService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchIncomingPayments();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchIncomingPayments();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) => '₹ ${_toDouble(value).toStringAsFixed(2)}';

  static const List<String> _payTypes = [
    'INVOICE',
    'QUOTATION_ADVANCE',
    'LOAN_OTHER',
  ];

  static const List<String> _modes = [
    'CASH',
    'BANK',
    'UPI',
    'CHEQUE',
  ];

  Map<String, dynamic>? _findById(
    List<Map<String, dynamic>> rows,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final row in rows) {
      if (row['id']?.toString() == id) return row;
    }
    return null;
  }


  Future<void> _openForm({Map<String, dynamic>? row}) async {
    final invoiceOptions = await _service.fetchInvoiceOptions();
    final bankOptions = await _service.fetchBankAccountOptions();

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final paymentDateController = TextEditingController(
      text: (row?['payment_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
    );
    final clientNameController = TextEditingController(
      text: (row?['client_name_snapshot'] ?? '').toString(),
    );
    final chequeNoController = TextEditingController(
      text: (row?['cheque_no'] ?? '').toString(),
    );
    final refNoController = TextEditingController(
      text: (row?['ref_no'] ?? '').toString(),
    );
    final amountController = TextEditingController(
      text: _toDouble(row?['received_amount']).toStringAsFixed(2),
    );
    final tdsController = TextEditingController(
      text: _toDouble(row?['tds_amount']).toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: (row?['note'] ?? '').toString());

    String status = (row?['status'] ?? 'ACTIVE').toString();
    String payType = ((row?['pay_type'] ?? 'INVOICE').toString().trim().isEmpty)
        ? 'INVOICE'
        : (row?['pay_type'] ?? 'INVOICE').toString().trim().toUpperCase();
    String mode = ((row?['mode'] ?? 'CASH').toString().trim().isEmpty)
        ? 'CASH'
        : (row?['mode'] ?? 'CASH').toString().trim().toUpperCase();

    String? selectedInvoiceId = row?['invoice_id']?.toString();
    String? selectedQuotationId = row?['quotation_id']?.toString();
    String? selectedBankId = row?['bank_account_id']?.toString();
    String? selectedClientId = row?['client_id']?.toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> pickDate() async {
          final initial = DateTime.tryParse(paymentDateController.text) ?? DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            paymentDateController.text = picked.toIso8601String().substring(0, 10);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final invoiceRows = invoiceOptions
                .where((e) => (e['doc_type'] ?? '').toString().toUpperCase() == 'INVOICE')
                .toList();

            final quotationRows = invoiceOptions
                .where((e) => (e['doc_type'] ?? '').toString().toUpperCase() == 'QUOTATION')
                .where((e) {
                  final status = (e['status'] ?? 'ACTIVE').toString().toUpperCase();
                  return status != 'CONVERTED' && status != 'CANCELLED';
                })
                .toList();

            final selectedInvoiceRow = _findById(invoiceRows, selectedInvoiceId);
            final selectedQuotationRow = _findById(quotationRows, selectedQuotationId);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row == null ? 'Add Incoming Payment' : 'Edit Incoming Payment',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: paymentDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: pickDate,
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: payType,
                        items: _payTypes
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            payType = value ?? 'INVOICE';
                            selectedInvoiceId = null;
                            selectedQuotationId = null;
                            selectedClientId = null;
                            clientNameController.clear();

                            if (payType == 'LOAN_OTHER') {
                              // keep manual entry mode
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Pay Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: mode,
                        items: _modes
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            mode = value ?? 'CASH';

                            if (mode == 'CASH') {
                              selectedBankId = null;
                              chequeNoController.clear();
                              refNoController.clear();
                            } else if (mode == 'BANK' || mode == 'UPI') {
                              chequeNoController.clear();
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (mode == 'BANK' || mode == 'UPI' || mode == 'CHEQUE')
                        DropdownButtonFormField<String>(
                          value: selectedBankId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Select Bank Account'),
                            ),
                            ...bankOptions.map(
                              (e) => DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text(
                                  '${(e['label'] ?? '').toString().trim().isEmpty ? 'Bank Account' : e['label']}'
                                  '${(e['bank_name'] ?? '').toString().trim().isEmpty ? '' : ' • ${e['bank_name']}'}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setSheetState(() {
                              selectedBankId = (value == null || value.isEmpty) ? null : value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Bank Account',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((mode == 'BANK' || mode == 'UPI' || mode == 'CHEQUE') &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Select bank account';
                            }
                            return null;
                          },
                        ),
                      if (mode == 'BANK' || mode == 'UPI' || mode == 'CHEQUE')
                        const SizedBox(height: 12),
                      if (mode == 'CHEQUE') ...[
                        TextFormField(
                          controller: chequeNoController,
                          decoration: const InputDecoration(
                            labelText: 'Cheque No',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (mode == 'CHEQUE' && (value == null || value.trim().isEmpty)) {
                              return 'Cheque No required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (mode == 'BANK' || mode == 'UPI' || mode == 'CHEQUE') ...[
                        TextFormField(
                          controller: refNoController,
                          decoration: const InputDecoration(
                            labelText: 'Reference No',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (payType == 'INVOICE')
                        DropdownButtonFormField<String>(
                          value: selectedInvoiceId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Select Invoice'),
                            ),
                            ...invoiceRows.map(
                              (e) => DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text(
                                  '${e['invoice_no'] ?? 'No Invoice'}'
                                  ' • ${e['client_name_snapshot'] ?? ''}'
                                  ' • ₹${_toDouble(e['grand_total']).toStringAsFixed(2)}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setSheetState(() {
                              selectedInvoiceId = (value == null || value.isEmpty) ? null : value;
                              final selected = invoiceRows.where(
                                (e) => e['id'].toString() == selectedInvoiceId,
                              );
                              if (selected.isNotEmpty) {
                                selectedClientId = selected.first['client_id']?.toString();
                                clientNameController.text =
                                    (selected.first['client_name_snapshot'] ?? '').toString();
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Invoice',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (payType == 'INVOICE' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Select invoice';
                            }
                            return null;
                          },
                        ),

                      if (payType == 'INVOICE' && selectedInvoiceRow != null) ...[
                        const SizedBox(height: 12),
                        FutureBuilder<double>(
                          future: _service.getInvoiceBalance(
                            selectedInvoiceId!,
                            excludePaymentId: row?['id']?.toString(),
                          ),
                          builder: (context, snapshot) {
                            final balance = snapshot.data ?? 0;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Invoice: ${selectedInvoiceRow['invoice_no'] ?? '-'}\n'
                                'Client: ${selectedInvoiceRow['client_name_snapshot'] ?? '-'}\n'
                                'Grand Total: ${_money(selectedInvoiceRow['grand_total'])}\n'
                                'Balance: ₹ ${balance.toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
                      ],

                      if (payType == 'QUOTATION_ADVANCE')
                        DropdownButtonFormField<String>(
                          value: selectedQuotationId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Select Quotation'),
                            ),
                            ...quotationRows.map(
                              (e) => DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text(
                                  '${e['invoice_no'] ?? 'No Quotation'}'
                                  ' • ${e['client_name_snapshot'] ?? ''}'
                                  ' • ₹${_toDouble(e['grand_total']).toStringAsFixed(2)}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setSheetState(() {
                              selectedQuotationId =
                                  (value == null || value.isEmpty) ? null : value;
                              final selected = quotationRows.where(
                                (e) => e['id'].toString() == selectedQuotationId,
                              );
                              if (selected.isNotEmpty) {
                                selectedClientId = selected.first['client_id']?.toString();
                                clientNameController.text =
                                    (selected.first['client_name_snapshot'] ?? '').toString();
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Quotation',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (payType == 'QUOTATION_ADVANCE' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Select quotation';
                            }
                            return null;
                          },
                        ),
                      if (payType == 'QUOTATION_ADVANCE' && selectedQuotationRow != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Quotation: ${selectedQuotationRow['invoice_no'] ?? '-'}\n'
                            'Client: ${selectedQuotationRow['client_name_snapshot'] ?? '-'}\n'
                            'Quotation Total: ${_money(selectedQuotationRow['grand_total'])}\n'
                            'Status: ${selectedQuotationRow['status'] ?? '-'}',
                          ),
                        ),
                      ],
                      if (payType == 'INVOICE' || payType == 'QUOTATION_ADVANCE')
                        const SizedBox(height: 12),
                      TextFormField(
                        controller: clientNameController,
                        decoration: InputDecoration(
                          labelText: payType == 'LOAN_OTHER'
                              ? 'From (Name)'
                              : 'Client Name Snapshot',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return payType == 'LOAN_OTHER'
                                ? 'From (name) required'
                                : 'Client name required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Received Amount',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tdsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'TDS Amount',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Must be 0 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            status = value ?? 'ACTIVE';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final receivedAmount =
                                double.tryParse(amountController.text.trim()) ?? 0;
                            final tdsAmount =
                                double.tryParse(tdsController.text.trim()) ?? 0;

                            if (receivedAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Received Amount required')),
                              );
                              return;
                            }

                            if ((mode == 'BANK' || mode == 'UPI' || mode == 'CHEQUE') &&
                                (selectedBankId == null || selectedBankId!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Select bank account')),
                              );
                              return;
                            }

                            if (payType == 'INVOICE' &&
                                (selectedInvoiceId == null || selectedInvoiceId!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Select invoice')),
                              );
                              return;
                            }

                            if (payType == 'QUOTATION_ADVANCE' &&
                                (selectedQuotationId == null ||
                                    selectedQuotationId!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Select quotation')),
                              );
                              return;
                            }

                            if (payType == 'INVOICE' && selectedInvoiceId != null) {
                              final balance = await _service.getInvoiceBalance(
                                selectedInvoiceId!,
                                excludePaymentId: row?['id']?.toString(),
                              );
                              final net = receivedAmount + tdsAmount;

                              if (net > (balance + 0.01)) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Overpayment not allowed. Balance: ₹${balance.toStringAsFixed(2)} • Net: ₹${net.toStringAsFixed(2)}',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            if (row == null) {
                              await _service.createIncomingPayment(
                                paymentDate: paymentDateController.text.trim(),
                                payType: payType,
                                mode: mode,
                                clientId: selectedClientId,
                                clientName: clientNameController.text.trim(),
                                invoiceId: selectedInvoiceId,
                                quotationId: selectedQuotationId,
                                bankAccountId: selectedBankId,
                                chequeNo: chequeNoController.text.trim(),
                                refNo: refNoController.text.trim(),
                                receivedAmount: receivedAmount,
                                tdsAmount: tdsAmount,
                                note: noteController.text.trim(),
                                status: status,
                              );
                            } else {
                              await _service.updateIncomingPayment(
                                id: row['id'].toString(),
                                paymentDate: paymentDateController.text.trim(),
                                payType: payType,
                                mode: mode,
                                clientId: selectedClientId,
                                clientName: clientNameController.text.trim(),
                                invoiceId: selectedInvoiceId,
                                quotationId: selectedQuotationId,
                                bankAccountId: selectedBankId,
                                chequeNo: chequeNoController.text.trim(),
                                refNo: refNoController.text.trim(),
                                receivedAmount: receivedAmount,
                                tdsAmount: tdsAmount,
                                note: noteController.text.trim(),
                                status: status,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            await _reload();
                          },
                          child: Text(row == null ? 'Save Payment' : 'Update Payment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _card(Map<String, dynamic> row) {
    final status = (row['status'] ?? 'ACTIVE').toString();
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text('${row['payment_code'] ?? '-'} • ${_money(row['received_amount'])}'),
        subtitle: Text(
          'Date: ${row['payment_date'] ?? '-'}\n'
          'Type: ${row['pay_type'] ?? '-'} • Client: ${row['client_name_snapshot'] ?? '-'}\n'
          'Mode: ${row['mode'] ?? '-'}'
          '${(row['cheque_no'] ?? '').toString().trim().isEmpty ? '' : ' • Cheque: ${row['cheque_no']}'}'
          '${(row['ref_no'] ?? '').toString().trim().isEmpty ? '' : ' • Ref: ${row['ref_no']}'}'
          ' • TDS: ${_money(row['tds_amount'])} • Status: $status',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openForm(row: row);
            } else if (value == 'toggle') {
              await _service.setIncomingPaymentStatus(
                id: row['id'].toString(),
                status: isActive ? 'INACTIVE' : 'ACTIVE',
              );
              await _reload();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(isActive ? 'Mark Inactive' : 'Mark Active'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Payments'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Error: ${snapshot.error}')),
                ],
              );
            }

            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No incoming payments found')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (_, index) => _card(rows[index]),
            );
          },
        ),
      ),
    );
  }
}