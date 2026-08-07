import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/logout_button.dart';
import '../../auth/application/auth_controller.dart';

/// Rider — Profile. No dedicated design mockup exists for this screen (it
/// is only referenced as a bottom-nav tab in screens 14/16), so this is a
/// simple, style-consistent screen built from the same primitives used
/// elsewhere: an initials avatar, name, a role badge, and a log-out row.
class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final name = authState.name ?? 'Rider';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty ? '?' : parts.take(2).map((p) => p[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Text('Profile', style: AppText.h1(AppColors.ink900).copyWith(fontSize: 19)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.coralChipBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: AppText.h1(AppColors.coralChipText).copyWith(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: AppText.h2(AppColors.ink900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.coralChipBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Rider',
                        style: AppText.captionBold(AppColors.coralChipText),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => confirmLogout(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.logout, size: 19, color: AppColors.redText),
                                const SizedBox(width: 12),
                                Text('Log Out', style: AppText.bodyBold(AppColors.redText)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
