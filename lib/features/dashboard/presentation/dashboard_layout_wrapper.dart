import 'package:flutter/material.dart';
import 'dashboard_page.dart'; // Your perfectly tuned mobile/tablet version
import 'dashboard_page_web.dart'; // The new desktop version we are about to create

class DashboardLayoutWrapper extends StatelessWidget {
  const DashboardLayoutWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen width is wider than 850 pixels, it assumes it's a desktop browser
        if (constraints.maxWidth > 850) {
          return const DashboardPageWeb(); // Send them to the wide layout
        }
        
        // If it's under 850 pixels (Phones and portrait Tablets)
        // Send them to your untouched, perfectly tuned layout!
        return const DashboardPage(); 
      },
    );
  }
}