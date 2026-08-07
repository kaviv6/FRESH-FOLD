import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../models/garment.dart';
import '../data/garment_repository.dart';

const _garmentStages = ['received', 'cleaning', 'ready', 'delivered'];

const _garmentStateLabels = {
  'received': 'Received',
  'cleaning': 'Cleaning',
  'ready': 'Ready',
  'delivered': 'Delivered',
};

int _garmentStageIndex(String state) {
  final i = _garmentStages.indexOf(state);
  return i < 0 ? 0 : i;
}

/// Per-item garment tracking for an order, pushed from Order Detail when
/// `garment_count > 0`. Wraps `POST /api/v1/garment/list`, which had no UI
/// entry point before this.
class GarmentTrackingScreen extends ConsumerWidget {
  const GarmentTrackingScreen({super.key, required this.orderId, required this.orderName});

  final int orderId;
  final String orderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentsForOrderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: DetailAppBar(title: '$orderName · Garments'),
      body: AsyncValueView<List<Garment>>(
        value: garmentsAsync,
        data: (context, garments) {
          if (garments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No garments tagged for this order yet.',
                  textAlign: TextAlign.center,
                  style: AppText.body(AppColors.muted450),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            itemCount: garments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _GarmentCard(garment: garments[i]),
          );
        },
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({required this.garment});
  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final stageIndex = _garmentStageIndex(garment.state);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garment.serviceType ?? garment.name,
                      style: AppText.bodyBold(AppColors.ink900),
                    ),
                    Text(
                      '${garment.barcode} · qty ${garment.qty}',
                      style: AppText.caption(AppColors.muted450),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.statusChip(garment.state).$1,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _garmentStateLabels[garment.state] ?? garment.state,
                  style: AppText.microBold(AppColors.statusChip(garment.state).$2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _garmentStages.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: i <= stageIndex ? AppColors.teal : AppColors.surfaceMuted,
                    ),
                  ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= stageIndex ? AppColors.teal : AppColors.surfaceMuted,
                  ),
                ),
              ],
            ],
          ),
          if (garment.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(garment.notes, style: AppText.caption(AppColors.muted450)),
          ],
        ],
      ),
    );
  }
}
