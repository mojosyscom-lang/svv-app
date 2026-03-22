import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    const totalModules = 5;
    const realPages = 0;
    const pendingPages = 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Admin Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryCard(
                  title: 'Modules',
                  value: '$totalModules',
                  icon: Icons.dashboard_customize_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  title: 'Live Pages',
                  value: '$realPages',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryCard(
                  title: 'Pending',
                  value: '$pendingPages',
                  icon: Icons.pending_actions_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  title: 'Group',
                  value: 'Admin',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Admin Modules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _sectionTile(
              icon: Icons.group_outlined,
              title: 'Users',
              subtitle: 'User list and management',
              onTap: () => Navigator.pushNamed(context, RouteNames.users),
            ),
            _sectionTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'New Users',
              subtitle: 'Create new user accounts',
              onTap: () => Navigator.pushNamed(context, RouteNames.newUsers),
            ),
            _sectionTile(
              icon: Icons.lock_reset_outlined,
              title: 'Edit Passwords',
              subtitle: 'Update user passwords',
              onTap: () => Navigator.pushNamed(context, RouteNames.editPasswords),
            ),
            _sectionTile(
              icon: Icons.business_outlined,
              title: 'Company Profile',
              subtitle: 'Company profile and details',
              onTap: () => Navigator.pushNamed(context, RouteNames.companyProfile),
            ),
            _sectionTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App and company settings',
              onTap: () => Navigator.pushNamed(context, RouteNames.settings),
            ),
          ],
        ),
      ),
    );
  }
}