import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../models/user_profile.dart';
import '../../../routing/app_routes.dart';
import '../data/profile_repository.dart';
import '../data/wallet_repository.dart';

/// Screen 12 · Profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: AsyncValueView<UserProfile>(
          value: profileAsync,
          data: (context, profile) => _ProfileBody(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(profile.initials, style: AppText.h2(Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppText.title(AppColors.ink900)),
                    Text(profile.email, style: AppText.caption(AppColors.muted450).copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _comingSoon(context, 'Edit profile'),
                child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted450),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const _WalletCard(),
              const SizedBox(height: 14),
              _ProfileRow(
                icon: Icons.location_on_outlined,
                label: 'My Addresses',
                onTap: () => context.push(AppRoutes.addressBook),
              ),
              const SizedBox(height: 6),
              _ProfileRow(
                icon: Icons.payments_outlined,
                label: 'Payment Methods',
                onTap: () => _comingSoon(context, 'Payment Methods'),
              ),
              const SizedBox(height: 6),
              _ProfileRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => _comingSoon(context, 'Notifications'),
              ),
              const SizedBox(height: 6),
              _ProfileRow(
                icon: Icons.business_outlined,
                iconColor: AppColors.purple,
                label: 'Request Business Account',
                onTap: () => context.push(AppRoutes.businessEnquiry),
              ),
              const SizedBox(height: 6),
              _ProfileRow(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () => _comingSoon(context, 'Help & Support'),
              ),
              const SizedBox(height: 14),
              _ProfileRow(
                icon: Icons.logout,
                iconColor: AppColors.redText,
                label: 'Log Out',
                labelColor: AppColors.redText,
                borderColor: AppColors.redChipBgSoft,
                onTap: () => confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.teal,
    this.labelColor = AppColors.ink700,
    this.borderColor = AppColors.borderLight,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppText.bodyBold(labelColor).copyWith(fontWeight: FontWeight.w600))),
              if (labelColor != AppColors.redText)
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted300),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wallet balance card — reads `POST /api/v1/wallet`, which had no UI
/// before this. Top-up is admin-only server-side (credited after an online
/// payment confirms), so there is no "add funds" action here.
class _WalletCard extends ConsumerWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_outlined, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet balance', style: AppText.caption(Colors.white70)),
                const SizedBox(height: 2),
                walletAsync.when(
                  data: (w) => Text(formatMoney(w.balance), style: AppText.title(Colors.white)),
                  loading: () => Text('—', style: AppText.title(Colors.white70)),
                  error: (_, __) => Text('Unavailable', style: AppText.bodySmallBold(Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
