import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The pill-shaped, drop-shadowed CTA button used everywhere in the design
/// (e.g. "Log In", "Confirm Pickup", "Mark as Picked Up").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.teal,
    this.height = 52,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: AppText.button(Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary (outlined) button variant, e.g. "Back to Home".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderColor = AppColors.border,
    this.textColor = AppColors.ink600,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: AppText.button(textColor)),
      ),
    );
  }
}
