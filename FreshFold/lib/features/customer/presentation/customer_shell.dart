import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';

/// Mounted at [AppRoutes.customerRoot]. Holds the 4 customer tabs
/// (Home / Services / Orders / Profile) in an [IndexedStack] so tab state
/// (scroll position, in-progress cart, etc.) survives switching tabs,
/// matching the design's persistent bottom nav (screen 04).
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ServicesScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    RoleBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
    RoleBottomNavItem(icon: Icons.checkroom_outlined, label: 'Services'),
    RoleBottomNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    RoleBottomNavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: RoleBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        accentColor: AppColors.teal,
      ),
    );
  }
}
