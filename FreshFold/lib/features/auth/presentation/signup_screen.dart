import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routing/app_routes.dart';
import '../application/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).signup(
          name: _nameCtrl.text.trim(),
          login: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          mobile: _mobileCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.go(AppRoutes.customerRoot);
    } else {
      final message = ref.read(authControllerProvider).errorMessage ?? 'Sign up failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Create account', style: AppText.title(AppColors.ink900)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(child: _StepBar(active: true)),
                    SizedBox(width: 8),
                    Expanded(child: _StepBar(active: false)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('STEP 1 OF 2', style: AppText.eyebrow(AppColors.teal)),
                const SizedBox(height: 4),
                Text('Your details', style: AppText.h1(AppColors.ink900)),
                const SizedBox(height: 20),
                _Field('Full name', _nameCtrl, hint: 'Anjali Mehta'),
                _Field('Mobile number', _mobileCtrl, hint: '+91 98xxxxxx10', keyboardType: TextInputType.phone),
                _Field('Email', _emailCtrl, hint: 'anjali@example.com', keyboardType: TextInputType.emailAddress),
                _Field('Password', _passwordCtrl, hint: '••••••••', obscure: true),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Continue', loading: _submitting, onPressed: _submit),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'Already have an account? ', style: AppText.bodySmall(AppColors.muted450)),
                          TextSpan(text: 'Log in', style: AppText.bodySmallBold(AppColors.teal)),
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

class _StepBar extends StatelessWidget {
  const _StepBar({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.teal : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller, {required this.hint, this.obscure = false, this.keyboardType});
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.captionBold(AppColors.ink500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: appFieldDecoration(hint: hint),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }
}
