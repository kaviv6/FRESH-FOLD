import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_services_screen.dart';

/// Mounted at [AppRoutes.adminRoot]. Holds the 4 admin bottom-nav tabs
/// (Dashboard / Orders / Pricing / Requests) in an [IndexedStack] so tab
/// state survives switching tabs, matching the design's persistent bottom
/// nav (screens 17-21). "All Pickups" (screen 19) is intentionally *not* a
/// tab here — the design only wires 4 icons into its bottom nav, and the
/// Dashboard's "Pickups" quick-action tile pushes it as a full-screen route
/// instead (see [AppRoutes.adminPickups]).
///
/// Tab switching from within a tab (e.g. the Dashboard's "Manage" quick
/// actions) is plumbed via a simple `ValueChanged<int>` callback passed down
/// to [AdminDashboardScreen] — no InheritedWidget needed since only the
/// dashboard screen needs to trigger a tab change.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _goToTab(int index) => setState(() => _index = index);

  static const _items = [
    RoleBottomNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    RoleBottomNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    RoleBottomNavItem(icon: Icons.local_laundry_service_outlined, label: 'Pricing'),
    RoleBottomNavItem(icon: Icons.business_outlined, label: 'Requests'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(onNavigateToTab: _goToTab),
      const AdminOrdersScreen(),
      const AdminServicesScreen(),
      const AdminRequestsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: RoleBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: _goToTab,
        accentColor: AppColors.purple,
      ),
    );
  }
}
