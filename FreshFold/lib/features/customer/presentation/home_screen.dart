import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/pickup.dart';
import '../../../models/service_type.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../data/catalog_repository.dart';
import '../data/pickup_repository.dart';

/// Screen 04 · Home.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final name = authState.name ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeaderSection(greeting: _greeting(), name: name)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PromoCard(
                      onTap: () => context.push(AppRoutes.bookPickupItems),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Our services', style: AppText.bodyBold(AppColors.ink900)),
                        Text('See all', style: AppText.caption(AppColors.tealText).copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ServicesPreviewRow(),
                    const SizedBox(height: 20),
                    Text('Active order', style: AppText.bodyBold(AppColors.ink900)),
                    const SizedBox(height: 12),
                    _ActiveOrderCard(),
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.tealMid, AppColors.tealDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: AppText.caption(Colors.white.withOpacity(0.75)).copyWith(fontWeight: FontWeight.w500)),
                  Text(name, style: AppText.h2(Colors.white)),
                ],
              ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
                      ),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.coralLight,
                            border: Border.all(color: AppColors.tealMid, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    alignment: Alignment.center,
                    child: const LogoutButton(size: 19),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink900.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.tealMid),
                const SizedBox(width: 10),
                Text('Search services…', style: AppText.body(AppColors.muted500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [AppColors.coral, AppColors.coralLight],
          ),
        ),
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -6,
              bottom: -10,
              child: Icon(Icons.local_laundry_service_outlined, size: 70, color: Colors.white.withOpacity(0.25)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule a pickup', style: AppText.bodyBold(Colors.white).copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 200,
                  child: Text(
                    'Doorstep pickup in as fast as 2 hours',
                    style: AppText.caption(Colors.white.withOpacity(0.85)).copyWith(fontSize: 12.5, fontWeight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Book Now', style: AppText.bodySmallBold(AppColors.coralDeep)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.coralDeep),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePreview {
  const _ServicePreview({
    required this.name,
    required this.fallbackPrice,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  final String name;
  final String fallbackPrice;
  final IconData icon;
  final Color bg;
  final Color iconColor;
}

const _servicePreviewDefs = [
  _ServicePreview(
    name: 'Normal Wash',
    fallbackPrice: 'from ₹15',
    icon: Icons.local_laundry_service_outlined,
    bg: AppColors.tealChipBg,
    iconColor: AppColors.teal,
  ),
  _ServicePreview(
    name: 'Dry Clean',
    fallbackPrice: 'from ₹50',
    icon: Icons.dry_cleaning_outlined,
    bg: AppColors.purpleChipBg,
    iconColor: AppColors.purple,
  ),
  _ServicePreview(
    name: 'Steam Press',
    fallbackPrice: 'from ₹30',
    icon: Icons.iron_outlined,
    bg: AppColors.coralChipBg,
    iconColor: AppColors.coralText,
  ),
];

class _ServicesPreviewRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final services = servicesAsync.asData?.value ?? const <ServiceType>[];

    ServiceType? findByName(String name) {
      for (final s in services) {
        if (s.name.toLowerCase() == name.toLowerCase()) return s;
      }
      return null;
    }

    return Row(
      children: [
        for (var i = 0; i < _servicePreviewDefs.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _ServicePreviewTile(def: _servicePreviewDefs[i], match: findByName(_servicePreviewDefs[i].name))),
        ],
      ],
    );
  }
}

class _ServicePreviewTile extends StatelessWidget {
  const _ServicePreviewTile({required this.def, required this.match});

  final _ServicePreview def;
  final ServiceType? match;

  @override
  Widget build(BuildContext context) {
    final priceLabel = match != null ? 'from ${formatMoney(match!.price)}' : def.fallbackPrice;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: def.bg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(def.icon, size: 17, color: def.iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            def.name,
            textAlign: TextAlign.center,
            style: AppText.caption(AppColors.ink700).copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            priceLabel,
            textAlign: TextAlign.center,
            style: AppText.caption(AppColors.muted450).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

bool _isActivePickupState(String state) => state != 'delivered' && state != 'cancel' && state != 'cancelled';

class _ActiveOrderCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(pickupsListProvider);

    return pickupsAsync.when(
      data: (pickups) {
        PickupRequest? active;
        for (final p in pickups) {
          if (_isActivePickupState(p.state)) {
            active = p;
            break;
          }
        }
        if (active == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_laundry_service_outlined, color: AppColors.muted300, size: 26),
                const SizedBox(height: 8),
                Text('No active pickups right now', style: AppText.bodySmall(AppColors.muted450)),
              ],
            ),
          );
        }
        final p = active;
        final itemCount = p.lines?.fold<int>(0, (sum, l) => sum + l.quantity) ?? 0;
        return GestureDetector(
          onTap: () => context.push(AppRoutes.pickupDetail(p.id)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontSize: 13.5)),
                    StatusPill(label: stateLabel(p.state), state: p.state, dense: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stateHint(p.state)} · $itemCount items',
                  style: AppText.caption(AppColors.muted450).copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.teal)),
      ),
      error: (e, st) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text('Could not load active order', style: AppText.bodySmall(AppColors.muted450)),
      ),
    );
  }
}

String stateHint(String state) {
  switch (state) {
    case 'draft':
      return 'Awaiting confirmation';
    case 'scheduled':
      return 'Rider scheduled for pickup';
    case 'picked':
      return 'Rider on the way to facility';
    default:
      return 'In progress';
  }
}
