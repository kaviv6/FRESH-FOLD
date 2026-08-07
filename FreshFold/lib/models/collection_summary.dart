/// Mirrors the `data` payload of `/api/v1/rider/collection_summary` —
/// total cash/UPI/card collected in person by a rider over a period.
class CollectionSummary {
  const CollectionSummary({
    required this.collectedAmount,
    required this.collectionsCount,
    required this.period,
  });

  final double collectedAmount;
  final int collectionsCount;
  final String period;

  factory CollectionSummary.fromJson(Map<String, dynamic> json) => CollectionSummary(
        collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0,
        collectionsCount: (json['collections_count'] as num?)?.toInt() ?? 0,
        period: json['period'] as String? ?? 'today',
      );
}
