import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../constants/route_names.dart';

class AppShellScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const AppShellScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: body,
    );
  }
}