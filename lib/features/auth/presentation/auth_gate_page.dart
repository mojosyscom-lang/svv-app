import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/services/auth_service.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final user = _authService.currentUser;

    if (!mounted) return;

    if (user == null) {
      _go(RouteNames.login);
      return;
    }

    final profile = await _authService.getMyProfile();

    if (!mounted) return;

    if (profile == null) {
      await _authService.signOut();
      if (!mounted) return;
      _go(RouteNames.login);
      return;
    }

    final role = (profile['role'] ?? '').toString();

    if (role == 'staff') {
      _go(RouteNames.inventoryTxn);
      return;
    }

    if (role == 'owner' || role == 'superadmin') {
      _go(RouteNames.dashboard);
      return;
    }

    await _authService.signOut();
    if (!mounted) return;
    _go(RouteNames.login);
  }


    void _go(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}