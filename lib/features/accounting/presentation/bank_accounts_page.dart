import 'package:flutter/material.dart';
import '../../../data/services/accounting_service.dart';

class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  final AccountingService _service = AccountingService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchBankAccounts();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchBankAccounts();
    });
  }

  Future<void> _openForm({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: (row?['label'] ?? '').toString());
    final bankNameController = TextEditingController(text: (row?['bank_name'] ?? '').toString());
    final branchController = TextEditingController(text: (row?['branch_name'] ?? '').toString());
    final accountNameController = TextEditingController(text: (row?['account_name'] ?? '').toString());
    final accountNoController = TextEditingController(text: (row?['account_no_full'] ?? '').toString());
    final ifscController = TextEditingController(text: (row?['ifsc'] ?? '').toString());
    final upiController = TextEditingController(text: (row?['upi_id'] ?? '').toString());

    bool isActive = row?['is_active'] == true;
    bool isDefault = row?['is_default'] == true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                        row == null ? 'Add Bank Account' : 'Edit Bank Account',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: branchController,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: accountNameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: accountNoController,
                        decoration: const InputDecoration(
                          labelText: 'Full Account Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ifscController,
                        decoration: const InputDecoration(
                          labelText: 'IFSC',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: upiController,
                        decoration: const InputDecoration(
                          labelText: 'UPI ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        onChanged: (value) {
                          setSheetState(() {
                            isActive = value;
                          });
                        },
                        title: const Text('Active'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isDefault,
                        onChanged: (value) {
                          setSheetState(() {
                            isDefault = value;
                          });
                        },
                        title: const Text('Default Account'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            if (row == null) {
                              await _service.createBankAccount(
                                label: labelController.text.trim(),
                                bankName: bankNameController.text.trim(),
                                branchName: branchController.text.trim(),
                                accountName: accountNameController.text.trim(),
                                accountNoFull: accountNoController.text.trim(),
                                ifsc: ifscController.text.trim(),
                                upiId: upiController.text.trim(),
                                isActive: isActive,
                                isDefault: isDefault,
                              );
                            } else {
                              await _service.updateBankAccount(
                                id: row['id'].toString(),
                                label: labelController.text.trim(),
                                bankName: bankNameController.text.trim(),
                                branchName: branchController.text.trim(),
                                accountName: accountNameController.text.trim(),
                                accountNoFull: accountNoController.text.trim(),
                                ifsc: ifscController.text.trim(),
                                upiId: upiController.text.trim(),
                                isActive: isActive,
                                isDefault: isDefault,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            await _reload();
                          },
                          child: Text(row == null ? 'Save Bank Account' : 'Update Bank Account'),
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
    final label = (row['label'] ?? '').toString().trim();
    final bankName = (row['bank_name'] ?? '').toString().trim();
    final branchName = (row['branch_name'] ?? '').toString().trim();
    final accountName = (row['account_name'] ?? '').toString().trim();
    final last4 = (row['account_no_last4'] ?? '').toString().trim();
    final ifsc = (row['ifsc'] ?? '').toString().trim();
    final upi = (row['upi_id'] ?? '').toString().trim();
    final isActive = row['is_active'] == true;
    final isDefault = row['is_default'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text(label.isEmpty ? 'Bank Account' : label),
        subtitle: Text(
          'Bank: ${bankName.isEmpty ? '-' : bankName}'
          '${branchName.isEmpty ? '' : ' • $branchName'}\n'
          'Account: ${accountName.isEmpty ? '-' : accountName}'
          '${last4.isEmpty ? '' : ' • ****$last4'}\n'
          'IFSC: ${ifsc.isEmpty ? '-' : ifsc} • UPI: ${upi.isEmpty ? '-' : upi} • ${isActive ? 'ACTIVE' : 'INACTIVE'} ${isDefault ? '• DEFAULT' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _openForm(row: row);
            } else if (value == 'toggle') {
              await _service.setBankAccountActive(
                id: row['id'].toString(),
                isActive: !isActive,
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
        title: const Text('Bank Accounts'),
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
                  Center(child: Text('No bank accounts found')),
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