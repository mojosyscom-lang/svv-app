import 'package:flutter/material.dart';
import '../data/superadmin_user_service.dart';

class EditPasswordsPage extends StatefulWidget {
  const EditPasswordsPage({super.key});

  @override
  State<EditPasswordsPage> createState() => _EditPasswordsPageState();
}

class _EditPasswordsPageState extends State<EditPasswordsPage> {
  final SuperadminUserService _service = SuperadminUserService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final access = await _service.getMyAccess();
    if (access['isSuperadmin'] == true) {
      final users = await _service.listUsers();
      return {
        'access': access,
        'users': users,
      };
    }

    return {
      'access': access,
      'users': <Map<String, dynamic>>[],
    };
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final username = (user['username'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset password for $username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final p1 = controller.text;
              final p2 = confirmController.text;

              if (p1.isEmpty || p1.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum 6 characters required')),
                );
                return;
              }

              if (p1 != p2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateUserPassword(
        userId: (user['id'] ?? '').toString(),
        newPassword: controller.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      controller.dispose();
      confirmController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Passwords'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load users: ${snapshot.error}'),
              ),
            );
          }

          final payload = snapshot.data ?? const <String, dynamic>{};
          final access = Map<String, dynamic>.from(
            (payload['access'] ?? const <String, dynamic>{}) as Map,
          );
          final isSuperadmin = access['isSuperadmin'] == true;

          if (!isSuperadmin) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Only superadmin can edit other user passwords.'),
              ),
            );
          }

          final currentUserId = (_service.currentUser?.id ?? '').trim();

          final users = ((payload['users'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((u) => (u['id'] ?? '').toString() != currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Text('No users available for password reset.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final username = (user['username'] ?? '').toString();
                final displayName = (user['display_name'] ?? '').toString();
                final role = (user['role'] ?? '').toString();
                final status = (user['status'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      displayName.isEmpty ? username : displayName,
                    ),
                    subtitle: Text('Username: $username\nRole: $role\nStatus: $status'),
                    isThreeLine: true,
                    trailing: OutlinedButton(
                      onPressed: () => _resetPassword(user),
                      child: const Text('Reset'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}