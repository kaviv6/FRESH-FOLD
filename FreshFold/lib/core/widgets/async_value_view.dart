import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Renders the three states of an [AsyncValue] with consistent loading and
/// error UI, so screens only need to supply the success builder.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) => data(context, d),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.teal),
        ),
      ),
      error: (err, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.redText, size: 32),
              const SizedBox(height: 12),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: AppText.body(AppColors.muted400),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
