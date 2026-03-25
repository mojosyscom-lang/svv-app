import 'package:flutter/material.dart';
import '../core/constants/route_names.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/auth_gate_page.dart';
import '../features/accounting/presentation/accounting_page.dart';
import '../features/accounting/presentation/bank_accounts_page.dart';
import '../features/accounting/presentation/expenses_page.dart';
import '../features/accounting/presentation/gst_bills_page.dart';
import '../features/accounting/presentation/incoming_payments_page.dart';
import '../features/accounting/presentation/invoices_page.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/admin/company_profile/presentation/company_profile_page.dart';
import '../features/common/presentation/module_placeholder_page.dart';
import '../features/events/presentation/events_page.dart';
import '../features/dashboard/presentation/dashboard_layout_wrapper.dart';
import '../features/events/inventory_txn/presentation/inventory_txn_page.dart';
import '../features/payroll/worker_advances/presentation/worker_advances_page.dart';
import '../features/payroll/workers/presentation/workers_page.dart';
import '../features/payroll/presentation/payroll_page.dart';
import '../features/settings/presentation/my_password_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/superadmin/presentation/superadmin_page.dart';
import '../features/superadmin/users/presentation/edit_passwords_page.dart';
import '../features/superadmin/users/presentation/new_user_page.dart';
import '../features/superadmin/users/presentation/users_page.dart';

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
        // --- CHANGED: Point to the Wrapper instead of DashboardPage ---
        return MaterialPageRoute(builder: (_) => const DashboardLayoutWrapper());

      case RouteNames.inventoryTxn:
        return MaterialPageRoute(builder: (_) => const InventoryTxnPage());

      case RouteNames.payroll:
        return MaterialPageRoute(builder: (_) => const PayrollPage());

      case RouteNames.events:
        return MaterialPageRoute(builder: (_) => const EventsPage());

      case RouteNames.accounting:
        return MaterialPageRoute(builder: (_) => const AccountingPage());

      case RouteNames.accountingIncomingPayments:
        return MaterialPageRoute(builder: (_) => const IncomingPaymentsPage());

      case RouteNames.accountingExpenses:
        return MaterialPageRoute(builder: (_) => const ExpensesPage());

      case RouteNames.accountingGstBills:
        return MaterialPageRoute(builder: (_) => const GstBillsPage());

      case RouteNames.accountingInvoices:
        return MaterialPageRoute(builder: (_) => const InvoicesPage());

      case RouteNames.accountingBankAccounts:
        return MaterialPageRoute(builder: (_) => const BankAccountsPage());

      case RouteNames.settings:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Settings',
            subtitle: 'Settings module placeholder page',
          ),
        );

      case RouteNames.admin:
        return MaterialPageRoute(builder: (_) => const AdminPage());

      case RouteNames.superadmin:
        return MaterialPageRoute(builder: (_) => const SuperadminPage());

      case RouteNames.advances:
        return MaterialPageRoute(builder: (_) => const WorkerAdvancesPage());

      // --- REPLACED PLACEHOLDER WITH REAL PAGE ---
      case RouteNames.expenses:
        return MaterialPageRoute(builder: (_) => const ExpensesPage());

      case RouteNames.salary:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Salary',
            subtitle: 'Salary module placeholder page',
          ),
        );

      case RouteNames.holidays:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Worker Holidays',
            subtitle: 'Worker holidays module placeholder page',
          ),
        );

      case RouteNames.inventory:
        return MaterialPageRoute(builder: (_) => const InventoryTxnPage());

      case RouteNames.letterpad:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Letterpad',
            subtitle: 'Letterpad module placeholder page',
          ),
        );

      case RouteNames.orders:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Orders',
            subtitle: 'Orders module placeholder page',
          ),
        );

      case RouteNames.clients:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Clients',
            subtitle: 'Clients module placeholder page',
          ),
        );

      // --- REPLACED PLACEHOLDER WITH REAL PAGE ---
      case RouteNames.quotationInvoices:
        return MaterialPageRoute(builder: (_) => const InvoicesPage());

      // --- REPLACED PLACEHOLDER WITH REAL PAGE ---
      case RouteNames.gstBills:
        return MaterialPageRoute(builder: (_) => const GstBillsPage());

      case RouteNames.incomes:
        return MaterialPageRoute(builder: (_) => const IncomingPaymentsPage());

      case RouteNames.workers:
        return MaterialPageRoute(builder: (_) => const WorkersPage());

      case RouteNames.passwordReset:
        return MaterialPageRoute(builder: (_) => const MyPasswordPage());

      case RouteNames.companyProfile:
        return MaterialPageRoute(builder: (_) => const CompanyProfilePage());

      // --- REPLACED PLACEHOLDER WITH REAL PAGE ---
      case RouteNames.bankProfile:
        return MaterialPageRoute(builder: (_) => const BankAccountsPage());

      case RouteNames.inventoryMaster:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Inventory Master',
            subtitle: 'Inventory master module placeholder page',
          ),
        );

      case RouteNames.gst:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'GST',
            subtitle: 'GST settings module placeholder page',
          ),
        );

      case RouteNames.reports:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Reports',
            subtitle: 'Reports module placeholder page',
          ),
        );

      case RouteNames.exports:
        return MaterialPageRoute(
          builder: (_) => const ModulePlaceholderPage(
            title: 'Exports',
            subtitle: 'Exports module placeholder page',
          ),
        );

      case RouteNames.users:
        return MaterialPageRoute(builder: (_) => const UsersPage());

      case RouteNames.newUsers:
        return MaterialPageRoute(builder: (_) => const NewUserPage());

      case RouteNames.editPasswords:
        return MaterialPageRoute(builder: (_) => const EditPasswordsPage());

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