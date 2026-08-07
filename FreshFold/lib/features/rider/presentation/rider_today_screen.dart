import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/pill_filter_row.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/pickup.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../data/rider_repository.dart';

class _ScanGarmentButton extends StatelessWidget {
  const _ScanGarmentButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.riderScan),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
      ),
    );
  }
}

/// Rider — Today's Pickups (design screen 14). Coral gradient header with
/// greeting + stats, a client-side state filter, and a list of pickup
/// cards with the state-dependent primary action.
class RiderTodayScreen extends ConsumerStatefulWidget {
  const RiderTodayScreen({super.key});

  @override
  ConsumerState<RiderTodayScreen> createState() => _RiderTodayScreenState();
}

class _RiderTodayScreenState extends ConsumerState<RiderTodayScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Scheduled', 'Picked'];

  @override
  Widget build(BuildContext context) {
    final pickupsAsync = ref.watch(riderPickupsProvider);
    final authState = ref.watch(authControllerProvider);
    final collectedTodayAsync = ref.watch(riderCollectionSummaryProvider('today'));

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        bottom: false,
        child: AsyncValueView<List<PickupRequest>>(
          value: pickupsAsync,
          onRetry: () => ref.invalidate(riderPickupsProvider),
          data: (context, pickups) {
            final remaining = pickups
                .where((p) => p.state != 'delivered' && p.state != 'cancel' && p.state != 'cancelled')
                .length;
            // Real remaining balance per pickup's order (accounts for
            // partial payments already made online/by wallet/collected) —
            // not just a payment_method == 'cod' guess.
            final toCollect = pickups
                .where((p) => p.state != 'delivered' && p.state != 'cancel' && p.state != 'cancelled')
                .fold<double>(0, (sum, p) => sum + p.amountDue);
            final collectedToday = collectedTodayAsync.asData?.value.collectedAmount ?? 0;

            final filtered = pickups.where((p) {
              switch (_filter) {
                case 'Scheduled':
                  return p.state == 'scheduled';
                case 'Picked':
                  return p.state == 'picked';
                default:
                  return true;
              }
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  name: authState.name ?? 'Rider',
                  pickupCount: pickups.length,
                  remaining: remaining,
                  toCollect: toCollect,
                  collectedToday: collectedToday,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: PillFilterRow(
                    options: _filters,
                    selected: _filter,
                    accentColor: AppColors.coral,
                    onSelected: (v) => setState(() => _filter = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No pickups in this filter.',
                            style: AppText.body(AppColors.muted400),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _PickupCard(pickup: filtered[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.pickupCount,
    required this.remaining,
    required this.toCollect,
    required this.collectedToday,
  });

  final String name;
  final int pickupCount;
  final int remaining;
  final double toCollect;
  final double collectedToday;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.coral, AppColors.coralDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $name', style: AppText.bodySmallBold(Colors.white.withOpacity(0.8))
                        .copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('$pickupCount pickups today',
                        style: AppText.h1(Colors.white).copyWith(fontSize: 19)),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(_initials, style: AppText.bodySmallBold(Colors.white)),
              ),
              const SizedBox(width: 10),
              const _ScanGarmentButton(),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const LogoutButton(size: 19),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(value: '$remaining', label: 'Remaining'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: formatMoney(toCollect), label: 'To collect'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: formatMoney(collectedToday), label: 'Collected today'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.h2(Colors.white).copyWith(fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _PickupCard extends ConsumerStatefulWidget {
  const _PickupCard({required this.pickup});
  final PickupRequest pickup;

  @override
  ConsumerState<_PickupCard> createState() => _PickupCardState();
}

class _PickupCardState extends ConsumerState<_PickupCard> {
  bool _loading = false;

  Future<void> _runAction(String action) async {
    setState(() => _loading = true);
    try {
      await ref.read(riderRepositoryProvider).performAction(widget.pickup.id, action);
      ref.invalidate(riderPickupsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.pickup;
    final isTerminal = pickup.state == 'delivered' ||
        pickup.state == 'cancel' ||
        pickup.state == 'cancelled';
    final itemCount = pickup.lines?.length ?? 0;
    final scheduleTime = pickup.scheduleDate != null
        ? _timeOfDay(pickup.scheduleDate!)
        : null;
    final locationParts = [
      pickup.address.city.isNotEmpty ? pickup.address.city : pickup.address.singleLine,
      if (scheduleTime != null) scheduleTime,
      '$itemCount items',
    ].where((p) => p.trim().isNotEmpty).join(' · ');

    return AppCard(
      opacity: isTerminal ? 0.6 : 1,
      onTap: () => context.push(AppRoutes.riderPickupDetail(pickup.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${pickup.customer} · ${pickup.name}',
                  style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: stateLabel(pickup.state), state: pickup.state, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted450),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationParts,
                  style: AppText.caption(AppColors.muted500).copyWith(fontWeight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isTerminal) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (pickup.state == 'scheduled') ...[
                  Expanded(
                    child: _ActionChip(
                      label: 'Navigate',
                      bg: AppColors.blueChipBg,
                      fg: AppColors.blueChipText,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Google Maps...')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionChip(
                      label: 'Pick Up',
                      bg: AppColors.coral,
                      fg: Colors.white,
                      loading: _loading,
                      onTap: () => _runAction('pickup'),
                    ),
                  ),
                ] else if (pickup.state == 'picked') ...[
                  Expanded(
                    child: _ActionChip(
                      label: 'Deliver',
                      bg: AppColors.greenChipBg,
                      fg: AppColors.greenChipText,
                      loading: _loading,
                      onTap: () => _runAction('deliver'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _timeOfDay(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: loading
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(label, style: AppText.captionBold(fg)),
      ),
    );
  }
}
