import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/dashboard_hero_card.dart';
import '../../../core/widgets/dashboard_metric_card.dart';
import '../../../core/widgets/radial_menu.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/dashboard_service.dart';
import '../../../core/utils/app_refresh_bus.dart';
import 'expanded_modules_page.dart';

class DashboardPageWeb extends StatefulWidget {
  const DashboardPageWeb({super.key});

  @override
  State<DashboardPageWeb> createState() => _DashboardPageWebState();
}

class _DashboardPageWebState extends State<DashboardPageWeb> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.getDashboardBundle();
    AppRefreshBus.dashboardTick.addListener(_handleDashboardRefresh);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _dashboardService.getDashboardBundle();
    });
  }

  void _handleDashboardRefresh() {
    if (!mounted) return;
    _reload();
  }
  @override
  void dispose() {
    AppRefreshBus.dashboardTick.removeListener(_handleDashboardRefresh);
    super.dispose();
  }
  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
  }

  void _openExpandedModules() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => const ExpandedModulesPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final data = snapshot.data!;
          final userName = (data['userName'] ?? 'user name').toString();

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height), 
              
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/full-app-bg.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final contentWidth = constraints.maxWidth;
                        
                        final heroRowHeight = contentWidth * 0.23;
                        final metricRowHeight = contentWidth * 0.12;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DashboardHeaderWeb(userName: userName),
                              
                              const SizedBox(height: 20),

                              Stack(
                                children: [
                                  Transform.translate(
                                    offset: const Offset(2, 6),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                                      child: Image.asset(
                                        'assets/images/dashboard-txt.png',
                                        height: 60, 
                                        color: Colors.black.withOpacity(0.45),
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/images/dashboard-txt.png',
                                    height: 58,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              SizedBox(
                                height: heroRowHeight, 
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DashboardHeroCard(
                                        icon: Icons.account_balance_wallet_outlined,
                                        title: 'Account Balance',
                                        amount: _dashboardService.formatMoney(data['accountBalance']),
                                        changeText: 'last txns',
                                        gradientColors: const [Color(0xFF901A35), Color(0xFFD32F2F)],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      child: DashboardHeroCard(
                                        icon: Icons.trending_up,
                                        title: 'Total Income',
                                        amount: _dashboardService.formatMoney(data['totalIncome']),
                                        changeText: '↑ +12%',
                                        gradientColors: const [Color(0xFFE65100), Color(0xFFFFB300)],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      child: DashboardHeroCard(
                                        icon: Icons.savings_outlined,
                                        title: 'Salary',
                                        amount: _dashboardService.formatMoney(data['salary']),
                                        changeText: '↓ -5%',
                                        gradientColors: const [Color(0xFFE83A64), Color(0xFFF06292)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              SizedBox(
                                height: metricRowHeight, 
                                child: Row(
                                  children: [
                                    Expanded(child: DashboardMetricCard(imagePath: 'assets/images/expense-icon.png', title: 'Expense', value: _dashboardService.formatMoney(data['expense']))),
                                    const SizedBox(width: 25),
                                    Expanded(child: DashboardMetricCard(imagePath: 'assets/images/total-advance-paid-icon.png', title: 'Total Advance Paid', value: _dashboardService.formatMoney(data['advance']))),
                                    const SizedBox(width: 25),
                                    Expanded(child: DashboardMetricCard(imagePath: 'assets/images/gst-net-icon.png', title: 'GST Net', value: _dashboardService.formatMoney(data['gstNet']))),
                                    const SizedBox(width: 25),
                                    Expanded(child: DashboardMetricCard(imagePath: 'assets/images/tds-net-icon.png', title: 'TDS Net', value: _dashboardService.formatMoney(data['tdsNet']))),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 60),

                              Center(
                                child: SizedBox(
                                  width: contentWidth * 0.75,  
                                  height: contentWidth * 0.40, 
                                  child: RadialMenu(
                                    onCenterTap: _openExpandedModules,
                                    items: [
                                      RadialItem(
                                        imagePath: 'assets/images/modules-icons-payroll.png',
                                        onTap: () => Navigator.pushNamed(context, RouteNames.payroll),
                                      ),
                                      RadialItem(
                                        imagePath: 'assets/images/modules-icons-events.png',
                                        onTap: () => Navigator.pushNamed(context, RouteNames.events),
                                      ),
                                      RadialItem(
                                        imagePath: 'assets/images/modules-icons-admin.png',
                                        onTap: () => Navigator.pushNamed(context, RouteNames.admin),
                                      ),
                                      RadialItem(
                                        imagePath: 'assets/images/modules-icons-accounting.png',
                                        onTap: () => Navigator.pushNamed(context, RouteNames.accounting),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 50),
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeaderWeb extends StatelessWidget {
  final String userName;
  const _DashboardHeaderWeb({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Updated to use the static dashboard logo asset
        Image.asset(
          'assets/images/svv-logo-dashboard.png',
          height: 65, // Increased height for web visibility
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shiv Video Vision',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFFFEAA7).withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Hello, $userName! 👋',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFFFEAA7),
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}