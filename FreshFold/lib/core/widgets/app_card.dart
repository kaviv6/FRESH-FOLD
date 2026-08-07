import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A white, rounded, thin-bordered card — the base unit for list rows
/// throughout the app (order cards, pickup cards, service rows, etc).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.color = AppColors.white,
    this.borderColor = AppColors.borderLight,
    this.radius = 16,
    this.onTap,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final card = Opacity(
      opacity: opacity,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
        ),
        child: child,
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
