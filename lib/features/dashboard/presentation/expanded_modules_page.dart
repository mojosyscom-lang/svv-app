import 'dart:ui';
import 'dart:math' as math; 
import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/radial_menu.dart';

String? _routeForModuleImage(String imagePath) {
  switch (imagePath) {
    case 'assets/images/modules-icons-payroll.png':
      return RouteNames.payroll;
    case 'assets/images/modules-icons-events.png':
      return RouteNames.events;
    case 'assets/images/modules-icons-accounting.png':
      return RouteNames.accounting;
    case 'assets/images/modules-icons-settings.png':
      return RouteNames.settings;
    case 'assets/images/modules-icons-admin.png':
      return RouteNames.admin;
    case 'assets/images/modules-icons-superadmin.png':
      return RouteNames.superadmin;

    case 'assets/images/modules-icons-advance.png':
      return RouteNames.advances;
    case 'assets/images/modules-icons-expenses.png':
      return RouteNames.expenses;
    case 'assets/images/modules-icons-salary.png':
      return RouteNames.salary;
    case 'assets/images/modules-icons-holidays.png':
      return RouteNames.holidays;

    case 'assets/images/modules-icons-inventory.png':
      return RouteNames.inventory;
    case 'assets/images/modules-icons-letterpad.png':
      return RouteNames.letterpad;
    case 'assets/images/modules-icons-orders.png':
      return RouteNames.orders;
    case 'assets/images/modules-icons-clients.png':
      return RouteNames.clients;

    case 'assets/images/modules-icons-quotation-invoices.png':
      return RouteNames.quotationInvoices;
    case 'assets/images/modules-icons-gst-bills.png':
      return RouteNames.gstBills;
    case 'assets/images/modules-icons-incomes.png':
      return RouteNames.incomes;

    case 'assets/images/modules-icons-workers.png':
      return RouteNames.workers;
    case 'assets/images/modules-icons-password-reset.png':
      return RouteNames.passwordReset;

    case 'assets/images/modules-icons-company-profile.png':
      return RouteNames.companyProfile;
    case 'assets/images/modules-icons-bank-profile.png':
      return RouteNames.bankProfile;
    case 'assets/images/modules-icons-inventory-master.png':
      return RouteNames.inventoryMaster;
    case 'assets/images/modules-icons-gst.png':
      return RouteNames.gst;
    case 'assets/images/modules-icons-reports.png':
      return RouteNames.reports;
    case 'assets/images/modules-icons-exports.png':
      return RouteNames.exports;

    case 'assets/images/modules-icons-users.png':
      return RouteNames.users;
    case 'assets/images/modules-icons-new-users.png':
      return RouteNames.newUsers;
    case 'assets/images/modules-icons-edit-passwords.png':
      return RouteNames.editPasswords;
  }

  return null;
}

void _openModuleRoute(BuildContext context, String imagePath) {
  final route = _routeForModuleImage(imagePath);
  if (route == null) return;

  Navigator.of(context).pushNamed(route);
}

class ExpandedModulesPage extends StatefulWidget {
  const ExpandedModulesPage({super.key});

  @override
  State<ExpandedModulesPage> createState() => _ExpandedModulesPageState();
}

class _ExpandedModulesPageState extends State<ExpandedModulesPage> {
  // --- 1. THE DATA STRUCTURE ---
  final Map<String, List<String>> menuHierarchy = {
    'assets/images/modules-icons-payroll.png': [
      'assets/images/modules-icons-advance.png',
      'assets/images/modules-icons-expenses.png',
      'assets/images/modules-icons-salary.png',
      'assets/images/modules-icons-holidays.png',
    ],
    'assets/images/modules-icons-events.png': [
      'assets/images/modules-icons-inventory.png',
      'assets/images/modules-icons-letterpad.png',
      'assets/images/modules-icons-orders.png',
      'assets/images/modules-icons-clients.png',
    ],
    'assets/images/modules-icons-accounting.png': [
      'assets/images/modules-icons-quotation-invoices.png',
      'assets/images/modules-icons-gst-bills.png',
      'assets/images/modules-icons-incomes.png',
    ],
    'assets/images/modules-icons-settings.png': [
      'assets/images/modules-icons-workers.png',
      'assets/images/modules-icons-password-reset.png',
    ],
    'assets/images/modules-icons-admin.png': [
      'assets/images/modules-icons-company-profile.png',
      'assets/images/modules-icons-bank-profile.png',
      'assets/images/modules-icons-inventory-master.png',
      'assets/images/modules-icons-gst.png',
      'assets/images/modules-icons-reports.png',
      'assets/images/modules-icons-exports.png',
    ],
    'assets/images/modules-icons-superadmin.png': [
      'assets/images/modules-icons-users.png',
      'assets/images/modules-icons-new-users.png',
      'assets/images/modules-icons-edit-passwords.png',
    ],
  };

  // --- 2. TOP vs BOTTOM ROUTING ---
  final List<String> topHalfIcons = [
    'assets/images/modules-icons-payroll.png',
    'assets/images/modules-icons-events.png',
    'assets/images/modules-icons-superadmin.png', 
  ];

  // --- 3. THE STATE TRACKERS ---
  String? activeSubMenu;
  String? lastActiveSubMenu; 

