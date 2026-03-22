import 'package:flutter/material.dart';
import '../../../data/services/accounting_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final AccountingService _service = AccountingService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchExpenses();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchExpenses();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) => '₹ ${_toDouble(value).toStringAsFixed(2)}';

  Future<void> _openQuickAddType() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Expense Type'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Type Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await _service.createExpenseType(name);
                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openForm({Map<String, dynamic>? row}) async {
    List<Map<String, dynamic>> typeOptions = await _service.fetchExpenseTypes();

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final entryDateController = TextEditingController(
      text: (row?['entry_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
    );
    final descriptionController = TextEditingController(text: (row?['description'] ?? '').toString());
    final amountController = TextEditingController(text: _toDouble(row?['amount']).toStringAsFixed(2));
    final tdsController = TextEditingController(text: _toDouble(row?['tds_amount']).toStringAsFixed(2));

    String? selectedCategory = (row?['category'] ?? '').toString().trim().isEmpty
        ? null
        : (row?['category'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> pickDate() async {
          final initial = DateTime.tryParse(entryDateController.text) ?? DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            entryDateController.text = picked.toIso8601String().substring(0, 10);
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
                        row == null ? 'Add Expense' : 'Edit Expense',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: entryDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Entry Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: pickDate,
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              items: typeOptions
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['type_name'].toString(),
                                      child: Text(e['type_name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setSheetState(() {
                                  selectedCategory = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Expense Type',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty) ? 'Select expense type' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () async {
                              await _openQuickAddType();
                              typeOptions = await _service.fetchExpenseTypes();
                              if (!mounted) return;
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            if (row == null) {
                              await _service.createExpense(
                                entryDate: entryDateController.text.trim(),
                                category: selectedCategory ?? '',
                                description: descriptionController.text.trim(),
                                amount: double.parse(amountController.text.trim()),
                                tdsAmount: double.tryParse(tdsController.text.trim()) ?? 0,
                              );
                            } else {
                              await _service.updateExpense(
                                id: row['id'].toString(),
                                entryDate: entryDateController.text.trim(),
                                category: selectedCategory ?? '',
                                description: descriptionController.text.trim(),
                                amount: double.parse(amountController.text.trim()),
                                tdsAmount: double.tryParse(tdsController.text.trim()) ?? 0,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            await _reload();
                          },
                          child: Text(row == null ? 'Save Expense' : 'Update Expense'),
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

  Future<void> _deleteExpense(String id) async {
    await _service.deleteExpense(id);
    await _reload();
  }

  Widget _card(Map<String, dynamic> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text('${row['category'] ?? 'Expense'} • ${_money(row['amount'])}'),
        subtitle: Text(
          'Date: ${row['entry_date'] ?? '-'}\n'
          'Description: ${row['description'] ?? '-'}\n'
          'TDS: ${_money(row['tds_amount'])}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openForm(row: row);
            } else if (value == 'delete') {
              await _deleteExpense(row['id'].toString());
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
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
                  Center(child: Text('No expenses found')),
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