import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/dashboard_kpis.dart';
import '../../../models/order.dart';
import '../../../models/pickup.dart';
import '../../../routing/app_routes.dart';
import '../../customer/data/orders_repository.dart';
import '../../customer/data/pickup_repository.dart';
import '../data/dashboard_repository.dart';

/// Screen 17 · Admin · Dashboard.
///
/// Stat tiles and the rider performance list come from the real
/// `POST /api/v1/dashboard` KPI endpoint (H1/H2 in ROADMAP.md). "Recent
/// activity" has no backend equivalent, so it stays client-derived from
/// [ordersListProvider] / [pickupsListProvider] — the 3 most-recently-dated
/// order/pickup records, rendered as a generic "{name} is {stateLabel}"
/// line with no fabricated actor names.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key, required this.onNavigateToTab});

  /// Switches the parent [AdminShell]'s selected bottom-nav tab. Passed down
  /// from the shell so the "Manage" quick actions (Orders/Pricing/Requests)
  /// can jump to another tab without needing a route.
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardProvider);
    final ordersAsync = ref.watch(ordersListProvider);
    final pickupsAsync = ref.watch(pickupsListProvider);

    final orders = ordersAsync.asData?.value ?? const <LaundryOrder>[];
    final pickups = pickupsAsync.asData?.value ?? const <PickupRequest>[];

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dashboard', style: AppText.h1(AppColors.ink900)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Notifications aren't wired to the backend yet")),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 19, color: AppColors.muted450),
                      ),
                      const SizedBox(width: 16),
                      const LogoutButton(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(ordersListProvider);
                  ref.invalidate(pickupsListProvider);
                  await ref.read(dashboardProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    AsyncValueView<DashboardKpis>(
                      value: kpisAsync,
                      data: (context, kpis) => _KpiSection(kpis: kpis),
                    ),
                    const SizedBox(height: 18),
                    Text('Manage', style: AppText.bodySmallBold(AppColors.ink700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ManageTile(
                            icon: Icons.receipt_long_outlined,
                            label: 'Orders',
                            onTap: () => onNavigateToTab(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ManageTile(
                            icon: Icons.local_shipping_outlined,
                            label: 'Pickups',
                            onTap: () => context.push(AppRoutes.adminPickups),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ManageTile(
                            icon: Icons.local_laundry_service_outlined,
                            label: 'Pricing',
                            onTap: () => onNavigateToTab(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ManageTile(
                            icon: Icons.business_outlined,
                            label: 'Requests',
                            onTap: () => onNavigateToTab(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AsyncValueView<DashboardKpis>(
                      value: kpisAsync,
                      data: (context, kpis) => _RiderPerformanceSection(riderStats: kpis.riderStats),
                    ),
                    const SizedBox(height: 18),
                    Text('Recent activity', style: AppText.bodySmallBold(AppColors.ink700)),
                    const SizedBox(height: 10),
                    _RecentActivityList(orders: orders, pickups: pickups),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.kpis});
  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _StatTile(value: formatMoney(kpis.revenueThisMonth), label: 'Revenue this month'),
            _StatTile(value: '${kpis.activePickups}', label: 'Active pickups', valueColor: AppColors.coralText),
            _StatTile(value: '${kpis.deliveredToday}', label: 'Delivered today', valueColor: AppColors.tealText),
            _StatTile(value: '${kpis.ridersActive}', label: 'Riders active'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.coral),
              const SizedBox(width: 8),
              Text(
                kpis.totalRatings > 0
                    ? '${kpis.avgRating.toStringAsFixed(1)} avg rating · ${kpis.totalRatings} rated'
                    : 'No ratings yet',
                style: AppText.bodySmallBold(AppColors.ink700),
              ),
              const Spacer(),
              Text('${kpis.draftOrders} draft · ${kpis.confirmedOrders} confirmed', style: AppText.caption(AppColors.muted450)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.valueColor = AppColors.ink900});

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppText.h2(valueColor)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(AppColors.muted500)),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.purple),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.caption(AppColors.ink700).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderPerformanceSection extends StatelessWidget {
  const _RiderPerformanceSection({required this.riderStats});
  final List<RiderStat> riderStats;

  @override
  Widget build(BuildContext context) {
    if (riderStats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rider performance', style: AppText.bodySmallBold(AppColors.ink700)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (var i = 0; i < riderStats.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: AppColors.coralChipBg, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.two_wheeler, size: 15, color: AppColors.coralChipText),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(riderStats[i].name, style: AppText.bodySmallBold(AppColors.ink900)),
                      ),
                      Text(
                        '${riderStats[i].activePickups} active',
                        style: AppText.caption(riderStats[i].activePickups > 0 ? AppColors.tealText : AppColors.muted450),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${riderStats[i].deliveredTotal} delivered',
                        style: AppText.caption(AppColors.muted450),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({required this.label, required this.date, required this.dotColor});
  final String label;
  final DateTime date;
  final Color dotColor;
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.orders, required this.pickups});

  final List<LaundryOrder> orders;
  final List<PickupRequest> pickups;

  @override
  Widget build(BuildContext context) {
    final entries = <_ActivityEntry>[
      for (final o in orders)
        if (o.orderDate != null)
          _ActivityEntry(
            label: '${o.name} is ${stateLabel(o.state)}',
            date: o.orderDate!,
            dotColor: AppColors.statusChip(o.state).$2,
          ),
      for (final p in pickups)
        if (p.scheduleDate != null)
          _ActivityEntry(
            label: '${p.name} is ${stateLabel(p.state)}',
            date: p.scheduleDate!,
            dotColor: AppColors.statusChip(p.state).$2,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final recent = entries.take(3).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text('No recent activity', style: AppText.bodySmall(AppColors.muted450)),
      );
    }

    return Column(
      children: [
        for (final entry in recent) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: entry.dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.label,
                    style: AppText.caption(AppColors.ink600).copyWith(fontSize: 12.5, fontWeight: FontWeight.w400),
                  ),
                ),
                Text(
                  formatRelativeDateTime(entry.date).replaceFirst('Today, ', ''),
                  style: AppText.caption(AppColors.muted400).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
