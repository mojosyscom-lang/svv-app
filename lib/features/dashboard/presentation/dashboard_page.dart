import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_hero_card.dart';
import '../../../core/widgets/dashboard_metric_card.dart';
import '../../../core/widgets/dashboard_module_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.getDashboardBundle();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _dashboardService.getDashboardBundle();
    });
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load dashboard.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final userName = (data['userName'] ?? 'User').toString();

            final accountBalance =
                _dashboardService.formatMoney(data['accountBalance']);
            final totalIncome =
                _dashboardService.formatMoney(data['totalIncome']);
            final salary = _dashboardService.formatMoney(data['salary']);
            final expense = _dashboardService.formatMoney(data['expense']);
            final advance = _dashboardService.formatMoney(data['advance']);
            final gstNet = _dashboardService.formatMoney(data['gstNet']);
            final tdsNet = _dashboardService.formatMoney(data['tdsNet']);

            return RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomSafe + 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(
                      userName: userName,
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'DASHBOARD',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 215,
                      child: PageView(
                        controller: PageController(viewportFraction: 0.82),
                        padEnds: false,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 10),
                            child: DashboardHeroCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Account Balance',
                              amount: accountBalance,
                              changeText: 'LIVE',
                              gradientColors: const [
                                Color(0xFF9B1F45),
                                Color(0xFFC93F4D),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: DashboardHeroCard(
                              icon: Icons.trending_up,
                              title: 'Total Income',
                              amount: totalIncome,
                              changeText: 'MONTH',
                              gradientColors: const [
                                Color(0xFFD6742C),
                                Color(0xFFF0B34A),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: DashboardHeroCard(
                              icon: Icons.savings_outlined,
                              title: 'Salary',
                              amount: salary,
                              changeText: 'MONTH',
                              gradientColors: const [
                                Color(0xFFE56E7C),
                                Color(0xFFF19AA5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      height: 138,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        children: [
                          DashboardMetricCard(
                            icon: Icons.money_off_csred_outlined,
                            title: 'Expense',
                            value: expense,
                          ),
                          const SizedBox(width: 12),
                          DashboardMetricCard(
                            icon: Icons.account_balance_wallet,
                            title: 'Total Advance Paid',
                            value: advance,
                          ),
                          const SizedBox(width: 12),
                          DashboardMetricCard(
                            icon: Icons.percent,
                            title: 'GST Net',
                            value: gstNet,
                          ),
                          const SizedBox(width: 12),
                          DashboardMetricCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'TDS Net',
                            value: tdsNet,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'MODULES',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.86,
                        children: [
                          DashboardModuleButton(
                            icon: Icons.payments_outlined,
                            label: 'Payroll',
                            onTap: () {},
                          ),
                          DashboardModuleButton(
                            icon: Icons.event_outlined,
                            label: 'Events',
                            onTap: () {},
                          ),
                          DashboardModuleButton(
                            icon: Icons.calculate_outlined,
                            label: 'Accounting',
                            onTap: () {},
                          ),
                          DashboardModuleButton(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Admin',
                            onTap: () {},
                          ),
                          DashboardModuleButton(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            onTap: () {},
                          ),
                          DashboardModuleButton(
                            icon: Icons.logout,
                            label: 'Logout',
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final Future<void> Function() onLogout;

  const _DashboardHeader({
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12 + topSafe * 0.15, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.headerStart,
            AppColors.headerMid,
            AppColors.headerEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/logo_svv1.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shiv Video Vision',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, $userName! 👋',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}