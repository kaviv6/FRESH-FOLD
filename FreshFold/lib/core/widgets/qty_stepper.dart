import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The pill "− qty +" control used to pick item counts in Services &
/// Pricing / Book Pickup. When [quantity] is 0 it renders as a single "+"
/// affordance instead, matching the design's collapsed state.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.accentColor = AppColors.teal,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (quantity <= 0) {
      return GestureDetector(
        onTap: onIncrement,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text('+', style: AppText.bodyBold(accentColor)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Text('−', style: AppText.body(AppColors.ink400)),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppText.bodySmallBold(AppColors.ink900),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Text('+', style: AppText.bodyBold(accentColor)),
          ),
        ],
      ),
    );
  }
}