  void _openModule(String imagePath) {
    final route = _routeForModuleImage(imagePath);
    if (route == null) return;

    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu-icons-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Tap Detector (Returns to Dashboard)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(), 
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // The Curved Sub-Menu Layer
          Positioned.fill(
            child: _buildCurvedSubMenu(size),
          ),
          
          // The Main Radial Menu
          Center(
            child: Hero(
              tag: 'modules_star',
              child: SizedBox(
                height: size.height * 0.45,
                width: size.width,
                child: Center(
                  child: RadialMenu(
                    onCenterTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation, secondaryAnimation) => 
                              AllModulesListPage(menuHierarchy: menuHierarchy),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                    items: menuHierarchy.keys.map((parentImagePath) {
                      return RadialItem(
                        imagePath: parentImagePath, 
                        onTap: () {
                          setState(() {
                            if (activeSubMenu == parentImagePath) {
                              activeSubMenu = null; 
                            } else {
                              activeSubMenu = parentImagePath;
                              lastActiveSubMenu = parentImagePath; 
                            }
                          });
                        }
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THE MATH MAGIC: Calculates the perfect curve ---
  Widget _buildCurvedSubMenu(Size size) {
    if (lastActiveSubMenu == null) return const SizedBox.shrink();

    List<String> children = menuHierarchy[lastActiveSubMenu]!;
    int count = children.length;

    double shortestSide = math.min(size.width, size.height);
    bool isLandscape = size.width > size.height;

    bool isTopHalf = topHalfIcons.contains(lastActiveSubMenu);
    double centerAngle = isTopHalf ? -math.pi / 2 : math.pi / 2;
    
    double angleStep = count > 4 ? math.pi / 7.0 : math.pi / 5; 
    
    double totalSweep = angleStep * (count - 1);
    double startAngle = centerAngle - (totalSweep / 2);

    double centerX = size.width / 2;
    
    double nudgeAmount = isLandscape ? (shortestSide * 0.01) : (shortestSide * 0.05);
    double verticalNudge = isTopHalf ? -nudgeAmount : nudgeAmount;
    double centerY = (size.height / 2) + verticalNudge;
    
    double radius = isLandscape ? shortestSide * 0.32 : shortestSide * 0.44; 
    double iconSize = isLandscape ? shortestSide * 0.09 : shortestSide * 0.12; 

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: activeSubMenu != null ? 1.0 : 0.0,
      child: Stack(
        children: children.asMap().entries.map((entry) {
          int index = entry.key;
          String imagePath = entry.value;

          double angle = startAngle + (index * angleStep);
          double dx = centerX + (radius * math.cos(angle)) - (iconSize / 2);
          double dy = centerY + (radius * math.sin(angle)) - (iconSize / 2);

          return Positioned(
            left: dx,
            top: dy,
            child: Container(
              width: iconSize, 
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: shortestSide * 0.02, 
                    offset: Offset(0, shortestSide * 0.005), 
                  )
                ]
              ),
              // --- THE GLOW EFFECT ---
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withOpacity(0.4), // Soft inner glow
                    highlightColor: Colors.white.withOpacity(0.2), // Pressed glow
                    onTap: () {
                      _openModule(imagePath);
                    },
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =========================================================================
// THE ALL MODULES DIRECTORY PAGE
// =========================================================================

class AllModulesListPage extends StatelessWidget {
  final Map<String, List<String>> menuHierarchy;

  const AllModulesListPage({super.key, required this.menuHierarchy});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double shortestSide = math.min(size.width, size.height);

    // --- 100% PERCENTAGE SCALING CONSTANTS ---
    final double parentIconSize = shortestSide * 0.16;
    final double childIconSize = shortestSide * 0.12;
    final double paddingOuter = shortestSide * 0.05;
    final double spacing = shortestSide * 0.03;
    final double borderRadius = shortestSide * 0.04;
    final double borderWidth = shortestSide * 0.005;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Solid Background 
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu-icons-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. The List of Categories
          SafeArea(
            // --- THE BACKGROUND TAP FIX ---
            // Wraps the ListView to catch any tap in empty list space or empty card space!
            child: GestureDetector(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              behavior: HitTestBehavior.translucent, // Crucial: Lets taps fall through to detector
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(paddingOuter),
                itemCount: menuHierarchy.length,
                separatorBuilder: (context, index) => SizedBox(height: spacing),
                itemBuilder: (context, index) {
                  String parentPath = menuHierarchy.keys.elementAt(index);
                  List<String> children = menuHierarchy[parentPath]!;

                  return Container(
                    padding: EdgeInsets.all(spacing),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2), 
                        width: borderWidth,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Menu Parent Icon
                        Container(
                          width: parentIconSize,
                          height: parentIconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: shortestSide * 0.02,
                                offset: Offset(0, shortestSide * 0.005),
                              )
                            ]
                          ),
                          child: Image.asset(parentPath, fit: BoxFit.contain),
                        ),
                        
                        SizedBox(width: spacing),
                        
                        // Vertical Divider
                        Container(
                          width: borderWidth,
                          height: parentIconSize * 0.8,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        
                        SizedBox(width: spacing),
                        
                        // Group of Sub-Menu Icons
                        Expanded(
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: children.map((childPath) {
                              return Container(
                                width: childIconSize,
                                height: childIconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: shortestSide * 0.015,
                                      offset: Offset(0, shortestSide * 0.004),
                                    )
                                  ]
                                ),
                                // --- THE GLOW EFFECT ---
                                child: ClipOval(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      splashColor: Colors.white.withOpacity(0.4), // Soft inner glow
                                      highlightColor: Colors.white.withOpacity(0.2), // Pressed glow
                                      onTap: () {
                                        _openModuleRoute(context, childPath);
                                      },
                                      child: Image.asset(childPath, fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}