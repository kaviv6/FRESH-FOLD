import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../models/service_type.dart';
import '../../customer/data/catalog_repository.dart';

/// Screen 20 · Admin · Services & Pricing.
///
/// `/api/v1/services` (`get_services`) is read-only — there is no
/// create/update/delete endpoint for `service.type` yet. The list below is
/// real data from [servicesProvider], but the header "+" button and each
/// row's edit-pencil icon are stubs that show a SnackBar instead of opening
/// a fake edit form.
class AdminServicesScreen extends ConsumerWidget {
  const AdminServicesScreen({super.key});

  void _stubEdit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Editing service pricing isn't wired to the backend yet")),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Services & Pricing', style: AppText.h1(AppColors.ink900)),
                  GestureDetector(
                    onTap: () => _stubEdit(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<ServiceType>>(
                value: servicesAsync,
                data: (context, services) {
                  if (services.isEmpty) {
                    return Center(
                      child: Text('No services configured', style: AppText.bodySmall(AppColors.muted450)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final service = services[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name, style: AppText.bodySmallBold(AppColors.ink900)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${formatMoney(service.price)} / item',
                                    style: AppText.caption(AppColors.muted500),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _stubEdit(context),
                              child: const Icon(Icons.edit_outlined, size: 17, color: AppColors.muted500),
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
