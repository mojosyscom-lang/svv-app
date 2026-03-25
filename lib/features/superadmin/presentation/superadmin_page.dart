import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';
import '../users/data/superadmin_user_service.dart';

class SuperadminPage extends StatelessWidget {
  const SuperadminPage({super.key});

  Widget _tile({
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
        title: const Text('Superadmin'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: SuperadminUserService().getMyAccess(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load access: ${snapshot.error}'),
              ),
            );
          }

          final access = snapshot.data ?? const <String, dynamic>{};
          final isSuperadmin = access['isSuperadmin'] == true;

          if (!isSuperadmin) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Only superadmin can access this module.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Superadmin Tools',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _tile(
                icon: Icons.group_outlined,
                title: 'Users',
                subtitle: 'View users and activate / deactivate',
                onTap: () => Navigator.pushNamed(context, RouteNames.users),
              ),
              _tile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'New Users',
                subtitle: 'Create a new user for this company',
                onTap: () => Navigator.pushNamed(context, RouteNames.newUsers),
              ),
              _tile(
                icon: Icons.lock_reset_outlined,
                title: 'Edit Passwords',
                subtitle: 'Reset password for another user',
                onTap: () => Navigator.pushNamed(context, RouteNames.editPasswords),
              ),
            ],
          );
        },
      ),
    );
  }
}