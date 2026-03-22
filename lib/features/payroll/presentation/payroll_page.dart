import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Payroll Modules',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _sectionTile(
            icon: Icons.groups_outlined,
            title: 'Workers',
            subtitle: 'Add, edit, and manage worker status',
            onTap: () => Navigator.pushNamed(context, RouteNames.workers),
          ),
          _sectionTile(
            icon: Icons.money_off_csred_outlined,
            title: 'Worker Advances',
            subtitle: 'Add advance + monthly summary',
            onTap: () => Navigator.pushNamed(context, RouteNames.advances),
          ),
          _sectionTile(
            icon: Icons.payments_outlined,
            title: 'Salary',
            subtitle: 'Salary payments and summaries',
            onTap: () => Navigator.pushNamed(context, RouteNames.salary),
          ),
          _sectionTile(
            icon: Icons.event_busy_outlined,
            title: 'Holidays',
            subtitle: 'Worker holiday entries and management',
            onTap: () => Navigator.pushNamed(context, RouteNames.holidays),
          ),
        ],
      ),
    );
  }
}