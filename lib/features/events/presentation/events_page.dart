import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const totalModules = 4;
    const realPages = 1;
    const pendingPages = 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Events Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryCard(
                  context: context,
                  title: 'Modules',
                  value: '$totalModules',
                  icon: Icons.dashboard_customize_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  context: context,
                  title: 'Live Pages',
                  value: '$realPages',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryCard(
                  context: context,
                  title: 'Pending',
                  value: '$pendingPages',
                  icon: Icons.pending_actions_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  context: context,
                  title: 'Group',
                  value: 'Events',
                  icon: Icons.event_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Event Modules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _sectionTile(
              icon: Icons.assignment_outlined,
              title: 'Orders',
              subtitle: 'Orders and event workflow',
              onTap: () => Navigator.pushNamed(context, RouteNames.orders),
            ),
            _sectionTile(
              icon: Icons.people_alt_outlined,
              title: 'Clients',
              subtitle: 'Client records and details',
              onTap: () => Navigator.pushNamed(context, RouteNames.clients),
            ),
            _sectionTile(
              icon: Icons.inventory_2_outlined,
              title: 'Inventory',
              subtitle: 'Inventory and movement tracking',
              onTap: () => Navigator.pushNamed(context, RouteNames.inventory),
            ),
            _sectionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Letterpad',
              subtitle: 'Letterpad and printable formats',
              onTap: () => Navigator.pushNamed(context, RouteNames.letterpad),
            ),
          ],
        ),
      ),
    );
  }
}