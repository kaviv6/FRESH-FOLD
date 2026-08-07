import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Horizontal row of rounded filter chips, e.g. the "All / Scheduled /
/// Picked" row on the rider Today screen or "All / Draft / Invoiced" on
/// Admin Orders.
class PillFilterRow extends StatelessWidget {
  const PillFilterRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.accentColor = AppColors.teal,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _Pill(
              label: option,
              active: option == selected,
              accentColor: accentColor,
              onTap: () => onSelected(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: active ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: active
              ? AppText.captionBold(Colors.white)
              : AppText.caption(AppColors.ink400).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
