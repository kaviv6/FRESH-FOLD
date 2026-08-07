import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/auth_result.dart';
import '../../../routing/app_routes.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      final role = ref.read(authControllerProvider).role;
      switch (role) {
        case AppRole.customer:
          context.go(AppRoutes.customerRoot);
        case AppRole.rider:
          context.go(AppRoutes.riderRoot);
        case AppRole.admin:
          context.go(AppRoutes.adminRoot);
      }
    } else {
      final message = ref.read(authControllerProvider).errorMessage ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(
                  size: 52,
                  tileColor: AppColors.tealChipBgSoft,
                  iconColor: AppColors.teal,
                  radius: 16,
                ),
                const SizedBox(height: 24),
                Text('Welcome back', style: AppText.display(AppColors.ink900)),
                const SizedBox(height: 6),
                Text(
                  'Log in to book a pickup or manage orders.',
                  style: AppText.body(AppColors.muted450),
                ),
                const SizedBox(height: 32),
                _FieldLabel('Email or mobile'),
                TextFormField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: appFieldDecoration(hint: 'you@example.com'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Password'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: appFieldDecoration(hint: 'Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.muted450,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Text('Forgot password?', style: AppText.bodySmallBold(AppColors.teal)),
                  ),
                ),
                PrimaryButton(
                  label: 'Log In',
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or continue with', style: AppText.caption(AppColors.muted350)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata)),
                    const SizedBox(width: 12),
                    Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple)),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'New here? ', style: AppText.bodySmall(AppColors.muted450)),
                          TextSpan(text: 'Create account', style: AppText.bodySmallBold(AppColors.teal)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppText.captionBold(AppColors.ink500)),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Social login is not wired up yet.')),
      ),
      icon: Icon(icon, size: 18, color: AppColors.ink700),
      label: Text(label, style: AppText.bodySmallBold(AppColors.ink700)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
