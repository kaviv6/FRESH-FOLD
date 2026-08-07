import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/pill_filter_row.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/order.dart';
import '../../../routing/app_routes.dart';
import '../../customer/data/orders_repository.dart';

/// Screen 18 · Admin · All Orders.
///
/// `/api/v1/orders` returns every order for an admin caller (server-side
/// `_is_admin` bypasses the customer `partner_id` filter) but has no state
/// query param, so the All/Draft/Invoiced filter pills below are applied
/// client-side over the single fetched list. This reuses the exact same
/// [ordersListProvider] the customer "My Orders" tab uses.
///
/// `_format_order` does not include rider/assignee info (the design shows
/// "Rider: Rakesh K." per row) — there is no such field in the API
/// response, so we show a static "Rider: —" placeholder instead of
/// fabricating a name.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Draft', 'Invoiced'];

  List<LaundryOrder> _applyFilter(List<LaundryOrder> orders) {
    switch (_filter) {
      case 'Draft':
        return orders.where((o) => o.state == 'draft').toList();
      case 'Invoiced':
        return orders.where((o) => o.state == 'invoiced').toList();
      default:
        return orders;
    }
  }

  void _stub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Orders', style: AppText.h1(AppColors.ink900)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _stub(context, "Search isn't wired to the backend yet"),
                        child: const Icon(Icons.search, size: 19, color: AppColors.muted450),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _stub(context, "Sort isn't wired to the backend yet"),
                        child: const Icon(Icons.sort, size: 19, color: AppColors.muted450),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: PillFilterRow(
                options: _filters,
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
                accentColor: AppColors.purple,
              ),
            ),
            Expanded(
              child: AsyncValueView<List<LaundryOrder>>(
                value: ordersAsync,
                data: (context, orders) {
                  final filtered = _applyFilter(orders);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No orders here yet', style: AppText.bodySmall(AppColors.muted450)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final order = filtered[i];
                      final terminal = order.state == 'cancel' || order.state == 'cancelled';
                      return AppCard(
                        opacity: terminal ? 0.7 : 1,
                        onTap: () => context.push(AppRoutes.orderDetail(order.id)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.name, style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontSize: 13.5)),
                                StatusPill(label: stateLabel(order.state), state: order.state, dense: true),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${order.customer} · Rider: —',
                              style: AppText.caption(AppColors.muted500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatDate(order.orderDate), style: AppText.caption(AppColors.muted450)),
                                Text(formatMoney(order.totalAmount), style: AppText.bodySmallBold(AppColors.ink700)),
                              ],
                            ),
                          ],
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
