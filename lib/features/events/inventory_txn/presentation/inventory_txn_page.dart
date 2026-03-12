import 'package:flutter/material.dart';
import '../../../../core/widgets/app_shell_scaffold.dart';

class InventoryTxnPage extends StatelessWidget {
  const InventoryTxnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShellScaffold(
      title: 'Inventory Transactions',
      body: Center(
        child: Text(
          'Staff Inventory Transactions Page',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}