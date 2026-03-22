import 'package:flutter/material.dart';
import '../data/worker_advances_service.dart';

class WorkerAdvancesPage extends StatefulWidget {
  const WorkerAdvancesPage({super.key});

  @override
  State<WorkerAdvancesPage> createState() => _WorkerAdvancesPageState();
}

class _WorkerAdvancesPageState extends State<WorkerAdvancesPage> {
  final WorkerAdvancesService _service = WorkerAdvancesService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _pageLoading = true;
  bool _saving = false;
  bool _summaryLoading = false;
  bool _summaryLoaded = false;

  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _rows = [];

  String? _selectedWorkerId;
  DateTime _selectedEntryDate = DateTime.now();

  String? _selectedFilterWorkerId;
  DateTime _selectedFilterMonth = DateTime(DateTime.now().year, DateTime.now().month);

  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return '₹ ${_toDouble(value).toStringAsFixed(2)}';
  }

  String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _pageLoading = true;
    });

    try {
      final workers = await _service.fetchActiveWorkers();
      if (!mounted) return;

      setState(() {
        _workers = workers;
        if (_selectedWorkerId == null && workers.isNotEmpty) {
          _selectedWorkerId = workers.first['id'].toString();
        }
        _pageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workers: $e')),
      );
    }
  }

  String _workerNameById(String? workerId) {
    if ((workerId ?? '').isEmpty) return '';
    for (final worker in _workers) {
      if (worker['id'].toString() == workerId) {
        return (worker['worker_name'] ?? '').toString();
      }
    }
    return '';
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEntryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedEntryDate = picked;
      });
    }
  }

  Future<void> _pickFilterMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedFilterMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Future<bool> _confirmDuplicateProceed() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Duplicate Advance Found'),
          content: const Text(
            'Same advance entry already exists for this worker, date, and amount.\n\nDo you want to add it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add Anyway'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _saveAdvance() async {
    if (!_formKey.currentState!.validate()) return;

    final workerId = _selectedWorkerId ?? '';
    final workerName = _workerNameById(workerId);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final entryDate = _dateText(_selectedEntryDate);

    if (workerId.isEmpty || workerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker')),
      );
      return;
    }

    if (_selectedEntryDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Future dates are not allowed')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final duplicate = await _service.isDuplicateAdvance(
        workerId: workerId,
        entryDate: entryDate,
        amount: amount,
      );

      if (duplicate) {
        final proceed = await _confirmDuplicateProceed();
        if (!proceed) {
          if (!mounted) return;
          setState(() {
            _saving = false;
          });
          return;
        }
      }

      await _service.createAdvance(
        workerId: workerId,
        workerNameSnapshot: workerName,
        entryDate: entryDate,
        amount: amount,
        description: _descriptionController.text.trim(),
      );

      _amountController.clear();
      _descriptionController.clear();

      if (_summaryLoaded) {
        await _loadSummary();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advance added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save advance: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryLoaded = true;
    });

    try {
      final monthKey = _service.monthKeyFromDate(_selectedFilterMonth);
      final rows = await _service.fetchAdvances(
        monthKey: monthKey,
        workerId: _selectedFilterWorkerId,
      );

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _total = _service.computeTotal(rows);
        _summaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summaryLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load summary: $e')),
      );
    }
  }

  void _clearSummary() {
    setState(() {
      _selectedFilterWorkerId = null;
      _selectedFilterMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _rows = [];
      _total = 0;
      _summaryLoaded = false;
    });
  }

  Future<void> _refreshAll() async {
    await _loadWorkers();
    if (_summaryLoaded) {
      await _loadSummary();
    }
  }

  Widget _buildTopFormCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Advance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedWorkerId,
                items: _workers
                    .map(
                      (worker) => DropdownMenuItem<String>(
                        value: worker['id'].toString(),
                        child: Text(worker['worker_name'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedWorkerId = value;
                        });
                      },
                decoration: const InputDecoration(
                  labelText: 'Worker',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Select worker' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) return 'Invalid number';
                  if (parsed <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _saving ? null : _pickEntryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dateText(_selectedEntryDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAdvance,
                  child: Text(_saving ? 'Saving...' : 'Add Advance'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Future dates are not allowed. Duplicate entries show a warning before saving.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryFilterCard() {
    final selectedMonthKey = _service.monthKeyFromDate(_selectedFilterMonth);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advance Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _summaryLoading ? null : _pickFilterMonth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(selectedMonthKey),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFilterWorkerId,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Workers'),
                ),
                ..._workers.map(
                  (worker) => DropdownMenuItem<String>(
                    value: worker['id'].toString(),
                    child: Text(worker['worker_name'].toString()),
                  ),
                ),
              ],
              onChanged: _summaryLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedFilterWorkerId = value;
                      });
                    },
              decoration: const InputDecoration(
                labelText: 'Worker',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _summaryLoading ? null : _loadSummary,
                  child: Text(_summaryLoading ? 'Loading...' : 'Show'),
                ),
                OutlinedButton(
                  onPressed: _summaryLoading ? null : _clearSummary,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _summaryLoaded
                  ? 'Total Advance: ${_money(_total)}'
                      '${_selectedFilterWorkerId != null ? ' • Worker: ${_workerNameById(_selectedFilterWorkerId)}' : ''}'
                      ' • Month: $selectedMonthKey'
                  : 'Nothing will show until you click Show.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(Map<String, dynamic> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        title: Text(
          '${row['worker_name_snapshot'] ?? '-'} • ${_money(row['amount'])}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Date: ${row['entry_date'] ?? '-'}\n'
          'Month: ${row['month_key'] ?? '-'}\n'
          'Description: ${((row['description'] ?? '').toString().trim().isEmpty) ? '-' : row['description']}',
        ),
      ),
    );
  }

  Widget _buildSummaryResultCard() {
    if (!_summaryLoaded) {
      return const SizedBox.shrink();
    }

    if (_summaryLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rows.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No advance entries found.'),
        ),
      );
    }

    return Column(
      children: _rows.map(_buildRowCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Worker Advances')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Advances'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTopFormCard(),
            _buildSummaryFilterCard(),
            _buildSummaryResultCard(),
          ],
        ),
      ),
    );
  }
}