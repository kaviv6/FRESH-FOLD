import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/pickup.dart';
import '../data/pickup_repository.dart';

const _stageOrder = ['requested', 'scheduled', 'picked', 'delivered'];
const _stageLabels = {
  'requested': 'Requested',
  'scheduled': 'Scheduled',
  'picked': 'Picked Up',
  'delivered': 'Delivered',
};

/// Maps a pickup's raw `state` to how far along the 4-stage stepper is.
/// `draft` -> requested only complete; `scheduled` -> requested+scheduled;
/// `picked` -> +picked; `delivered` -> all four.
int _stageIndexFor(String state) {
  switch (state) {
    case 'draft':
      return 0;
    case 'scheduled':
      return 1;
    case 'picked':
      return 2;
    case 'delivered':
      return 3;
    default:
      return 0;
  }
}

/// Screen 10 · Pickup Detail. Route: `/customer/pickups/:id`.
class PickupDetailScreen extends ConsumerWidget {
  const PickupDetailScreen({super.key, required this.pickupId});

  final int pickupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupAsync = ref.watch(pickupDetailsProvider(pickupId));
    final title = pickupAsync.asData?.value.name ?? 'Pickup';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DetailAppBar(title: title, trailing: const LogoutButton()),
      body: AsyncValueView<PickupRequest>(
        value: pickupAsync,
        data: (context, pickup) => _PickupDetailBody(pickup: pickup),
      ),
    );
  }
}

class _PickupDetailBody extends StatelessWidget {
  const _PickupDetailBody({required this.pickup});
  final PickupRequest pickup;

  @override
  Widget build(BuildContext context) {
    final isCancelled = pickup.state == 'cancel' || pickup.state == 'cancelled';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusPill(label: stateLabel(pickup.state), state: pickup.state),
              Text(formatRelativeDateTime(pickup.scheduleDate), style: AppText.caption(AppColors.muted450)),
            ],
          ),
          const SizedBox(height: 20),
          if (isCancelled)
            _CancelledBanner()
          else
            _PickupStepper(state: pickup.state),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.coralChipBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: pickup.state == 'picked' || pickup.state == 'delivered'
                      ? const Icon(Icons.person, size: 18, color: AppColors.coralChipText)
                      : const Icon(Icons.person_outline, size: 18, color: AppColors.coralChipText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (pickup.state == 'picked' || pickup.state == 'delivered')
                            ? 'Assigned once picked up'
                            : 'Not yet assigned',
                        style: AppText.bodySmallBold(AppColors.ink900),
                      ),
                      Text('Your rider', style: AppText.caption(AppColors.muted450)),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.tealChipBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.call_outlined, size: 16, color: AppColors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Items', style: AppText.bodySmallBold(AppColors.ink700)),
          const SizedBox(height: 10),
          for (final line in pickup.lines ?? const [])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${line.serviceType ?? line.product} × ${line.quantity}', style: AppText.body(AppColors.ink600)),
                  Text(formatMoney(line.subtotal), style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppText.bodyBold(AppColors.ink900)),
                Text(formatMoney(pickup.totalAmount), style: AppText.h2(AppColors.ink900).copyWith(fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support chat coming soon')),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.redChipBgSoft, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Contact Support', style: AppText.bodyBold(AppColors.redText)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.statusChip('cancel');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('This pickup was cancelled.', style: AppText.bodySmallBold(fg)),
          ),
        ],
      ),
    );
  }
}

class _PickupStepper extends StatelessWidget {
  const _PickupStepper({required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final stageIndex = _stageIndexFor(state);
    return Row(
      children: [
        for (var i = 0; i < _stageOrder.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: i <= stageIndex ? AppColors.teal : AppColors.surfaceMuted,
              ),
            ),
          _StageDot(
            label: _stageLabels[_stageOrder[i]]!,
            done: i < stageIndex,
            current: i == stageIndex,
          ),
        ],
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.label, required this.done, required this.current});
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final active = done || current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current
                ? AppColors.coralLight
                : (done ? AppColors.teal : AppColors.surfaceMuted),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : (current ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) : null),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: active
              ? AppText.micro(AppColors.ink700).copyWith(fontWeight: FontWeight.w700, fontSize: 9.5)
              : AppText.micro(AppColors.muted350).copyWith(fontSize: 9.5),
        ),
      ],
    );
  }
}
