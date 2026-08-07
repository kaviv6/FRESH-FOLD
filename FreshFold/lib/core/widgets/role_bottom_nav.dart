import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RoleBottomNavItem {
  const RoleBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// The 3/4-tab bottom bar shared by the customer, rider and admin shells —
/// white background, top hairline border, icon + label, active item tinted
/// with the role's accent color. Matches the ~78px-tall bar in the design.
class RoleBottomNav extends StatelessWidget {
  const RoleBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accentColor = AppColors.teal,
  });

  final List<RoleBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.only(bottom: 14, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavButton(
              item: items[i],
              active: i == currentIndex,
              accentColor: accentColor,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final RoleBottomNavItem item;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? accentColor : AppColors.muted350;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 21, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: active ? AppText.microBold(color) : AppText.micro(color),
          ),
        ],
      ),
    );
  }
}
