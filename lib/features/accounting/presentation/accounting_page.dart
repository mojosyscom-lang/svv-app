import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/services/accounting_service.dart';
import '../../../data/services/auth_service.dart';

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  final AccountingService _service = AccountingService();
  final AuthService _authService = AuthService();

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAccountingHomeSummary();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.getAccountingHomeSummary();
    });
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
  }

  Widget _sectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 2),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    return '₹ ${n.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Map<String, dynamic>>(
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

            final data = snapshot.data ?? {};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Accounting Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _summaryCard('Income', _money(data['incomeTotal'] ?? 0)),
                    const SizedBox(width: 12),
                    _summaryCard('Expenses', _money(data['expenseTotal'] ?? 0)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _summaryCard('GST Input', _money(data['gstInputTotal'] ?? 0)),
                    const SizedBox(width: 12),
                    _summaryCard('Invoices', _money(data['invoiceTotal'] ?? 0)),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTile(
                  icon: Icons.payments_outlined,
                  title: 'Incoming Payments',
                  subtitle: '${data['incomeCount'] ?? 0} entries',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountingIncomingPayments),
                ),
                _sectionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Expenses',
                  subtitle: '${data['expenseCount'] ?? 0} entries',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountingExpenses),
                ),
                _sectionTile(
                  icon: Icons.description_outlined,
                  title: 'GST Bills',
                  subtitle: '${data['gstBillCount'] ?? 0} entries',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountingGstBills),
                ),
                _sectionTile(
                  icon: Icons.request_quote_outlined,
                  title: 'Invoices',
                  subtitle: '${data['invoiceCount'] ?? 0} invoice rows',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountingInvoices),
                ),
                _sectionTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank Accounts',
                  subtitle: '${data['bankAccountCount'] ?? 0} active accounts',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountingBankAccounts),
                ),
                _sectionTile(
                  icon: Icons.money_off_csred_outlined,
                  title: 'Worker Advances',
                  subtitle: 'Add advance + monthly summary',
                  onTap: () => Navigator.pushNamed(context, RouteNames.advances),
                ),
                                _sectionTile(
                  icon: Icons.groups_outlined,
                  title: 'Workers',
                  subtitle: 'Add, edit, and manage worker status',
                  onTap: () => Navigator.pushNamed(context, RouteNames.workers),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}