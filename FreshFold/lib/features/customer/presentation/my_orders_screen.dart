import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/order.dart';
import '../../../models/pickup.dart';
import '../../../routing/app_routes.dart';
import '../data/orders_repository.dart';
import '../data/pickup_repository.dart';

enum _Segment { pickups, orders }

bool _isTerminal(String state) => state == 'delivered' || state == 'invoiced' || state == 'cancel' || state == 'cancelled';

/// Screen 09 · My Orders.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  _Segment _segment = _Segment.pickups;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Orders', style: AppText.h1(AppColors.ink900)),
                      const LogoutButton(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentTab(
                            label: 'Pickups',
                            active: _segment == _Segment.pickups,
                            onTap: () => setState(() => _segment = _Segment.pickups),
                          ),
                        ),
                        Expanded(
                          child: _SegmentTab(
                            label: 'Orders',
                            active: _segment == _Segment.orders,
                            onTap: () => setState(() => _segment = _Segment.orders),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _segment == _Segment.pickups ? const _PickupsList() : const _OrdersList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.teal,
        onPressed: () => context.push(AppRoutes.bookPickupItems),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(color: AppColors.ink900.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: active
              ? AppText.bodySmallBold(AppColors.ink900)
              : AppText.bodySmall(AppColors.muted450).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PickupsList extends ConsumerWidget {
  const _PickupsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(pickupsListProvider);
    return AsyncValueView<List<PickupRequest>>(
      value: pickupsAsync,
      data: (context, pickups) {
        if (pickups.isEmpty) {
          return const _EmptyState(message: 'No pickups yet. Tap + to schedule one.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: pickups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = pickups[i];
            final itemCount = p.lines?.fold<int>(0, (sum, l) => sum + l.quantity) ?? 0;
            final terminal = _isTerminal(p.state);
            return AppCard(
              opacity: (p.state == 'cancel' || p.state == 'cancelled') ? 0.7 : 1,
              onTap: () => context.push(AppRoutes.pickupDetail(p.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: AppText.bodyBold(AppColors.ink900)),
                      StatusPill(label: stateLabel(p.state), state: p.state),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatRelativeDateTime(p.scheduleDate)} · $itemCount items',
                    style: AppText.caption(AppColors.muted450),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatMoney(p.totalAmount), style: AppText.bodySmallBold(AppColors.ink700)),
                      Text(
                        terminal ? 'View →' : 'Track →',
                        style: AppText.caption(AppColors.tealText).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    return AsyncValueView<List<LaundryOrder>>(
      value: ordersAsync,
      data: (context, orders) {
        if (orders.isEmpty) {
          return const _EmptyState(message: 'No orders yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final o = orders[i];
            final itemCount = o.lines?.fold<int>(0, (sum, l) => sum + l.quantity) ?? 0;
            final terminal = _isTerminal(o.state);
            return AppCard(
              opacity: (o.state == 'cancel' || o.state == 'cancelled') ? 0.7 : 1,
              onTap: () => context.push(AppRoutes.orderDetail(o.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o.name, style: AppText.bodyBold(AppColors.ink900)),
                      StatusPill(label: stateLabel(o.state), state: o.state),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatRelativeDateTime(o.orderDate)}${itemCount > 0 ? ' · $itemCount items' : ''}',
                    style: AppText.caption(AppColors.muted450),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatMoney(o.totalAmount), style: AppText.bodySmallBold(AppColors.ink700)),
                      Text(
                        terminal ? 'View →' : 'Track →',
                        style: AppText.caption(AppColors.tealText).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.muted300),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppText.body(AppColors.muted450)),
          ],
        ),
      ),
    );
  }
}
