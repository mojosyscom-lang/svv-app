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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _future;

  final PageController _heroController = PageController(initialPage: 1, viewportFraction: 1.0);
  ScrollController? _metricController;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.getDashboardBundle();
    AppRefreshBus.dashboardTick.addListener(_handleDashboardRefresh);
  }

  void _handleDashboardRefresh() {
    if (!mounted) return;
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_metricController == null) {
      final size = MediaQuery.of(context).size;
      
      final screenPadding = size.width * 0.05; 
      final cardSpacing = size.width * 0.025;  
      
      final availableWidth = size.width - (screenPadding * 2) - (cardSpacing * 2);
      final metricCardWidth = availableWidth / 3;
      
      _metricController = ScrollController(
        initialScrollOffset: (metricCardWidth + cardSpacing) * 4000,
      );
    }
  }

  @override
  void dispose() {
    AppRefreshBus.dashboardTick.removeListener(_handleDashboardRefresh);
    _heroController.dispose();
    _metricController?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _dashboardService.getDashboardBundle();
    });
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
    
    final screenPadding = size.width * 0.05; 
    final cardSpacing = size.width * 0.025; 
    final availableWidth = size.width - (screenPadding * 2) - (cardSpacing * 2);
    final metricCardWidth = availableWidth / 3;

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

          return SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/full-app-bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),

                RefreshIndicator(
                  onRefresh: _reload,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(userName: userName),

                        SizedBox(height: size.height * 0.01), 

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.035),
                          child: Stack(
                            children: [
                              Transform.translate(
                                offset: Offset(size.width * 0.002, size.height * 0.012),
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                  child: Image.asset(
                                    'assets/images/dashboard-txt.png',
                                    height: size.height * 0.06, 
                                    color: Colors.black.withOpacity(0.45),
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/dashboard-txt.png',
                                height: size.height * 0.058,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: size.height * 0.01),

                        SizedBox(
                          height: size.height * 0.31, 
                          child: PageView(
                            controller: _heroController,
                            clipBehavior: Clip.none,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildHeroPage(
                                DashboardHeroCard(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: 'Account Balance',
                                  amount: _dashboardService.formatMoney(data['accountBalance']),
                                  changeText: 'last txns',
                                  gradientColors: const [Color(0xFF901A35), Color(0xFFD32F2F)],
                                ),
                                size.width, 
                              ),
                              _buildHeroPage(
                                DashboardHeroCard(
                                  icon: Icons.trending_up,
                                  title: 'Total Income',
                                  amount: _dashboardService.formatMoney(data['totalIncome']),
                                  changeText: '↑ +12%',
                                  gradientColors: const [Color(0xFFE65100), Color(0xFFFFB300)],
                                ),
                                size.width,
                              ),
                              _buildHeroPage(
                                DashboardHeroCard(
                                  icon: Icons.savings_outlined,
                                  title: 'Salary',
                                  amount: _dashboardService.formatMoney(data['salary']),
                                  changeText: '↓ -5%',
                                  gradientColors: const [Color(0xFFE83A64), Color(0xFFF06292)],
                                ),
                                size.width,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: size.height * 0.015), 

                        SizedBox(
                          height: size.height * 0.17,  
                          child: ListView.builder(
                            controller: _metricController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: screenPadding),
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemExtent: metricCardWidth + cardSpacing,
                            itemBuilder: (context, index) {
                              final itemIndex = index % 4; 
                              
                              Widget card;
                              if (itemIndex == 0) {
                                card = DashboardMetricCard(imagePath: 'assets/images/expense-icon.png', title: 'Expense', value: _dashboardService.formatMoney(data['expense']));
                              } else if (itemIndex == 1) {
                                card = DashboardMetricCard(imagePath: 'assets/images/total-advance-paid-icon.png', title: 'Total Advance Paid', value: _dashboardService.formatMoney(data['advance']));
                              } else if (itemIndex == 2) {
                                card = DashboardMetricCard(imagePath: 'assets/images/gst-net-icon.png', title: 'GST Net', value: _dashboardService.formatMoney(data['gstNet']));
                              } else {
                                card = DashboardMetricCard(imagePath: 'assets/images/tds-net-icon.png', title: 'TDS Net', value: _dashboardService.formatMoney(data['tdsNet']));
                              }

                              return Padding(
                                padding: EdgeInsets.only(right: cardSpacing), 
                                child: SizedBox(
                                  width: metricCardWidth, 
                                  child: card,
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: size.height * 0.015), 

                        SizedBox(
                          width: size.width,
                          height: size.height * 0.31,  
                          child: Center(
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroPage(Widget child, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      child: child,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  const _DashboardHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.06, 
        topPadding + (size.height * 0.01), 
        size.width * 0.06, 
        size.height * 0.01
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Loading the static logo image directly
          Image.asset(
            'assets/images/svv-logo-dashboard.png',
            height: size.height * 0.045, // Adjusted to match your header height
            fit: BoxFit.contain,
          ),
          SizedBox(width: size.width * 0.04), 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shiv Video Vision',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFFFFEAA7).withOpacity(0.9), 
                      fontSize: size.height * 0.014, 
                      fontWeight: FontWeight.w600)),
              Text('Hello, $userName! 👋',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFFFFEAA7),
                      fontSize: size.height * 0.018,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}