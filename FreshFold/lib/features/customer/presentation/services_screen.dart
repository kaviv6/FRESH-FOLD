import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../models/service_type.dart';
import '../../../routing/app_routes.dart';
import '../application/booking_cart_controller.dart';
import '../data/catalog_repository.dart';

/// Screen 05 · Services & Pricing.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final cart = ref.watch(bookingCartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text('Services & Pricing', style: AppText.title(AppColors.ink900)),
        actions: const [LogoutButton(), SizedBox(width: 16)],
      ),
      body: AsyncValueView<List<ServiceType>>(
        value: servicesAsync,
        data: (context, services) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final service = services[i];
              final qty = cart.lines[service.id]?.qty ?? 0;
              return _ServiceRow(
                service: service,
                qty: qty,
                onIncrement: () => ref.read(bookingCartProvider.notifier).increment(service),
                onDecrement: () => ref.read(bookingCartProvider.notifier).decrement(service),
              );
            },
          );
        },
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
                label: 'Book Pickup',
                onPressed: () => context.push(AppRoutes.bookPickupItems),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _iconByName = <String, IconData>{
  'normal wash': Icons.local_laundry_service_outlined,
  'dry clean': Icons.dry_cleaning_outlined,
  'petrol wash': Icons.local_laundry_service_outlined,
  'bleaching': Icons.science_outlined,
  'stain removal': Icons.search,
  'steam press': Icons.iron_outlined,
};

const _bgByName = <String, Color>{
  'normal wash': AppColors.tealChipBg,
  'dry clean': AppColors.purpleChipBg,
  'petrol wash': AppColors.purpleChipBgSoft,
  'bleaching': AppColors.redChipBgSoft,
  'stain removal': AppColors.coralChipBg,
  'steam press': AppColors.coralChipBg,
};

const _fgByName = <String, Color>{
  'normal wash': AppColors.teal,
  'dry clean': AppColors.purple,
  'petrol wash': AppColors.purple,
  'bleaching': AppColors.redText,
  'stain removal': AppColors.coralText,
  'steam press': AppColors.coralText,
};

IconData iconForService(String name) => _iconByName[name.toLowerCase()] ?? Icons.local_laundry_service_outlined;
Color bgForService(String name) => _bgByName[name.toLowerCase()] ?? AppColors.tealChipBg;
Color fgForService(String name) => _fgByName[name.toLowerCase()] ?? AppColors.teal;

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgScreen,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bgForService(service.name), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(iconForService(service.name), size: 20, color: fgForService(service.name)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppText.bodyBold(AppColors.ink900)),
                Text('${formatMoney(service.price)} / item', style: AppText.caption(AppColors.muted450)),
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
