import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The "‹ Title" header pattern used on every pushed detail/form screen in
/// the design (Services & Pricing, Book a Pickup, Pickup/Order Detail...).
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.backgroundColor = AppColors.white,
    this.titleColor = AppColors.ink900,
  });

  final String title;
  final Widget? trailing;
  final Color backgroundColor;
  final Color titleColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      titleSpacing: 4,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: titleColor),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(title, style: AppText.title(titleColor)),
      actions: trailing == null ? null : [trailing!, const SizedBox(width: 16)],
    );
  }
}
