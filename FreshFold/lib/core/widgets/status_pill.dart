import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The rounded status chip used on order/pickup cards (e.g. "Picked Up",
/// "Scheduled", "Delivered", "Cancelled").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.state, this.dense = false});

  final String label;
  final String state;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.statusChip(state);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 12, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        label,
        style: (dense ? AppText.microBold(fg) : AppText.captionBold(fg)),
      ),
    );
  }
}

/// Human-readable label for a raw Odoo state string.
String stateLabel(String state) {
  switch (state) {
    case 'draft':
      return 'Draft';
    case 'order':
      return 'Order';
    case 'scheduled':
      return 'Scheduled';
    case 'picked':
      return 'Picked Up';
    case 'invoiced':
      return 'Invoiced';
    case 'delivered':
      return 'Delivered';
    case 'cancel':
    case 'cancelled':
      return 'Cancelled';
    case 'submitted':
      return 'Submitted';
    case 'in_negotiation':
      return 'Negotiation';
    case 'converted':
      return 'Converted';
    default:
      return state;
  }
}
