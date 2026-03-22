import 'package:flutter/material.dart';
import '../../../data/services/accounting_service.dart';

class GstBillsPage extends StatefulWidget {
  const GstBillsPage({super.key});

  @override
  State<GstBillsPage> createState() => _GstBillsPageState();
}

class _GstBillsPageState extends State<GstBillsPage> {
  final AccountingService _service = AccountingService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchGstBills();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchGstBills();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) => '₹ ${_toDouble(value).toStringAsFixed(2)}';

  Future<void> _openForm({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final billDateController = TextEditingController(
      text: (row?['bill_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
    );
    final billNoController = TextEditingController(text: (row?['bill_no'] ?? '').toString());
    final vendorController = TextEditingController(text: (row?['vendor'] ?? '').toString());
    final totalController = TextEditingController(text: _toDouble(row?['total_amount']).toStringAsFixed(2));
    final gstTypeController = TextEditingController(text: (row?['gst_type'] ?? '').toString());
    final gstAmountController = TextEditingController(text: _toDouble(row?['gst_amount']).toStringAsFixed(2));
    final cgstController = TextEditingController(text: _toDouble(row?['cgst']).toStringAsFixed(2));
    final sgstController = TextEditingController(text: _toDouble(row?['sgst']).toStringAsFixed(2));
    final igstController = TextEditingController(text: _toDouble(row?['igst']).toStringAsFixed(2));

    String status = (row?['status'] ?? 'ACTIVE').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> pickDate() async {
          final initial = DateTime.tryParse(billDateController.text) ?? DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            billDateController.text = picked.toIso8601String().substring(0, 10);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        row == null ? 'Add GST Bill' : 'Edit GST Bill',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: billDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Bill Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: pickDate,
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: billNoController,
                        decoration: const InputDecoration(
                          labelText: 'Bill No',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: totalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Total Amount',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Must be 0 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gstTypeController,
                        decoration: const InputDecoration(
                          labelText: 'GST Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gstAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'GST Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cgstController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'IGST',
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

                            if (row == null) {
                              await _service.createGstBill(
                                billDate: billDateController.text.trim(),
                                billNo: billNoController.text.trim(),
                                vendor: vendorController.text.trim(),
                                totalAmount: double.parse(totalController.text.trim()),
                                gstType: gstTypeController.text.trim(),
                                gstAmount: double.tryParse(gstAmountController.text.trim()) ?? 0,
                                cgst: double.tryParse(cgstController.text.trim()) ?? 0,
                                sgst: double.tryParse(sgstController.text.trim()) ?? 0,
                                igst: double.tryParse(igstController.text.trim()) ?? 0,
                                status: status,
                              );
                            } else {
                              await _service.updateGstBill(
                                id: row['id'].toString(),
                                billDate: billDateController.text.trim(),
                                billNo: billNoController.text.trim(),
                                vendor: vendorController.text.trim(),
                                totalAmount: double.parse(totalController.text.trim()),
                                gstType: gstTypeController.text.trim(),
                                gstAmount: double.tryParse(gstAmountController.text.trim()) ?? 0,
                                cgst: double.tryParse(cgstController.text.trim()) ?? 0,
                                sgst: double.tryParse(sgstController.text.trim()) ?? 0,
                                igst: double.tryParse(igstController.text.trim()) ?? 0,
                                status: status,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            await _reload();
                          },
                          child: Text(row == null ? 'Save GST Bill' : 'Update GST Bill'),
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
    final isActive = status == 'ACTIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text('${row['vendor'] ?? 'GST Bill'} • ${_money(row['total_amount'])}'),
        subtitle: Text(
          'Bill No: ${row['bill_no'] ?? '-'} • Date: ${row['bill_date'] ?? '-'}\n'
          'GST Type: ${row['gst_type'] ?? '-'} • GST: ${_money(row['gst_amount'])}\n'
          'CGST: ${_money(row['cgst'])} • SGST: ${_money(row['sgst'])} • IGST: ${_money(row['igst'])} • $status',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openForm(row: row);
            } else if (value == 'toggle') {
              await _service.setGstBillStatus(
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
        title: const Text('GST Bills'),
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
                  Center(child: Text('No GST bills found')),
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