import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../routing/app_routes.dart';
import '../theme/app_colors.dart';

/// Shows the "Log out?" confirmation used across every screen, then clears
/// the session and returns to the login screen.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to log in again to continue.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Log Out', style: TextStyle(color: AppColors.redText)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) context.go(AppRoutes.login);
}

/// A small logout icon for screen headers/app bars. Tapping it runs
/// [confirmLogout].
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key, this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => confirmLogout(context, ref),
      child: Icon(Icons.logout, size: size, color: AppColors.redText),
    );
  }
}
