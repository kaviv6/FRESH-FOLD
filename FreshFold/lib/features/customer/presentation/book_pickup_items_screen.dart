import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../models/service_type.dart';
import '../../../routing/app_routes.dart';
import '../application/booking_cart_controller.dart';
import '../data/catalog_repository.dart';
import 'services_screen.dart' show iconForService, fgForService;

/// Screen 06 · Book Pickup — Step 1 · Select Items.
///
/// Shows the FULL catalog (not just already-selected lines) so the screen
/// is self-sufficient without bouncing back to the Services tab — lines
/// with qty > 0 get the teal-tinted "selected" treatment from the design.
class BookPickupItemsScreen extends ConsumerWidget {
  const BookPickupItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final cart = ref.watch(bookingCartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DetailAppBar(title: 'Book a Pickup', trailing: LogoutButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Row(
              children: const [
                Expanded(child: _StepBar(active: true)),
                SizedBox(width: 8),
                Expanded(child: _StepBar(active: false)),
                SizedBox(width: 8),
                Expanded(child: _StepBar(active: false)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'STEP 1 · SELECT ITEMS',
                style: AppText.captionBold(AppColors.tealText).copyWith(letterSpacing: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AsyncValueView<List<ServiceType>>(
              value: servicesAsync,
              data: (context, services) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: services.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == services.length) {
                      return _AddMoreRow(onTap: () => context.pop());
                    }
                    final service = services[i];
                    final qty = cart.lines[service.id]?.qty ?? 0;
                    return _ItemRow(
                      service: service,
                      qty: qty,
                      onIncrement: () => ref.read(bookingCartProvider.notifier).increment(service),
                      onDecrement: () => ref.read(bookingCartProvider.notifier).decrement(service),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cart.itemCount} items', style: AppText.captionBold(AppColors.muted450).copyWith(fontWeight: FontWeight.w600)),
                    Text(formatMoney(cart.total), style: AppText.h2(AppColors.ink900).copyWith(fontSize: 17)),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Continue',
                onPressed: cart.isEmpty ? null : () => context.push(AppRoutes.bookPickupSchedule),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.teal : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.service,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ServiceType service;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final selected = qty > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.tealChipBg.withOpacity(0.5) : AppColors.bgScreen,
        border: Border.all(color: selected ? AppColors.teal : AppColors.borderLight, width: selected ? 1.5 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(iconForService(service.name), size: 20, color: fgForService(service.name)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppText.bodyBold(AppColors.ink900)),
                Text(
                  selected ? '${formatMoney(service.price)} × $qty' : '${formatMoney(service.price)} / item',
                  style: AppText.caption(AppColors.muted500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          QtyStepper(quantity: qty, onIncrement: onIncrement, onDecrement: onDecrement),
        ],
      ),
    );
  }
}

class _AddMoreRow extends StatelessWidget {
  const _AddMoreRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.teal),
            const SizedBox(width: 10),
            Text('Add more services', style: AppText.bodySmallBold(AppColors.teal).copyWith(fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
