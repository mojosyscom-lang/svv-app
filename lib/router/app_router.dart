import 'package:flutter/material.dart';
import '../core/constants/route_names.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/auth_gate_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/events/inventory_txn/presentation/inventory_txn_page.dart';
import '../features/splash/presentation/splash_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case RouteNames.authGate:
        return MaterialPageRoute(builder: (_) => const AuthGatePage());

      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case RouteNames.inventoryTxn:
        return MaterialPageRoute(builder: (_) => const InventoryTxnPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}