import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../models/auth_result.dart';
import '../../../routing/app_routes.dart';
import '../application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.status == SessionStatus.authenticated) {
      switch (state.role) {
        case AppRole.customer:
          context.go(AppRoutes.customerRoot);
        case AppRole.rider:
          context.go(AppRoutes.riderRoot);
        case AppRole.admin:
          context.go(AppRoutes.adminRoot);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [AppColors.teal, AppColors.tealDeep],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 96),
              const SizedBox(height: 20),
              const Text(
                'FreshFold',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Laundry, picked up & delivered',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
