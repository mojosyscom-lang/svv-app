import 'package:flutter/material.dart';
import '../data/workers_service.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  final WorkersService _service = WorkersService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  bool _pageLoading = true;
  bool _saving = false;
  bool _statusUpdating = false;

  Map<String, dynamic>? _permission;
  List<Map<String, dynamic>> _workers = [];
  Map<String, String> _addedByNames = {};

  String? _editingWorkerId;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedStatusDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return '₹ ${_toDouble(value).toStringAsFixed(2)}';
  }

  Future<void> _loadPage() async {
    setState(() {
      _pageLoading = true;
    });

    try {
      final permission = await _service.getWorkersPermission();

      if (permission['canView'] != true) {
        if (!mounted) return;
        setState(() {
          _permission = permission;
          _workers = [];
          _pageLoading = false;
        });
        return;
      }

      final workers = await _service.fetchWorkers();

      final ids = workers
          .map((w) => (w['added_by'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, String> names = {};
      for (final id in ids) {
        names[id] = await _service.usernameByUserId(id);
      }

      if (!mounted) return;

      setState(() {
        _permission = permission;
        _workers = workers;
        _addedByNames = names;
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _pickStatusDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStatusDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedStatusDate = picked;
      });
    }
  }

  void _fillFormForEdit(Map<String, dynamic> worker) {
    setState(() {
      _editingWorkerId = worker['id'].toString();
      _workerNameController.text = (worker['worker_name'] ?? '').toString();
      _salaryController.text = _toDouble(worker['monthly_salary']).toStringAsFixed(2);
      final rawDate = (worker['start_date'] ?? '').toString();
      _selectedStartDate = rawDate.isNotEmpty ? DateTime.parse(rawDate) : DateTime.now();
      _selectedStatusDate = DateTime.now();
    });
  }

  void _clearForm() {
    setState(() {
      _editingWorkerId = null;
      _workerNameController.clear();
      _salaryController.clear();
      _selectedStartDate = DateTime.now();
      _selectedStatusDate = DateTime.now();
    });
  }

  Future<void> _saveWorker() async {
    if (_permission?['canCreate'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to add workers')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final workerName = _workerNameController.text.trim();
    final monthlySalary = double.tryParse(_salaryController.text.trim()) ?? 0;
    final startDate = _dateText(_selectedStartDate);

    setState(() {
      _saving = true;
    });

    try {
      final exists = await _service.workerNameExists(workerName: workerName);
      if (exists) {
        throw Exception('Worker with same name already exists.');
      }

      await _service.createWorker(
        workerName: workerName,
        monthlySalary: monthlySalary,
        startDate: startDate,
      );

      _clearForm();
      await _loadPage();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save worker: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _updateWorker() async {
    if (_permission?['canUpdate'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to update workers')),
      );
      return;
    }

    if ((_editingWorkerId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a worker row first to edit')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final workerName = _workerNameController.text.trim();
    final monthlySalary = double.tryParse(_salaryController.text.trim()) ?? 0;
    final startDate = _dateText(_selectedStartDate);

    setState(() {
      _saving = true;
    });

    try {
      final exists = await _service.workerNameExists(
        workerName: workerName,
        excludeId: _editingWorkerId,
      );
      if (exists) {
        throw Exception('Another worker with same name already exists.');
      }

      await _service.updateWorker(
        workerId: _editingWorkerId!,
        workerName: workerName,
        monthlySalary: monthlySalary,
        startDate: startDate,
      );

      _clearForm();
      await _loadPage();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update worker: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> worker) async {
    if (_permission?['canUpdate'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to update worker status')),
      );
      return;
    }

    final currentStatus = (worker['status'] ?? 'ACTIVE').toString().toUpperCase();
    final nextStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final workerName = (worker['worker_name'] ?? '').toString();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Change Status: $workerName'),
          content: Text(
            'Status date: ${_dateText(_selectedStatusDate)}\n\n'
            'Do you want to change this worker to $nextStatus?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (proceed != true) return;

    setState(() {
      _statusUpdating = true;
    });

    try {
      await _service.updateWorkerStatus(
        workerId: worker['id'].toString(),
        nextStatus: nextStatus,
        statusDate: _dateText(_selectedStatusDate),
      );

      await _loadPage();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$workerName updated to $nextStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _statusUpdating = false;
      });
    }
  }

  Widget _buildFormCard() {
    final editing = (_editingWorkerId ?? '').isNotEmpty;

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
                'Add / Edit Worker',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _workerNameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Worker Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Worker name required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Salary required';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) return 'Invalid salary';
                  if (parsed <= 0) return 'Salary must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _saving ? null : _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dateText(_selectedStartDate)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _saveWorker,
                    child: Text(_saving ? 'Saving...' : 'Save Worker'),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _updateWorker,
                    child: Text(_saving ? 'Updating...' : 'Update Worker'),
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : _clearForm,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                editing
                    ? 'Editing selected worker. Tap Clear to reset form.'
                    : 'Tip: Tap a worker row below to load it into the form for editing.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDateCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _statusUpdating ? null : _pickStatusDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.event),
                ),
                child: Text(_dateText(_selectedStatusDate)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the date worker became Active or Inactive. You can backdate this to fix salary calculations.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerRow(Map<String, dynamic> worker) {
    final status = (worker['status'] ?? 'ACTIVE').toString().toUpperCase();
    final addedById = (worker['added_by'] ?? '').toString().trim();
    final addedBy = _addedByNames[addedById] ?? '-';
    final activeDate = (worker['active_date'] ?? '').toString();
    final inactiveDate = (worker['inactive_date'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _fillFormForEdit(worker),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (worker['worker_name'] ?? '-').toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Salary: ${_money(worker['monthly_salary'])}'),
              Text('Start Date: ${worker['start_date'] ?? '-'}'),
              Text('Status: $status'),
              Text('Active Date: ${activeDate.isEmpty ? '-' : activeDate}'),
              Text('Inactive Date: ${inactiveDate.isEmpty ? '-' : inactiveDate}'),
              Text('Added By: $addedBy'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () => _fillFormForEdit(worker),
                    child: const Text('Edit'),
                  ),
                  ElevatedButton(
                    onPressed: _statusUpdating ? null : () => _changeStatus(worker),
                    child: Text(status == 'ACTIVE' ? 'Set Inactive' : 'Set Active'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerList() {
    if (_workers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No workers found.'),
        ),
      );
    }

    return Column(
      children: _workers.map(_buildWorkerRow).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workers')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_permission?['canView'] != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workers')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Unauthorized.\nYou do not have permission to access Workers.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFormCard(),
            _buildStatusDateCard(),
            const SizedBox(height: 4),
            const Text(
              'Worker List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildWorkerList(),
          ],
        ),
      ),
    );
  }
}