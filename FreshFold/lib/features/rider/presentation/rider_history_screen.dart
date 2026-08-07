import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/pickup.dart';
import '../data/rider_repository.dart';

/// Rider — History (design screen 16). Fully derived client-side from
/// [riderPickupsProvider] (there is no dedicated rider history endpoint):
/// delivered + cancelled pickups, grouped by calendar day of `pickupDate`
/// (falling back to `scheduleDate` when `pickupDate` is missing, e.g. a
/// cancelled-before-pickup request).
class RiderHistoryScreen extends ConsumerWidget {
  const RiderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(riderPickupsProvider);
    final collectedWeekAsync = ref.watch(riderCollectionSummaryProvider('week'));

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: AsyncValueView<List<PickupRequest>>(
          value: pickupsAsync,
          onRetry: () => ref.invalidate(riderPickupsProvider),
          data: (context, pickups) {
            final now = DateTime.now();
            final weekAgo = now.subtract(const Duration(days: 7));

            final delivered = pickups.where((p) => p.state == 'delivered').toList();
            final deliveredThisWeek = delivered.where((p) {
              final d = p.pickupDate?.toLocal();
              return d != null && d.isAfter(weekAgo);
            }).toList();
            // Real cash/UPI/card collected this week (from the payment
            // log), not a payment_method == 'cod' guess.
            final collected = collectedWeekAsync.asData?.value.collectedAmount ?? 0;

            final historyItems = pickups
                .where((p) =>
                    p.state == 'delivered' || p.state == 'cancel' || p.state == 'cancelled')
                .toList();

            final grouped = _groupByDay(historyItems);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    children: [
                      Text('History', style: AppText.h1(AppColors.ink900).copyWith(fontSize: 19)),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 19, color: AppColors.muted450),
                      const SizedBox(width: 16),
                      const LogoutButton(),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.8, -1),
                      end: Alignment(0.8, 1),
                      colors: [AppColors.coral, AppColors.coralLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${deliveredThisWeek.length}',
                              style: AppText.h2(Colors.white).copyWith(fontSize: 17)),
                          const SizedBox(height: 2),
                          Text('Delivered this week',
                              style: AppText.caption(Colors.white.withOpacity(0.85))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatMoney(collected),
                              style: AppText.h2(Colors.white).copyWith(fontSize: 17)),
                          const SizedBox(height: 2),
                          Text('Collected', style: AppText.caption(Colors.white.withOpacity(0.85))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: grouped.isEmpty
                      ? Center(
                          child: Text('No history yet.', style: AppText.body(AppColors.muted400)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          itemCount: grouped.length,
                          itemBuilder: (context, i) {
                            final group = grouped[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    group.label.toUpperCase(),
                                    style: AppText.captionBold(AppColors.muted500)
                                        .copyWith(letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final pickup in group.pickups)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _HistoryRow(pickup: pickup),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<PickupRequest> pickups) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final sorted = [...pickups]..sort((a, b) {
        final da = a.pickupDate ?? a.scheduleDate ?? DateTime(1970);
        final db = b.pickupDate ?? b.scheduleDate ?? DateTime(1970);
        return db.compareTo(da);
      });

    final Map<DateTime, List<PickupRequest>> byDay = {};
    for (final p in sorted) {
      final dt = (p.pickupDate ?? p.scheduleDate)?.toLocal();
      final key = dt != null ? DateTime(dt.year, dt.month, dt.day) : DateTime(1970);
      byDay.putIfAbsent(key, () => []).add(p);
    }

    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys.map((key) {
      String label;
      if (key == today) {
        label = 'Today';
      } else if (key == yesterday) {
        label = 'Yesterday';
      } else if (key == DateTime(1970)) {
        label = 'Earlier';
      } else {
        label = formatDate(key);
      }
      return _DayGroup(label: label, pickups: byDay[key]!);
    }).toList();
  }
}

class _DayGroup {
  _DayGroup({required this.label, required this.pickups});
  final String label;
  final List<PickupRequest> pickups;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.pickup});
  final PickupRequest pickup;

  bool get _isCancelled => pickup.state == 'cancel' || pickup.state == 'cancelled';

  String get _time {
    final dt = (pickup.pickupDate ?? pickup.scheduleDate)?.toLocal();
    if (dt == null) return '—';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final (_, statusFg) = AppColors.statusChip(pickup.state);
    return Opacity(
      opacity: _isCancelled ? 0.7 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pickup.customer, style: AppText.bodySmallBold(AppColors.ink900)),
                  const SizedBox(height: 2),
                  Text(
                    '${pickup.name} · $_time',
                    style: AppText.caption(AppColors.muted500).copyWith(fontSize: 11.5, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatMoney(pickup.totalAmount), style: AppText.bodySmallBold(AppColors.ink700)),
                const SizedBox(height: 2),
                Text(
                  stateLabel(pickup.state),
                  style: AppText.microBold(statusFg),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
