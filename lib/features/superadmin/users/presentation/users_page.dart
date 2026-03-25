import 'package:flutter/material.dart';
import '../data/superadmin_user_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
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

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final currentStatus = (user['status'] ?? 'ACTIVE').toString().trim();
    final nextStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final username = (user['username'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$nextStatus user'),
        content: Text('Change status for $username to $nextStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateUserStatus(
        userId: (user['id'] ?? '').toString(),
        status: nextStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status changed to $nextStatus')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Color _statusColor(String status) {
    return status == 'ACTIVE' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
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
                child: Text('Only superadmin can access Users.'),
              ),
            );
          }

          final users = ((payload['users'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found.'),
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isEmpty ? username : displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
Text('Username: $username'),
const SizedBox(height: 2),
Text(
  'Email: ${user['email'] ?? ''}',
  style: const TextStyle(fontSize: 12, color: Colors.grey),
),
const SizedBox(height: 4),
Text('Role: $role'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(status),
                              backgroundColor:
                                  _statusColor(status).withOpacity(0.12),
                              labelStyle: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () => _toggleStatus(user),
                              icon: Icon(
                                status == 'ACTIVE'
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outline,
                              ),
                              label: Text(
                                status == 'ACTIVE' ? 'Deactivate' : 'Activate',
                              ),
                            ),
                          ],
                        ),
                      ],
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