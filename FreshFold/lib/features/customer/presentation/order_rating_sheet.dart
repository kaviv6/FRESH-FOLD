import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/order_rating.dart';
import '../data/orders_repository.dart';

/// Rating + review block shown on an invoiced order's detail screen.
/// Reads/writes `POST /api/v1/order/rate` and `POST /api/v1/order/rating` —
/// neither had any UI before this.
class OrderRatingSection extends ConsumerWidget {
  const OrderRatingSection({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(orderRatingProvider(orderId));
    return ratingAsync.when(
      data: (rating) => rating.hasRating
          ? _RatingDisplay(rating: rating)
          : _RatingForm(orderId: orderId),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  const _RatingDisplay({required this.rating});
  final OrderRating rating;

  @override
  Widget build(BuildContext context) {
    final stars = rating.ratingAvg.round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgScreen,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your rating', style: AppText.bodySmallBold(AppColors.ink900)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= stars ? Icons.star : Icons.star_border,
                  size: 20,
                  color: AppColors.coral,
                ),
            ],
          ),
          if (rating.review.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rating.review, style: AppText.body(AppColors.ink600)),
          ],
        ],
      ),
    );
  }
}

class _RatingForm extends ConsumerStatefulWidget {
  const _RatingForm({required this.orderId});
  final int orderId;

  @override
  ConsumerState<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends ConsumerState<_RatingForm> {
  int _selected = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == 0) return;
    setState(() => _submitting = true);
    try {
      await ref.read(ordersRepositoryProvider).rateOrder(
            widget.orderId,
            _selected,
            review: _reviewCtrl.text.trim(),
          );
      ref.invalidate(orderRatingProvider(widget.orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for rating your order!')));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not submit rating.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgScreen,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate your order', style: AppText.bodySmallBold(AppColors.ink900)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i <= _selected ? Icons.star : Icons.star_border,
                      size: 28,
                      color: AppColors.coral,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewCtrl,
            maxLines: 2,
            decoration: appFieldDecoration(hint: 'Share your experience (optional)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Submit Rating',
              height: 44,
              loading: _submitting,
              onPressed: _selected == 0 ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
