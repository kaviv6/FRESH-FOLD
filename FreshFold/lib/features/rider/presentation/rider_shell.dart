import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import 'rider_history_screen.dart';
import 'rider_profile_screen.dart';
import 'rider_today_screen.dart';

/// Mounted at [AppRoutes.riderRoot]. Holds the 3 rider tabs
/// (Today / History / Profile) in an [IndexedStack] so tab state survives
/// switching tabs, matching the design's persistent bottom nav (screens
/// 14 & 16).
class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _index = 0;

  static const _screens = [
    RiderTodayScreen(),
    RiderHistoryScreen(),
    RiderProfileScreen(),
  ];

  static const _items = [
    RoleBottomNavItem(icon: Icons.two_wheeler_outlined, label: 'Today'),
    RoleBottomNavItem(icon: Icons.history, label: 'History'),
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
        accentColor: AppColors.coral,
      ),
    );
  }
}
