import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routing/app_routes.dart';

/// Screen 08 · Booking Confirmed.
///
/// Reads the summary passed via go_router's `extra` from the schedule step
/// (id/name/pickupWindow/paymentMethod). Falls back to sensible placeholders
/// if `extra` is missing or the wrong shape, rather than crashing.
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final map = extra is Map ? extra as Map : const {};
    final int? pickupId = map['id'] is int ? map['id'] as int : null;
    final String requestId = map['name'] as String? ?? '—';
    final String pickupWindow = map['pickupWindow'] as String? ?? '—';
    final String paymentMethod = _paymentLabel(map['paymentMethod'] as String? ?? 'cod');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(color: AppColors.greenChipBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, size: 42, color: AppColors.greenChipText),
                  ),
                  const SizedBox(height: 24),
                  Text('Pickup Scheduled!', style: AppText.h1(AppColors.ink900)),
                  const SizedBox(height: 8),
                  Text(
                    'Your rider will arrive at your address during the selected time slot.',
                    textAlign: TextAlign.center,
                    style: AppText.body(AppColors.muted450),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bgScreen,
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Request ID', value: requestId),
                        const SizedBox(height: 10),
                        _SummaryRow(label: 'Pickup window', value: pickupWindow),
                        const SizedBox(height: 10),
                        _SummaryRow(label: 'Payment', value: paymentMethod),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Track Pickup',
                    onPressed: pickupId == null
                        ? null
                        : () => context.pushReplacement(AppRoutes.pickupDetail(pickupId)),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Back to Home',
                    onPressed: () => context.go(AppRoutes.customerRoot),
                  ),
                ],
              ),
            ),
            const Positioned(top: 0, right: 0, child: LogoutButton()),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'online':
        return 'Online Payment';
      case 'wallet':
        return 'Wallet';
      case 'cod':
      default:
        return 'Cash on Delivery';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.caption(AppColors.muted450).copyWith(fontSize: 12.5)),
        Text(value, style: AppText.bodySmallBold(AppColors.ink900)),
      ],
    );
  }
}
