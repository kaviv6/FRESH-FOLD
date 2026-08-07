import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/admin_rider.dart';
import '../../../models/pickup.dart';
import '../../../routing/app_routes.dart';
import '../../customer/data/pickup_repository.dart';
import '../data/admin_rider_repository.dart';

/// Screen 19 · Admin · All Pickups. Pushed (not a bottom-nav tab) from the
/// Dashboard's "Pickups" quick-action tile, at [AppRoutes.adminPickups].
///
/// Each card shows the assigned rider (or an "Assign Rider" CTA) and wraps
/// `/api/v1/admin/riders` + `/api/v1/admin/pickup/assign_rider`. Until a
/// rider is assigned here, the pickup never shows up in any rider's app —
/// `rider_pickups()` filters on exactly this field server-side.
class AdminPickupsScreen extends ConsumerWidget {
  const AdminPickupsScreen({super.key});

  Future<void> _openAssignSheet(BuildContext context, WidgetRef ref, PickupRequest pickup) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AssignRiderSheet(pickup: pickup),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(pickupsListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: const DetailAppBar(title: 'Pickups'),
      body: SafeArea(
        top: false,
        child: AsyncValueView<List<PickupRequest>>(
          value: pickupsAsync,
          onRetry: () => ref.invalidate(pickupsListProvider),
          data: (context, pickups) {
            if (pickups.isEmpty) {
              return Center(
                child: Text('No pickups yet', style: AppText.bodySmall(AppColors.muted450)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              itemCount: pickups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final pickup = pickups[i];
                final terminal = pickup.state == 'cancel' || pickup.state == 'cancelled' || pickup.state == 'delivered';
                final assigned = pickup.riderId != null;
                return AppCard(
                  opacity: (pickup.state == 'cancel' || pickup.state == 'cancelled') ? 0.7 : 1,
                  onTap: () => context.push(AppRoutes.pickupDetail(pickup.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pickup.name, style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontSize: 13.5)),
                          StatusPill(label: stateLabel(pickup.state), state: pickup.state, dense: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pickup.customer} · ${formatRelativeDateTime(pickup.scheduleDate)}',
                        style: AppText.caption(AppColors.muted500),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: terminal ? null : () => _openAssignSheet(context, ref, pickup),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: assigned ? AppColors.tealChipBg : AppColors.chipNeutralBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                assigned ? Icons.two_wheeler : Icons.person_outline,
                                size: 13,
                                color: assigned ? AppColors.tealTextStrong : AppColors.muted450,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              assigned ? pickup.riderName ?? 'Assigned' : (terminal ? 'No rider assigned' : 'Assign Rider'),
                              style: AppText.caption(assigned ? AppColors.ink700 : AppColors.tealText)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (!terminal) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, size: 14, color: assigned ? AppColors.muted450 : AppColors.tealText),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AssignRiderSheet extends ConsumerStatefulWidget {
  const _AssignRiderSheet({required this.pickup});
  final PickupRequest pickup;

  @override
  ConsumerState<_AssignRiderSheet> createState() => _AssignRiderSheetState();
}

class _AssignRiderSheetState extends ConsumerState<_AssignRiderSheet> {
  int? _assigningRiderId;

  Future<void> _assign(AdminRider rider) async {
    setState(() => _assigningRiderId = rider.id);
    try {
      await ref.read(adminRiderRepositoryProvider).assignRider(
            pickupId: widget.pickup.id,
            riderId: rider.id,
          );
      ref.invalidate(pickupsListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.toString() : 'Could not assign rider.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _assigningRiderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(adminRidersListProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Rider', style: AppText.title(AppColors.ink900)),
            const SizedBox(height: 2),
            Text(widget.pickup.name, style: AppText.caption(AppColors.muted450)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: AsyncValueView<List<AdminRider>>(
                value: ridersAsync,
                onRetry: () => ref.invalidate(adminRidersListProvider),
                data: (context, riders) {
                  if (riders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No riders found.', style: AppText.body(AppColors.muted450)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: riders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final rider = riders[i];
                      final isCurrent = rider.id == widget.pickup.riderId;
                      final busy = _assigningRiderId == rider.id;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: (isCurrent || _assigningRiderId != null) ? null : () => _assign(rider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.tealChipBg.withOpacity(0.4) : AppColors.bgScreen,
                              border: Border.all(color: isCurrent ? AppColors.teal : AppColors.borderLight),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(color: AppColors.coralChipBg, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.two_wheeler, size: 16, color: AppColors.coralChipText),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(rider.name, style: AppText.bodySmallBold(AppColors.ink900)),
                                ),
                                if (busy)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                  )
                                else if (isCurrent)
                                  Text('Current', style: AppText.captionBold(AppColors.tealTextStrong))
                                else
                                  Text('${rider.activePickups} active', style: AppText.caption(AppColors.muted450)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
