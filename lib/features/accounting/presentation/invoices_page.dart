import 'package:flutter/material.dart';
import '../../../data/services/accounting_service.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final AccountingService _service = AccountingService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchInvoices();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchInvoices();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) => '₹ ${_toDouble(value).toStringAsFixed(2)}';

  static const List<String> _docTypes = [
    'INVOICE',
    'QUOTATION',
  ];

  static const List<String> _gstTypes = [
    'NONE',
    'CGST_SGST',
    'IGST',
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

  void _applyClientToControllers(
    Map<String, dynamic> client,
    TextEditingController clientNameController,
    TextEditingController clientCompanyController,
    TextEditingController phone1Controller,
    TextEditingController phone2Controller,
    TextEditingController addressController,
    TextEditingController gstinController,
  ) {
    clientNameController.text = (client['client_name'] ?? '').toString();
    clientCompanyController.text = (client['client_company'] ?? '').toString();
    phone1Controller.text = (client['phone1'] ?? '').toString();
    phone2Controller.text = (client['phone2'] ?? '').toString();
    addressController.text = (client['address'] ?? '').toString();
    gstinController.text = (client['gst'] ?? '').toString();
  }

  void _recalcInvoiceFields({
    required String docType,
    required String gstType,
    required TextEditingController subtotalController,
    required TextEditingController gstRateController,
    required TextEditingController cgstController,
    required TextEditingController sgstController,
    required TextEditingController igstController,
    required TextEditingController grandTotalController,
  }) {
    final subtotal = _toDouble(subtotalController.text.trim());
    final gstRate = _toDouble(gstRateController.text.trim());

    final amounts = _service.calculateInvoiceAmounts(
      docType: docType,
      gstType: gstType,
      gstRate: gstRate,
      subtotal: subtotal,
    );

    cgstController.text = (amounts['cgst'] ?? 0).toStringAsFixed(2);
    sgstController.text = (amounts['sgst'] ?? 0).toStringAsFixed(2);
    igstController.text = (amounts['igst'] ?? 0).toStringAsFixed(2);
    grandTotalController.text = (amounts['grand_total'] ?? 0).toStringAsFixed(2);

    if (docType == 'QUOTATION') {
      gstRateController.text = '0.00';
    }
  }

  Future<void> _openForm({Map<String, dynamic>? row}) async {
    final clientOptions = await _service.fetchClientOptions();
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();

    final invoiceNoController = TextEditingController(
      text: (row?['invoice_no'] ?? '').toString(),
    );
    final invoiceDateController = TextEditingController(
      text: (row?['invoice_date'] ??
              DateTime.now().toIso8601String().substring(0, 10))
          .toString(),
    );
    final clientNameController = TextEditingController(
      text: (row?['client_name_snapshot'] ?? '').toString(),
    );
    final clientCompanyController = TextEditingController(
      text: (row?['client_company_snapshot'] ?? '').toString(),
    );
    final phone1Controller = TextEditingController(
      text: (row?['client_phone_snapshot'] ?? '').toString(),
    );
    final phone2Controller = TextEditingController(
      text: (row?['client_phone2_snapshot'] ?? '').toString(),
    );
    final addressController = TextEditingController(
      text: (row?['client_address_snapshot'] ?? '').toString(),
    );
    final gstinController = TextEditingController(
      text: (row?['client_gstin_snapshot'] ?? '').toString(),
    );
    final venueController = TextEditingController(
      text: (row?['venue'] ?? '').toString(),
    );
    final gstRateController = TextEditingController(
      text: _toDouble(row?['gst_rate']).toStringAsFixed(2),
    );
    final subtotalController = TextEditingController(
      text: _toDouble(row?['subtotal']).toStringAsFixed(2),
    );
    final cgstController = TextEditingController(
      text: _toDouble(row?['cgst']).toStringAsFixed(2),
    );
    final sgstController = TextEditingController(
      text: _toDouble(row?['sgst']).toStringAsFixed(2),
    );
    final igstController = TextEditingController(
      text: _toDouble(row?['igst']).toStringAsFixed(2),
    );
    final grandTotalController = TextEditingController(
      text: _toDouble(row?['grand_total']).toStringAsFixed(2),
    );

    String docType = ((row?['doc_type'] ?? 'INVOICE').toString().trim().isEmpty)
        ? 'INVOICE'
        : (row?['doc_type'] ?? 'INVOICE').toString().trim().toUpperCase();

    String gstType = ((row?['gst_type'] ?? 'NONE').toString().trim().isEmpty)
        ? 'NONE'
        : (row?['gst_type'] ?? 'NONE').toString().trim().toUpperCase();

    String status = ((row?['status'] ?? 'ACTIVE').toString().trim().isEmpty)
        ? 'ACTIVE'
        : (row?['status'] ?? 'ACTIVE').toString().trim().toUpperCase();

    String? selectedClientId = row?['client_id']?.toString();

    void recalc() {
      _recalcInvoiceFields(
        docType: docType,
        gstType: gstType,
        subtotalController: subtotalController,
        gstRateController: gstRateController,
        cgstController: cgstController,
        sgstController: sgstController,
        igstController: igstController,
        grandTotalController: grandTotalController,
      );
    }

    if (docType == 'QUOTATION') {
      gstType = 'NONE';
    }
    recalc();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> pickDate() async {
          final initial =
              DateTime.tryParse(invoiceDateController.text) ?? DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            invoiceDateController.text =
                picked.toIso8601String().substring(0, 10);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedClient = _findById(clientOptions, selectedClientId);

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
                        row == null
                            ? 'Add Invoice / Quotation'
                            : 'Edit Invoice / Quotation',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: invoiceNoController,
                        decoration: InputDecoration(
                          labelText:
                              docType == 'QUOTATION' ? 'Quotation No' : 'Invoice No',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: invoiceDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Document Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: pickDate,
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: docType,
                        items: _docTypes
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            docType = value ?? 'INVOICE';
                            if (docType == 'QUOTATION') {
                              gstType = 'NONE';
                            }
                            recalc();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedClientId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Select Client'),
                          ),
                          ...clientOptions.map(
                            (e) => DropdownMenuItem<String>(
                              value: e['id'].toString(),
                              child: Text(
                                '${e['client_name'] ?? ''}'
                                '${(e['client_company'] ?? '').toString().trim().isEmpty ? '' : ' • ${e['client_company']}'}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            selectedClientId =
                                (value == null || value.isEmpty) ? null : value;
                            final selected =
                                _findById(clientOptions, selectedClientId);
                            if (selected != null) {
                              _applyClientToControllers(
                                selected,
                                clientNameController,
                                clientCompanyController,
                                phone1Controller,
                                phone2Controller,
                                addressController,
                                gstinController,
                              );
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Select client'
                                : null,
                      ),
                      if (selectedClient != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Selected Client: ${selectedClient['client_name'] ?? '-'}\n'
                            'Company: ${selectedClient['client_company'] ?? '-'}\n'
                            'Phone: ${selectedClient['phone1'] ?? '-'}\n'
                            'GST: ${selectedClient['gst'] ?? '-'}',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name Snapshot',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: clientCompanyController,
                        decoration: const InputDecoration(
                          labelText: 'Client Company Snapshot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone1Controller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Client Phone 1 Snapshot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone2Controller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Client Phone 2 Snapshot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Client Address Snapshot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gstinController,
                        decoration: const InputDecoration(
                          labelText: 'Client GSTIN Snapshot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Venue required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      if (docType == 'QUOTATION')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Quotation mode: GST is disabled and totals will save without tax.',
                          ),
                        ),
                      if (docType == 'QUOTATION') const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: docType == 'QUOTATION' ? 'NONE' : gstType,
                        items: _gstTypes
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: docType == 'QUOTATION'
                            ? null
                            : (value) {
                                setSheetState(() {
                                  gstType = value ?? 'NONE';
                                  recalc();
                                });
                              },
                        decoration: const InputDecoration(
                          labelText: 'GST Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gstRateController,
                        readOnly: docType == 'QUOTATION' || gstType == 'NONE',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'GST Rate (%)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setSheetState(recalc);
                        },
                        validator: (value) {
                          final parsed = double.tryParse(value?.trim() ?? '');
                          if (parsed == null && (value?.trim().isNotEmpty ?? false)) {
                            return 'Invalid number';
                          }
                          if ((parsed ?? 0) < 0) return 'Must be 0 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subtotalController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Subtotal',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setSheetState(recalc);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Must be 0 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cgstController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'CGST',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: sgstController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'SGST',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: igstController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'IGST',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: grandTotalController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Grand Total',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value?.trim() ?? '');
                          if (parsed == null) return 'Invalid total';
                          if (parsed < 0) return 'Must be 0 or more';
                          return null;
                        },
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

                            final cleanInvoiceNo = invoiceNoController.text.trim();
                            final cleanDate = invoiceDateController.text.trim();
                            final cleanVenue = venueController.text.trim();
                            final cleanClientName = clientNameController.text.trim();

                            final subtotal = double.tryParse(
                                  subtotalController.text.trim(),
                                ) ??
                                0;
                            final gstRate = double.tryParse(
                                  gstRateController.text.trim(),
                                ) ??
                                0;
                            final grandTotal = double.tryParse(
                                  grandTotalController.text.trim(),
                                ) ??
                                0;
                            final cgst = double.tryParse(
                                  cgstController.text.trim(),
                                ) ??
                                0;
                            final sgst = double.tryParse(
                                  sgstController.text.trim(),
                                ) ??
                                0;
                            final igst = double.tryParse(
                                  igstController.text.trim(),
                                ) ??
                                0;

                            if (cleanInvoiceNo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invoice / Quotation No required')),
                              );
                              return;
                            }

                            if (selectedClientId == null || selectedClientId!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Select client')),
                              );
                              return;
                            }

                            if (cleanClientName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Client name required')),
                              );
                              return;
                            }

                            if (cleanVenue.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Venue required')),
                              );
                              return;
                            }

                            if (grandTotal < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Grand total invalid')),
                              );
                              return;
                            }

                            final duplicate = await _service.invoiceNoExists(
                              invoiceNo: cleanInvoiceNo,
                              docType: docType,
                              excludeId: row?['id']?.toString(),
                            );

                            if (duplicate) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${docType == 'QUOTATION' ? 'Quotation' : 'Invoice'} No already exists',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (docType == 'QUOTATION') {
                              gstType = 'NONE';
                            }

                            if (row == null) {
                              await _service.createInvoice(
                                invoiceNo: cleanInvoiceNo,
                                invoiceDate: cleanDate,
                                docType: docType,
                                clientId: selectedClientId,
                                clientNameSnapshot: cleanClientName,
                                clientCompanySnapshot: clientCompanyController.text.trim(),
                                clientPhoneSnapshot: phone1Controller.text.trim(),
                                clientPhone2Snapshot: phone2Controller.text.trim(),
                                clientAddressSnapshot: addressController.text.trim(),
                                clientGstinSnapshot: gstinController.text.trim(),
                                venue: cleanVenue,
                                gstType: gstType,
                                gstRate: gstRate,
                                subtotal: subtotal,
                                cgst: cgst,
                                sgst: sgst,
                                igst: igst,
                                grandTotal: grandTotal,
                                status: status,
                              );
                            } else {
                              await _service.updateInvoice(
                                id: row['id'].toString(),
                                invoiceNo: cleanInvoiceNo,
                                invoiceDate: cleanDate,
                                docType: docType,
                                clientId: selectedClientId,
                                clientNameSnapshot: cleanClientName,
                                clientCompanySnapshot: clientCompanyController.text.trim(),
                                clientPhoneSnapshot: phone1Controller.text.trim(),
                                clientPhone2Snapshot: phone2Controller.text.trim(),
                                clientAddressSnapshot: addressController.text.trim(),
                                clientGstinSnapshot: gstinController.text.trim(),
                                venue: cleanVenue,
                                gstType: gstType,
                                gstRate: gstRate,
                                subtotal: subtotal,
                                cgst: cgst,
                                sgst: sgst,
                                igst: igst,
                                grandTotal: grandTotal,
                                status: status,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            await _reload();
                          },
                          child: Text(
                            row == null ? 'Save Document' : 'Update Document',
                          ),
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
    final status = (row['status'] ?? 'ACTIVE').toString().toUpperCase();
    final isActive = status == 'ACTIVE';
    final docType = (row['doc_type'] ?? '-').toString().toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text('${row['invoice_no'] ?? '-'} • $docType'),
        subtitle: Text(
          'Date: ${row['invoice_date'] ?? '-'}\n'
          'Client: ${row['client_name_snapshot'] ?? '-'}\n'
          'Venue: ${row['venue'] ?? '-'} • Grand Total: ${_money(row['grand_total'])} • Status: $status',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openForm(row: row);
            } else if (value == 'toggle') {
              await _service.setInvoiceStatus(
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
        title: const Text('Invoices'),
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
                  Center(child: Text('No invoices found')),
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