import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/user_profile.dart';
import '../../../routing/app_routes.dart';
import '../../shared/data/serviceability_repository.dart';
import '../application/booking_cart_controller.dart';
import '../data/pickup_repository.dart';
import '../data/profile_repository.dart';

/// Checks the signed-in customer's saved address against
/// `/api/v1/serviceable` so the schedule screen can warn before submit,
/// matching the same check `pickup/create` enforces server-side. Returns
/// `null` (no verdict yet / address unknown) rather than blocking the UI
/// while the profile is still loading.
final serviceabilityForProfileProvider =
    FutureProvider.autoDispose<ServiceabilityResult?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile.zip.trim().isEmpty && profile.city.trim().isEmpty) return null;
  return ref.watch(serviceabilityRepositoryProvider).check(zip: profile.zip, city: profile.city);
});

class _DateOption {
  const _DateOption({required this.label, required this.date});
  final String label;
  final DateTime date;
}

class _TimeSlot {
  const _TimeSlot({required this.label, required this.startHour});
  final String label;
  final int startHour;
}

const _timeSlots = [
  _TimeSlot(label: '9–11 AM', startHour: 9),
  _TimeSlot(label: '11–1 PM', startHour: 11),
  _TimeSlot(label: '2–4 PM', startHour: 14),
  _TimeSlot(label: '4–6 PM', startHour: 16),
];

/// Screen 07 · Book Pickup — Step 2 · Schedule.
class BookPickupScheduleScreen extends ConsumerStatefulWidget {
  const BookPickupScheduleScreen({super.key});

  @override
  ConsumerState<BookPickupScheduleScreen> createState() => _BookPickupScheduleScreenState();
}

class _BookPickupScheduleScreenState extends ConsumerState<BookPickupScheduleScreen> {
  late final List<_DateOption> _dateOptions;
  int _selectedDateIndex = 0;
  int _selectedSlotIndex = 1; // 11–1 PM, matching design default
  String _paymentMethod = 'cod';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateOptions = [
      _DateOption(label: 'Today', date: today),
      _DateOption(label: 'Tomorrow', date: today.add(const Duration(days: 1))),
      _DateOption(label: DateFormat('MMM d').format(today.add(const Duration(days: 2))), date: today.add(const Duration(days: 2))),
    ];
    _paymentMethod = ref.read(bookingCartProvider).paymentMethod;
  }

  Future<void> _confirm() async {
    final cart = ref.read(bookingCartProvider);
    if (cart.isEmpty) return;

    final slot = _timeSlots[_selectedSlotIndex];
    final date = _dateOptions[_selectedDateIndex].date;
    final scheduleDateTime = DateTime(date.year, date.month, date.day, slot.startHour);
    final scheduleDateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduleDateTime);

    setState(() => _submitting = true);
    try {
      final pickup = await ref.read(pickupRepositoryProvider).createPickup(
            scheduleDate: scheduleDateStr,
            lines: cart.toApiLines(),
            paymentMethod: _paymentMethod,
          );
      if (!mounted) return;
      ref.read(bookingCartProvider.notifier).reset();
      context.push(
        AppRoutes.bookingConfirmed,
        extra: {
          'id': pickup.id,
          'name': pickup.name,
          'pickupWindow': '${_dateOptions[_selectedDateIndex].label}, ${slot.label}',
          'paymentMethod': _paymentMethod,
        },
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(bookingCartProvider);
    final profileAsync = ref.watch(profileProvider);
    final serviceabilityAsync = ref.watch(serviceabilityForProfileProvider);
    final notServiceable = serviceabilityAsync.asData?.value?.serviceable == false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DetailAppBar(title: 'Book a Pickup', trailing: LogoutButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: const [
                Expanded(child: _StepBar(active: true)),
                SizedBox(width: 8),
                Expanded(child: _StepBar(active: true)),
                SizedBox(width: 8),
                Expanded(child: _StepBar(active: false)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 2 · PICKUP DETAILS',
                    style: AppText.captionBold(AppColors.tealText).copyWith(letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 12),
                  _AddressCard(profileAsync: profileAsync),
                  if (notServiceable) ...[
                    const SizedBox(height: 10),
                    _ServiceabilityBanner(
                      message: serviceabilityAsync.asData?.value?.message ??
                          "Sorry, we don't serve your area yet.",
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Pickup date', style: AppText.bodySmallBold(AppColors.ink700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < _dateOptions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _DateChip(
                            label: _dateOptions[i].label,
                            selected: i == _selectedDateIndex,
                            onTap: () => setState(() => _selectedDateIndex = i),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Time slot', style: AppText.bodySmallBold(AppColors.ink700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _timeSlots.length; i++)
                        _SlotPill(
                          label: _timeSlots[i].label,
                          selected: i == _selectedSlotIndex,
                          onTap: () => setState(() => _selectedSlotIndex = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Payment method', style: AppText.bodySmallBold(AppColors.ink700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentTile(
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                          selected: _paymentMethod == 'cod',
                          onTap: () => setState(() => _paymentMethod = 'cod'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaymentTile(
                          label: 'Online',
                          icon: Icons.credit_card_outlined,
                          selected: _paymentMethod == 'online',
                          onTap: () => setState(() => _paymentMethod = 'online'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaymentTile(
                          label: 'Wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          selected: _paymentMethod == 'wallet',
                          onTap: () => setState(() => _paymentMethod = 'wallet'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
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
                    Text('Total', style: AppText.captionBold(AppColors.muted450).copyWith(fontWeight: FontWeight.w600)),
                    Text(formatMoney(cart.total), style: AppText.h2(AppColors.ink900).copyWith(fontSize: 17)),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Confirm Pickup',
                loading: _submitting,
                onPressed: (cart.isEmpty || notServiceable) ? null : _confirm,
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.profileAsync});
  final AsyncValue<UserProfile> profileAsync;

  @override
  Widget build(BuildContext context) {
    String subtitle = 'Add your address in Profile to speed up future bookings.';
    profileAsync.whenData((profile) {
      if (profile.addressSingleLine.trim().isNotEmpty) {
        subtitle = profile.addressSingleLine;
      }
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgScreen,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on_outlined, size: 18, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home', style: AppText.bodySmallBold(AppColors.ink900)),
                Text(subtitle, style: AppText.caption(AppColors.muted450).copyWith(height: 1.4)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved addresses coming soon')),
            ),
            child: Text('Change', style: AppText.bodySmallBold(AppColors.tealText).copyWith(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _ServiceabilityBanner extends StatelessWidget {
  const _ServiceabilityBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redChipBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_off_outlined, size: 18, color: AppColors.redText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppText.bodySmallBold(AppColors.redText).copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.transparent,
          border: selected ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: selected
              ? AppText.captionBold(Colors.white).copyWith(fontSize: 12.5)
              : AppText.caption(AppColors.ink700).copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.transparent,
          border: selected ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: selected
              ? AppText.caption(Colors.white).copyWith(fontWeight: FontWeight.w700)
              : AppText.caption(AppColors.ink600).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealChipBg.withOpacity(0.5) : Colors.transparent,
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.teal : AppColors.muted450),
            const SizedBox(height: 6),
            Text(
              label,
              style: selected
                  ? AppText.caption(AppColors.tealText).copyWith(fontSize: 11, fontWeight: FontWeight.w700)
                  : AppText.caption(AppColors.ink600).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
