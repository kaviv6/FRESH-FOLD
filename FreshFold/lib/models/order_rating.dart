/// Mirrors the `data` block returned by `POST /api/v1/order/rating`.
class OrderRating {
  const OrderRating({
    required this.ratingAvg,
    required this.ratingCount,
    required this.review,
  });

  final double ratingAvg;
  final int ratingCount;
  final String review;

  bool get hasRating => ratingCount > 0;

  factory OrderRating.fromJson(Map<String, dynamic> json) => OrderRating(
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        review: json['review'] as String? ?? '',
      );
}
